using Kripteks.Core.Interfaces;
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
    public async Task<IActionResult> GetCoins()
    {
        var coins = await _marketService.GetAvailablePairsAsync();
        return Ok(coins);
    }
}
