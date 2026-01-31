using Kripteks.Core.DTOs;
using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class BotsController : ControllerBase
{
    private readonly IBotService _botService;

    public BotsController(IBotService botService)
    {
        _botService = botService;
    }

    [HttpGet]
    public async Task<ActionResult<List<BotDto>>> GetBots()
    {
        var bots = await _botService.GetAllBotsAsync();
        return Ok(bots);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<BotDto>> GetBot(Guid id)
    {
        var bot = await _botService.GetBotByIdAsync(id);
        if (bot == null) return NotFound();
        return Ok(bot);
    }

    [HttpPost("start")]
    public async Task<ActionResult<BotDto>> StartBot([FromBody] CreateBotRequest request)
    {
        if (request.Amount <= 0)
            return BadRequest("Amount must be greater than 0");

        var newBot = await _botService.CreateBotAsync(request);
        return CreatedAtAction(nameof(GetBot), new { id = newBot.Id }, newBot);
    }

    [HttpPost("{id}/stop")]
    public async Task<IActionResult> StopBot(Guid id)
    {
        await _botService.StopBotAsync(id);
        return Ok(new { message = "Bot stopped successfully" });
    }

    [HttpPost("stop-all")]
    public async Task<IActionResult> StopAllBots()
    {
        await _botService.StopAllBotsAsync();
        return Ok(new { message = "All bots stopped successfully" });
    }

    [HttpPost("{id}/clear-logs")]
    public async Task<IActionResult> ClearLogs(Guid id)
    {
        await _botService.ClearLogsAsync(id);
        return Ok(new { message = "Logs cleared" });
    }
}
