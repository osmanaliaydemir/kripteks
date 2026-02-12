using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class PortfolioController : ControllerBase
{
    private readonly IPortfolioService _portfolioService;

    public PortfolioController(IPortfolioService portfolioService)
    {
        _portfolioService = portfolioService;
    }

    /// <summary>
    /// Portföy özet bilgisini döndürür: asset dağılımı, risk metrikleri, rebalancing önerileri.
    /// </summary>
    [HttpGet("summary")]
    public async Task<IActionResult> GetPortfolioSummary()
    {
        var summary = await _portfolioService.GetPortfolioSummaryAsync();
        return Ok(summary);
    }
}
