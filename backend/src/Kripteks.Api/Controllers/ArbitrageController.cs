using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class ArbitrageController : ControllerBase
{
    private readonly IArbitrageScannerService _arbitrageScannerService;

    public ArbitrageController(IArbitrageScannerService arbitrageScannerService)
    {
        _arbitrageScannerService = arbitrageScannerService;
    }

    [HttpGet("opportunities")]
    public async Task<IActionResult> GetOpportunities()
    {
        var opportunities = await _arbitrageScannerService.GetOpportunitiesAsync();
        return Ok(opportunities);
    }
}
