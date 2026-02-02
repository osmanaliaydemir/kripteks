using System.ComponentModel.DataAnnotations;

namespace Kripteks.Core.Entities;

public class SystemSetting
{
    public int Id { get; set; }

    [Required]
    public string UserId { get; set; } = string.Empty;

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

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
