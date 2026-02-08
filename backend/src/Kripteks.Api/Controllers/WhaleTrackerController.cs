using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class WhaleTrackerController : ControllerBase
{
    private readonly IWhaleTrackerService _whaleTrackerService;

    public WhaleTrackerController(IWhaleTrackerService whaleTrackerService)
    {
        _whaleTrackerService = whaleTrackerService;
    }

    [HttpGet]
    public async Task<IActionResult> GetWhaleTrades([FromQuery] int minUsdValue = 100000, [FromQuery] int count = 20)
    {
        var trades = await _whaleTrackerService.GetRecentWhaleTradesAsync(minUsdValue, count);
        return Ok(trades);
    }
}
