using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Helpers;

namespace Kripteks.Infrastructure.Strategies;

public class PhoenixMomentumStrategy : IStrategy
{
    public string Id => "strategy-phoenix-momentum";
    public string Name => "Phoenix Momentum Strategy";

    public string Description =>
        "Hacim, RSI ve Bollinger indikatörlerini birleştirerek kısa vadeli sert yükseliş (pump) potansiyeli taşıyan pariteleri yakalar.";

    private int _rsiPeriod = 14;
    private int _bbPeriod = 20;
    private decimal _bbStdDev = 2;
    private int _volumeSmaPeriod = 20;

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters.TryGetValue("RsiPeriod", out var rsi)) _rsiPeriod = int.Parse(rsi);
        if (parameters.TryGetValue("BbPeriod", out var bb)) _bbPeriod = int.Parse(bb);
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        if (candles.Count < 50) return new StrategyResult { Action = TradeAction.None };

        var score = CalculateSignalScore(candles);
        var lastPrice = candles.Last().Close;

        if (score >= 80)
        {
            return new StrategyResult
            {
                Action = TradeAction.Buy,
                TargetPrice = lastPrice * 1.10m, // %10 hedef
                StopPrice = lastPrice * 0.95m, // %5 stop
                Description = "Güçlü hacim ve momentum kırılımı (Pump Sinyali)"
            };
        }

        return new StrategyResult { Action = TradeAction.None, Description = "Momentum yetersiz" };
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        if (candles.Count < 50) return 0;

        var prices = candles.Select(c => c.Close).ToList();
        var volumes = candles.Select(c => c.Volume).ToList();

        // Indikator Hesaplamaları (Local Helper)
        var rsiResults = TechnicalIndicators.CalculateRsi(prices, _rsiPeriod);
        var bbResults = TechnicalIndicators.CalculateBollingerBands(prices, _bbPeriod, _bbStdDev);
        var volSmaResults = TechnicalIndicators.CalculateSma(volumes, _volumeSmaPeriod); // Volume için SMA
        var macdResults = TechnicalIndicators.CalculateMacd(prices);

        var lastRsi = rsiResults.LastOrDefault();
        var lastBbUpper = bbResults.Upper.LastOrDefault();
        var lastVolSma = volSmaResults.LastOrDefault();
        var lastMacdLine = macdResults.MacdLine.LastOrDefault();
        var lastSignalLine = macdResults.SignalLine.LastOrDefault();
        var lastCandle = candles.Last();

        if (lastRsi == null || lastBbUpper == null || lastVolSma == null || lastMacdLine == null ||
            lastSignalLine == null) return 0;

        decimal score = 0;
        decimal maxScore = 100;

        // 1. Hacim Patlaması (Volume Spike) - En Kritik! (Ağırlık: 30)
        // Son hacim ortalamanın 2 katıysa tam puan.
        if (lastVolSma > 0)
        {
            decimal volRatio = lastCandle.Volume / lastVolSma.Value;
            if (volRatio >= 2.0m) score += 30;
            else if (volRatio >= 1.5m) score += 20;
            else if (volRatio >= 1.2m) score += 10;
        }

        // 2. Bollinger Bant Durumu (Volatility) (Ağırlık: 25)
        // Fiyat üst bandın üzerindeyse veya %5 yakınındaysa (Breakout)
        decimal bbUpper = lastBbUpper.Value;
        if (lastCandle.Close > bbUpper) score += 25; // Tam Breakout
        else if (lastCandle.Close >= bbUpper * 0.99m) score += 20; // Eli kulağında

        // 3. RSI Momentum (Ağırlık: 25)
        // RSI 55-75 arası ideal boğa bölgesidir.
        decimal rsi = lastRsi.Value;
        if (rsi >= 55 && rsi <= 75) score += 25;
        else if (rsi > 75 && rsi < 85) score += 15; // Çok güçlü ama riskli
        else if (rsi >= 50 && rsi < 55) score += 10; // Başlangıç aşaması

        // 4. MACD Onayı (Ağırlık: 20)
        // MACD > Signal ve ikisi de 0'ın üzerindeyse
        if (lastMacdLine > lastSignalLine && lastMacdLine > 0) score += 20;
        else if (lastMacdLine > lastSignalLine) score += 10; // Kesişim var ama 0 altı

        return Math.Min(score, maxScore);
    }
}
