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

    // Bollinger Bands Calculation
    public static (List<decimal?> Upper, List<decimal?> Middle, List<decimal?> Lower) CalculateBollingerBands(
        List<decimal> prices, int period = 20, decimal stdDevMultiplier = 2)
    {
        var upper = new List<decimal?>();
        var middle = new List<decimal?>();
        var lower = new List<decimal?>();

        var smaList = CalculateSma(prices, period);

        for (int i = 0; i < prices.Count; i++)
        {
            if (smaList[i] == null)
            {
                upper.Add(null);
                middle.Add(null);
                lower.Add(null);
                continue;
            }

            decimal sma = smaList[i].Value;
            middle.Add(sma);

            // Calculate Standard Deviation for the period
            var periodPrices = prices.Skip(i - period + 1).Take(period).ToList();
            decimal avg = periodPrices.Average();
            decimal sumSqDiff = periodPrices.Sum(p => (p - avg) * (p - avg));
            decimal stdDev = (decimal)Math.Sqrt((double)(sumSqDiff / period));

            upper.Add(sma + (stdDev * stdDevMultiplier));
            lower.Add(sma - (stdDev * stdDevMultiplier));
        }

        return (upper, middle, lower);
    }

    // MACD Calculation (12, 26, 9 default)
    public static (List<decimal?> MacdLine, List<decimal?> SignalLine, List<decimal?> Histogram) CalculateMacd(
        List<decimal> prices, int fastPeriod = 12, int slowPeriod = 26, int signalPeriod = 9)
    {
        var fastEma = CalculateEma(prices, fastPeriod);
        var slowEma = CalculateEma(prices, slowPeriod);

        var macdLine = new List<decimal?>();
        var signalLine = new List<decimal?>(); // Signal Line is EMA of MACD Line
        var histogram = new List<decimal?>();

        var validMacdValues = new List<decimal>(); // For calculating Signal Line

        for (int i = 0; i < prices.Count; i++)
        {
            if (fastEma[i] == null || slowEma[i] == null)
            {
                macdLine.Add(null);
                signalLine.Add(null);
                histogram.Add(null);
                continue;
            }

            decimal macd = fastEma[i].Value - slowEma[i].Value;
            macdLine.Add(macd);
            validMacdValues.Add(macd);
        }

        // Calculate Signal Line (EMA of MACD Line)
        // Note: The loop indices need to align correctly with the original prices list
        var signalEmaValues = CalculateEma(validMacdValues, signalPeriod);

        // Pad the beginning of Signal Line to match MACD Line length
        // Signal EMA calculation starts after validMacdValues has enough data
        int macdStartIndex = macdLine.IndexOf(macdLine.First(x => x != null));

        // Re-align signal line results to the original array
        int signalIndex = 0;
        for (int i = 0; i < macdLine.Count; i++)
        {
            if (i < macdStartIndex)
            {
                // Already handled by nulls in macdLine loop? No, signalLine needs padding
                // Actually the previous loop added nulls to macdLine, signalLine is empty
            }
        }

        // Easier approach: Calculate Signal Line from valid values, then prepend nulls based on offset
        // Offset is where validMacdValues started relative to prices

        var alignedSignalLine = new List<decimal?>(new decimal?[macdStartIndex]);
        alignedSignalLine.AddRange(signalEmaValues);

        // Fill remaining potentially if signalEmaValues is shorter than remaining
        while (alignedSignalLine.Count < prices.Count) alignedSignalLine.Add(null);

        // Let's rewrite strictly:
        // We have macdLine with nulls at start.
        // We need signalLine to be calculated on the non-null part of macdLine.

        // Clear and rebuild correctly
        macdLine.Clear();
        signalLine.Clear();
        histogram.Clear();

        // Re-calculate simply
        var tempFast = CalculateEma(prices, fastPeriod);
        var tempSlow = CalculateEma(prices, slowPeriod);

        var tempMacdValues = new List<decimal>();
        var tempMacdIndices = new List<int>();

        for (int i = 0; i < prices.Count; i++)
        {
            if (tempFast[i].HasValue && tempSlow[i].HasValue)
            {
                decimal val = tempFast[i].Value - tempSlow[i].Value;
                macdLine.Add(val);
                tempMacdValues.Add(val);
                tempMacdIndices.Add(i);
            }
            else
            {
                macdLine.Add(null);
            }
        }

        var tempSignal = CalculateEma(tempMacdValues, signalPeriod);

        // Now map tempSignal back to full list
        // tempSignal[0] corresponds to tempMacdValues[0] which is at price index tempMacdIndices[0]
        // But EMA calculation itself introduces nulls at the start of its input list!
        // So tempSignal[k] corresponds to tempMacdValues[k]

        int signalCounter = 0;
        for (int i = 0; i < prices.Count; i++)
        {
            if (macdLine[i] == null)
            {
                signalLine.Add(null);
                histogram.Add(null);
            }
            else
            {
                // We are in the valid MACD zone
                if (signalCounter < tempSignal.Count)
                {
                    var sigVal = tempSignal[signalCounter];
                    signalLine.Add(sigVal);
                    if (sigVal.HasValue)
                        histogram.Add(macdLine[i] - sigVal);
                    else
                        histogram.Add(null);

                    signalCounter++;
                }
                else
                {
                    signalLine.Add(null);
                    histogram.Add(null);
                }
            }
        }

        return (macdLine, signalLine, histogram);
    }
}
