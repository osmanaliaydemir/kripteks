using Binance.Net.Interfaces.Clients;
using Binance.Net.Interfaces;
using System.Text.Json;
using Kripteks.Core.DTOs;
using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Kripteks.Infrastructure.Helpers;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class AlertService : IAlertService
{
    private readonly AppDbContext _context;
    private readonly IMarketDataService _marketDataService;
    private readonly INotificationService _notificationService;
    private readonly IBinanceRestClient _binanceClient;
    private readonly ILogger<AlertService> _logger;

    public AlertService(
        AppDbContext context,
        IMarketDataService marketDataService,
        INotificationService notificationService,
        IBinanceRestClient binanceClient,
        ILogger<AlertService> logger)
    {
        _context = context;
        _marketDataService = marketDataService;
        _notificationService = notificationService;
        _binanceClient = binanceClient;
        _logger = logger;
    }

    public async Task<List<AlertDto>> GetUserAlertsAsync(Guid userId)
    {
        var userIdStr = userId.ToString();
        return await _context.UserAlerts
            .Where(a => a.UserId == userIdStr)
            .OrderByDescending(a => a.CreatedAt)
            .Select(a => new AlertDto
            {
                Id = a.Id,
                Symbol = a.Symbol,
                Type = a.Type,
                TargetValue = a.TargetValue,
                Condition = a.Condition,
                IndicatorName = a.IndicatorName,
                Timeframe = a.Timeframe,
                IsEnabled = a.IsEnabled,
                LastTriggeredAt = a.LastTriggeredAt,
                CreatedAt = a.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<AlertDto> CreateAlertAsync(Guid userId, CreateAlertDto createDto)
    {
        var alert = new UserAlert
        {
            UserId = userId.ToString(),
            Symbol = createDto.Symbol,
            Type = createDto.Type,
            TargetValue = createDto.TargetValue,
            Condition = createDto.Condition,
            IndicatorName = createDto.IndicatorName,
            Timeframe = createDto.Timeframe,
            Parameters = createDto.Parameters,
            IsEnabled = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.UserAlerts.Add(alert);
        await _context.SaveChangesAsync();

        return new AlertDto
        {
            Id = alert.Id,
            Symbol = alert.Symbol,
            Type = alert.Type,
            TargetValue = alert.TargetValue,
            Condition = alert.Condition,
            IndicatorName = alert.IndicatorName,
            Timeframe = alert.Timeframe,
            Parameters = alert.Parameters,
            IsEnabled = alert.IsEnabled,
            LastTriggeredAt = alert.LastTriggeredAt,
            CreatedAt = alert.CreatedAt
        };
    }

    public async Task<AlertDto?> UpdateAlertAsync(Guid userId, Guid alertId, UpdateAlertDto updateDto)
    {
        var userIdStr = userId.ToString();
        var alert = await _context.UserAlerts
            .FirstOrDefaultAsync(a => a.Id == alertId && a.UserId == userIdStr);

        if (alert == null) return null;

        alert.TargetValue = updateDto.TargetValue;
        alert.IsEnabled = updateDto.IsEnabled;
        alert.CooldownMinutes = updateDto.CooldownMinutes;
        alert.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        // Return updated DTO
        return new AlertDto
        {
            Id = alert.Id,
            Symbol = alert.Symbol,
            Type = alert.Type,
            TargetValue = alert.TargetValue,
            Condition = alert.Condition,
            IndicatorName = alert.IndicatorName,
            Timeframe = alert.Timeframe,
            IsEnabled = alert.IsEnabled,
            LastTriggeredAt = alert.LastTriggeredAt,
            CreatedAt = alert.CreatedAt
        };
    }

    public async Task<bool> DeleteAlertAsync(Guid userId, Guid alertId)
    {
        var userIdStr = userId.ToString();
        var alert = await _context.UserAlerts
            .FirstOrDefaultAsync(a => a.Id == alertId && a.UserId == userIdStr);

        if (alert == null) return false;

        _context.UserAlerts.Remove(alert);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task ProcessAlertsAsync()
    {
        var alerts = await _context.UserAlerts
            .Where(a => a.IsEnabled)
            .ToListAsync();

        if (!alerts.Any()) return;

        var alertsBySymbol = alerts.GroupBy(a => a.Symbol);

        foreach (var group in alertsBySymbol)
        {
            var symbol = group.Key;
            decimal currentPrice = 0;

            try
            {
                currentPrice = await _marketDataService.GetPriceAsync(symbol);
            }
            catch
            {
                continue;
            }

            // Group alerts by timeframe to optimize kline fetching
            var alertsByTimeframe = group
                .Where(a => a.Type == AlertType.Technical || a.Type == AlertType.MarketMovement)
                .GroupBy(a => a.Timeframe ?? "1h");

            var klinesCache = new Dictionary<string, List<IBinanceKline>>();

            foreach (var tfGroup in alertsByTimeframe)
            {
                var interval = GetInterval(tfGroup.Key);
                // Fetch enough candles for indicators (e.g. 200 for EMA200)
                var klines = await _binanceClient.SpotApi.ExchangeData.GetKlinesAsync(symbol, interval, limit: 300);
                if (klines.Success)
                {
                    klinesCache[tfGroup.Key] = klines.Data.Cast<IBinanceKline>().ToList();
                }
            }

            foreach (var alert in group)
            {
                if (alert.LastTriggeredAt.HasValue &&
                    alert.LastTriggeredAt.Value.AddMinutes(alert.CooldownMinutes) > DateTime.UtcNow)
                {
                    continue;
                }

                bool triggered = false;
                string message = "";

                try
                {
                    if (alert.Type == AlertType.Price)
                    {
                        triggered = CheckPriceCondition(currentPrice, alert.TargetValue, alert.Condition);
                        message =
                            $"🔔 Fiyat Alarmı: {alert.Symbol} {currentPrice} seviyesine ulaştı! (Hedef: {alert.TargetValue})";
                    }
                    else if (alert.Type == AlertType.Technical && klinesCache.ContainsKey(alert.Timeframe ?? "1h"))
                    {
                        var klines = klinesCache[alert.Timeframe ?? "1h"];
                        var candles = klines.Select(k => new Kripteks.Core.Interfaces.Candle
                        {
                            OpenTime = k.OpenTime,
                            Open = k.OpenPrice,
                            High = k.HighPrice,
                            Low = k.LowPrice,
                            Close = k.ClosePrice,
                            Volume = k.Volume
                        }).ToList();

                        (triggered, message) = CheckTechnicalCondition(alert, candles);
                    }
                    else if (alert.Type == AlertType.MarketMovement && klinesCache.ContainsKey(alert.Timeframe ?? "1h"))
                    {
                        var klines = klinesCache[alert.Timeframe ?? "1h"];
                        var candles = klines.Select(k => new Kripteks.Core.Interfaces.Candle
                        {
                            OpenTime = k.OpenTime,
                            Open = k.OpenPrice,
                            High = k.HighPrice,
                            Low = k.LowPrice,
                            Close = k.ClosePrice,
                            Volume = k.Volume
                        }).ToList();

                        (triggered, message) = CheckMarketMovementCondition(alert, candles);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error checking alert {AlertId}", alert.Id);
                    continue;
                }

                if (triggered)
                {
                    await _notificationService.SendNotificationAsync(
                        "Kripteks Alarm",
                        message,
                        NotificationType.Info,
                        userId: alert.UserId
                    );

                    alert.LastTriggeredAt = DateTime.UtcNow;
                }
            }
        }

        await _context.SaveChangesAsync();
    }

    private bool CheckPriceCondition(decimal current, decimal target, AlertCondition condition)
    {
        return condition switch
        {
            AlertCondition.Above => current > target,
            AlertCondition.Below => current < target,
            _ => false
        };
    }

    private (bool Triggered, string Message) CheckTechnicalCondition(UserAlert alert,
        List<Kripteks.Core.Interfaces.Candle> candles)
    {
        var prices = candles.Select(c => c.Close).ToList();

        switch (alert.IndicatorName)
        {
            case "RSI":
                var rsiValues = TechnicalIndicators.CalculateRsi(prices, 14); // Default 14
                var lastRsi = rsiValues.LastOrDefault();
                if (lastRsi == null) return (false, "");

                bool rsiTrigger = CheckCondition(lastRsi.Value, alert.TargetValue, alert.Condition);
                return (rsiTrigger,
                    $"🔔 RSI Alarmı: {alert.Symbol} RSI({alert.Timeframe}) {lastRsi.Value:F2} oldu! (Hedef: {alert.Condition} {alert.TargetValue})");

            case "MACD":
                var macdData = TechnicalIndicators.CalculateMacd(prices);
                var lastMacd = macdData.MacdLine.LastOrDefault();
                var lastSignal = macdData.SignalLine.LastOrDefault();

                // Simplified MACD Trigger: MACD Line vs 0 or generic target
                // For proper MACD Cross, we need prev values.
                // Assuming simple alert on MACD value for now or we can implement Cross params.
                if (lastMacd == null) return (false, "");

                // Check if JSON parameters exist for specific Cross logic
                return (false, ""); // Placeholder for advanced logic

            case "EMA_CROSS":
                // Default 50/200 if not specified
                var result = TechnicalIndicators.DetectEmaCross(prices, 50, 200);
                if (alert.Condition == AlertCondition.CrossOver && result.IsGoldenCross)
                    return (true,
                        $"🔔 Golden Cross: {alert.Symbol} ({alert.Timeframe}) EMA 50, EMA 200'ü yukarı kesti!");
                if (alert.Condition == AlertCondition.CrossUnder && result.IsDeathCross)
                    return (true, $"🔔 Death Cross: {alert.Symbol} ({alert.Timeframe}) EMA 50, EMA 200'ü aşağı kesti!");

                return (false, "");

            default:
                return (false, "");
        }
    }

    private (bool Triggered, string Message) CheckMarketMovementCondition(UserAlert alert,
        List<Kripteks.Core.Interfaces.Candle> candles)
    {
        if (candles.Count < 2) return (false, "");
        var lastCandle = candles.Last();

        // Volume Spike
        if (alert.IndicatorName == "VOLUME_SPIKE")
        {
            var volumes = candles.Take(candles.Count - 1).Select(c => c.Volume).ToList();
            if (volumes.Count < 20) return (false, "");

            var avgVolume = volumes.TakeLast(20).Average();
            // TargetValue is percentage (e.g. 200 for 200% increase)
            var threshold = avgVolume * (alert.TargetValue / 100);

            if (lastCandle.Volume > avgVolume + threshold)
            {
                return (true,
                    $"🔔 Hacim Patlaması: {alert.Symbol} ({alert.Timeframe}) hacim ortalamanın %{alert.TargetValue}'i üzerinde!");
            }
        }

        // Price Change (Pump/Dump)
        if (alert.IndicatorName == "PRICE_CHANGE")
        {
            var open = lastCandle.Open;
            var close = lastCandle.Close;
            var changePercent = ((close - open) / open) * 100;

            if (Math.Abs(changePercent) >= alert.TargetValue)
            {
                var direction = changePercent > 0 ? "Yükseliş" : "Düşüş";
                return (true, $"🔔 Ani {direction}: {alert.Symbol} ({alert.Timeframe}) %{changePercent:F2} değişti!");
            }
        }

        return (false, "");
    }

    private bool CheckCondition(decimal current, decimal target, AlertCondition condition)
    {
        return condition switch
        {
            AlertCondition.Above => current > target,
            AlertCondition.Below => current < target,
            _ => false
        };
    }

    private Binance.Net.Enums.KlineInterval GetInterval(string timeframe)
    {
        return timeframe switch
        {
            "15m" => Binance.Net.Enums.KlineInterval.FifteenMinutes,
            "1h" => Binance.Net.Enums.KlineInterval.OneHour,
            "4h" => Binance.Net.Enums.KlineInterval.FourHour,
            "1d" => Binance.Net.Enums.KlineInterval.OneDay,
            _ => Binance.Net.Enums.KlineInterval.OneHour
        };
    }
}
