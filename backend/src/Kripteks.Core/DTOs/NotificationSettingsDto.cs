namespace Kripteks.Core.DTOs;

public class NotificationSettingsDto
{
    // Bot Notifications
    public bool NotifyBuySignals { get; set; }
    public bool NotifySellSignals { get; set; }
    public bool NotifyStopLoss { get; set; }
    public bool NotifyTakeProfit { get; set; }

    // System Notifications
    public bool NotifyGeneral { get; set; }
    public bool NotifyErrors { get; set; }

    // Push Notifications
    public bool EnablePushNotifications { get; set; }
}

public class UpdateFcmTokenRequest
{
    public string FcmToken { get; set; } = string.Empty;
}
