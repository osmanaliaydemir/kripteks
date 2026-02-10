using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class FirebaseNotificationService : IFirebaseNotificationService
{
    private readonly AppDbContext _context;
    private readonly ILogger<FirebaseNotificationService> _logger;

    public FirebaseNotificationService(
        AppDbContext context,
        ILogger<FirebaseNotificationService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<string> SendToDeviceAsync(
        string fcmToken,
        string title,
        string body,
        Dictionary<string, string>? data = null)
    {
        try
        {
            var message = BuildMessage(fcmToken, title, body, data);
            var response = await FirebaseMessaging.DefaultInstance.SendAsync(message);

            _logger.LogInformation("Successfully sent notification to device: {Token}", fcmToken.Substring(0, 20));
            return response;
        }
        catch (FirebaseMessagingException ex)
        {
            _logger.LogError(ex, "Failed to send notification to device: {Token}", fcmToken.Substring(0, 20));

            // If token is invalid, mark device as inactive
            if (ex.MessagingErrorCode == MessagingErrorCode.Unregistered ||
                ex.MessagingErrorCode == MessagingErrorCode.InvalidArgument)
            {
                await MarkDeviceInactiveAsync(fcmToken);
            }

            throw;
        }
    }

    public async Task<int> SendToUserAsync(
        string userId,
        string title,
        string body,
        Dictionary<string, string>? data = null)
    {
        var devices = await _context.UserDevices
            .Where(d => d.UserId == userId && d.IsActive)
            .Select(d => d.FcmToken)
            .ToListAsync();

        if (!devices.Any())
        {
            _logger.LogWarning("No active devices found for user: {UserId}", userId);
            return 0;
        }

        return await SendBulkNotificationAsync(devices, title, body, data);
    }

    public async Task<int> SendBulkNotificationAsync(
        List<string> fcmTokens,
        string title,
        string body,
        Dictionary<string, string>? data = null)
    {
        if (!fcmTokens.Any())
        {
            return 0;
        }

        try
        {
            var messages = fcmTokens.Select(token => BuildMessage(token, title, body, data)).ToList();
            var response = await FirebaseMessaging.DefaultInstance.SendEachAsync(messages);

            _logger.LogInformation(
                "Bulk send result: {SuccessCount}/{TotalCount} successful",
                response.SuccessCount,
                fcmTokens.Count);

            // Handle failed tokens
            if (response.FailureCount > 0)
            {
                for (int i = 0; i < response.Responses.Count; i++)
                {
                    var sendResponse = response.Responses[i];
                    if (!sendResponse.IsSuccess)
                    {
                        var exception = sendResponse.Exception;
                        if (exception is FirebaseMessagingException fmEx &&
                            (fmEx.MessagingErrorCode == MessagingErrorCode.Unregistered ||
                             fmEx.MessagingErrorCode == MessagingErrorCode.InvalidArgument))
                        {
                            await MarkDeviceInactiveAsync(fcmTokens[i]);
                        }
                    }
                }
            }

            return response.SuccessCount;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send bulk notifications");
            throw;
        }
    }

    private static Message BuildMessage(
        string fcmToken,
        string title,
        string body,
        Dictionary<string, string>? data)
    {
        return new Message
        {
            Token = fcmToken,
            Notification = new Notification
            {
                Title = title,
                Body = body
            },
            Data = data,
            Android = new AndroidConfig
            {
                Priority = Priority.High,
                Notification = new AndroidNotification
                {
                    Sound = "default",
                    ChannelId = "kripteks_channel"
                }
            },
            Apns = new ApnsConfig
            {
                Aps = new Aps
                {
                    Sound = "default",
                    Badge = 1,
                    Alert = new ApsAlert
                    {
                        Title = title,
                        Body = body
                    }
                }
            }
        };
    }

    private async Task MarkDeviceInactiveAsync(string fcmToken)
    {
        var device = await _context.UserDevices
            .FirstOrDefaultAsync(d => d.FcmToken == fcmToken);

        if (device != null)
        {
            device.IsActive = false;
            await _context.SaveChangesAsync();
            _logger.LogInformation("Marked device as inactive: {Token}", fcmToken.Substring(0, 20));
        }
    }
}
