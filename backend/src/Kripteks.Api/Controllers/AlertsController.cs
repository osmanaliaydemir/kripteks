using System.Security.Claims;
using Kripteks.Core.DTOs;
using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class AlertsController : ControllerBase
{
    private readonly IAlertService _alertService;

    public AlertsController(IAlertService alertService)
    {
        _alertService = alertService;
    }

    private Guid GetUserId() => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? throw new Exception("User not found"));

    [HttpGet]
    public async Task<IActionResult> GetAlerts()
    {
        var alerts = await _alertService.GetUserAlertsAsync(GetUserId());
        return Ok(alerts);
    }

    [HttpPost]
    public async Task<IActionResult> CreateAlert([FromBody] CreateAlertDto createDto)
    {
        var alert = await _alertService.CreateAlertAsync(GetUserId(), createDto);
        return Ok(alert);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateAlert(Guid id, [FromBody] UpdateAlertDto updateDto)
    {
        var alert = await _alertService.UpdateAlertAsync(GetUserId(), id, updateDto);
        if (alert == null) return NotFound();
        return Ok(alert);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteAlert(Guid id)
    {
        var success = await _alertService.DeleteAlertAsync(GetUserId(), id);
        if (!success) return NotFound();
        return Ok();
    }
}
