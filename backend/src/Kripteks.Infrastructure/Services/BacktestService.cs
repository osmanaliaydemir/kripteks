using Kripteks.Core.DTOs;
using Kripteks.Core.Interfaces;
using Binance.Net.Clients;
using Binance.Net.Enums;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class BacktestService
{
    private readonly BinanceRestClient _client;
    private readonly ILogger<BacktestService> _logger;

    public BacktestService(ILogger<BacktestService> logger)
    {
        _logger = logger;
        _client = new BinanceRestClient();
    }

    public async Task<BacktestResultDto> RunBacktestAsync(BacktestRequestDto request)
    {
        var result = new BacktestResultDto
        {
            Trades = new List<BacktestTradeDto>()
        };

        // 1. Tarih Aralığını Belirle
        // 1. Tarih Aralığı Belirle
        DateTime startTime;
        DateTime endTime = DateTime.UtcNow;

        if (!string.IsNullOrEmpty(request.StartDate))
        {
            // Kullanıcı özel tarih seçmiş
            if (DateTime.TryParse(request.StartDate, out var s))
            {
                startTime = s;

                // EndDate varsa onu kullan, yoksa bugünün sonuna kadar (Default UtcNow zaten)
                if (!string.IsNullOrEmpty(request.EndDate) && DateTime.TryParse(request.EndDate, out var e))
                {
                    endTime = e.AddDays(1).AddSeconds(-1); // Gün sonu
                }
            }
            else
            {
                startTime = DateTime.UtcNow.AddDays(-7);
            }
        }
        else
        {
            // Periyod seçimi
            startTime = DateTime.UtcNow.AddDays(-7); // Default
            if (request.Period == "1d") startTime = DateTime.UtcNow.AddDays(-1);
            else if (request.Period == "30d") startTime = DateTime.UtcNow.AddDays(-30);
            else if (request.Period == "90d") startTime = DateTime.UtcNow.AddDays(-90);
        }

        // Warm-up için geriye git (350 mum)
        var intervalSpan = GetIntervalTimeSpan(request.Interval);
        startTime = startTime.Subtract(intervalSpan * 350);

        // 2. Binance Verilerini Çek
        var symbol = request.Symbol.Replace("/", "").ToUpper();

        // Strateji seçimi (Şu an hardcoded "GoldenRose" ama ileride Factory kullanılabilir)
        IStrategy strategy;
        if (request.StrategyId == "strategy-golden-rose")
        {
            strategy = new Kripteks.Infrastructure.Strategies.GoldenRoseStrategy();
        }
        else
        {
            // Varsayılan / Fallback
            _logger.LogWarning("Strateji bulunamadı, Golden Rose kullanılıyor: {Id}", request.StrategyId);
            strategy = new Kripteks.Infrastructure.Strategies.GoldenRoseStrategy();
        }

        var interval = request.Interval switch
        {
            "1m" => KlineInterval.OneMinute,
            "3m" => KlineInterval.ThreeMinutes,
            "5m" => KlineInterval.FiveMinutes,
            "15m" => KlineInterval.FifteenMinutes,
            "30m" => KlineInterval.ThirtyMinutes,
            "1h" => KlineInterval.OneHour,
            "2h" => KlineInterval.TwoHour,
            "4h" => KlineInterval.FourHour,
            "1d" => KlineInterval.OneDay,
            "1w" => KlineInterval.OneWeek,
            _ => KlineInterval.FifteenMinutes
        };

        try
        {
            // Backtest için yeterli veri çekelim (Pagination ile)
            // Hedef: İstenen start time'dan bugüne kadar olan verileri 1000'er 1000'er çekip birleştirmek.

            var allCandles = new List<Candle>();
            var currentStartTime = startTime;
            // endTime is already defined above

            while (currentStartTime < endTime)
            {
                // Binance'den çek
                var klines =
                    await _client.SpotApi.ExchangeData.GetKlinesAsync(symbol, interval, startTime: currentStartTime,
                        limit: 1000);

                if (!klines.Success || !klines.Data.Any()) break;

                var batch = klines.Data.Select(k => new Candle
                {
                    OpenTime = k.OpenTime,
                    Open = k.OpenPrice,
                    High = k.HighPrice,
                    Low = k.LowPrice,
                    Close = k.ClosePrice,
                    Volume = k.Volume
                }).ToList();

                allCandles.AddRange(batch);

                // Son çekilen mumun zamanı bir sonraki sorgunun başlangıcı olsun
                var lastCandleTime = klines.Data.Last().OpenTime;

                // Eğer son mum zaten end time'a çok yakınsa veya döngü sonsuza girerse çık
                if (lastCandleTime >= endTime.AddMinutes(-5)) break;

                // Bir sonraki batch için başlangıç zamanını güncelle (Son mumun açılış saati + 1 interval kadar ileri gitmek lazım ama basitçe son mum zamanı + 1ms diyelim)
                // Binance GetKlines startTime inclusive'dir. O yüzden son mumun kapanış saati veya openTime + interval eklemek gerekir.
                // Fakat interval enum olduğu için generic bir ekleme yapamayız. 
                // Pratik çözüm: Son mumun OpenTime'ına biraz ekle.
                currentStartTime = lastCandleTime.AddSeconds(1);

                // Eğer batch 1000'den az geldiyse zaten veri bitmiştir
                if (batch.Count < 1000) break;

                // API Rate Limit'e takılmamak için minik bir bekleme (Opsiyonel ama iyi olur)
                await Task.Delay(100);
            }

            _logger.LogInformation("Backtest Veri Tamamlandı: {Symbol} | Toplam {Count} mum çekildi.", symbol,
                allCandles.Count);

            var candles = allCandles;

            decimal currentBalance = request.InitialBalance;
            decimal positionAmount = 0;

            decimal entryPrice = 0;
            DateTime entryDate = DateTime.MinValue;
            decimal targetPrice = 0;
            decimal stopPrice = 0;
            bool inPosition = false;

            // Simülasyon Döngüsü
            // Stratejinin ısınması için gereken ilk N mumu atlamamız lazım (350 SMA için 350 mum)
            int warmUpPeriod = 350;

            for (int i = warmUpPeriod; i < candles.Count; i++)
            {
                // O ana kadar olan mumlar (Sanal Geçmiş)
                var history = candles.Take(i + 1).ToList();
                var currentCandle = candles[i];

                // Stratejiye sor: Ne yapayım?
                var signal = strategy.Analyze(history, currentBalance, positionAmount);

                if (!inPosition)
                {
                    // ALIM SİNYALİ GELDİ Mİ?
                    if (signal.Action == TradeAction.Buy)
                    {
                        decimal amountToInvest = currentBalance; // Tüm parayla gir (Basitlik için)
                        positionAmount = amountToInvest / currentCandle.Close;
                        currentBalance -= amountToInvest;
                        currentBalance -= amountToInvest;
                        entryPrice = currentCandle.Close;
                        entryDate = currentCandle.OpenTime;
                        targetPrice = signal.TargetPrice; // Stratejiden gelen hedef
                        stopPrice = signal.StopPrice; // Stratejiden gelen stop
                        inPosition = true;
                    }
                }
                else
                {
                    // POZİSYNDAYIZ: SATIŞ KONTROLÜ
                    bool shouldSell = false;
                    string exitReason = "";

                    // 1. Stratejiden Satış Sinyali Geldi mi? (Trend Bozulması)
                    if (signal.Action == TradeAction.Sell)
                    {
                        shouldSell = true;
                        exitReason = signal.Description;
                    }
                    // 2. Kar Al Hedefi
                    else if (targetPrice > 0 && currentCandle.High >= targetPrice)
                    {
                        shouldSell = true;
                        exitReason = "Take Profit (Golden Rose Hedefi)";
                    }
                    // 3. Zarar Durdur
                    else if (stopPrice > 0 && currentCandle.Low <= stopPrice)
                    {
                        shouldSell = true;
                        exitReason = "Stop Loss";
                    }

                    if (shouldSell)
                    {
                        // ÇIKIŞ YAP

                        // Gerçekçi çıkış fiyatı (Eğer TP ise TargetPrice, SL ise StopPrice, Sinyal ise Close)
                        decimal exitPrice = currentCandle.Close;
                        if (exitReason.Contains("Take Profit")) exitPrice = targetPrice;
                        else if (exitReason.Contains("Stop Loss")) exitPrice = stopPrice;

                        decimal exitTotal = positionAmount * exitPrice;
                        decimal pnl = exitTotal - (positionAmount * entryPrice);
                        currentBalance += exitTotal;

                        result.Trades.Add(new BacktestTradeDto
                        {
                            Type = pnl > 0 ? $"Take Profit ({exitReason})" : $"Stop Loss ({exitReason})",
                            EntryDate = entryDate,
                            ExitDate = currentCandle.OpenTime,
                            EntryPrice = entryPrice,
                            ExitPrice = exitPrice,
                            Pnl = pnl
                        });

                        inPosition = false;
                        positionAmount = 0;
                        entryPrice = 0;
                    }
                }
            }

            // İstatistikleri Hesapla
            result.TotalTrades = result.Trades.Count;
            result.WinningTrades = result.Trades.Count(t => t.Pnl > 0);
            result.LosingTrades = result.Trades.Count(t => t.Pnl <= 0);
            result.TotalPnl = result.Trades.Sum(t => t.Pnl);
            result.TotalPnlPercent = (result.TotalPnl / request.InitialBalance) * 100;
            result.WinRate = result.TotalTrades > 0 ? ((decimal)result.WinningTrades / result.TotalTrades) * 100 : 0;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Backtest sırasında hata oluştu: {Message}", ex.Message);
            throw;
        }

        return result;
    }

    private TimeSpan GetIntervalTimeSpan(string interval)
    {
        return interval switch
        {
            "1m" => TimeSpan.FromMinutes(1),
            "3m" => TimeSpan.FromMinutes(3),
            "5m" => TimeSpan.FromMinutes(5),
            "15m" => TimeSpan.FromMinutes(15),
            "30m" => TimeSpan.FromMinutes(30),
            "1h" => TimeSpan.FromHours(1),
            "2h" => TimeSpan.FromHours(2),
            "4h" => TimeSpan.FromHours(4),
            "6h" => TimeSpan.FromHours(6),
            "8h" => TimeSpan.FromHours(8),
            "12h" => TimeSpan.FromHours(12),
            "1d" => TimeSpan.FromDays(1),
            "1w" => TimeSpan.FromDays(7),
            _ => TimeSpan.FromMinutes(15)
        };
    }
}

// DTOs (Dosya içinde pratik olsun diye)
public class BacktestRequestDto
{
    public string Symbol { get; set; } = "BTC/USDT";
    public string StrategyId { get; set; }
    public string Period { get; set; } = "7d";
    public string? StartDate { get; set; } // YYYY-MM-DD
    public string? EndDate { get; set; } // YYYY-MM-DD
    public string Interval { get; set; } = "15m"; // Yeni alan: 3m, 5m, 15m, 1h...
    public decimal InitialBalance { get; set; } = 1000;
}

public class BacktestResultDto
{
    public int TotalTrades { get; set; }
    public int WinningTrades { get; set; }
    public int LosingTrades { get; set; }
    public decimal TotalPnl { get; set; }
    public decimal TotalPnlPercent { get; set; }
    public decimal WinRate { get; set; }
    public decimal MaxDrawdown { get; set; }
    public List<BacktestTradeDto> Trades { get; set; }
}

public class BacktestTradeDto
{
    public string Type { get; set; } // Take Profit, Stop Loss
    public DateTime EntryDate { get; set; }
    public DateTime ExitDate { get; set; }
    public decimal EntryPrice { get; set; }
    public decimal ExitPrice { get; set; }
    public decimal Pnl { get; set; }
}
