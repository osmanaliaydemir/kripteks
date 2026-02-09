using Kripteks.Core.Entities;
using Kripteks.Core.DTOs;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class SettingsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IAuditLogService _auditLogService;
    private readonly IEncryptionService _encryptionService;

    public SettingsController(AppDbContext context, IAuditLogService auditLogService,
        IEncryptionService encryptionService)
    {
        _context = context;
        _auditLogService = auditLogService;
        _encryptionService = encryptionService;
    }

    [Authorize(Roles = "Admin,Trader")]
    [HttpGet("keys")]
    public async Task<IActionResult> GetApiKeys()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var creds = await _context.ExchangeCredentials
            .FirstOrDefaultAsync(x => x.UserId == userId && x.ExchangeName == "Binance");

        if (creds == null) return Ok(new { hasKeys = false });

        // Şifreli API Key'i çözüp maskeli dönüyoruz. Secret Key asla dönmüyor.
        var decryptedKey = _encryptionService.Decrypt(creds.ApiKey);
        var maskedKey = decryptedKey.Length > 8
            ? string.Concat(decryptedKey.AsSpan(0, 4), "****", decryptedKey.AsSpan(decryptedKey.Length - 4))
            : "****";

        return Ok(new { hasKeys = true, apiKey = maskedKey });
    }

    [Authorize(Roles = "Admin,Trader")]
    [HttpPost("keys")]
    public async Task<IActionResult> SaveApiKeys([FromBody] ApiKeyDto model)
    {
        if (string.IsNullOrEmpty(model.ApiKey) || string.IsNullOrEmpty(model.SecretKey))
            return BadRequest("API Key ve Secret Key zorunludur.");

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var existing = await _context.ExchangeCredentials
            .FirstOrDefaultAsync(x => x.UserId == userId && x.ExchangeName == "Binance");

        var encryptedApiKey = _encryptionService.Encrypt(model.ApiKey);
        var encryptedSecret = _encryptionService.Encrypt(model.SecretKey);

        if (existing != null)
        {
            existing.ApiKey = encryptedApiKey;
            existing.ApiSecret = encryptedSecret;
            existing.UpdatedAt = DateTime.UtcNow;
            _context.ExchangeCredentials.Update(existing);
        }
        else
        {
            var newCreds = new ExchangeCredential
            {
                UserId = userId,
                ExchangeName = "Binance",
                ApiKey = encryptedApiKey,
                ApiSecret = encryptedSecret,
                CreatedAt = DateTime.UtcNow
            };
            await _context.ExchangeCredentials.AddAsync(newCreds);
        }

        await _context.SaveChangesAsync();
        await _auditLogService.LogAsync(userId, "API Anahtarları Güncellendi", new { Exchange = "Binance" });
        return Ok(new { message = "API anahtarları başarıyla kaydedildi." });
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("general")]
    public async Task<IActionResult> GetGeneralSettings()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var settings = await _context.SystemSettings
            .FirstOrDefaultAsync(x => x.UserId == userId);

        if (settings == null)
        {
            // Varsayılan ayarlar
            return Ok(new SystemSetting { UserId = userId });
        }

        return Ok(settings);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("general")]
    public async Task<IActionResult> SaveGeneralSettings([FromBody] SystemSetting model)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var existing = await _context.SystemSettings
            .FirstOrDefaultAsync(x => x.UserId == userId);

        if (existing != null)
        {
            existing.TelegramBotToken = model.TelegramBotToken;
            existing.TelegramChatId = model.TelegramChatId;
            existing.EnableTelegramNotifications = model.EnableTelegramNotifications;
            existing.GlobalStopLossPercent = model.GlobalStopLossPercent;
            existing.MaxActiveBots = model.MaxActiveBots;
            existing.DefaultTimeframe = model.DefaultTimeframe;
            existing.DefaultAmount = model.DefaultAmount;
            existing.UpdatedAt = DateTime.UtcNow;
            _context.SystemSettings.Update(existing);
        }
        else
        {
            model.UserId = userId;
            model.UpdatedAt = DateTime.UtcNow;
            await _context.SystemSettings.AddAsync(model);
        }

        await _context.SaveChangesAsync();
        await _auditLogService.LogAsync(userId, "Sistem Ayarları Güncellendi");
        return Ok(new { message = "Sistem ayarları başarıyla kaydedildi." });
    }

    [Authorize(Roles = "Admin,Trader")]
    [HttpGet("notifications")]
    public async Task<IActionResult> GetNotificationSettings()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var settings = await _context.SystemSettings
            .FirstOrDefaultAsync(x => x.UserId == userId);

        if (settings == null)
        {
            // Varsayılan değerler
            return Ok(new NotificationSettingsDto
            {
                NotifyBuySignals = true,
                NotifySellSignals = true,
                NotifyStopLoss = true,
                NotifyTakeProfit = true,
                NotifyGeneral = true,
                NotifyErrors = true,
                EnablePushNotifications = true
            });
        }

        return Ok(new NotificationSettingsDto
        {
            NotifyBuySignals = settings.NotifyBuySignals,
            NotifySellSignals = settings.NotifySellSignals,
            NotifyStopLoss = settings.NotifyStopLoss,
            NotifyTakeProfit = settings.NotifyTakeProfit,
            NotifyGeneral = settings.NotifyGeneral,
            NotifyErrors = settings.NotifyErrors,
            EnablePushNotifications = settings.EnablePushNotifications
        });
    }

    [Authorize(Roles = "Admin,Trader")]
    [HttpPut("notifications")]
    public async Task<IActionResult> UpdateNotificationSettings([FromBody] NotificationSettingsDto model)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var existing = await _context.SystemSettings
            .FirstOrDefaultAsync(x => x.UserId == userId);

        if (existing != null)
        {
            existing.NotifyBuySignals = model.NotifyBuySignals;
            existing.NotifySellSignals = model.NotifySellSignals;
            existing.NotifyStopLoss = model.NotifyStopLoss;
            existing.NotifyTakeProfit = model.NotifyTakeProfit;
            existing.NotifyGeneral = model.NotifyGeneral;
            existing.NotifyErrors = model.NotifyErrors;
            existing.EnablePushNotifications = model.EnablePushNotifications;
            existing.UpdatedAt = DateTime.UtcNow;
            _context.SystemSettings.Update(existing);
        }
        else
        {
            var newSettings = new SystemSetting
            {
                UserId = userId,
                NotifyBuySignals = model.NotifyBuySignals,
                NotifySellSignals = model.NotifySellSignals,
                NotifyStopLoss = model.NotifyStopLoss,
                NotifyTakeProfit = model.NotifyTakeProfit,
                NotifyGeneral = model.NotifyGeneral,
                NotifyErrors = model.NotifyErrors,
                EnablePushNotifications = model.EnablePushNotifications,
                UpdatedAt = DateTime.UtcNow
            };
            await _context.SystemSettings.AddAsync(newSettings);
        }

        await _context.SaveChangesAsync();
        await _auditLogService.LogAsync(userId, "Bildirim Ayarları Güncellendi");
        return Ok(new { message = "Bildirim ayarları başarıyla kaydedildi." });
    }

    [Authorize(Roles = "Admin,Trader")]
    [HttpPost("fcm-token")]
    public async Task<IActionResult> UpdateFcmToken([FromBody] UpdateFcmTokenRequest model)
    {
        if (string.IsNullOrWhiteSpace(model.FcmToken))
            return BadRequest("FCM token zorunludur.");

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var existing = await _context.SystemSettings
            .FirstOrDefaultAsync(x => x.UserId == userId);

        if (existing != null)
        {
            existing.FcmToken = model.FcmToken;
            existing.UpdatedAt = DateTime.UtcNow;
            _context.SystemSettings.Update(existing);
        }
        else
        {
            var newSettings = new SystemSetting
            {
                UserId = userId,
                FcmToken = model.FcmToken,
                UpdatedAt = DateTime.UtcNow
            };
            await _context.SystemSettings.AddAsync(newSettings);
        }

        await _context.SaveChangesAsync();
        return Ok(new { message = "FCM token kaydedildi." });
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("audit-logs")]
    public async Task<IActionResult> GetAuditLogs()
    {
        var logs = await _context.AuditLogs
            .OrderByDescending(x => x.Timestamp)
            .Take(200) // Son 200 log
            .ToListAsync();
        return Ok(logs);
    }
}

public class ApiKeyDto
{
    [System.ComponentModel.DataAnnotations.Required(ErrorMessage = "API Key zorunludur.")]
    [System.ComponentModel.DataAnnotations.StringLength(512, MinimumLength = 8, ErrorMessage = "API Key en az 8 karakter olmalıdır.")]
    public string ApiKey { get; set; } = string.Empty;

    [System.ComponentModel.DataAnnotations.Required(ErrorMessage = "Secret Key zorunludur.")]
    [System.ComponentModel.DataAnnotations.StringLength(512, MinimumLength = 8, ErrorMessage = "Secret Key en az 8 karakter olmalıdır.")]
    public string SecretKey { get; set; } = string.Empty;
}

