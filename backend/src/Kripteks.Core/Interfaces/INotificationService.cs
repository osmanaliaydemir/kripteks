using Kripteks.Core.DTOs;
using Kripteks.Core.Entities;

namespace Kripteks.Core.Interfaces;

public class NotificationDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public NotificationType Type { get; set; }
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? UserId { get; set; }
    public Guid? RelatedBotId { get; set; }
}

public interface INotificationService
{
    /// <summary>
    /// Bildirim gönder. userId null ise genel bildirim (tüm kullanıcılara), set ise kullanıcıya özel.
    /// </summary>
    Task SendNotificationAsync(string title, string message, NotificationType type,
        Guid? relatedBotId = null, string? userId = null);

    /// <summary>
    /// Kullanıcının tüm bildirimlerini getir (genel + kullanıcıya özel), per-user read status ile.
    /// </summary>
    Task<PagedResult<NotificationDto>> GetNotificationsAsync(string userId, int page = 1, int pageSize = 20,
        NotificationType? type = null);

    /// <summary>
    /// Kullanıcı için belirli bir bildirimi okundu olarak işaretle.
    /// </summary>
    Task MarkAsReadAsync(Guid notificationId, string userId);

    /// <summary>
    /// Kullanıcı için tüm bildirimleri okundu olarak işaretle.
    /// </summary>
    Task MarkAllAsReadAsync(string userId);

    Task NotifyBotUpdate(object bot);
    Task NotifyLog(string botId, object log);
    Task NotifyWalletUpdate(object wallet);
}
