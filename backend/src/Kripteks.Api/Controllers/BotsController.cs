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
    private readonly IAuditLogService _auditLogService;

    public BotsController(IBotService botService, IAuditLogService auditLogService)
    {
        _botService = botService;
        _auditLogService = auditLogService;
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

    [Authorize(Roles = "Admin,Trader")]
    [HttpPost("start")]
    public async Task<ActionResult<BotDto>> StartBot([FromBody] CreateBotRequest request)
    {
        if (request.Amount <= 0)
            return BadRequest("Amount must be greater than 0");

        var newBot = await _botService.CreateBotAsync(request);
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (userId != null)
        {
            await _auditLogService.LogAsync(userId, "Bot Başlatıldı",
                new
                {
                    BotId = newBot.Id, Symbol = newBot.Symbol, Amount = newBot.Amount, Strategy = newBot.StrategyName
                });
        }

        return CreatedAtAction(nameof(GetBot), new { id = newBot.Id }, newBot);
    }

    [Authorize(Roles = "Admin,Trader")]
    [HttpPost("{id}/stop")]
    public async Task<IActionResult> StopBot(Guid id)
    {
        await _botService.StopBotAsync(id);
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (userId != null)
        {
            await _auditLogService.LogAsync(userId, "Bot Durduruldu", new { BotId = id });
        }

        return Ok(new { message = "Bot stopped successfully" });
    }

    [Authorize(Roles = "Admin,Trader")]
    [HttpPost("stop-all")]
    public async Task<IActionResult> StopAllBots()
    {
        await _botService.StopAllBotsAsync();
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (userId != null)
        {
            await _auditLogService.LogAsync(userId, "Tüm Botlar Durduruldu");
        }

        return Ok(new { message = "All bots stopped successfully" });
    }

    [Authorize(Roles = "Admin,Trader")]
    [HttpPost("{id}/clear-logs")]
    public async Task<IActionResult> ClearLogs(Guid id)
    {
        await _botService.ClearLogsAsync(id);
        return Ok(new { message = "Logs cleared" });
    }

    [Authorize(Roles = "Admin,Trader")]
    [HttpPost("clear-history")]
    public async Task<IActionResult> ClearHistory()
    {
        await _botService.ArchiveHistoryAsync();
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (userId != null)
        {
            await _auditLogService.LogAsync(userId, "İşlem Geçmişi Temizlendi");
        }

        return Ok(new { message = "History cleared" });
    }
}
