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
}
