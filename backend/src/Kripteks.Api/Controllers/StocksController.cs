using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Services;
using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StocksController : ControllerBase
{
    private readonly IMarketDataService _marketService;

    public StocksController(IMarketDataService marketService)
    {
        _marketService = marketService;
    }

    [HttpGet]
    public async Task<IActionResult> GetCoins([FromQuery] string market = "crypto")
    {
        if (market.ToLower() == "bist")
        {
            var bistService = HttpContext.RequestServices.GetRequiredService<BistMarketService>();
            var stocks = await bistService.GetAvailablePairsAsync();
            return Ok(stocks);
        }

        var coins = await _marketService.GetAvailablePairsAsync();
        return Ok(coins);
    }
}
