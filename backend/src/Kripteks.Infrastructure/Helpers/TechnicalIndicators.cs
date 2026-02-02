using Kripteks.Core.Interfaces;

namespace Kripteks.Infrastructure.Helpers;

public static class TechnicalIndicators
{
    // Simple Moving Average (SMA)
    public static List<decimal?> CalculateSma(List<decimal> prices, int period)
    {
        var result = new List<decimal?>();
        for (int i = 0; i < prices.Count; i++)
        {
            if (i < period - 1)
            {
                result.Add(null);
                continue;
            }

            decimal sum = 0;
            for (int j = 0; j < period; j++)
            {
                sum += prices[i - j];
            }

            result.Add(sum / period);
        }

        return result;
    }

    // Exponential Moving Average (EMA)
    public static List<decimal?> CalculateEma(List<decimal> prices, int period)
    {
        var result = new List<decimal?>();
        decimal multiplier = 2.0m / (period + 1);

        for (int i = 0; i < prices.Count; i++)
        {
            if (i < period - 1)
            {
                result.Add(null);
                continue;
            }

            if (i == period - 1)
            {
                // İlk EMA değeri SMA ile başlar
                decimal sum = 0;
                for (int j = 0; j < period; j++) sum += prices[j];
                result.Add(sum / period);
            }
            else
            {
                // EMA = (Close - PreviousEMA) * Multiplier + PreviousEMA
                decimal? prevEma = result.Last();
                if (prevEma.HasValue)
                {
                    decimal ema = (prices[i] - prevEma.Value) * multiplier + prevEma.Value;
                    result.Add(ema);
                }
                else
                {
                    result.Add(null);
                }
            }
        }

        return result;
    }

    // Basit Swing High/Low Bulucu (Fibonacci için gerekli)
    // Son 'lookback' muma bakarak en yüksek tepeyi ve en düşük dibi bulur
    public static (decimal High, decimal Low) FindRecentSwing(List<Candle> candles, int lookback = 50)
    {
        if (candles.Count < lookback) return (0, 0);

        var snapshot = candles.TakeLast(lookback).ToList();
        decimal high = snapshot.Max(c => c.High);
        decimal low = snapshot.Min(c => c.Low);

        return (high, low);
    }

    // Relative Strength Index (RSI)
    public static List<decimal?> CalculateRsi(List<decimal> prices, int period = 14)
    {
        var result = new List<decimal?>();
        if (prices.Count <= period)
        {
            for (int i = 0; i < prices.Count; i++) result.Add(null);
            return result;
        }

        var gains = new List<decimal>();
        var losses = new List<decimal>();

        for (int i = 1; i < prices.Count; i++)
        {
            decimal diff = prices[i] - prices[i - 1];
            gains.Add(diff > 0 ? diff : 0);
            losses.Add(diff < 0 ? Math.Abs(diff) : 0);
        }

        decimal avgGain = gains.Take(period).Average();
        decimal avgLoss = losses.Take(period).Average();

        for (int i = 0; i <= period; i++) result.Add(null);

        decimal rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
        result.Add(100 - (100 / (1 + rs)));

        for (int i = period + 1; i < gains.Count; i++)
        {
            avgGain = (avgGain * (period - 1) + gains[i]) / period;
            avgLoss = (avgLoss * (period - 1) + losses[i]) / period;

            rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
            result.Add(100 - (100 / (1 + rs)));
        }

        return result;
    }
}
