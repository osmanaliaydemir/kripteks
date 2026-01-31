using Kripteks.Core.Entities;

namespace Kripteks.Core.DTOs;

public class BotDto
{
    public Guid Id { get; set; }
    public string Symbol { get; set; } = string.Empty;
    public string StrategyName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Interval { get; set; } = "1h";
    public decimal? StopLoss { get; set; }
    public decimal? TakeProfit { get; set; }
    public string Status { get; set; } = string.Empty; // Enum as string
    public decimal Pnl { get; set; } // Calculated Property (not in DB)
    public decimal PnlPercent { get; set; }
    public DateTime CreatedAt { get; set; }
    public decimal EntryPrice { get; set; }
    public decimal CurrentPnl { get; set; }
    public decimal CurrentPnlPercent { get; set; }
    public List<Log> Logs { get; set; } = new();
}

public class CreateBotRequest
{
    public string Symbol { get; set; } = string.Empty;
    public string StrategyId { get; set; } = string.Empty; // strategy_id from frontend
    public decimal Amount { get; set; }
    public string Interval { get; set; } = "1h";
    public decimal? TakeProfit { get; set; }
    public decimal? StopLoss { get; set; }
}
