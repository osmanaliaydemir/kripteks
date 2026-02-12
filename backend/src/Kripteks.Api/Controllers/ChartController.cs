using Binance.Net.Clients;
using Binance.Net.Enums;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Kripteks.Infrastructure.Helpers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Kripteks.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ChartController : ControllerBase
{
    private readonly BinanceRestClient _client;
    private readonly AppDbContext _context;

    public ChartController(BinanceRestClient client, AppDbContext context)
    {
        _client = client;
        _context = context;
    }

    /// <summary>
    /// Belirtilen sembol için OHLCV (kline) verisini döner.
    /// </summary>
    [HttpGet("klines/{symbol}")]
    public async Task<IActionResult> GetKlines(
        string symbol,
        [FromQuery] string interval = "1h",
        [FromQuery] int limit = 300)
    {
        if (limit > 500) limit = 500;

        var klineInterval = MapInterval(interval);
        var cleanSymbol = symbol.Replace("/", "").Replace("-", "").ToUpperInvariant();

        var result = await _client.SpotApi.ExchangeData.GetKlinesAsync(
            cleanSymbol, klineInterval, limit: limit);

        if (!result.Success)
            return BadRequest(new { error = result.Error?.Message ?? "Veri çekilemedi" });

        var klines = result.Data.Select(k => new
        {
            time = new DateTimeOffset(k.OpenTime).ToUnixTimeSeconds(),
            open = k.OpenPrice,
            high = k.HighPrice,
            low = k.LowPrice,
            close = k.ClosePrice,
            volume = k.Volume
        }).ToList();

        return Ok(klines);
    }

    /// <summary>
    /// OHLCV + Teknik göstergeler (EMA, RSI, MACD, Bollinger)
    /// </summary>
    [HttpGet("klines-with-indicators/{symbol}")]
    public async Task<IActionResult> GetKlinesWithIndicators(
        string symbol,
        [FromQuery] string interval = "1h",
        [FromQuery] int limit = 300)
    {
        if (limit > 500) limit = 500;

        var klineInterval = MapInterval(interval);
        var cleanSymbol = symbol.Replace("/", "").Replace("-", "").ToUpperInvariant();

        var result = await _client.SpotApi.ExchangeData.GetKlinesAsync(
            cleanSymbol, klineInterval, limit: limit);

        if (!result.Success)
            return BadRequest(new { error = result.Error?.Message ?? "Veri çekilemedi" });

        var candles = result.Data.Select(k => new Candle
        {
            OpenTime = k.OpenTime,
            Open = k.OpenPrice,
            High = k.HighPrice,
            Low = k.LowPrice,
            Close = k.ClosePrice,
            Volume = k.Volume
        }).ToList();

        var prices = candles.Select(c => c.Close).ToList();

        // Göstergeleri hesapla
        var ema20 = TechnicalIndicators.CalculateEma(prices, 20);
        var ema50 = TechnicalIndicators.CalculateEma(prices, 50);
        var ema200 = TechnicalIndicators.CalculateEma(prices, 200);
        var rsi = TechnicalIndicators.CalculateRsi(prices, 14);
        var (macdLine, signalLine, histogram) = TechnicalIndicators.CalculateMacd(prices);
        var (upper, middle, lower) = TechnicalIndicators.CalculateBollingerBands(prices, 20, 2);

        var klines = candles.Select((c, i) => new
        {
            time = new DateTimeOffset(c.OpenTime).ToUnixTimeSeconds(),
            open = c.Open,
            high = c.High,
            low = c.Low,
            close = c.Close,
            volume = c.Volume
        }).ToList();

        return Ok(new
        {
            klines,
            indicators = new
            {
                ema20 = ema20.Select((v, i) => new { time = klines[i].time, value = v }).ToList(),
                ema50 = ema50.Select((v, i) => new { time = klines[i].time, value = v }).ToList(),
                ema200 = ema200.Select((v, i) => new { time = klines[i].time, value = v }).ToList(),
                rsi = rsi.Select((v, i) => new { time = klines[i].time, value = v }).ToList(),
                macd = macdLine.Select((v, i) => new
                {
                    time = klines[i].time,
                    macd = v,
                    signal = i < signalLine.Count ? signalLine[i] : (decimal?)null,
                    histogram = i < histogram.Count ? histogram[i] : (decimal?)null
                }).ToList(),
                bollingerUpper = upper.Select((v, i) => new { time = klines[i].time, value = v }).ToList(),
                bollingerMiddle = middle.Select((v, i) => new { time = klines[i].time, value = v }).ToList(),
                bollingerLower = lower.Select((v, i) => new { time = klines[i].time, value = v }).ToList()
            }
        });
    }

    /// <summary>
    /// Bot'un giriş/çıkış marker'larını döner.
    /// </summary>
    [HttpGet("bot-markers/{botId:guid}")]
    public async Task<IActionResult> GetBotMarkers(Guid botId)
    {
        var bot = await _context.Bots.AsNoTracking().FirstOrDefaultAsync(b => b.Id == botId);
        if (bot == null) return NotFound();

        var markers = new List<object>();

        if (bot.EntryPrice > 0 && bot.EntryDate.HasValue)
        {
            markers.Add(new
            {
                time = new DateTimeOffset(bot.EntryDate.Value).ToUnixTimeSeconds(),
                position = "belowBar",
                color = "#10B981",
                shape = "arrowUp",
                text = $"Giriş: {bot.EntryPrice:F2}"
            });
        }

        if (bot.ExitDate.HasValue)
        {
            markers.Add(new
            {
                time = new DateTimeOffset(bot.ExitDate.Value).ToUnixTimeSeconds(),
                position = "aboveBar",
                color = "#EF4444",
                shape = "arrowDown",
                text = $"Çıkış"
            });
        }

        // Trade geçmişinden ek marker'lar
        var trades = await _context.Trades
            .Where(t => t.BotId == botId)
            .OrderBy(t => t.Timestamp)
            .Select(t => new
            {
                t.Timestamp,
                t.Type,
                t.Price,
                t.Quantity
            })
            .ToListAsync();

        foreach (var trade in trades)
        {
            var isBuy = trade.Type == Core.Entities.TradeType.Buy;
            markers.Add(new
            {
                time = new DateTimeOffset(trade.Timestamp).ToUnixTimeSeconds(),
                position = isBuy ? "belowBar" : "aboveBar",
                color = isBuy ? "#10B981" : "#EF4444",
                shape = isBuy ? "arrowUp" : "arrowDown",
                text = $"{(isBuy ? "Al" : "Sat")}: {trade.Price:F2}"
            });
        }

        return Ok(markers);
    }

    private static KlineInterval MapInterval(string interval)
    {
        return interval switch
        {
            "1m" => KlineInterval.OneMinute,
            "3m" => KlineInterval.ThreeMinutes,
            "5m" => KlineInterval.FiveMinutes,
            "15m" => KlineInterval.FifteenMinutes,
            "30m" => KlineInterval.ThirtyMinutes,
            "1h" => KlineInterval.OneHour,
            "2h" => KlineInterval.TwoHour,
            "4h" => KlineInterval.FourHour,
            "6h" => KlineInterval.SixHour,
            "8h" => KlineInterval.EightHour,
            "12h" => KlineInterval.TwelveHour,
            "1d" => KlineInterval.OneDay,
            "1w" => KlineInterval.OneWeek,
            _ => KlineInterval.OneHour
        };
    }
}
