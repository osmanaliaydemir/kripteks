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
            UserId = userId, // null = genel, set = kullanıcıya özel
            CreatedAt = DateTime.UtcNow
        };

        context.Notifications.Add(notification);
        await context.SaveChangesAsync();

        // SignalR broadcast (client tarafta filtreleme yapılır)
        await hubContext.Clients.All.ReceiveNotification(notification);

        // Push notification data payload
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
            // Kullanıcıya özel bildirimse sadece o kullanıcıya gönder
            if (!string.IsNullOrEmpty(userId))
            {
                if (await ShouldSendPushAsync(userId, type))
                {
                    await firebaseNotificationService.SendToUserAsync(userId, title, message, data);
                }
                return;
            }

            // Genel bildirim - tüm aktif kullanıcılara gönder
            var targetUserIds = await context.UserDevices
                .Where(d => d.IsActive)
                .Select(d => d.UserId)
                .Distinct()
                .ToListAsync();

            foreach (var targetUserId in targetUserIds)
            {
                if (!await ShouldSendPushAsync(targetUserId, type))
                {
                    logger.LogInformation(
                        "Push notification atlandı - kullanıcı tercihi kapalı: {UserId}, {Type}",
                        targetUserId, type);
                    continue;
                }

                await firebaseNotificationService.SendToUserAsync(targetUserId, title, message, data);
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

        if (settings == null) return true;
        if (!settings.EnablePushNotifications) return false;

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

    public async Task<List<NotificationDto>> GetNotificationsAsync(string userId)
    {
        // Kullanıcının okuduğu bildirim ID'lerini al
        var readNotificationIds = await context.UserNotificationReads
            .AsNoTracking()
            .Where(r => r.UserId == userId)
            .Select(r => r.NotificationId)
            .ToHashSetAsync();

        // Kullanıcıya ait bildirimler: genel (UserId=null) + kullanıcıya özel (UserId=userId)
        var notifications = await context.Notifications
            .AsNoTracking()
            .Where(n => n.UserId == null || n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt)
            .Take(50)
            .ToListAsync();

        return notifications.Select(n => new NotificationDto
        {
            Id = n.Id,
            Title = n.Title,
            Message = n.Message,
            Type = n.Type,
            IsRead = readNotificationIds.Contains(n.Id),
            CreatedAt = n.CreatedAt,
            UserId = n.UserId,
            RelatedBotId = n.RelatedBotId
        }).ToList();
    }

    public async Task MarkAsReadAsync(Guid notificationId, string userId)
    {
        // Zaten okunmuş mu kontrol et
        var alreadyRead = await context.UserNotificationReads
            .AnyAsync(r => r.UserId == userId && r.NotificationId == notificationId);

        if (!alreadyRead)
        {
            context.UserNotificationReads.Add(new UserNotificationRead
            {
                UserId = userId,
                NotificationId = notificationId,
                ReadAt = DateTime.UtcNow
            });
            await context.SaveChangesAsync();
        }
    }

    public async Task MarkAllAsReadAsync(string userId)
    {
        // Kullanıcının görmesi gereken ama henüz okumadığı bildirimleri bul
        var unreadNotificationIds = await context.Notifications
            .Where(n => n.UserId == null || n.UserId == userId)
            .Where(n => !context.UserNotificationReads
                .Any(r => r.UserId == userId && r.NotificationId == n.Id))
            .Select(n => n.Id)
            .ToListAsync();

        if (unreadNotificationIds.Count > 0)
        {
            var readRecords = unreadNotificationIds.Select(nId => new UserNotificationRead
            {
                UserId = userId,
                NotificationId = nId,
                ReadAt = DateTime.UtcNow
            });

            context.UserNotificationReads.AddRange(readRecords);
            await context.SaveChangesAsync();
        }
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
