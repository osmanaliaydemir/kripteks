using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using FirebaseAdmin;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

/// <summary>
/// Firebase Cloud Messaging servisi.
/// FirebaseAdmin SDK'nın HTTP client sorunu nedeniyle doğrudan FCM v1 API kullanılır.
/// </summary>
public class FirebaseNotificationService : IFirebaseNotificationService
{
    private readonly AppDbContext _context;
    private readonly ILogger<FirebaseNotificationService> _logger;
    private readonly HttpClient _httpClient;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    public FirebaseNotificationService(
        AppDbContext context,
        ILogger<FirebaseNotificationService> logger,
        IHttpClientFactory httpClientFactory)
    {
        _context = context;
        _logger = logger;
        _httpClient = httpClientFactory.CreateClient("Firebase");
    }

    public async Task<string> SendToDeviceAsync(
        string fcmToken,
        string title,
        string body,
        Dictionary<string, string>? data = null)
    {
        try
        {
            var response = await SendFcmMessageAsync(fcmToken, title, body, data);
            _logger.LogInformation("Successfully sent notification to device: {Token}", fcmToken[..Math.Min(20, fcmToken.Length)]);
            return response;
        }
        catch (FcmException ex) when (ex.ErrorCode is "UNREGISTERED" or "INVALID_ARGUMENT")
        {
            _logger.LogWarning("Invalid FCM token, marking device inactive: {Token}", fcmToken[..Math.Min(20, fcmToken.Length)]);
            await MarkDeviceInactiveAsync(fcmToken);
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send notification to device: {Token}", fcmToken[..Math.Min(20, fcmToken.Length)]);
            throw;
        }
    }

    public async Task<int> SendToUserAsync(
        string userId,
        string title,
        string body,
        Dictionary<string, string>? data = null)
    {
        var devices = await _context.UserDevices
            .Where(d => d.UserId == userId && d.IsActive)
            .Select(d => d.FcmToken)
            .ToListAsync();

        if (!devices.Any())
        {
            _logger.LogWarning("No active devices found for user: {UserId}", userId);
            return 0;
        }

        return await SendBulkNotificationAsync(devices, title, body, data);
    }

    public async Task<int> SendBulkNotificationAsync(
        List<string> fcmTokens,
        string title,
        string body,
        Dictionary<string, string>? data = null)
    {
        if (!fcmTokens.Any())
            return 0;

        var successCount = 0;

        foreach (var token in fcmTokens)
        {
            try
            {
                await SendFcmMessageAsync(token, title, body, data);
                successCount++;
            }
            catch (FcmException ex) when (ex.ErrorCode is "UNREGISTERED" or "INVALID_ARGUMENT")
            {
                await MarkDeviceInactiveAsync(token);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send to token: {Token}", token[..Math.Min(20, token.Length)]);
            }
        }

        _logger.LogInformation("Bulk send result: {SuccessCount}/{TotalCount} successful", successCount, fcmTokens.Count);
        return successCount;
    }

    /// <summary>
    /// FCM v1 API'sine doğrudan HTTP POST ile mesaj gönderir.
    /// Firebase SDK'nın internal HTTP client'ı yerine kendi HttpClient'ımızı kullanır.
    /// </summary>
    private async Task<string> SendFcmMessageAsync(
        string fcmToken,
        string title,
        string body,
        Dictionary<string, string>? data)
    {
        var app = FirebaseApp.DefaultInstance
            ?? throw new InvalidOperationException("Firebase is not initialized");

        var projectId = app.Options.ProjectId
            ?? throw new InvalidOperationException("Firebase ProjectId is not configured");

        // OAuth 2 token al
        var credential = app.Options.Credential;
        var accessToken = await credential.UnderlyingCredential.GetAccessTokenForRequestAsync();

        if (string.IsNullOrEmpty(accessToken))
            throw new InvalidOperationException("Failed to obtain Firebase OAuth access token");

        // FCM v1 API payload oluştur
        var payload = new
        {
            message = new
            {
                token = fcmToken,
                notification = new { title, body },
                data,
                android = new
                {
                    priority = "HIGH",
                    notification = new
                    {
                        sound = "default",
                        channel_id = "kripteks_channel"
                    }
                },
                apns = new
                {
                    payload = new
                    {
                        aps = new
                        {
                            sound = "default",
                            badge = 1,
                            alert = new { title, body }
                        }
                    }
                }
            }
        };

        var json = JsonSerializer.Serialize(payload, JsonOptions);
        var url = $"https://fcm.googleapis.com/v1/projects/{projectId}/messages:send";

        using var request = new HttpRequestMessage(HttpMethod.Post, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        request.Content = new StringContent(json, Encoding.UTF8, "application/json");

        using var response = await _httpClient.SendAsync(request);
        var responseBody = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError("FCM API error: {StatusCode} - {Body}", response.StatusCode, responseBody);

            // FCM error code'unu parse et
            var errorCode = TryParseErrorCode(responseBody);
            throw new FcmException(
                $"FCM API returned {response.StatusCode}: {responseBody}",
                errorCode);
        }

        // Response'dan message name'i al
        var messageId = TryParseMessageName(responseBody) ?? "success";
        return messageId;
    }

    private static string? TryParseErrorCode(string responseBody)
    {
        try
        {
            using var doc = JsonDocument.Parse(responseBody);
            if (doc.RootElement.TryGetProperty("error", out var error) &&
                error.TryGetProperty("details", out var details))
            {
                foreach (var detail in details.EnumerateArray())
                {
                    if (detail.TryGetProperty("errorCode", out var code))
                        return code.GetString();
                }
            }

            // Alternatif: status field
            if (doc.RootElement.TryGetProperty("error", out var err) &&
                err.TryGetProperty("status", out var status))
            {
                return status.GetString();
            }
        }
        catch { }
        return null;
    }

    private static string? TryParseMessageName(string responseBody)
    {
        try
        {
            using var doc = JsonDocument.Parse(responseBody);
            if (doc.RootElement.TryGetProperty("name", out var name))
                return name.GetString();
        }
        catch { }
        return null;
    }

    private async Task MarkDeviceInactiveAsync(string fcmToken)
    {
        var device = await _context.UserDevices
            .FirstOrDefaultAsync(d => d.FcmToken == fcmToken);

        if (device != null)
        {
            device.IsActive = false;
            await _context.SaveChangesAsync();
            _logger.LogInformation("Marked device as inactive: {Token}", fcmToken[..Math.Min(20, fcmToken.Length)]);
        }
    }
}

/// <summary>
/// FCM API hata exception'ı
/// </summary>
public class FcmException : Exception
{
    public string? ErrorCode { get; }

    public FcmException(string message, string? errorCode = null) : base(message)
    {
        ErrorCode = errorCode;
    }
}
