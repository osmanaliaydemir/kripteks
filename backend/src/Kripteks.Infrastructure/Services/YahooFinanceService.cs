using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using Kripteks.Core.Interfaces;
using Kripteks.Core.Models.Strategy;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class YahooFinanceService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<YahooFinanceService> _logger;

    public YahooFinanceService(HttpClient httpClient, ILogger<YahooFinanceService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _httpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0");
    }

    public async Task<List<Candle>> GetKlinesAsync(string symbol, string interval)
    {
        try
        {
            // Yahoo Finance interval mapping
            var yahooInterval = interval switch
            {
                "15m" => "15m",
                "1h" => "1h",
                "4h" => "1h", // Aggregate later
                "1d" => "1d",
                _ => "1h"
            };

            // Range should be long enough for the strategy (SMA 111 needs > 111 candles)
            var range = interval == "1d" ? "1y" : "60d";

            var url =
                $"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?interval={yahooInterval}&range={range}";
            var response = await _httpClient.GetAsync(url);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Yahoo Finance API error for {Symbol}: {Status}", symbol, response.StatusCode);
                return new List<Candle>();
            }

            var content = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(content);

            if (!doc.RootElement.TryGetProperty("chart", out var chart) ||
                !chart.TryGetProperty("result", out var results) ||
                results.ValueKind == JsonValueKind.Null ||
                results.GetArrayLength() == 0)
            {
                return new List<Candle>();
            }

            var result = results[0];

            if (!result.TryGetProperty("timestamp", out var timestampProp))
                return new List<Candle>();

            var timestamps = timestampProp.EnumerateArray().Select(x => x.GetInt64()).ToList();
            var indicators = result.GetProperty("indicators").GetProperty("quote")[0];

            var opens = indicators.GetProperty("open").EnumerateArray()
                .Select(x => x.ValueKind == JsonValueKind.Null ? 0m : x.GetDecimal()).ToList();
            var highs = indicators.GetProperty("high").EnumerateArray()
                .Select(x => x.ValueKind == JsonValueKind.Null ? 0m : x.GetDecimal()).ToList();
            var lows = indicators.GetProperty("low").EnumerateArray()
                .Select(x => x.ValueKind == JsonValueKind.Null ? 0m : x.GetDecimal()).ToList();
            var closes = indicators.GetProperty("close").EnumerateArray()
                .Select(x => x.ValueKind == JsonValueKind.Null ? 0m : x.GetDecimal()).ToList();

            List<decimal> volumes;
            if (indicators.TryGetProperty("volume", out var volProp))
                volumes = volProp.EnumerateArray().Select(x => x.ValueKind == JsonValueKind.Null ? 0m : x.GetDecimal())
                    .ToList();
            else
                volumes = Enumerable.Repeat(0m, timestamps.Count).ToList();

            var candles = new List<Candle>();
            for (int i = 0; i < timestamps.Count; i++)
            {
                if (i >= opens.Count || i >= closes.Count) break;
                if (opens[i] == 0 || closes[i] == 0) continue;

                candles.Add(new Candle
                {
                    OpenTime = DateTimeOffset.FromUnixTimeSeconds(timestamps[i]).UtcDateTime,
                    Open = opens[i],
                    High = highs[i],
                    Low = lows[i],
                    Close = closes[i],
                    Volume = volumes[i]
                });
            }

            if (interval == "4h")
            {
                return AggregateCandles(candles, 4);
            }

            return candles;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching Yahoo Finance data for {Symbol}", symbol);
            return new List<Candle>();
        }
    }

    private List<Candle> AggregateCandles(List<Candle> candles, int chunk)
    {
        var aggregated = new List<Candle>();
        for (int i = 0; i < candles.Count; i += chunk)
        {
            var subset = candles.Skip(i).Take(chunk).ToList();
            if (!subset.Any()) break;

            aggregated.Add(new Candle
            {
                OpenTime = subset.First().OpenTime,
                Open = subset.First().Open,
                High = subset.Max(x => x.High),
                Low = subset.Min(x => x.Low),
                Close = subset.Last().Close,
                Volume = subset.Sum(x => x.Volume)
            });
        }

        return aggregated;
    }
}
