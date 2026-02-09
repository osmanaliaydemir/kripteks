using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Helpers;

namespace Kripteks.Infrastructure.Strategies;

/// <summary>
/// Divergence Detector Strategy - Uyumsuzluk Tespit
/// Fiyat ve indikatörler arasındaki uyumsuzlukları tespit ederek trend dönüşlerini yakalar.
/// Bullish divergence = Dip alma fırsatı
/// </summary>
public class DivergenceDetectorStrategy : IStrategy
{
    public string Id => "strategy-divergence-detector";
    public string Name => "Uyumsuzluk Dedektörü";

    public string Description =>
        "Fiyat ve RSI/MACD arasındaki uyumsuzlukları tespit eder. Fiyat düşerken RSI yükseliyorsa (bullish divergence) trend dönüşü sinyali verir. Erken giriş fırsatları sunar.";

    public StrategyCategory Category => StrategyCategory.Scanner;

    private int _rsiPeriod = 14;
    private int _divergenceLookback = 20;

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters.TryGetValue("RsiPeriod", out var rsi)) _rsiPeriod = int.Parse(rsi);
        if (parameters.TryGetValue("DivergenceLookback", out var lb)) _divergenceLookback = int.Parse(lb);
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        if (candles.Count < 50) return new StrategyResult { Action = TradeAction.None };

        var score = CalculateSignalScore(candles);
        var lastPrice = candles.Last().Close;

        if (score >= 70)
        {
            return new StrategyResult
            {
                Action = TradeAction.Buy,
                TargetPrice = lastPrice * 1.12m, // %12 hedef
                StopPrice = lastPrice * 0.95m, // %5 stop
                Description = "Bullish divergence tespit edildi - Trend dönüşü sinyali"
            };
        }

        return new StrategyResult { Action = TradeAction.None, Description = "Divergence sinyali yok" };
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        if (candles.Count < 50) return 0;

        var prices = candles.Select(c => c.Close).ToList();
        var volumes = candles.Select(c => c.Volume).ToList();

        // İndikatör Hesaplamaları
        var rsiResults = TechnicalIndicators.CalculateRsi(prices, _rsiPeriod);
        var macdResult = TechnicalIndicators.CalculateMacd(prices);
        var volSma = TechnicalIndicators.CalculateSma(volumes, 20);

        var lastRsi = rsiResults.LastOrDefault();
        var lastMacdHist = macdResult.Histogram.LastOrDefault();
        var lastVolSma = volSma.LastOrDefault();
        var lastCandle = candles.Last();

        if (lastRsi == null) return 0;

        decimal score = 0;
        decimal maxScore = 100;

        // 1. RSI Bullish Divergence (Ağırlık: 35)
        if (DetectRsiBullishDivergence(candles, rsiResults, _divergenceLookback))
        {
            score += 35;
        }
        else if (DetectRsiHiddenBullishDivergence(candles, rsiResults, _divergenceLookback))
        {
            score += 25; // Hidden divergence daha az güçlü
        }

        // 2. MACD Bullish Divergence (Ağırlık: 25)
        if (DetectMacdBullishDivergence(candles, macdResult.Histogram, _divergenceLookback))
        {
            score += 25;
        }

        // 3. RSI Oversold Bölgesinden Çıkış (Ağırlık: 20)
        // Divergence + Oversold = Güçlü sinyal
        if (lastRsi <= 40)
        {
            if (lastRsi <= 30) score += 20; // Aşırı satım bölgesinde
            else score += 15; // Yaklaşıyor
        }

        // 4. Hacim Onayı (Ağırlık: 10)
        if (lastVolSma != null && lastVolSma > 0)
        {
            decimal volRatio = lastCandle.Volume / lastVolSma.Value;
            if (volRatio >= 1.3m) score += 10;
            else if (volRatio >= 1.0m) score += 5;
        }

        // 5. MACD Histogram Pozitif Dönüş (Ağırlık: 10)
        if (macdResult.Histogram.Count >= 2)
        {
            var prevHist = macdResult.Histogram[macdResult.Histogram.Count - 2];
            if (prevHist != null && lastMacdHist != null)
            {
                if (prevHist < 0 && lastMacdHist > prevHist)
                {
                    score += 10; // Negatiften yükseliyor
                }
            }
        }

        return Math.Min(score, maxScore);
    }

    // RSI Bullish Divergence: Fiyat düşük yapar, RSI yükselir
    private bool DetectRsiBullishDivergence(List<Candle> candles, List<decimal?> rsiValues, int lookback)
    {
        if (candles.Count < lookback || rsiValues.Count < lookback) return false;

        var recentCandles = candles.TakeLast(lookback).ToList();
        var recentRsi = rsiValues.TakeLast(lookback).Where(r => r.HasValue).Select(r => r!.Value).ToList();

        if (recentRsi.Count < 5) return false;

        // İlk yarı ve ikinci yarıdaki dipleri karşılaştır
        int halfPoint = recentCandles.Count / 2;

        decimal priceLow1 = recentCandles.Take(halfPoint).Min(c => c.Low);
        decimal priceLow2 = recentCandles.Skip(halfPoint).Min(c => c.Low);

        decimal rsiLow1 = recentRsi.Take(halfPoint).Min();
        decimal rsiLow2 = recentRsi.Skip(halfPoint).Min();

        // Bullish divergence: Fiyat düşük yapar, RSI yüksek yapar
        return priceLow2 < priceLow1 && rsiLow2 > rsiLow1;
    }

    // Hidden Bullish Divergence: Fiyat yüksek yapar, RSI düşük yapar (trend devam sinyali)
    private bool DetectRsiHiddenBullishDivergence(List<Candle> candles, List<decimal?> rsiValues, int lookback)
    {
        if (candles.Count < lookback || rsiValues.Count < lookback) return false;

        var recentCandles = candles.TakeLast(lookback).ToList();
        var recentRsi = rsiValues.TakeLast(lookback).Where(r => r.HasValue).Select(r => r!.Value).ToList();

        if (recentRsi.Count < 5) return false;

        int halfPoint = recentCandles.Count / 2;

        decimal priceLow1 = recentCandles.Take(halfPoint).Min(c => c.Low);
        decimal priceLow2 = recentCandles.Skip(halfPoint).Min(c => c.Low);

        decimal rsiLow1 = recentRsi.Take(halfPoint).Min();
        decimal rsiLow2 = recentRsi.Skip(halfPoint).Min();

        // Hidden bullish: Fiyat yüksek dip yapar, RSI düşük dip yapar
        return priceLow2 > priceLow1 && rsiLow2 < rsiLow1;
    }

    // MACD Bullish Divergence
    private bool DetectMacdBullishDivergence(List<Candle> candles, List<decimal?> macdHist, int lookback)
    {
        if (candles.Count < lookback || macdHist.Count < lookback) return false;

        var recentCandles = candles.TakeLast(lookback).ToList();
        var recentMacd = macdHist.TakeLast(lookback).Where(m => m.HasValue).Select(m => m!.Value).ToList();

        if (recentMacd.Count < 5) return false;

        int halfPoint = recentCandles.Count / 2;

        decimal priceLow1 = recentCandles.Take(halfPoint).Min(c => c.Low);
        decimal priceLow2 = recentCandles.Skip(halfPoint).Min(c => c.Low);

        decimal macdLow1 = recentMacd.Take(halfPoint).Min();
        decimal macdLow2 = recentMacd.Skip(halfPoint).Min();

        return priceLow2 < priceLow1 && macdLow2 > macdLow1;
    }
}
