using Kripteks.Core.Interfaces;
using Kripteks.Core.Models.Strategy;
using Kripteks.Infrastructure.Helpers;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Strategies;

public class Sma111BuySellStrategy : BaseStrategy
{
    private const int Sma111Period = 111;
    private const int Sma350Period = 350;

    // Multipliers for visualization
    private readonly decimal[] _multipliers = { 0.702m, 1.618m, 2.0m, 3.0m, 5.0m, 8.0m, 13.0m, 21.0m };

    public Sma111BuySellStrategy(ILogger<Sma111BuySellStrategy> logger) : base(logger)
    {
    }

    public override string Id => "Sma111BuySellStrategy";
    public override string Name => "SMA 111 Kırılım Al-Sat";

    public override string Description =>
        "Fiyatın 111 günlük SMA'yı yukarı kestiğinde AL, aşağı kestiğinde SAT sinyali ürettiği trend takip stratejisi.";

    protected override StrategyResult OnAnalyze(List<Candle> candles, decimal currentBalance,
        decimal currentPositionAmount, decimal entryPrice, int currentStep)
    {
        // Yeterli veri kontrolü (en az SMA111 period + 4 mum gerekli ki geçmiş mumları kontrol edebilelim)
        if (candles.Count < Sma111Period + 4)
        {
            return new StrategyResult { Action = TradeAction.None, Description = "Yetersiz veri." };
        }

        var prices = candles.Select(c => c.Close).ToList();
        var lastCandle = candles.Last();
        var prevCandle = candles[candles.Count - 2];

        // SMA Hesaplamaları
        var sma111Values = TechnicalIndicators.CalculateSma(prices, Sma111Period);
        var sma350Values = TechnicalIndicators.CalculateSma(prices, Sma350Period);

        var currentSma111 = sma111Values.Last();
        var prevSma111 = sma111Values[sma111Values.Count - 2];
        var currentSma350 = sma350Values.Last();

        // Veri Validasyonu
        if (currentSma111 == null || prevSma111 == null || currentSma350 == null)
        {
            return new StrategyResult { Action = TradeAction.None, Description = "Yetersiz SMA verisi." };
        }

        // Görselleştirme Verileri
        var indicators = new Dictionary<string, object>
        {
            { "SMA111", currentSma111.Value },
            { "SMA350", currentSma350.Value }
        };

        foreach (var m in _multipliers)
        {
            indicators.Add($"x{m}", currentSma350.Value * m);
        }

        // Sinyal Mantığı: State Check yerine Crossover Check (Whipsaw önlemek için)
        // Ancak tarayıcıdan "Hızlı Al" yapıldığında kapanmış mumun kırılımını da yakalamak için
        // son 3 mum içerisindeki kırılımları geçerli sayıyoruz.

        TradeAction action = TradeAction.None;
        string message = string.Empty;

        var prevPrevCandle = candles[candles.Count - 3];
        var prevPrevSma111 = sma111Values[sma111Values.Count - 3];
        var prev3Candle = candles[candles.Count - 4];
        var prev3Sma111 = sma111Values[sma111Values.Count - 4];

        // Veri Validasyonu
        if (currentSma111 == null || prevSma111 == null || currentSma350 == null || prevPrevSma111 == null ||
            prev3Sma111 == null)
        {
            return new StrategyResult { Action = TradeAction.None, Description = "Yetersiz SMA verisi." };
        }

        // AL Sinyali Kontrolleri
        bool isCurrentBullishCross = prevCandle.Close <= prevSma111.Value && lastCandle.Close > currentSma111.Value;
        bool isRecentBullishCross1 = prevPrevCandle.Close <= prevPrevSma111.Value &&
                                     prevCandle.Close > prevSma111.Value && lastCandle.Close > currentSma111.Value;
        bool isRecentBullishCross2 = prev3Candle.Close <= prev3Sma111.Value &&
                                     prevPrevCandle.Close > prevPrevSma111.Value &&
                                     prevCandle.Close > prevSma111.Value && lastCandle.Close > currentSma111.Value;

        bool isBullishCross = isCurrentBullishCross || isRecentBullishCross1 || isRecentBullishCross2;

        // SAT Sinyali Kontrolleri (Satış için anlık veya 1 önceki kapanış yeterli)
        bool isCurrentBearishCross = prevCandle.Close >= prevSma111.Value && lastCandle.Close < currentSma111.Value;
        bool isRecentBearishCross1 = prevPrevCandle.Close >= prevPrevSma111.Value &&
                                     prevCandle.Close < prevSma111.Value && lastCandle.Close < currentSma111.Value;

        bool isBearishCross = isCurrentBearishCross || isRecentBearishCross1;

        // Pozisyon Yönetimi ve Sinyal Üretimi
        if (currentPositionAmount == 0)
        {
            // Pozisyon yoksa, sadece ALIM kesişimi (Bullish Crossover) varsa işlem aç
            if (isBullishCross)
            {
                action = TradeAction.Buy;
                message =
                    $"SMA 111 KESİŞİMİ (YUKARI): Fiyat {prevCandle.Close:F8} -> {lastCandle.Close:F8}, SMA {currentSma111:F8}";
            }
            else
            {
                action = TradeAction.None;
                // Durum bilgisi (Opsiyonel: Kullanıcıya trendin ne olduğunu söylemek için)
                if (lastCandle.Close > currentSma111.Value)
                    message = "Trend YUKARI (Pozisyon yok, yeni kesişim bekleniyor)";
                else
                    message = "Trend AŞAĞI (Nötr)";
            }
        }
        else
        {
            // Pozisyon varsa, sadece SATIM kesişimi (Bearish Crossover) varsa işlem kapat
            if (isBearishCross)
            {
                action = TradeAction.Sell;
                message =
                    $"SMA 111 KESİŞİMİ (AŞAĞI): Fiyat {prevCandle.Close:F8} -> {lastCandle.Close:F8}, SMA {currentSma111:F8}. Pozisyon kapatılıyor.";
            }
            else
            {
                action = TradeAction.None;
                message = $"Pozisyon taşınıyor. Fiyat: {lastCandle.Close:F8} > SMA111: {currentSma111:F8}";
            }
        }

        return new StrategyResult
        {
            Action = action,
            Description = message,
            Price = lastCandle.Close,
            Time = lastCandle.OpenTime,
            Indicators = indicators
        };
    }

    protected override decimal OnCalculateSignalScore(List<Candle> candles)
    {
        // Basit skorlama: 
        // Fiyat SMA 111 üzerindeyse => 80
        // Fiyat SMA 111 altındaysa => 20
        // Veri yoksa => 0

        if (candles.Count < Sma111Period) return 0;

        var prices = candles.Select(c => c.Close).ToList();
        var sma111Values = TechnicalIndicators.CalculateSma(prices, Sma111Period);
        var currentSma111 = sma111Values.Last();
        var lastPrice = candles.Last().Close;

        if (currentSma111 == null) return 0;

        if (lastPrice > currentSma111.Value)
        {
            // Trend yukarı, güçlü alım/tutma bölgesi
            return 80;
        }
        else
        {
            // Trend aşağı
            return 20;
        }
    }
}
