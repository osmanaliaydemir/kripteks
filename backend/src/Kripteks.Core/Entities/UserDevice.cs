namespace Kripteks.Core.Entities;

public class UserDevice
{
    public int Id { get; set; }
    public required string UserId { get; set; }
    public required string FcmToken { get; set; }
    public string DeviceType { get; set; } = string.Empty; // iOS, Android, Web
    public string? DeviceModel { get; set; }
    public string? AppVersion { get; set; }
    public DateTime RegisteredAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastUsedAt { get; set; }
    public bool IsActive { get; set; } = true;

    // Navigation
    public AppUser? User { get; set; }
}
