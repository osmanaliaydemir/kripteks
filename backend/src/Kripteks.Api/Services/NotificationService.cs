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
        Guid? relatedBotId = null)
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

        try
        {
            // For now, since bots don't have UserId and it's a single-user system,
            // we send notifications to all registered devices.
            // In a multi-user system, we would filter by UserId.
            var usersWithDevices = await context.UserDevices
                .Select(d => d.UserId)
                .Distinct()
                .ToListAsync();

            foreach (var userId in usersWithDevices)
            {
                await firebaseNotificationService.SendToUserAsync(userId, title, message);
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Push notification gönderilemedi: {Title}", title);
        }
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
