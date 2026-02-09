using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Helpers;

namespace Kripteks.Infrastructure.Strategies;

/// <summary>
/// Breakout Hunter Strategy - Kırılım Avcısı
/// Konsolidasyon bölgelerinden çıkış yapan coinleri yakalamak.
/// Volatilite sıkışmasından sonra hacim destekli patlama bekler.
/// </summary>
public class BreakoutHunterStrategy : IStrategy
{
    public string Id => "strategy-breakout-hunter";
    public string Name => "Kırılım Avcısı";

    public string Description =>
        "Bollinger Band sıkışması (düşük bandwidth) ve ATR daralması ile konsolidasyon tespit eder. Hacim patlamasıyla birlikte üst bandı kıran coinleri yakalar.";

    public StrategyCategory Category => StrategyCategory.Scanner;

    private int _bbPeriod = 20;
    private decimal _bbStdDev = 2;
    private int _atrPeriod = 14;
    private int _volumeSmaPeriod = 20;

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters.TryGetValue("BbPeriod", out var bb)) _bbPeriod = int.Parse(bb);
        if (parameters.TryGetValue("AtrPeriod", out var atr)) _atrPeriod = int.Parse(atr);
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
                TargetPrice = lastPrice * 1.15m, // %15 hedef (breakout momentum)
                StopPrice = lastPrice * 0.94m, // %6 stop (false breakout koruması)
                Description = "Konsolidasyondan kırılım tespit edildi - Breakout fırsatı"
            };
        }

        return new StrategyResult { Action = TradeAction.None, Description = "Kırılım sinyali yok" };
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        if (candles.Count < 50) return 0;

        var prices = candles.Select(c => c.Close).ToList();
        var volumes = candles.Select(c => c.Volume).ToList();

        // İndikatör Hesaplamaları
        var bbResult = TechnicalIndicators.CalculateBollingerBands(prices, _bbPeriod, _bbStdDev);
        var bandwidth = TechnicalIndicators.CalculateBollingerBandwidth(prices, _bbPeriod, _bbStdDev);
        var atr = TechnicalIndicators.CalculateAtr(candles, _atrPeriod);
        var volSma = TechnicalIndicators.CalculateSma(volumes, _volumeSmaPeriod);

        var lastBandwidth = bandwidth.LastOrDefault();
        decimal? prevBandwidth = bandwidth.Count >= 5
            ? (decimal?)bandwidth.Skip(bandwidth.Count - 5).Take(4).Average(b => b ?? 0)
            : null;
        var lastAtr = atr.LastOrDefault();
        decimal? prevAtr = atr.Count >= 5 ? (decimal?)atr.Skip(atr.Count - 5).Take(4).Average(a => a ?? 0) : null;
        var lastBbUpper = bbResult.Upper.LastOrDefault();
        var lastBbMiddle = bbResult.Middle.LastOrDefault();
        var lastVolSma = volSma.LastOrDefault();
        var lastCandle = candles.Last();
        var prevCandle = candles.Count >= 2 ? candles[candles.Count - 2] : null;

        if (lastBandwidth == null || lastAtr == null || lastBbUpper == null || lastVolSma == null) return 0;

        decimal score = 0;
        decimal maxScore = 100;

        // 1. Bollinger Squeeze (Düşük Bandwidth) (Ağırlık: 25)
        // Önceki bandwidth'e göre sıkışma var mı?
        if (prevBandwidth != null && prevBandwidth > 0)
        {
            decimal bandwidthRatio = lastBandwidth.Value / prevBandwidth.Value;

            // Sıkışma sonrası genişleme = Breakout başlangıcı
            if (bandwidthRatio > 1.3m && lastBandwidth < 8) score += 25; // Genişliyor ama hala dar
            else if (lastBandwidth < 4) score += 20; // Çok sıkı
            else if (lastBandwidth < 6) score += 15;
            else if (lastBandwidth < 8) score += 10;
        }

        // 2. ATR Expansion (Volatilite Patlaması) (Ağırlık: 20)
        if (prevAtr != null && prevAtr > 0)
        {
            decimal atrRatio = lastAtr.Value / prevAtr.Value;
            if (atrRatio >= 1.5m) score += 20; // Volatilite patlaması
            else if (atrRatio >= 1.3m) score += 15;
            else if (atrRatio >= 1.1m) score += 10;
        }

        // 3. Üst Band Kırılımı (Ağırlık: 25)
        // Fiyat üst bandı kırdı mı veya yaklaştı mı?
        if (lastCandle.Close > lastBbUpper)
        {
            score += 25; // Tam breakout
        }
        else if (lastBbMiddle != null && lastCandle.Close > lastBbMiddle.Value)
        {
            decimal distanceToUpper = (lastBbUpper.Value - lastCandle.Close) / lastCandle.Close * 100;
            if (distanceToUpper < 1) score += 20; // Çok yakın
            else if (distanceToUpper < 2) score += 15;
            else score += 10; // Orta bandın üzerinde
        }

        // 4. Hacim Onayı (Kırılım Hacimle Desteklenmeli) (Ağırlık: 20)
        if (lastVolSma > 0)
        {
            decimal volRatio = lastCandle.Volume / lastVolSma.Value;
            if (volRatio >= 2.0m) score += 20; // Güçlü hacim patlaması
            else if (volRatio >= 1.5m) score += 15;
            else if (volRatio >= 1.2m) score += 10;
        }

        // 5. Mum Yapısı (Güçlü Boğa Mumu) (Ağırlık: 10)
        // Son mum yeşil ve gövde büyükse
        if (lastCandle.Close > lastCandle.Open)
        {
            decimal bodySize = lastCandle.Close - lastCandle.Open;
            decimal totalRange = lastCandle.High - lastCandle.Low;
            if (totalRange > 0)
            {
                decimal bodyRatio = bodySize / totalRange;
                if (bodyRatio > 0.7m) score += 10; // Güçlü boğa gövdesi
                else if (bodyRatio > 0.5m) score += 7;
                else if (bodyRatio > 0.3m) score += 5;
            }
        }

        return Math.Min(score, maxScore);
    }
}
