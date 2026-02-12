namespace Kripteks.Core.Interfaces;

public interface IFirebaseNotificationService
{
    /// <summary>
    /// Send notification to a single device by FCM token
    /// </summary>
    Task<string> SendToDeviceAsync(
        string fcmToken,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        int? badgeCount = null);

    /// <summary>
    /// Send notification to all active devices of a user
    /// </summary>
    Task<int> SendToUserAsync(
        string userId,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        int? badgeCount = null);

    /// <summary>
    /// Send notification to multiple devices (bulk send)
    /// </summary>
    Task<int> SendBulkNotificationAsync(
        List<string> fcmTokens,
        string title,
        string body,
        Dictionary<string, string>? data = null,
        int? badgeCount = null);
}
