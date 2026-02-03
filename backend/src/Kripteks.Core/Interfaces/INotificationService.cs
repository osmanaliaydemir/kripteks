using Kripteks.Core.Entities;

namespace Kripteks.Core.Interfaces;

public interface INotificationService
{
    Task SendNotificationAsync(string title, string message, NotificationType type, Guid? relatedBotId = null);
    Task<List<Notification>> GetUnreadNotificationsAsync();
    Task MarkAsReadAsync(Guid id);
    Task MarkAllAsReadAsync();

    // Legacy support or removal? Keeping legacy signatures if used elsewhere or removing if not.
    // Assuming we are unifying, we should remove the old ones if possible or keep them as overloads.
    Task NotifyBotUpdate(object bot);
    Task NotifyLog(string botId, object log);
    Task NotifyWalletUpdate(object wallet);
}
