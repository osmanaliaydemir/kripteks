namespace Kripteks.Core.Entities;

public class Notification
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public NotificationType Type { get; set; } = NotificationType.Info;
    public bool IsRead { get; set; } = false;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Optional: Link to a specific bot or trade
    public Guid? RelatedBotId { get; set; }
}

public enum NotificationType
{
    Info,
    Success,
    Warning,
    Error,
    Trade // Special type for trade executions
}
