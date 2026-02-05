using Kripteks.Core.DTOs;

namespace Kripteks.Infrastructure.Services;

public class MonteCarloSimulator
{
    private readonly Random _random = new();
    private const int DEFAULT_SIMULATIONS = 1000;
    private const int DEFAULT_TRADES_PER_SIM = 100;

    public MonteCarloResultDto RunSimulation(BacktestResultDto backtestResult, MonteCarloRequestDto? request = null)
    {
        var simCount = request?.SimulationCount ?? DEFAULT_SIMULATIONS;
        var tradesPerSim = request?.TradesPerSimulation ?? Math.Max(backtestResult.TotalTrades, DEFAULT_TRADES_PER_SIM);
        var initialBalance = request?.InitialBalance ?? 10000m;
        var ruinThreshold = request?.RuinThreshold ?? 0.5m; // 50% drawdown = ruin

        // Extract trade PnLs from backtest
        var tradePnls = backtestResult.Trades.Select(t => t.Pnl).ToList();
        if (tradePnls.Count == 0)
        {
            return new MonteCarloResultDto { Success = false, ErrorMessage = "No trades to simulate" };
        }

        var equityCurves = new List<decimal[]>();
        var finalBalances = new List<decimal>();
        var maxDrawdowns = new List<decimal>();
        var ruinCount = 0;

        // Run N simulations
        for (int sim = 0; sim < simCount; sim++)
        {
            var balance = initialBalance;
            var peak = balance;
            var maxDD = 0m;
            var curve = new decimal[tradesPerSim + 1];
            curve[0] = balance;

            for (int i = 0; i < tradesPerSim; i++)
            {
                // Randomly pick a trade result
                var randomPnl = tradePnls[_random.Next(tradePnls.Count)];
                balance += randomPnl;
                curve[i + 1] = balance;

                // Track drawdown
                if (balance > peak) peak = balance;
                var dd = peak > 0 ? (peak - balance) / peak : 0;
                if (dd > maxDD) maxDD = dd;

                // Check for ruin
                if (dd >= ruinThreshold)
                {
                    ruinCount++;
                    break;
                }
            }

            equityCurves.Add(curve);
            finalBalances.Add(balance);
            maxDrawdowns.Add(maxDD * 100);
        }

        // Calculate statistics
        finalBalances.Sort();
        maxDrawdowns.Sort();

        return new MonteCarloResultDto
        {
            Success = true,
            SimulationCount = simCount,
            TradesPerSimulation = tradesPerSim,
            InitialBalance = initialBalance,
            
            // Return distribution
            MedianReturn = CalculatePercentile(finalBalances, 50),
            Percentile5Return = CalculatePercentile(finalBalances, 5),
            Percentile25Return = CalculatePercentile(finalBalances, 25),
            Percentile75Return = CalculatePercentile(finalBalances, 75),
            Percentile95Return = CalculatePercentile(finalBalances, 95),
            AverageReturn = finalBalances.Average(),
            WorstCase = finalBalances.Min(),
            BestCase = finalBalances.Max(),
            
            // Risk metrics
            ProbabilityOfProfit = (decimal)finalBalances.Count(b => b > initialBalance) / simCount * 100,
            ProbabilityOfRuin = (decimal)ruinCount / simCount * 100,
            AverageMaxDrawdown = maxDrawdowns.Average(),
            Percentile95MaxDrawdown = CalculatePercentile(maxDrawdowns, 95),
            
            // Equity curves for visualization (sample 20 curves)
            SampleEquityCurves = equityCurves
                .OrderBy(_ => _random.Next())
                .Take(20)
                .Select(c => c.Select(v => Math.Round(v, 2)).ToArray())
                .ToList(),
            
            // Distribution histogram (10 buckets)
            ReturnDistribution = CalculateDistribution(finalBalances, 10)
        };
    }

    private decimal CalculatePercentile(List<decimal> sorted, int percentile)
    {
        int index = (int)Math.Ceiling(percentile / 100.0 * sorted.Count) - 1;
        return sorted[Math.Max(0, Math.Min(index, sorted.Count - 1))];
    }

    private List<DistributionBucket> CalculateDistribution(List<decimal> values, int buckets)
    {
        var min = values.Min();
        var max = values.Max();
        var range = max - min;
        var bucketSize = range / buckets;

        return Enumerable.Range(0, buckets).Select(i =>
        {
            var low = min + (bucketSize * i);
            var high = min + (bucketSize * (i + 1));
            var count = values.Count(v => v >= low && (i == buckets - 1 ? v <= high : v < high));
            return new DistributionBucket
            {
                RangeLow = Math.Round(low, 2),
                RangeHigh = Math.Round(high, 2),
                Count = count,
                Percentage = (decimal)count / values.Count * 100
            };
        }).ToList();
    }
}

public class MonteCarloRequestDto
{
    public int SimulationCount { get; set; } = 1000;
    public int TradesPerSimulation { get; set; } = 100;
    public decimal InitialBalance { get; set; } = 10000m;
    public decimal RuinThreshold { get; set; } = 0.5m; // 50%
}

public class MonteCarloResultDto
{
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
    public int SimulationCount { get; set; }
    public int TradesPerSimulation { get; set; }
    public decimal InitialBalance { get; set; }
    
    // Return Statistics
    public decimal MedianReturn { get; set; }
    public decimal Percentile5Return { get; set; }
    public decimal Percentile25Return { get; set; }
    public decimal Percentile75Return { get; set; }
    public decimal Percentile95Return { get; set; }
    public decimal AverageReturn { get; set; }
    public decimal WorstCase { get; set; }
    public decimal BestCase { get; set; }
    
    // Risk Metrics
    public decimal ProbabilityOfProfit { get; set; }
    public decimal ProbabilityOfRuin { get; set; }
    public decimal AverageMaxDrawdown { get; set; }
    public decimal Percentile95MaxDrawdown { get; set; }
    
    // Visualization Data
    public List<decimal[]> SampleEquityCurves { get; set; } = new();
    public List<DistributionBucket> ReturnDistribution { get; set; } = new();
}

public class DistributionBucket
{
    public decimal RangeLow { get; set; }
    public decimal RangeHigh { get; set; }
    public int Count { get; set; }
    public decimal Percentage { get; set; }
}
