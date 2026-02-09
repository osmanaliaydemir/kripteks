using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Helpers;

namespace Kripteks.Infrastructure.Strategies;

/// <summary>
/// Whale Accumulation Strategy - Balina Biriktirme Stratejisi
/// Büyük yatırımcıların sessizce birikim yaptığı coinleri tespit eder.
/// Düşük volatilite (Bollinger sıkışması) + Artan OBV = Birikim sinyali
/// </summary>
public class WhaleAccumulationStrategy : IStrategy
{
    public string Id => "strategy-whale-accumulation";
    public string Name => "Balina Biriktirmesi";

    public string Description =>
        "Düşük volatilite dönemlerinde (Bollinger sıkışması) OBV'nin yükseliş trendinde olduğu coinleri tespit eder. Büyük yatırımcıların sessizce birikim yaptığı potansiyel kırılım adaylarını yakalar.";

    public StrategyCategory Category => StrategyCategory.Scanner;

    private int _obvSmaPeriod = 20;
    private int _bbPeriod = 20;
    private decimal _bbStdDev = 2;
    private decimal _squeezeThreshold = 5m; // Bandwidth % threshold for squeeze

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters.TryGetValue("ObvSmaPeriod", out var obv)) _obvSmaPeriod = int.Parse(obv);
        if (parameters.TryGetValue("BbPeriod", out var bb)) _bbPeriod = int.Parse(bb);
        if (parameters.TryGetValue("SqueezeThreshold", out var sq)) _squeezeThreshold = decimal.Parse(sq);
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        if (candles.Count < 50) return new StrategyResult { Action = TradeAction.None };

        var score = CalculateSignalScore(candles);
        var lastPrice = candles.Last().Close;

        if (score >= 75)
        {
            return new StrategyResult
            {
                Action = TradeAction.Buy,
                TargetPrice = lastPrice * 1.15m, // %15 hedef (sıkışmadan sonra güçlü hareket beklentisi)
                StopPrice = lastPrice * 0.93m, // %7 stop
                Description = "Balina biriktirme tespit edildi - Kırılım bekleniyor"
            };
        }

        return new StrategyResult { Action = TradeAction.None, Description = "Birikim sinyali yetersiz" };
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        if (candles.Count < 50) return 0;

        var prices = candles.Select(c => c.Close).ToList();

        // 1. OBV Hesaplama
        var obvValues = TechnicalIndicators.CalculateObv(candles);
        var obvSma = TechnicalIndicators.CalculateSma(obvValues, _obvSmaPeriod);

        // 2. Bollinger Bandwidth (Sıkışma Tespiti)
        var bandwidth = TechnicalIndicators.CalculateBollingerBandwidth(prices, _bbPeriod, _bbStdDev);

        // 3. Volume Trend (Hacim ortalaması)
        var volumes = candles.Select(c => c.Volume).ToList();
        var volSma = TechnicalIndicators.CalculateSma(volumes, _obvSmaPeriod);

        // Son değerler
        var lastObv = obvValues.LastOrDefault();
        var lastObvSma = obvSma.LastOrDefault();
        var lastBandwidth = bandwidth.LastOrDefault();
        var lastVolSma = volSma.LastOrDefault();
        var lastCandle = candles.Last();

        // OBV trendini kontrol et (son 5 değerin ortalaması vs önceki 5)
        decimal obvTrend = 0;
        if (obvValues.Count >= 10)
        {
            var recentAvg = obvValues.TakeLast(5).Average();
            var prevAvg = obvValues.Skip(obvValues.Count - 10).Take(5).Average();
            obvTrend = prevAvg != 0 ? ((recentAvg - prevAvg) / Math.Abs(prevAvg)) * 100 : 0;
        }

        if (lastObvSma == null || lastBandwidth == null || lastVolSma == null) return 0;

        decimal score = 0;
        decimal maxScore = 100;

        // 1. Bollinger Squeeze (Düşük Volatilite) - Ağırlık: 35
        // Bandwidth ne kadar düşükse o kadar iyi (sıkışma)
        if (lastBandwidth < 3m) score += 35; // Çok sıkı squeeze
        else if (lastBandwidth < _squeezeThreshold) score += 30;
        else if (lastBandwidth < 7m) score += 20;
        else if (lastBandwidth < 10m) score += 10;

        // 2. OBV Trend (Birikim Göstergesi) - Ağırlık: 35
        // OBV yükseliyorsa = Birikim var
        if (lastObv > lastObvSma.Value)
        {
            if (obvTrend > 5) score += 35; // Güçlü birikim trendi
            else if (obvTrend > 2) score += 28;
            else if (obvTrend > 0) score += 20;
            else score += 10; // OBV > SMA ama trend zayıf
        }

        // 3. Fiyat Konsolidasyonu (Son 10 mumun range'i dar olmalı) - Ağırlık: 15
        var last10 = candles.TakeLast(10).ToList();
        var rangeHigh = last10.Max(c => c.High);
        var rangeLow = last10.Min(c => c.Low);
        var rangePercent = rangeLow > 0 ? ((rangeHigh - rangeLow) / rangeLow) * 100 : 100;

        if (rangePercent < 3) score += 15; // Çok dar range
        else if (rangePercent < 5) score += 12;
        else if (rangePercent < 8) score += 8;

        // 4. Hacim Durgunluğu (Düşük hacim = Sessiz birikim) - Ağırlık: 15
        // Çok yüksek hacim değil, ortalamanın biraz altı veya ortalaması
        if (lastVolSma > 0)
        {
            decimal volRatio = lastCandle.Volume / lastVolSma.Value;
            if (volRatio >= 0.6m && volRatio <= 1.2m) score += 15; // Normal/düşük hacim (ideal)
            else if (volRatio > 1.2m && volRatio <= 1.5m) score += 10; // Hafif yüksek
            else if (volRatio < 0.6m) score += 8; // Çok düşük
            // Çok yüksek hacim = Zaten hareket başlamış olabilir, düşük puan
        }

        return Math.Min(score, maxScore);
    }
}
