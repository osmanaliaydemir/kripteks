using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class NotificationsController(INotificationService notificationService) : ControllerBase
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
}
