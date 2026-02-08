using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/market-analysis")]
public class MarketAnalysisController : ControllerBase
{
    private readonly IMarketAnalysisService _marketAnalysisService;
    private readonly ILogger<MarketAnalysisController> _logger;

    public MarketAnalysisController(
        IMarketAnalysisService marketAnalysisService,
        ILogger<MarketAnalysisController> logger)
    {
        _marketAnalysisService = marketAnalysisService;
        _logger = logger;
    }

    /// <summary>
    /// Piyasa genel görünümünü döndürür
    /// </summary>
    [HttpGet("overview")]
    public async Task<IActionResult> GetOverview()
    {
        try
        {
            var overview = await _marketAnalysisService.GetMarketOverviewAsync();
            return Ok(overview);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching market overview");
            return StatusCode(500, new { error = "Piyasa verileri alınırken hata oluştu" });
        }
    }

    /// <summary>
    /// En çok kazanan coinleri döndürür
    /// </summary>
    [HttpGet("top-gainers")]
    public async Task<IActionResult> GetTopGainers([FromQuery] int count = 5)
    {
        try
        {
            var gainers = await _marketAnalysisService.GetTopGainersAsync(count);
            return Ok(gainers);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching top gainers");
            return StatusCode(500, new { error = "En çok kazananlar alınırken hata oluştu" });
        }
    }

    /// <summary>
    /// En çok kaybeden coinleri döndürür
    /// </summary>
    [HttpGet("top-losers")]
    public async Task<IActionResult> GetTopLosers([FromQuery] int count = 5)
    {
        try
        {
            var losers = await _marketAnalysisService.GetTopLosersAsync(count);
            return Ok(losers);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching top losers");
            return StatusCode(500, new { error = "En çok kaybedenler alınırken hata oluştu" });
        }
    }

    /// <summary>
    /// Belirtilen saatlik hacim geçmişini döndürür
    /// </summary>
    [HttpGet("volume-history")]
    public async Task<IActionResult> GetVolumeHistory([FromQuery] int hours = 24)
    {
        try
        {
            if (hours < 1 || hours > 168) // Max 1 hafta
            {
                return BadRequest(new { error = "Saat parametresi 1-168 arasında olmalıdır" });
            }

            var volumeHistory = await _marketAnalysisService.GetVolumeHistoryAsync(hours);
            return Ok(volumeHistory);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching volume history");
            return StatusCode(500, new { error = "Hacim geçmişi alınırken hata oluştu" });
        }
    }

    /// <summary>
    /// Piyasa metriklerini döndürür (Fear & Greed, BTC/ETH fiyatları vb.)
    /// </summary>
    [HttpGet("metrics")]
    public async Task<IActionResult> GetMetrics()
    {
        try
        {
            var metrics = await _marketAnalysisService.GetMarketMetricsAsync();
            return Ok(metrics);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching market metrics");
            return StatusCode(500, new { error = "Piyasa metrikleri alınırken hata oluştu" });
        }
    }
}
