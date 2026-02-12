using System.ComponentModel.DataAnnotations;

namespace Kripteks.Core.Entities;

public enum AlertType
{
    Price = 0,
    Technical = 1,
    MarketMovement = 2
}

public enum AlertCondition
{
    Above = 0,
    Below = 1,
    CrossOver = 2,
    CrossUnder = 3,
    InsideChannel = 4,
    OutsideChannel = 5
}

public class UserAlert
{
    [Key] public Guid Id { get; set; } = Guid.NewGuid();

    public string UserId { get; set; } = string.Empty;
    public AppUser User { get; set; } = null!;

    [Required] [MaxLength(20)] public string Symbol { get; set; } = string.Empty;

    public AlertType Type { get; set; }

    // For Price Alert: "50000"
    // For Indicator Alert: "30" (RSI value)
    public decimal TargetValue { get; set; }

    public AlertCondition Condition { get; set; }

    // Nullable for Price alerts
    [MaxLength(50)] public string? IndicatorName { get; set; } // "RSI", "MACD", "SMA"

    // Nullable for Price alerts
    [MaxLength(10)] public string? Timeframe { get; set; } // "15m", "1h", "4h"

    // JSON string for complex parameters (RSI Period, MA Fast/Slow, etc.)
    public string? Parameters { get; set; }

    public bool IsEnabled { get; set; } = true;

    // To prevent spamming alerts repeatedly
    public DateTime? LastTriggeredAt { get; set; }

    // Can represent cooldown period in minutes
    public int CooldownMinutes { get; set; } = 60;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}
