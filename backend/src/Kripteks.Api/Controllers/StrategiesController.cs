using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StrategiesController : ControllerBase
{
    [HttpGet]
    public IActionResult GetStrategies()
    {
        var strategies = new[]
        {
            new
            {
                id = "strategy-market-buy", name = "Hemen Al (Market Buy)",
                description = "Beklemeden o anki fiyattan alım yapar."
            },
            new
            {
                id = "strategy-golden-rose", name = "Golden Rose Trend Strategy",
                description =
                    "SMA 111-200-350 trend takibi ve Fibonacci 1.618 kar al hedefli özel strateji. Bitcoin halving döngüleri için optimize edilmiştir."
            },
            new
            {
                id = "strategy-alpha-trend", name = "Alpha Trend (EMA + RSI)",
                description =
                    "EMA 20/50 kesişimlerini RSI filtresi ile harmanlayan, trend başlangıçlarını yakalamaya çalışan gelişmiş strateji."
            },
            new
            {
                id = "SMA_111", name = "SMA 111 Basic", description = "Sadece SMA 111 kırılımına bakan basit strateji."
            },
            new
            {
                id = "RSI_SCALP", name = "RSI Scalper",
                description = "RSI 30-70 bandında işlem yapan yatay piyasa stratejisi."
            }
        };

        return Ok(strategies);
    }
}
