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
    private readonly INewsService _newsService;
    private readonly IMarketSentimentState _sentimentState;

    public AnalyticsController(IAnalyticsService analyticsService, INewsService newsService,
        IMarketSentimentState sentimentState)
    {
        _analyticsService = analyticsService;
        _newsService = newsService;
        _sentimentState = sentimentState;
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

    [HttpGet("news")]
    public async Task<IActionResult> GetNews([FromQuery] string symbol = "BTC")
    {
        var news = await _newsService.GetLatestNewsAsync(symbol);
        return Ok(news);
    }

    [HttpGet("sentiment")]
    public IActionResult GetSentiment()
    {
        return Ok(_sentimentState.CurrentSentiment);
    }
}
