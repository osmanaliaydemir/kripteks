using Kripteks.Core.Entities;
using Kripteks.Infrastructure.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Kripteks.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SummaryStatsController : ControllerBase
{
    private readonly AppDbContext _context;

    public SummaryStatsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetStats()
    {
        var totalBots = await _context.Bots.CountAsync();
        var activeBots =
            await _context.Bots.CountAsync(b => b.Status == BotStatus.Running || b.Status == BotStatus.WaitingForEntry);
        var stoppedBots = await _context.Bots.CountAsync(b => b.Status == BotStatus.Stopped);

        // Toplam Hacim (Trade tablosundan topla)
        var totalVolume = await _context.Trades.SumAsync(t => (decimal?)t.Total) ?? 0;

        return Ok(new
        {
            total_bots = totalBots,
            active_bots = activeBots,
            stopped_bots = stoppedBots,
            total_volume = totalVolume
        });
    }
}
