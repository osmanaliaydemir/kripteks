using Kripteks.Core.Entities;

namespace Kripteks.Core.DTOs;

public class CreateAlertDto
{
    public string Symbol { get; set; } = string.Empty;
    public AlertType Type { get; set; }
    public decimal TargetValue { get; set; }
    public AlertCondition Condition { get; set; }
    public string? IndicatorName { get; set; }
    public string? Timeframe { get; set; }
    public string? Parameters { get; set; }
}

public class UpdateAlertDto
{
    // ID comes from route
    public decimal TargetValue { get; set; }
    public bool IsEnabled { get; set; }
    public int CooldownMinutes { get; set; }
    public string? Parameters { get; set; }
}

public class AlertDto : CreateAlertDto
{
    public Guid Id { get; set; }
    public bool IsEnabled { get; set; }
    public DateTime? LastTriggeredAt { get; set; }
    public DateTime CreatedAt { get; set; }
}
