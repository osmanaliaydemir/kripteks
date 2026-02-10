using Kripteks.Core.Entities;

namespace Kripteks.Core.Interfaces;

public interface INotificationService
{
    Task SendNotificationAsync(string title, string message, NotificationType type,
        Guid? relatedBotId = null, string? userId = null);
    Task<List<Notification>> GetUnreadNotificationsAsync();
    Task MarkAsReadAsync(Guid id);
    Task MarkAllAsReadAsync();

    Task NotifyBotUpdate(object bot);
    Task NotifyLog(string botId, object log);
    Task NotifyWalletUpdate(object wallet);
}
