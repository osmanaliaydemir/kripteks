namespace Kripteks.Core.DTOs;

public class RegisterDeviceDto
{
    public required string FcmToken { get; set; }
    public required string DeviceType { get; set; } // iOS, Android, Web
    public string? DeviceModel { get; set; }
    public string? AppVersion { get; set; }
}
