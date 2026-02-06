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

    // On Balance Volume (OBV) - Detects accumulation/distribution
    public static List<decimal> CalculateObv(List<Candle> candles)
    {
        var result = new List<decimal>();
        if (candles.Count == 0) return result;

        decimal obv = 0;
        result.Add(obv);

        for (int i = 1; i < candles.Count; i++)
        {
            if (candles[i].Close > candles[i - 1].Close)
            {
                obv += candles[i].Volume;
            }
            else if (candles[i].Close < candles[i - 1].Close)
            {
                obv -= candles[i].Volume;
            }

            // If close == previous close, OBV stays the same
            result.Add(obv);
        }

        return result;
    }

    // Bollinger Bandwidth - Measures band width for squeeze detection
    public static List<decimal?> CalculateBollingerBandwidth(List<decimal> prices, int period = 20,
        decimal stdDevMultiplier = 2)
    {
        var result = new List<decimal?>();
        var (upper, middle, lower) = CalculateBollingerBands(prices, period, stdDevMultiplier);

        for (int i = 0; i < prices.Count; i++)
        {
            if (upper[i] == null || middle[i] == null || lower[i] == null || middle[i] == 0)
            {
                result.Add(null);
                continue;
            }

            // Bandwidth = (Upper - Lower) / Middle * 100
            decimal bandwidth = ((upper[i].Value - lower[i].Value) / middle[i].Value) * 100;
            result.Add(bandwidth);
        }

        return result;
    }

    // OBV Moving Average - For trend detection on OBV
    public static List<decimal?> CalculateObvSma(List<Candle> candles, int period = 20)
    {
        var obvValues = CalculateObv(candles);
        return CalculateSma(obvValues, period);
    }

    // Stochastic RSI - More sensitive oversold/overbought indicator
    public static (List<decimal?> K, List<decimal?> D) CalculateStochasticRsi(
        List<decimal> prices, int rsiPeriod = 14, int stochPeriod = 14, int smoothK = 3, int smoothD = 3)
    {
        var rsiValues = CalculateRsi(prices, rsiPeriod);
        var kValues = new List<decimal?>();
        var dValues = new List<decimal?>();

        // Calculate Stochastic of RSI
        for (int i = 0; i < rsiValues.Count; i++)
        {
            if (i < stochPeriod - 1 || rsiValues[i] == null)
            {
                kValues.Add(null);
                continue;
            }

            // Get last stochPeriod RSI values
            var periodRsi = rsiValues.Skip(i - stochPeriod + 1).Take(stochPeriod)
                .Where(r => r.HasValue).Select(r => r!.Value).ToList();

            if (periodRsi.Count < stochPeriod)
            {
                kValues.Add(null);
                continue;
            }

            decimal highestRsi = periodRsi.Max();
            decimal lowestRsi = periodRsi.Min();
            decimal currentRsi = rsiValues[i]!.Value;

            if (highestRsi == lowestRsi)
            {
                kValues.Add(50); // Neutral
            }
            else
            {
                decimal stochRsi = ((currentRsi - lowestRsi) / (highestRsi - lowestRsi)) * 100;
                kValues.Add(stochRsi);
            }
        }

        // Smooth K values with SMA
        var validK = kValues.Where(k => k.HasValue).Select(k => k!.Value).ToList();
        var smoothedK = CalculateSma(validK, smoothK);

        // Align smoothed K back to original length
        var alignedK = new List<decimal?>();
        int kIndex = 0;
        for (int i = 0; i < kValues.Count; i++)
        {
            if (kValues[i] == null)
            {
                alignedK.Add(null);
            }
            else
            {
                alignedK.Add(kIndex < smoothedK.Count ? smoothedK[kIndex] : null);
                kIndex++;
            }
        }

        // Calculate D (SMA of K)
        var validAlignedK = alignedK.Where(k => k.HasValue).Select(k => k!.Value).ToList();
        var dSma = CalculateSma(validAlignedK, smoothD);

        int dIndex = 0;
        for (int i = 0; i < alignedK.Count; i++)
        {
            if (alignedK[i] == null)
            {
                dValues.Add(null);
            }
            else
            {
                dValues.Add(dIndex < dSma.Count ? dSma[dIndex] : null);
                dIndex++;
            }
        }

        return (alignedK, dValues);
    }

    // Support Level - Finds recent support based on lowest lows
    public static decimal? CalculateSupportLevel(List<Candle> candles, int lookback = 20)
    {
        if (candles.Count < lookback) return null;

        var recentCandles = candles.TakeLast(lookback).ToList();
        return recentCandles.Min(c => c.Low);
    }

    // RSI Divergence Detection (Bullish: Price makes lower low, RSI makes higher low)
    public static bool DetectBullishDivergence(List<Candle> candles, List<decimal?> rsiValues, int lookback = 10)
    {
        if (candles.Count < lookback || rsiValues.Count < lookback) return false;

        var recentCandles = candles.TakeLast(lookback).ToList();
        var recentRsi = rsiValues.TakeLast(lookback).Where(r => r.HasValue).Select(r => r!.Value).ToList();

        if (recentRsi.Count < 5) return false;

        // Find price lows
        int priceLow1Idx = 0;
        int priceLow2Idx = recentCandles.Count / 2;

        decimal priceLow1 = recentCandles.Take(recentCandles.Count / 2).Min(c => c.Low);
        decimal priceLow2 = recentCandles.Skip(recentCandles.Count / 2).Min(c => c.Low);

        decimal rsiLow1 = recentRsi.Take(recentRsi.Count / 2).Min();
        decimal rsiLow2 = recentRsi.Skip(recentRsi.Count / 2).Min();

        // Bullish divergence: Price makes lower low, RSI makes higher low
        return priceLow2 < priceLow1 && rsiLow2 > rsiLow1;
    }

    // ATR (Average True Range) - Volatility indicator
    public static List<decimal?> CalculateAtr(List<Candle> candles, int period = 14)
    {
        var result = new List<decimal?>();
        if (candles.Count < 2) return result;

        var trueRanges = new List<decimal>();

        for (int i = 0; i < candles.Count; i++)
        {
            if (i == 0)
            {
                // First candle: TR = High - Low
                trueRanges.Add(candles[i].High - candles[i].Low);
            }
            else
            {
                // TR = Max(High - Low, |High - PrevClose|, |Low - PrevClose|)
                decimal highLow = candles[i].High - candles[i].Low;
                decimal highPrevClose = Math.Abs(candles[i].High - candles[i - 1].Close);
                decimal lowPrevClose = Math.Abs(candles[i].Low - candles[i - 1].Close);
                trueRanges.Add(Math.Max(highLow, Math.Max(highPrevClose, lowPrevClose)));
            }
        }

        // Calculate ATR as SMA of True Range
        for (int i = 0; i < trueRanges.Count; i++)
        {
            if (i < period - 1)
            {
                result.Add(null);
                continue;
            }

            decimal sum = 0;
            for (int j = 0; j < period; j++)
            {
                sum += trueRanges[i - j];
            }

            result.Add(sum / period);
        }

        return result;
    }

    // ADX (Average Directional Index) - Trend strength indicator
    public static (List<decimal?> Adx, List<decimal?> PlusDi, List<decimal?> MinusDi) CalculateAdx(
        List<Candle> candles, int period = 14)
    {
        var adxList = new List<decimal?>();
        var plusDiList = new List<decimal?>();
        var minusDiList = new List<decimal?>();

        if (candles.Count < period + 1)
        {
            for (int i = 0; i < candles.Count; i++)
            {
                adxList.Add(null);
                plusDiList.Add(null);
                minusDiList.Add(null);
            }

            return (adxList, plusDiList, minusDiList);
        }

        var plusDm = new List<decimal>();
        var minusDm = new List<decimal>();
        var tr = new List<decimal>();

        // Calculate +DM, -DM, and TR
        for (int i = 1; i < candles.Count; i++)
        {
            decimal upMove = candles[i].High - candles[i - 1].High;
            decimal downMove = candles[i - 1].Low - candles[i].Low;

            plusDm.Add(upMove > downMove && upMove > 0 ? upMove : 0);
            minusDm.Add(downMove > upMove && downMove > 0 ? downMove : 0);

            decimal highLow = candles[i].High - candles[i].Low;
            decimal highPrevClose = Math.Abs(candles[i].High - candles[i - 1].Close);
            decimal lowPrevClose = Math.Abs(candles[i].Low - candles[i - 1].Close);
            tr.Add(Math.Max(highLow, Math.Max(highPrevClose, lowPrevClose)));
        }

        // First value is null (no previous candle)
        adxList.Add(null);
        plusDiList.Add(null);
        minusDiList.Add(null);

        // Calculate smoothed values
        decimal smoothedPlusDm = plusDm.Take(period).Sum();
        decimal smoothedMinusDm = minusDm.Take(period).Sum();
        decimal smoothedTr = tr.Take(period).Sum();

        var dxList = new List<decimal>();

        for (int i = period - 1; i < plusDm.Count; i++)
        {
            if (i == period - 1)
            {
                // Initial values
            }
            else
            {
                smoothedPlusDm = smoothedPlusDm - (smoothedPlusDm / period) + plusDm[i];
                smoothedMinusDm = smoothedMinusDm - (smoothedMinusDm / period) + minusDm[i];
                smoothedTr = smoothedTr - (smoothedTr / period) + tr[i];
            }

            decimal plusDi = smoothedTr > 0 ? (smoothedPlusDm / smoothedTr) * 100 : 0;
            decimal minusDi = smoothedTr > 0 ? (smoothedMinusDm / smoothedTr) * 100 : 0;

            plusDiList.Add(plusDi);
            minusDiList.Add(minusDi);

            decimal diSum = plusDi + minusDi;
            decimal dx = diSum > 0 ? (Math.Abs(plusDi - minusDi) / diSum) * 100 : 0;
            dxList.Add(dx);

            // ADX is smoothed average of DX
            if (dxList.Count >= period)
            {
                decimal adx = dxList.TakeLast(period).Average();
                adxList.Add(adx);
            }
            else
            {
                adxList.Add(null);
            }
        }

        // Pad beginning with nulls
        while (plusDiList.Count < candles.Count) plusDiList.Insert(0, null);
        while (minusDiList.Count < candles.Count) minusDiList.Insert(0, null);
        while (adxList.Count < candles.Count) adxList.Insert(0, null);

        return (adxList, plusDiList, minusDiList);
    }

    // EMA Cross Detection - Detects Golden Cross (bullish) or Death Cross (bearish)
    public static (bool IsGoldenCross, bool IsDeathCross, decimal? FastEma, decimal? SlowEma) DetectEmaCross(
        List<decimal> prices, int fastPeriod = 50, int slowPeriod = 200)
    {
        var fastEma = CalculateEma(prices, fastPeriod);
        var slowEma = CalculateEma(prices, slowPeriod);

        var lastFast = fastEma.LastOrDefault();
        var lastSlow = slowEma.LastOrDefault();
        var prevFast = fastEma.Count >= 2 ? fastEma[fastEma.Count - 2] : null;
        var prevSlow = slowEma.Count >= 2 ? slowEma[slowEma.Count - 2] : null;

        if (lastFast == null || lastSlow == null || prevFast == null || prevSlow == null)
            return (false, false, lastFast, lastSlow);

        // Golden Cross: Fast crosses above Slow
        bool isGoldenCross = prevFast < prevSlow && lastFast > lastSlow;

        // Death Cross: Fast crosses below Slow
        bool isDeathCross = prevFast > prevSlow && lastFast < lastSlow;

        return (isGoldenCross, isDeathCross, lastFast, lastSlow);
    }
}
