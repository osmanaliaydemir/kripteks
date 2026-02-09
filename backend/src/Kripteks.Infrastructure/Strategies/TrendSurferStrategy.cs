using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Helpers;

namespace Kripteks.Infrastructure.Strategies;

/// <summary>
/// Trend Surfer Strategy - Trend Sörfçüsü
/// Güçlü trendlere sahip coinleri tespit edip trende biner.
/// ADX ile trend gücünü, EMA ile trend yönünü ölçer.
/// </summary>
public class TrendSurferStrategy : IStrategy
{
    public string Id => "strategy-trend-surfer";
    public string Name => "Trend Sörfçüsü";

    public string Description =>
        "ADX (Average Directional Index) ile trend gücünü ölçer, EMA 50/200 ile trend yönünü belirler. Güçlü yükseliş trendindeki coinleri tespit ederek trende binme fırsatı sunar.";

    public StrategyCategory Category => StrategyCategory.Scanner;

    private int _adxPeriod = 14;
    private int _fastEmaPeriod = 50;
    private int _slowEmaPeriod = 200;
    private decimal _strongTrendThreshold = 25m; // ADX > 25 = Strong trend

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters.TryGetValue("AdxPeriod", out var adx)) _adxPeriod = int.Parse(adx);
        if (parameters.TryGetValue("FastEmaPeriod", out var fast)) _fastEmaPeriod = int.Parse(fast);
        if (parameters.TryGetValue("SlowEmaPeriod", out var slow)) _slowEmaPeriod = int.Parse(slow);
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        if (candles.Count < 200) return new StrategyResult { Action = TradeAction.None };

        var score = CalculateSignalScore(candles);
        var lastPrice = candles.Last().Close;

        if (score >= 70)
        {
            return new StrategyResult
            {
                Action = TradeAction.Buy,
                TargetPrice = lastPrice * 1.20m, // %20 hedef (trend devam beklentisiyle)
                StopPrice = lastPrice * 0.92m, // %8 stop (trend kırılırsa)
                Description = "Güçlü yükseliş trendi tespit edildi - Trende binme fırsatı"
            };
        }

        return new StrategyResult { Action = TradeAction.None, Description = "Trend gücü yetersiz" };
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        if (candles.Count < 200) return 0;

        var prices = candles.Select(c => c.Close).ToList();

        // İndikatör Hesaplamaları
        var adxResult = TechnicalIndicators.CalculateAdx(candles, _adxPeriod);
        var emaCross = TechnicalIndicators.DetectEmaCross(prices, _fastEmaPeriod, _slowEmaPeriod);
        var rsiResults = TechnicalIndicators.CalculateRsi(prices, 14);

        var lastAdx = adxResult.Adx.LastOrDefault();
        var lastPlusDi = adxResult.PlusDi.LastOrDefault();
        var lastMinusDi = adxResult.MinusDi.LastOrDefault();
        var lastRsi = rsiResults.LastOrDefault();
        var lastCandle = candles.Last();

        if (lastAdx == null || lastPlusDi == null || lastMinusDi == null) return 0;

        decimal score = 0;
        decimal maxScore = 100;

        // 1. ADX Trend Gücü (Ağırlık: 35)
        // ADX > 25 = Güçlü trend, > 50 = Çok güçlü trend
        if (lastAdx >= 50) score += 35; // Çok güçlü trend
        else if (lastAdx >= 40) score += 30;
        else if (lastAdx >= _strongTrendThreshold) score += 25; // Güçlü trend
        else if (lastAdx >= 20) score += 15; // Orta trend
        else score += 5; // Zayıf trend

        // 2. Trend Yönü (+DI vs -DI) (Ağırlık: 25)
        // +DI > -DI = Yükseliş trendi
        if (lastPlusDi > lastMinusDi)
        {
            decimal diDiff = lastPlusDi.Value - lastMinusDi.Value;
            if (diDiff > 20) score += 25; // Güçlü boğa
            else if (diDiff > 10) score += 20;
            else if (diDiff > 5) score += 15;
            else score += 10;
        }
        // -DI > +DI ise puan verilmez (düşüş trendi)

        // 3. EMA Pozisyonu (50 EMA > 200 EMA = Boğa) (Ağırlık: 20)
        if (emaCross.FastEma != null && emaCross.SlowEma != null)
        {
            if (emaCross.FastEma > emaCross.SlowEma)
            {
                score += 20; // Boğa yapısı
                
                // Bonus: Golden Cross yakın zamanda olduysa
                if (emaCross.IsGoldenCross)
                {
                    score += 5; // Bonus puan
                }
            }
        }

        // 4. Fiyat EMA Üzerinde (Ağırlık: 10)
        if (emaCross.FastEma != null && lastCandle.Close > emaCross.FastEma)
        {
            score += 10; // Fiyat 50 EMA üzerinde
        }

        // 5. RSI Momentum Onayı (Ağırlık: 10)
        // Trend takibi için RSI 50-70 arası ideal
        if (lastRsi != null)
        {
            if (lastRsi >= 50 && lastRsi <= 70) score += 10; // İdeal momentum
            else if (lastRsi > 70 && lastRsi <= 80) score += 5; // Biraz aşırı alım
        }

        return Math.Min(score, maxScore);
    }
}
