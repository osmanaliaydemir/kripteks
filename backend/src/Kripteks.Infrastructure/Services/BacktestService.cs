using Kripteks.Core.Interfaces;
using Kripteks.Core.DTOs;
using Binance.Net.Clients;
using Binance.Net.Enums;
using Microsoft.Extensions.Logging;
using Kripteks.Core.Models.Strategy;

namespace Kripteks.Infrastructure.Services;

public class BacktestService
{
    private readonly BinanceRestClient _client;
    private readonly ILogger<BacktestService> _logger;
    private readonly IStrategyFactory _strategyFactory;
    private readonly IBacktestRepository _backtestRepository;

    public BacktestService(ILogger<BacktestService> logger, IStrategyFactory strategyFactory,
        IBacktestRepository backtestRepository)
    {
        _logger = logger;
        _strategyFactory = strategyFactory;
        _backtestRepository = backtestRepository;
        _client = new BinanceRestClient();
    }

    public async Task<BacktestResultDto> RunBacktestAsync(BacktestRequestDto request)
    {
        var allCandles = await FetchCandlesAsync(request);
        return SimulateBacktest(request, allCandles, request.StrategyParameters);
    }

    public async Task<BatchBacktestResultDto> RunBatchBacktestAsync(BatchBacktestRequestDto request)
    {
        var result = new BatchBacktestResultDto();

        foreach (var symbol in request.Symbols)
        {
            try
            {
                var singleRequest = new BacktestRequestDto
                {
                    Symbol = symbol,
                    StrategyId = request.StrategyId,
                    Interval = request.Interval,
                    StartDate = request.StartDate,
                    EndDate = request.EndDate,
                    InitialBalance = request.InitialBalance,
                    StrategyParameters = request.StrategyParameters,
                    CommissionRate = request.CommissionRate,
                    SlippageRate = request.SlippageRate
                };

                var singleResult = await RunBacktestAsync(singleRequest);
                result.Results.Add(new BatchBacktestResultItemDto
                {
                    Symbol = symbol,
                    TotalPnlPercent = singleResult.TotalPnlPercent,
                    WinRate = singleResult.WinRate,
                    TotalTrades = singleResult.TotalTrades,
                    MaxDrawdown = singleResult.MaxDrawdown,
                    ProfitFactor = singleResult.ProfitFactor,
                    SharpeRatio = singleResult.SharpeRatio,
                    Success = true
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error running backtest for {Symbol}", symbol);
                result.Results.Add(new BatchBacktestResultItemDto
                {
                    Symbol = symbol,
                    Success = false,
                    ErrorMessage = ex.Message
                });
            }
        }

        return result;
    }

    public async Task<Guid> SaveResultAsync(BacktestRequestDto request, BacktestResultDto result, string userId)
    {
        var entity = new Core.Entities.BacktestResult
        {
            UserId = userId,
            Symbol = request.Symbol,
            StrategyId = request.StrategyId,
            Interval = request.Interval,
            StartDate = DateTime.Parse(request.StartDate ?? DateTime.UtcNow.AddDays(-7).ToString("yyyy-MM-dd")),
            EndDate = DateTime.Parse(request.EndDate ?? DateTime.UtcNow.ToString("yyyy-MM-dd")),
            InitialBalance = request.InitialBalance,
            CommissionRate = request.CommissionRate,
            SlippageRate = request.SlippageRate,
            StrategyParameters = request.StrategyParameters != null
                ? System.Text.Json.JsonSerializer.Serialize(request.StrategyParameters)
                : null,
            TotalTrades = result.TotalTrades,
            WinningTrades = result.WinningTrades,
            LosingTrades = result.LosingTrades,
            TotalPnl = result.TotalPnl,
            TotalPnlPercent = result.TotalPnlPercent,
            WinRate = result.WinRate,
            MaxDrawdown = result.MaxDrawdown,
            TotalCommissionPaid = result.TotalCommissionPaid,
            SharpeRatio = result.SharpeRatio,
            SortinoRatio = result.SortinoRatio,
            ProfitFactor = result.ProfitFactor,
            AverageWin = result.AverageWin,
            AverageLoss = result.AverageLoss,
            MaxConsecutiveWins = result.MaxConsecutiveWins,
            MaxConsecutiveLosses = result.MaxConsecutiveLosses
        };

        var saved = await _backtestRepository.CreateAsync(entity);
        return saved.Id;
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

    public async Task<OptimizationResultDto> OptimizeBacktestWithProgressAsync(
        BacktestRequestDto request,
        Func<int, int, decimal?, decimal?, Dictionary<string, string>, Task>? progressCallback = null)
    {
        var allCandles = await FetchCandlesAsync(request);
        var bestResult = new OptimizationResultDto();
        var searchSpace = GetOptimizationSpace(request.StrategyId);
        int totalSteps = searchSpace.Count;
        int currentStep = 0;

        _logger.LogInformation("Optimizing {StrategyId} in {SpaceCount} combinations with progress tracking...",
            request.StrategyId, totalSteps);

        foreach (var parameters in searchSpace)
        {
            currentStep++;
            var currentResult = SimulateBacktest(request, allCandles, parameters);

            if (currentResult.TotalPnlPercent > bestResult.BestPnlPercent)
            {
                bestResult.BestPnlPercent = currentResult.TotalPnlPercent;
                bestResult.BestParameters = parameters;
                bestResult.Result = currentResult;
            }

            // Report progress every 5 steps or on first/last step
            if (progressCallback != null && (currentStep % 5 == 0 || currentStep == 1 || currentStep == totalSteps))
            {
                await progressCallback(currentStep, totalSteps, currentResult.TotalPnlPercent,
                    bestResult.BestPnlPercent, parameters);
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

        return allCandles.Where(c => c.OpenTime <= endTime).ToList();
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
        decimal totalCommission = 0;
        decimal entryCommission = 0; // Track commission paid on entry

        // MaxDrawdown tracking
        decimal peak = request.InitialBalance;
        decimal maxDrawdown = 0;

        // Determine start index based on StartDate to prevent trading on "warmup" data
        int startIndex = 350;
        if (!string.IsNullOrEmpty(request.StartDate) && DateTime.TryParse(request.StartDate, out var s))
        {
            var dateIndex = candles.FindIndex(c => c.OpenTime >= s);
            if (dateIndex > startIndex) startIndex = dateIndex;
        }

        for (int i = startIndex; i < candles.Count; i++)
        {
            var history = candles.Take(i + 1).ToList();
            var currentCandle = candles[i];
            var signal = strategy.Analyze(history, currentBalance, positionAmount);

            // Calculate current equity for drawdown tracking
            decimal currentEquity = currentBalance + (positionAmount * currentCandle.Close);
            if (currentEquity > peak) peak = currentEquity;
            decimal drawdown = peak > 0 ? ((peak - currentEquity) / peak) * 100 : 0;
            if (drawdown > maxDrawdown) maxDrawdown = drawdown;

            if (!inPosition)
            {
                if (signal.Action == TradeAction.Buy)
                {
                    // Use full current balance for compounding (per user request)
                    decimal amountToInvest = currentBalance;

                    // Apply slippage to entry price (worse price for buyer)
                    decimal entryPriceWithSlippage = currentCandle.Close * (1 + request.SlippageRate);

                    positionAmount = amountToInvest / entryPriceWithSlippage;
                    currentBalance -= amountToInvest;

                    // Apply commission on buy
                    entryCommission = amountToInvest * request.CommissionRate;
                    currentBalance -= entryCommission;
                    totalCommission += entryCommission;

                    entryPrice = entryPriceWithSlippage;
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

                    // Apply slippage to exit price (worse price for seller)
                    decimal exitPriceWithSlippage = exitPrice * (1 - request.SlippageRate);

                    decimal exitTotal = positionAmount * exitPriceWithSlippage;

                    // Apply commission on sell
                    decimal exitCommission = exitTotal * request.CommissionRate;
                    exitTotal -= exitCommission;
                    totalCommission += exitCommission;

                    decimal pnlValue = exitTotal - (positionAmount * entryPrice);
                    decimal tradeCommission = entryCommission + exitCommission;
                    decimal pnlPercent = (pnlValue / (positionAmount * entryPrice)) * 100;

                    currentBalance += exitTotal;

                    result.Trades.Add(new BacktestTradeDto
                    {
                        Type = pnlValue > 0 ? $"Take Profit ({exitReason})" : $"Stop Loss ({exitReason})",
                        EntryDate = entryDate,
                        ExitDate = currentCandle.OpenTime,
                        EntryPrice = entryPrice,
                        ExitPrice = exitPriceWithSlippage,
                        Pnl = pnlPercent,
                        Commission = tradeCommission
                    });

                    inPosition = false;
                    positionAmount = 0;
                    entryCommission = 0; // Reset for next trade
                }
            }
        }

        result.TotalTrades = result.Trades.Count;
        result.WinningTrades = result.Trades.Count(t => t.Pnl > 0);
        result.LosingTrades = result.Trades.Count(t => t.Pnl <= 0);
        result.TotalPnl = result.Trades.Sum(t => t.Pnl);
        result.TotalPnlPercent = (result.TotalPnl / request.InitialBalance) * 100;
        result.WinRate = result.TotalTrades > 0 ? ((decimal)result.WinningTrades / result.TotalTrades) * 100 : 0;
        result.MaxDrawdown = maxDrawdown;
        result.InitialBalance = request.InitialBalance;
        result.TotalCommissionPaid = totalCommission;

        // Advanced Metrics (Phase 2)
        CalculateAdvancedMetrics(result, request.InitialBalance);

        result.Candles = candles.Select(c => new BacktestCandleDto
            { Time = c.OpenTime, Open = c.Open, High = c.High, Low = c.Low, Close = c.Close }).ToList();

        return result;
    }

    private void CalculateAdvancedMetrics(BacktestResultDto result, decimal initialBalance)
    {
        if (result.Trades.Count == 0)
        {
            result.SharpeRatio = 0;
            result.SortinoRatio = 0;
            result.ProfitFactor = 0;
            result.AverageWin = 0;
            result.AverageLoss = 0;
            result.MaxConsecutiveWins = 0;
            result.MaxConsecutiveLosses = 0;
            return;
        }

        // Average Win and Average Loss
        var winningTrades = result.Trades.Where(t => t.Pnl > 0).ToList();
        var losingTrades = result.Trades.Where(t => t.Pnl <= 0).ToList();

        result.AverageWin = winningTrades.Any() ? winningTrades.Average(t => t.Pnl) : 0;
        result.AverageLoss = losingTrades.Any() ? losingTrades.Average(t => t.Pnl) : 0;

        // Profit Factor = Gross Profit / Gross Loss
        decimal grossProfit = winningTrades.Sum(t => t.Pnl);
        decimal grossLoss = Math.Abs(losingTrades.Sum(t => t.Pnl));
        result.ProfitFactor = grossLoss > 0 ? grossProfit / grossLoss : (grossProfit > 0 ? 999 : 0);

        // Sharpe Ratio = (Average Return - Risk Free Rate) / Standard Deviation of Returns
        // Risk-free rate assumed to be 0 for simplicity
        var returns = result.Trades.Select(t => t.Pnl / initialBalance).ToList();
        decimal avgReturn = returns.Average();
        decimal stdDev = CalculateStandardDeviation(returns);
        result.SharpeRatio = stdDev > 0 ? (avgReturn / stdDev) * (decimal)Math.Sqrt(252) : 0; // Annualized

        // Sortino Ratio = (Average Return - Risk Free Rate) / Downside Deviation
        var negativeReturns = returns.Where(r => r < 0).ToList();
        decimal downsideDev = negativeReturns.Any() ? CalculateStandardDeviation(negativeReturns) : 0.0001m;
        result.SortinoRatio = downsideDev > 0 ? (avgReturn / downsideDev) * (decimal)Math.Sqrt(252) : 0; // Annualized

        // Max Consecutive Wins and Losses
        int currentWinStreak = 0;
        int currentLossStreak = 0;
        int maxWinStreak = 0;
        int maxLossStreak = 0;

        foreach (var trade in result.Trades)
        {
            if (trade.Pnl > 0)
            {
                currentWinStreak++;
                currentLossStreak = 0;
                if (currentWinStreak > maxWinStreak) maxWinStreak = currentWinStreak;
            }
            else
            {
                currentLossStreak++;
                currentWinStreak = 0;
                if (currentLossStreak > maxLossStreak) maxLossStreak = currentLossStreak;
            }
        }

        result.MaxConsecutiveWins = maxWinStreak;
        result.MaxConsecutiveLosses = maxLossStreak;
    }

    private decimal CalculateStandardDeviation(List<decimal> values)
    {
        if (values.Count == 0) return 0;

        decimal avg = values.Average();
        decimal sumOfSquares = values.Sum(v => (v - avg) * (v - avg));
        decimal variance = sumOfSquares / values.Count;
        return (decimal)Math.Sqrt((double)variance);
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
