using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class AnalyticsController : ControllerBase
{
    private readonly IAnalyticsService _analyticsService;

    public AnalyticsController(IAnalyticsService analyticsService)
    {
        _analyticsService = analyticsService;
    }

    [HttpGet("stats")]
    public async Task<IActionResult> GetDashboardStats()
    {
        var stats = await _analyticsService.GetDashboardStatsAsync();
        return Ok(stats);
    }

    [HttpGet("equity")]
    public async Task<IActionResult> GetEquityCurve()
    {
        var data = await _analyticsService.GetEquityCurveAsync();
        return Ok(data);
    }

    [HttpGet("performance")]
    public async Task<IActionResult> GetStrategyPerformance()
    {
        var data = await _analyticsService.GetStrategyPerformanceAsync();
        return Ok(data);
    }
}
