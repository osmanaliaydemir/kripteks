using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class AnalyticsController : ControllerBase
{
    private readonly IAnalyticsService _analyticsService;
    private readonly INewsService _newsService;
    private readonly IMarketSentimentState _sentimentState;
    private readonly AppDbContext _dbContext;

    private readonly IAiService _aiService;

    public AnalyticsController(
        IAnalyticsService analyticsService,
        INewsService newsService,
        IMarketSentimentState sentimentState,
        IAiService aiService,
        AppDbContext dbContext)
    {
        _analyticsService = analyticsService;
        _newsService = newsService;
        _sentimentState = sentimentState;
        _aiService = aiService;
        _dbContext = dbContext;
    }

    [HttpGet("test-ai")]
    public async Task<IActionResult> TestAiIntegration()
    {
        var news = await _newsService.GetLatestNewsAsync();
        if (!news.Any()) return Ok(new { success = false, message = "Hiç haber bulunamadı." });

        var text = news.First().Title;
        var result = await _aiService.AnalyzeTextAsync(text);

        return Ok(new { success = true, result });
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

        // AI aktifse ve haber varsa Türkçe'ye çevir
        if (news.Any())
        {
            var tasks = news.Select(async item =>
            {
                try
                {
                    // Şimdilik sadece başlıkları çeviriyoruz (Hız için)
                    item.Title = await _aiService.TranslateAsync(item.Title);
                    // İsterseniz özeti de çevirebilirsiniz ama maliyeti artırır
                    // item.Summary = await _aiService.TranslateAsync(item.Summary);
                }
                catch
                {
                    // Çeviri hatası olursa orijinal kalsın
                }
            });

            await Task.WhenAll(tasks);
        }

        return Ok(news);
    }

    [HttpGet("sentiment")]
    public IActionResult GetSentiment()
    {
        return Ok(_sentimentState.CurrentSentiment);
    }

    /// <summary>
    /// Son X saatteki sentiment geçmişini döndürür
    /// </summary>
    [HttpGet("sentiment-history")]
    public async Task<IActionResult> GetSentimentHistory([FromQuery] int hours = 24)
    {
        var since = DateTime.UtcNow.AddHours(-hours);

        var history = await _dbContext.SentimentHistories
            .Where(h => h.RecordedAt >= since)
            .OrderBy(h => h.RecordedAt)
            .Select(h => new
            {
                h.Score,
                h.Action,
                h.Symbol,
                h.RecordedAt,
                h.ModelCount
            })
            .ToListAsync();

        return Ok(history);
    }
}
