using System.ComponentModel.DataAnnotations;

namespace Kripteks.Core.Entities;

public class SystemSetting
{
    public int Id { get; set; }

    [Required] public string UserId { get; set; } = string.Empty;

    // Telegram Bildirimleri
    public string? TelegramBotToken { get; set; }
    public string? TelegramChatId { get; set; }
    public bool EnableTelegramNotifications { get; set; }

    // Risk Yönetimi
    public decimal? GlobalStopLossPercent { get; set; }
    public int? MaxActiveBots { get; set; }

    // Sistem Tercihleri
    public string? DefaultTimeframe { get; set; } = "1h";
    public decimal? DefaultAmount { get; set; }

    // Bildirim Tercihleri - Bot
    public bool NotifyBuySignals { get; set; } = true;
    public bool NotifySellSignals { get; set; } = true;
    public bool NotifyStopLoss { get; set; } = true;
    public bool NotifyTakeProfit { get; set; } = true;

    // Bildirim Tercihleri - Sistem
    public bool NotifyGeneral { get; set; } = true;
    public bool NotifyErrors { get; set; } = true;

    // Push Notification
    public bool EnablePushNotifications { get; set; } = true;
    public string? FcmToken { get; set; }

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
