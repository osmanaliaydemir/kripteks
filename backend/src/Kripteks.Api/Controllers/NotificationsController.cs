using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class NotificationsController(
    INotificationService notificationService,
    IFirebaseNotificationService firebaseNotificationService,
    AppDbContext context) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<Notification>>> GetUnreadNotifications()
    {
        var notifications = await notificationService.GetUnreadNotificationsAsync();
        return Ok(notifications);
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        await notificationService.MarkAsReadAsync(id);
        return Ok();
    }

    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        await notificationService.MarkAllAsReadAsync();
        return Ok();
    }

    [HttpPost("test")]
    public async Task<IActionResult> TestNotification()
    {
        await notificationService.SendNotificationAsync(
            "Test Bildirimi",
            "Bu bir push notification testidir! 🚀",
            NotificationType.Info);

        return Ok(new { message = "Test notification sent" });
    }

    /// <summary>
    /// Push notification'ı doğrudan test et ve sonucu döndür
    /// </summary>
    [HttpPost("test-push")]
    public async Task<IActionResult> TestPushDirect()
    {
        try
        {
            // Aktif cihazları kontrol et
            var devices = await context.UserDevices
                .Where(d => d.IsActive)
                .Select(d => new { d.UserId, d.FcmToken, d.DeviceType, d.DeviceModel })
                .ToListAsync();

            if (!devices.Any())
            {
                return Ok(new { success = false, error = "Aktif cihaz bulunamadı", deviceCount = 0 });
            }

            // Doğrudan Firebase'e gönder
            var results = new List<object>();
            foreach (var device in devices)
            {
                try
                {
                    var response = await firebaseNotificationService.SendToDeviceAsync(
                        device.FcmToken,
                        "Test Push",
                        "Firebase push testi 🔥",
                        new Dictionary<string, string> { ["type"] = "info" });

                    results.Add(new
                    {
                        device = device.DeviceModel ?? device.DeviceType,
                        success = true,
                        messageId = response
                    });
                }
                catch (Exception ex)
                {
                    results.Add(new
                    {
                        device = device.DeviceModel ?? device.DeviceType,
                        success = false,
                        error = ex.Message
                    });
                }
            }

            return Ok(new
            {
                success = true,
                deviceCount = devices.Count,
                results
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { success = false, error = ex.Message, stackTrace = ex.StackTrace });
        }
    }
}
