using Kripteks.Core.Entities;
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

    public SettingsController(AppDbContext context, IAuditLogService auditLogService)
    {
        _context = context;
        _auditLogService = auditLogService;
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

        // Güvenlik için Secret Key'i asla tam dönmüyoruz.
        // Sadece maskeli API Key dönüyoruz.
        var maskedKey = creds.ApiKey.Length > 8
            ? string.Concat(creds.ApiKey.AsSpan(0, 4), "****", creds.ApiKey.AsSpan(creds.ApiKey.Length - 4))
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

        if (existing != null)
        {
            // Güncelleme
            existing.ApiKey = model.ApiKey;
            existing.ApiSecret = model.SecretKey; // Prodüksiyonda burada şifreleme yapılmalı!
            existing.UpdatedAt = DateTime.UtcNow;
            _context.ExchangeCredentials.Update(existing);
        }
        else
        {
            // Yeni Kayıt
            var newCreds = new ExchangeCredential
            {
                UserId = userId,
                ExchangeName = "Binance",
                ApiKey = model.ApiKey,
                ApiSecret = model.SecretKey, // Prodüksiyonda şifreleme!
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
    public string ApiKey { get; set; } = string.Empty;
    public string SecretKey { get; set; } = string.Empty;
}
