using Kripteks.Core.Interfaces;
using Binance.Net.Clients;
using Binance.Net.Enums;
using Microsoft.Extensions.Logging;
using Kripteks.Infrastructure.Strategies;

namespace Kripteks.Infrastructure.Services;

public class BacktestService
{
    private readonly BinanceRestClient _client;
    private readonly ILogger<BacktestService> _logger;
    private readonly IStrategyFactory _strategyFactory;

    public BacktestService(ILogger<BacktestService> logger, IStrategyFactory strategyFactory)
    {
        _logger = logger;
        _strategyFactory = strategyFactory;
        _client = new BinanceRestClient();
    }

    public async Task<BacktestResultDto> RunBacktestAsync(BacktestRequestDto request)
    {
        var allCandles = await FetchCandlesAsync(request);
        return SimulateBacktest(request, allCandles, request.StrategyParameters);
    }

    public async Task<OptimizationResultDto> OptimizeBacktestAsync(BacktestRequestDto request)
    {
        var allCandles = await FetchCandlesAsync(request);
        var bestResult = new OptimizationResultDto();
        var searchSpace = GetOptimizationSpace(request.StrategyId);

        _logger.LogInformation("Optimizing {StrategyId} in {SpaceCount} combinations...", request.StrategyId,
            searchSpace.Count);

        foreach (var parameters in searchSpace)
        {
            var currentResult = SimulateBacktest(request, allCandles, parameters);
            if (currentResult.TotalPnlPercent > bestResult.BestPnlPercent)
            {
                bestResult.BestPnlPercent = currentResult.TotalPnlPercent;
                bestResult.BestParameters = parameters;
                bestResult.Result = currentResult;
            }
        }

        return bestResult;
    }

    private List<Dictionary<string, string>> GetOptimizationSpace(string strategyId)
    {
        var space = new List<Dictionary<string, string>>();

        if (strategyId == "strategy-golden-rose")
        {
            // Search space for Golden Rose
            foreach (var sma1 in new[] { 100, 111, 120 })
            foreach (var sma2 in new[] { 300, 350, 400 })
            foreach (var tp in new[] { "1.5", "1.618", "1.8" })
            foreach (var cycle in new[] { "2", "2.2" })
            {
                space.Add(new Dictionary<string, string>
                {
                    { "sma1", sma1.ToString() },
                    { "sma2", sma2.ToString() },
                    { "tp", tp },
                    { "cycleTop", cycle }
                });
            }
        }
        else if (strategyId == "strategy-alpha-trend")
        {
            // Search space for Alpha Trend
            foreach (var fast in new[] { 15, 20, 25 })
            foreach (var slow in new[] { 45, 50, 60 })
            foreach (var rsiBuy in new[] { "60", "65", "70" })
            {
                space.Add(new Dictionary<string, string>
                {
                    { "fastEma", fast.ToString() },
                    { "slowEma", slow.ToString() },
                    { "rsiPeriod", "14" },
                    { "rsiBuy", rsiBuy },
                    { "rsiSell", "75" }
                });
            }
        }

        return space;
    }

    private async Task<List<Candle>> FetchCandlesAsync(BacktestRequestDto request)
    {
        DateTime startTime;
        DateTime endTime = DateTime.UtcNow;

        if (!string.IsNullOrEmpty(request.StartDate))
        {
            if (DateTime.TryParse(request.StartDate, out var s))
            {
                startTime = s;
                if (!string.IsNullOrEmpty(request.EndDate) && DateTime.TryParse(request.EndDate, out var e))
                    endTime = e.AddDays(1).AddSeconds(-1);
            }
            else startTime = DateTime.UtcNow.AddDays(-7);
        }
        else
        {
            startTime = DateTime.UtcNow.AddDays(-7);
            if (request.Period == "1d") startTime = DateTime.UtcNow.AddDays(-1);
            else if (request.Period == "30d") startTime = DateTime.UtcNow.AddDays(-30);
            else if (request.Period == "90d") startTime = DateTime.UtcNow.AddDays(-90);
        }

        var intervalSpan = GetIntervalTimeSpan(request.Interval);
        startTime = startTime.Subtract(intervalSpan * 400); // Buffer for indicators

        var symbol = request.Symbol.Replace("/", "").ToUpper();
        var interval = GetKlineInterval(request.Interval);

        var allCandles = new List<Candle>();
        var currentStartTime = startTime;

        while (currentStartTime < endTime)
        {
            var klines =
                await _client.SpotApi.ExchangeData.GetKlinesAsync(symbol, interval, startTime: currentStartTime,
                    limit: 1000);
            if (!klines.Success || !klines.Data.Any()) break;

            allCandles.AddRange(klines.Data.Select(k => new Candle
            {
                OpenTime = k.OpenTime, Open = k.OpenPrice, High = k.HighPrice, Low = k.LowPrice, Close = k.ClosePrice,
                Volume = k.Volume
            }));

            var lastCandleTime = klines.Data.Last().OpenTime;
            if (lastCandleTime >= endTime.AddMinutes(-5)) break;
            currentStartTime = lastCandleTime.AddSeconds(1);
            if (klines.Data.Count() < 1000) break;
            await Task.Delay(50);
        }

        return allCandles;
    }

    private BacktestResultDto SimulateBacktest(BacktestRequestDto request, List<Candle> candles,
        Dictionary<string, string>? parameters)
    {
        var result = new BacktestResultDto { Trades = new List<BacktestTradeDto>() };
        IStrategy strategy = _strategyFactory.GetStrategy(request.StrategyId);

        if (parameters != null) strategy.SetParameters(parameters);

        decimal currentBalance = request.InitialBalance;
        decimal positionAmount = 0;
        decimal entryPrice = 0;
        DateTime entryDate = DateTime.MinValue;
        decimal targetPrice = 0;
        decimal stopPrice = 0;
        bool inPosition = false;

        for (int i = 350; i < candles.Count; i++)
        {
            var history = candles.Take(i + 1).ToList();
            var currentCandle = candles[i];
            var signal = strategy.Analyze(history, currentBalance, positionAmount);

            if (!inPosition)
            {
                if (signal.Action == TradeAction.Buy)
                {
                    decimal amountToInvest = currentBalance;
                    positionAmount = amountToInvest / currentCandle.Close;
                    currentBalance -= amountToInvest;
                    entryPrice = currentCandle.Close;
                    entryDate = currentCandle.OpenTime;
                    targetPrice = signal.TargetPrice;
                    stopPrice = signal.StopPrice;
                    inPosition = true;
                }
            }
            else
            {
                bool shouldSell = false;
                string exitReason = "";

                if (signal.Action == TradeAction.Sell)
                {
                    shouldSell = true;
                    exitReason = signal.Description;
                }
                else if (targetPrice > 0 && currentCandle.High >= targetPrice)
                {
                    shouldSell = true;
                    exitReason = "Take Profit";
                }
                else if (stopPrice > 0 && currentCandle.Low <= stopPrice)
                {
                    shouldSell = true;
                    exitReason = "Stop Loss";
                }

                if (shouldSell)
                {
                    decimal exitPrice = currentCandle.Close;
                    if (exitReason == "Take Profit") exitPrice = targetPrice;
                    else if (exitReason == "Stop Loss") exitPrice = stopPrice;

                    decimal exitTotal = positionAmount * exitPrice;
                    decimal pnl = exitTotal - (positionAmount * entryPrice);
                    currentBalance += exitTotal;

                    result.Trades.Add(new BacktestTradeDto
                    {
                        Type = pnl > 0 ? $"Take Profit ({exitReason})" : $"Stop Loss ({exitReason})",
                        EntryDate = entryDate, ExitDate = currentCandle.OpenTime,
                        EntryPrice = entryPrice, ExitPrice = exitPrice, Pnl = pnl
                    });

                    inPosition = false;
                    positionAmount = 0;
                }
            }
        }

        result.TotalTrades = result.Trades.Count;
        result.WinningTrades = result.Trades.Count(t => t.Pnl > 0);
        result.LosingTrades = result.Trades.Count(t => t.Pnl <= 0);
        result.TotalPnl = result.Trades.Sum(t => t.Pnl);
        result.TotalPnlPercent = (result.TotalPnl / request.InitialBalance) * 100;
        result.WinRate = result.TotalTrades > 0 ? ((decimal)result.WinningTrades / result.TotalTrades) * 100 : 0;
        result.Candles = candles.Select(c => new BacktestCandleDto
            { Time = c.OpenTime, Open = c.Open, High = c.High, Low = c.Low, Close = c.Close }).ToList();

        return result;
    }

    private KlineInterval GetKlineInterval(string interval) => interval switch
    {
        "1m" => KlineInterval.OneMinute, "3m" => KlineInterval.ThreeMinutes, "5m" => KlineInterval.FiveMinutes,
        "15m" => KlineInterval.FifteenMinutes, "30m" => KlineInterval.ThirtyMinutes, "1h" => KlineInterval.OneHour,
        "2h" => KlineInterval.TwoHour, "4h" => KlineInterval.FourHour, "1d" => KlineInterval.OneDay,
        "1w" => KlineInterval.OneWeek, _ => KlineInterval.FifteenMinutes
    };

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
    public string StrategyId { get; set; } = string.Empty;
    public string Period { get; set; } = "7d";
    public string? StartDate { get; set; } // YYYY-MM-DD
    public string? EndDate { get; set; } // YYYY-MM-DD
    public string Interval { get; set; } = "15m"; // Yeni alan: 3m, 5m, 15m, 1h...
    public decimal InitialBalance { get; set; } = 1000;
    public Dictionary<string, string>? StrategyParameters { get; set; }
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
    public List<BacktestTradeDto> Trades { get; set; } = new();
    public List<BacktestCandleDto> Candles { get; set; } = new();
}

public class BacktestCandleDto
{
    public DateTime Time { get; set; }
    public decimal Open { get; set; }
    public decimal High { get; set; }
    public decimal Low { get; set; }
    public decimal Close { get; set; }
}

public class BacktestTradeDto
{
    public string Type { get; set; } = string.Empty;
    public DateTime EntryDate { get; set; }
    public DateTime ExitDate { get; set; }
    public decimal EntryPrice { get; set; }
    public decimal ExitPrice { get; set; }
    public decimal Pnl { get; set; }
}

public class OptimizationResultDto
{
    public Dictionary<string, string> BestParameters { get; set; } = new();
    public decimal BestPnlPercent { get; set; } = -999;
    public BacktestResultDto? Result { get; set; }
}
