using Kripteks.Core.Entities;
using Kripteks.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;

namespace Kripteks.Api.Controllers;

[Authorize(Roles = "Admin")]
[ApiController]
[Route("api/[controller]")]
public class LogsController : ControllerBase
{
    private readonly AppDbContext _context;

    public LogsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetLogs([FromQuery] int limit = 100, [FromQuery] string? level = null)
    {
        var query = _context.Logs.AsQueryable();

        if (!string.IsNullOrEmpty(level) && Enum.TryParse<Kripteks.Core.Entities.LogLevel>(level, true, out var logLevel))
        {
            query = query.Where(x => x.Level == logLevel);
        }

        var logs = await query
            .OrderByDescending(x => x.Timestamp)
            .Take(limit)
            .Select(x => new 
            {
                x.Id,
                x.Message,
                x.Timestamp,
                Level = x.Level.ToString(),
                x.BotId
            })
            .ToListAsync();

        return Ok(logs);
    }

    [HttpDelete]
    public async Task<IActionResult> ClearLogs()
    {
        // Tüm logları siler (Dikkatli kullanılmalı)
        _context.Logs.RemoveRange(_context.Logs);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Sistem logları temizlendi." });
    }
}
