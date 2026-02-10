namespace Kripteks.Core.Entities;

public class Notification
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public NotificationType Type { get; set; } = NotificationType.Info;
    public bool IsRead { get; set; } = false; // Legacy - artık UserNotificationRead tablosu kullanılıyor
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // null = genel bildirim (tüm kullanıcılara), set = kullanıcıya özel bildirim
    public string? UserId { get; set; }
    public AppUser? User { get; set; }

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
