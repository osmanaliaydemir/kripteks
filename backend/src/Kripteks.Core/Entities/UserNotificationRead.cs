namespace Kripteks.Core.Entities;

/// <summary>
/// Kullanıcının hangi bildirimi okuduğunu takip eden junction table.
/// Hem genel (UserId=null) hem kullanıcıya özel bildirimler için çalışır.
/// </summary>
public class UserNotificationRead
{
    public string UserId { get; set; } = string.Empty;
    public AppUser? User { get; set; }

    public Guid NotificationId { get; set; }
    public Notification? Notification { get; set; }

    public DateTime ReadAt { get; set; } = DateTime.UtcNow;
}
