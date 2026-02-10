using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
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
    AppDbContext context,
    IWebHostEnvironment env,
    IConfiguration configuration) : ControllerBase
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
                        error = ex.Message,
                        errorType = ex.GetType().Name,
                        innerError = ex.InnerException?.Message,
                        stackTrace = ex.StackTrace?.Split('\n').Take(3)
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

    /// <summary>
    /// Firebase durumunu, dosya yollarını ve credential doğrulamasını göster (debug amaçlı)
    /// </summary>
    [HttpGet("firebase-diagnostics")]
    public async Task<IActionResult> FirebaseDiagnostics()
    {
        var firebaseConfigPath = configuration["Firebase:ServiceAccountPath"] ?? "";
        var hasJsonConfig = !string.IsNullOrEmpty(configuration["Firebase:ServiceAccountJson"]);

        var searchPaths = new[]
        {
            Path.Combine(AppContext.BaseDirectory, firebaseConfigPath),
            Path.Combine(env.ContentRootPath, firebaseConfigPath),
            Path.Combine(env.WebRootPath ?? "", firebaseConfigPath),
            Path.Combine(env.ContentRootPath, "wwwroot", firebaseConfigPath),
            firebaseConfigPath
        };

        // Credential validation
        string? tokenStatus = null;
        string? credentialError = null;
        string? projectId = null;
        string? serviceAccountEmail = null;

        if (FirebaseApp.DefaultInstance != null)
        {
            try
            {
                var options = FirebaseApp.DefaultInstance.Options;
                projectId = options.ProjectId;
                if (options.Credential.UnderlyingCredential is ServiceAccountCredential saCred)
                    serviceAccountEmail = saCred.Id;

                // OAuth token almayı dene
                var token = await options.Credential
                    .CreateScoped("https://www.googleapis.com/auth/firebase.messaging")
                    .UnderlyingCredential
                    .GetAccessTokenForRequestAsync();

                tokenStatus = !string.IsNullOrEmpty(token)
                    ? $"Valid (token: {token.Substring(0, Math.Min(30, token.Length))}...)"
                    : "Empty token returned";
            }
            catch (Exception ex)
            {
                credentialError = ex.Message;
                tokenStatus = "FAILED";
            }
        }

        return Ok(new
        {
            firebaseInitialized = FirebaseApp.DefaultInstance != null,
            projectId,
            serviceAccountEmail,
            tokenStatus,
            credentialError,
            hasServiceAccountJson = hasJsonConfig,
            serviceAccountPath = firebaseConfigPath,
            appBaseDirectory = AppContext.BaseDirectory,
            contentRootPath = env.ContentRootPath,
            webRootPath = env.WebRootPath,
            currentDirectory = System.IO.Directory.GetCurrentDirectory(),
            searchResults = searchPaths.Select(p => new
            {
                path = p,
                exists = !string.IsNullOrEmpty(p) && System.IO.File.Exists(p)
            }),
            wwwrootFiles = System.IO.Directory.Exists(env.WebRootPath)
                ? System.IO.Directory.GetFiles(env.WebRootPath).Select(Path.GetFileName)
                : Enumerable.Empty<string>()
        });
    }
}
