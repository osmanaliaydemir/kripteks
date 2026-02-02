namespace Kripteks.Core.Interfaces;

public interface IAnalyticsService
{
    Task<DashboardStats> GetDashboardStatsAsync();
    Task<List<EquityPoint>> GetEquityCurveAsync();
    Task<List<StrategyPerformance>> GetStrategyPerformanceAsync();
}

public class DashboardStats
{
    public decimal TotalPnl { get; set; }
    public decimal WinRate { get; set; }
    public int TotalTrades { get; set; }
    public int WinningTrades { get; set; }
    public int LosingTrades { get; set; }
    public string BestPair { get; set; } = "";
    public decimal ProfitFactor { get; set; }
    public decimal AvgTradePnL { get; set; }
    public decimal MaxDrawdown { get; set; }
}

public class EquityPoint
{
    public string Date { get; set; } = "";
    public decimal Balance { get; set; }
    public decimal DailyPnl { get; set; }
}

public class StrategyPerformance
{
    public string StrategyName { get; set; } = "";
    public int TotalTrades { get; set; }
    public decimal WinRate { get; set; }
    public decimal TotalPnl { get; set; }
    public decimal ProfitFactor { get; set; }
    public decimal AvgTrade { get; set; }
}
