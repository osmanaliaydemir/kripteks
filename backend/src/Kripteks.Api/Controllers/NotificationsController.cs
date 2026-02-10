using System.Security.Claims;
using Kripteks.Core.DTOs;
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
    private string GetUserId() =>
        User.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? throw new UnauthorizedAccessException("User ID not found in token");

    [HttpGet]
    public async Task<IActionResult> GetNotifications([FromQuery] PaginationRequest pagination)
    {
        var userId = GetUserId();
        var result = await notificationService.GetNotificationsAsync(userId, pagination.Page, pagination.PageSize);
        return Ok(result);
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var userId = GetUserId();
        await notificationService.MarkAsReadAsync(id, userId);
        return Ok();
    }

    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var userId = GetUserId();
        await notificationService.MarkAllAsReadAsync(userId);
        return Ok();
    }

    /// <summary>
    /// Genel test bildirimi gönder (tüm kullanıcılara)
    /// </summary>
    [HttpPost("test")]
    public async Task<IActionResult> TestNotification()
    {
        await notificationService.SendNotificationAsync(
            "Test Bildirimi",
            "Bu bir push notification testidir! 🚀",
            NotificationType.Info);

        return Ok(new { message = "Test notification sent (broadcast)" });
    }

    /// <summary>
    /// Kullanıcıya özel test bildirimi gönder
    /// </summary>
    [HttpPost("test-personal")]
    public async Task<IActionResult> TestPersonalNotification()
    {
        var userId = GetUserId();
        await notificationService.SendNotificationAsync(
            "Kişisel Bildirim",
            "Bu sadece sana özel bir bildirimdir! 🔐",
            NotificationType.Info,
            userId: userId);

        return Ok(new { message = "Personal test notification sent", userId });
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
    /// Firebase durumunu, credential doğrulamasını ve FCM API testini göster
    /// </summary>
    [AllowAnonymous]
    [HttpGet("firebase-diagnostics")]
    public async Task<IActionResult> FirebaseDiagnostics()
    {
        string? tokenStatus = null;
        string? credentialError = null;
        string? projectId = null;
        string? serviceAccountEmail = null;

        // FCM API direct test
        string? fcmTestStatus = null;
        string? fcmTestResponse = null;
        int? fcmTestHttpCode = null;

        if (FirebaseApp.DefaultInstance != null)
        {
            try
            {
                var options = FirebaseApp.DefaultInstance.Options;
                projectId = options.ProjectId;
                if (options.Credential.UnderlyingCredential is ServiceAccountCredential saCred)
                    serviceAccountEmail = saCred.Id;

                // Scoped OAuth token al
                var scopedCredential = options.Credential.CreateScoped(
                    "https://www.googleapis.com/auth/firebase.messaging",
                    "https://www.googleapis.com/auth/cloud-platform");
                var accessToken = await scopedCredential.UnderlyingCredential.GetAccessTokenForRequestAsync();

                tokenStatus = !string.IsNullOrEmpty(accessToken)
                    ? $"Valid ({accessToken.Length} chars)"
                    : "Empty token returned";

                // FCM API'ye validate_only (dry-run) test yap
                if (!string.IsNullOrEmpty(accessToken) && !string.IsNullOrEmpty(projectId))
                {
                    using var httpClient = new HttpClient();
                    var testPayload = "{\"validate_only\":true,\"message\":{\"token\":\"fake-token\",\"notification\":{\"title\":\"test\",\"body\":\"test\"}}}";
                    var url = $"https://fcm.googleapis.com/v1/projects/{projectId}/messages:send";

                    using var request = new HttpRequestMessage(HttpMethod.Post, url);
                    request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);
                    request.Content = new StringContent(testPayload, System.Text.Encoding.UTF8, "application/json");

                    var response = await httpClient.SendAsync(request);
                    fcmTestHttpCode = (int)response.StatusCode;
                    fcmTestResponse = await response.Content.ReadAsStringAsync();

                    fcmTestStatus = fcmTestHttpCode switch
                    {
                        200 => "SUCCESS - FCM API fully working",
                        400 => "AUTH_OK - Token auth works (400 = fake token rejected, expected)",
                        401 => "FAILED - OAuth token rejected",
                        403 => "FAILED - FCM API not enabled or no permission",
                        _ => $"HTTP {fcmTestHttpCode}"
                    };
                }
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
            fcmApiTest = new { status = fcmTestStatus, httpCode = fcmTestHttpCode, response = fcmTestResponse }
        });
    }
}
