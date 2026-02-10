using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Kripteks.Core.DTOs;
using Kripteks.Core.Entities;
using Kripteks.Infrastructure.Data;

namespace Kripteks.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DevicesController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ILogger<DevicesController> _logger;

    public DevicesController(AppDbContext context, ILogger<DevicesController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpPost("register")]
    public async Task<IActionResult> RegisterDevice([FromBody] RegisterDeviceDto dto)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        // 1. Önce aynı kullanıcı + aynı cihaz modeli ile eşleşen kayıt ara
        var device = await _context.UserDevices
            .FirstOrDefaultAsync(d => d.UserId == userId
                && d.DeviceType == dto.DeviceType
                && d.DeviceModel == dto.DeviceModel);

        // 2. Bulunamazsa, aynı FcmToken ile ara (başka kullanıcıdan gelebilir)
        device ??= await _context.UserDevices
            .FirstOrDefaultAsync(d => d.FcmToken == dto.FcmToken);

        if (device != null)
        {
            // Mevcut cihazı güncelle (FcmToken dahil)
            device.UserId = userId;
            device.FcmToken = dto.FcmToken;
            device.LastUsedAt = DateTime.UtcNow;
            device.IsActive = true;
            device.DeviceModel = dto.DeviceModel;
            device.AppVersion = dto.AppVersion;

            _logger.LogInformation(
                "Device updated for user {UserId}: {DeviceModel} - token refreshed",
                userId, dto.DeviceModel);
        }
        else
        {
            // Yeni cihaz kaydı
            device = new UserDevice
            {
                UserId = userId,
                FcmToken = dto.FcmToken,
                DeviceType = dto.DeviceType,
                DeviceModel = dto.DeviceModel,
                AppVersion = dto.AppVersion,
                RegisteredAt = DateTime.UtcNow,
                LastUsedAt = DateTime.UtcNow,
                IsActive = true
            };

            _context.UserDevices.Add(device);

            _logger.LogInformation(
                "New device registered for user {UserId}: {DeviceType} - {DeviceModel}",
                userId, dto.DeviceType, dto.DeviceModel);
        }

        await _context.SaveChangesAsync();

        return Ok(new { message = "Device registered successfully" });
    }

    [HttpDelete("{fcmToken}")]
    public async Task<IActionResult> UnregisterDevice(string fcmToken)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var device = await _context.UserDevices
            .FirstOrDefaultAsync(d => d.FcmToken == fcmToken && d.UserId == userId);

        if (device == null)
        {
            return NotFound(new { message = "Device not found" });
        }

        _context.UserDevices.Remove(device);
        await _context.SaveChangesAsync();

        _logger.LogInformation(
            "Device unregistered for user {UserId}: {Token}",
            userId,
            fcmToken.Substring(0, Math.Min(20, fcmToken.Length)));

        return Ok(new { message = "Device unregistered successfully" });
    }

    [HttpGet]
    public async Task<IActionResult> GetUserDevices()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var devices = await _context.UserDevices
            .Where(d => d.UserId == userId)
            .OrderByDescending(d => d.LastUsedAt)
            .Select(d => new
            {
                d.Id,
                d.DeviceType,
                d.DeviceModel,
                d.AppVersion,
                d.RegisteredAt,
                d.LastUsedAt,
                d.IsActive
            })
            .ToListAsync();

        return Ok(devices);
    }
}
