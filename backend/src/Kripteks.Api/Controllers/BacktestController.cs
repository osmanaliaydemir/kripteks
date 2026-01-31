using Kripteks.Infrastructure.Services;
using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BacktestController : ControllerBase
{
    private readonly BacktestService _backtestService;

    public BacktestController(BacktestService backtestService)
    {
        _backtestService = backtestService;
    }

    [HttpPost("run")]
    public async Task<ActionResult<BacktestResultDto>> Run([FromBody] BacktestRequestDto request)
    {
        var result = await _backtestService.RunBacktestAsync(request);
        return Ok(result);
    }
}
