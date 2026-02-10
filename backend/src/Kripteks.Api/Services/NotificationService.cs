using Kripteks.Api.Hubs;
using Kripteks.Core.Entities;
using Kripteks.Infrastructure.Data;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Kripteks.Core.Interfaces;

namespace Kripteks.Api.Services;

public class NotificationService(
    AppDbContext context,
    IHubContext<BotHub, IBotHubClient> hubContext,
    IFirebaseNotificationService firebaseNotificationService,
    ILogger<NotificationService> logger)
    : INotificationService
{
    public async Task SendNotificationAsync(string title, string message, NotificationType type,
        Guid? relatedBotId = null, string? userId = null)
    {
        var notification = new Notification
        {
            Title = title,
            Message = message,
            Type = type,
            RelatedBotId = relatedBotId,
            CreatedAt = DateTime.UtcNow
        };

        context.Notifications.Add(notification);
        await context.SaveChangesAsync();

        // Broadcast to all connected clients via SignalR
        await hubContext.Clients.All.ReceiveNotification(notification);

        // Push notification data payload - mobile tarafta navigasyon için
        var data = new Dictionary<string, string>
        {
            ["type"] = type.ToString().ToLowerInvariant(),
            ["notificationId"] = notification.Id.ToString()
        };
        if (relatedBotId.HasValue)
        {
            data["relatedBotId"] = relatedBotId.Value.ToString();
        }

        try
        {
            // Kullanıcıları ve push tercihlerini çek
            var usersQuery = context.UserDevices
                .Where(d => d.IsActive)
                .Select(d => d.UserId)
                .Distinct();

            // Belirli bir kullanıcıya gönderilecekse filtrele
            if (!string.IsNullOrEmpty(userId))
            {
                usersQuery = usersQuery.Where(u => u == userId);
            }

            var targetUserIds = await usersQuery.ToListAsync();

            foreach (var targetUserId in targetUserIds)
            {
                // Kullanıcının bildirim tercihlerini kontrol et
                if (!await ShouldSendPushAsync(targetUserId, type))
                {
                    logger.LogInformation(
                        "Push notification atlandı - kullanıcı tercihi kapalı: {UserId}, {Type}",
                        targetUserId, type);
                    continue;
                }

                await firebaseNotificationService.SendToUserAsync(
                    targetUserId, title, message, data);
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Push notification gönderilemedi: {Title}", title);
        }
    }

    /// <summary>
    /// Kullanıcının bildirim tercihlerine göre push gönderilmeli mi kontrolü
    /// </summary>
    private async Task<bool> ShouldSendPushAsync(string userId, NotificationType type)
    {
        var settings = await context.SystemSettings
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.UserId == userId);

        // Ayar yoksa varsayılan olarak gönder
        if (settings == null) return true;

        // Genel push bildirimi kapalıysa hiç gönderme
        if (!settings.EnablePushNotifications) return false;

        // Bildirim tipine göre kullanıcı tercihini kontrol et
        return type switch
        {
            NotificationType.Trade => settings.NotifyBuySignals || settings.NotifySellSignals,
            NotificationType.Warning => settings.NotifyStopLoss || settings.NotifyTakeProfit,
            NotificationType.Error => settings.NotifyErrors,
            NotificationType.Info => settings.NotifyGeneral,
            NotificationType.Success => settings.NotifyGeneral,
            _ => true
        };
    }

    public async Task<List<Notification>> GetUnreadNotificationsAsync()
    {
        return await context.Notifications
            .Where(n => !n.IsRead)
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync();
    }

    public async Task MarkAsReadAsync(Guid id)
    {
        var notification = await context.Notifications.FindAsync(id);
        if (notification != null)
        {
            notification.IsRead = true;
            await context.SaveChangesAsync();
        }
    }

    public async Task MarkAllAsReadAsync()
    {
        var notifications = await context.Notifications.Where(n => !n.IsRead).ToListAsync();
        foreach (var n in notifications)
        {
            n.IsRead = true;
        }

        await context.SaveChangesAsync();
    }

    public Task NotifyBotUpdate(object bot)
    {
        return hubContext.Clients.All.ReceiveBotUpdate(bot);
    }

    public Task NotifyLog(string botId, object log)
    {
        return hubContext.Clients.All.ReceiveLog(botId, log);
    }

    public Task NotifyWalletUpdate(object wallet)
    {
        return hubContext.Clients.All.ReceiveWalletUpdate(wallet);
    }
}
