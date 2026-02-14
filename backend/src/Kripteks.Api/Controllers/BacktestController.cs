using Kripteks.Infrastructure.Services;
using Kripteks.Core.DTOs;
using Kripteks.Core.Interfaces;
using Kripteks.Api.Hubs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;

namespace Kripteks.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BacktestController : ControllerBase
{
    private readonly BacktestService _backtestService;
    private readonly IBacktestRepository _backtestRepository;
    private readonly IHubContext<BacktestHub> _hubContext;

    public BacktestController(
        BacktestService backtestService,
        IBacktestRepository backtestRepository,
        IHubContext<BacktestHub> hubContext)
    {
        _backtestService = backtestService;
        _backtestRepository = backtestRepository;
        _hubContext = hubContext;
    }

    [HttpPost("run")]
    public async Task<ActionResult<BacktestResultDto>> Run([FromBody] BacktestRequestDto request)
    {
        var result = await _backtestService.RunBacktestAsync(request);
        return Ok(result);
    }

    [HttpPost("scan")]
    public async Task<ActionResult<BatchBacktestResultDto>> Scan([FromBody] BatchBacktestRequestDto request)
    {
        var result = await _backtestService.RunBatchBacktestAsync(request);
        return Ok(result);
    }

    [HttpPost("optimize")]
    public async Task<ActionResult<OptimizationResultDto>> Optimize([FromBody] BacktestRequestDto request)
    {
        var result = await _backtestService.OptimizeBacktestAsync(request);
        return Ok(result);
    }

    [HttpPost("optimize-with-progress/{sessionId}")]
    public async Task<ActionResult<OptimizationResultDto>> OptimizeWithProgress(
        string sessionId,
        [FromBody] BacktestRequestDto request)
    {
        var result = await _backtestService.OptimizeBacktestWithProgressAsync(
            request,
            async (currentStep, totalSteps, currentPnl, bestPnl, parameters) =>
            {
                var progress = new BacktestProgressDto
                {
                    SessionId = sessionId,
                    CurrentStep = currentStep,
                    TotalSteps = totalSteps,
                    CurrentPnlPercent = currentPnl,
                    BestPnlPercent = bestPnl,
                    CurrentParameters = System.Text.Json.JsonSerializer.Serialize(parameters),
                    Status = currentStep == totalSteps ? "completed" : "running"
                };

                await _hubContext.Clients.Group($"backtest-{sessionId}")
                    .SendAsync("ReceiveProgress", progress);
            });

        // Send completion notification
        await _hubContext.Clients.Group($"backtest-{sessionId}")
            .SendAsync("ReceiveOptimizationComplete", new OptimizationCompleteDto
            {
                SessionId = sessionId,
                Success = true
            });

        return Ok(result);
    }

    [HttpPost("save")]
    public async Task<ActionResult<Guid>> SaveResult([FromBody] SaveBacktestRequestDto request)
    {
        // Get userId from claims (assuming authentication is in place)
        var userId = User.Identity?.Name ?? "anonymous";
        var resultId = await _backtestService.SaveResultAsync(request.Request, request.Result, userId);
        return Ok(new { id = resultId });
    }

    [HttpGet("history")]
    public async Task<ActionResult> GetHistory([FromQuery] int skip = 0, [FromQuery] int take = 50)
    {
        var userId = User.Identity?.Name ?? "anonymous";
        var results = await _backtestRepository.GetByUserIdAsync(userId, skip, take);
        var count = await _backtestRepository.GetCountByUserIdAsync(userId);
        return Ok(new { results, total = count });
    }

    [HttpGet("{id}")]
    public async Task<ActionResult> GetById(Guid id)
    {
        var result = await _backtestRepository.GetByIdAsync(id);
        if (result == null) return NotFound();
        return Ok(result);
    }

    [HttpPost("{id}/favorite")]
    public async Task<ActionResult> ToggleFavorite(Guid id)
    {
        var result = await _backtestRepository.GetByIdAsync(id);
        if (result == null) return NotFound();

        result.IsFavorite = !result.IsFavorite;
        await _backtestRepository.UpdateAsync(result);
        return Ok(new { isFavorite = result.IsFavorite });
    }

    [HttpDelete("{id}")]
    public async Task<ActionResult> Delete(Guid id)
    {
        await _backtestRepository.DeleteAsync(id);
        return NoContent();
    }
}


