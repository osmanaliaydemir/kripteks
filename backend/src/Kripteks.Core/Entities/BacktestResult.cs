namespace Kripteks.Core.Entities;

public class BacktestResult
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string UserId { get; set; } = string.Empty;
    
    // Test Parameters
    public string Symbol { get; set; } = string.Empty;
    public string StrategyId { get; set; } = string.Empty;
    public string Interval { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal InitialBalance { get; set; }
    public decimal CommissionRate { get; set; }
    public decimal SlippageRate { get; set; }
    public string? StrategyParameters { get; set; } // JSON
    
    // Basic Metrics
    public int TotalTrades { get; set; }
    public int WinningTrades { get; set; }
    public int LosingTrades { get; set; }
    public decimal TotalPnl { get; set; }
    public decimal TotalPnlPercent { get; set; }
    public decimal WinRate { get; set; }
    public decimal MaxDrawdown { get; set; }
    public decimal TotalCommissionPaid { get; set; }
    
    // Advanced Metrics
    public decimal SharpeRatio { get; set; }
    public decimal SortinoRatio { get; set; }
    public decimal ProfitFactor { get; set; }
    public decimal AverageWin { get; set; }
    public decimal AverageLoss { get; set; }
    public int MaxConsecutiveWins { get; set; }
    public int MaxConsecutiveLosses { get; set; }
    
    // Metadata
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string? Notes { get; set; }
    public bool IsFavorite { get; set; } = false;
}
