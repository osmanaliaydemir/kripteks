using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Helpers;

namespace Kripteks.Infrastructure.Strategies;

/// <summary>
/// Oversold Recovery Strategy - Aşırı Satım Toparlanması
/// RSI aşırı satım bölgesinden toparlanma sinyali veren coinleri tespit eder.
/// Düşük riskli "dip alma" stratejisi
/// </summary>
public class OversoldRecoveryStrategy : IStrategy
{
    public string Id => "strategy-oversold-recovery";
    public string Name => "Oversold Recovery (Aşırı Satım Toparlanması)";

    public string Description =>
        "RSI ve Stochastic RSI aşırı satım bölgesinden (30 altı) toparlanma sinyali veren coinleri tespit eder. Destek seviyesi yakınında, hacim artışıyla birlikte yukarı dönüş yapan pariteleri yakalar.";

    private int _rsiPeriod = 14;
    private int _stochRsiPeriod = 14;
    private decimal _oversoldLevel = 30m;

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters.TryGetValue("RsiPeriod", out var rsi)) _rsiPeriod = int.Parse(rsi);
        if (parameters.TryGetValue("StochRsiPeriod", out var stoch)) _stochRsiPeriod = int.Parse(stoch);
        if (parameters.TryGetValue("OversoldLevel", out var level)) _oversoldLevel = decimal.Parse(level);
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
                TargetPrice = lastPrice * 1.12m, // %12 hedef (toparlanma hareketiyle)
                StopPrice = lastPrice * 0.95m, // %5 stop (destek altına düşerse)
                Description = "Aşırı satımdan toparlanma sinyali - Dip alım fırsatı"
            };
        }

        return new StrategyResult { Action = TradeAction.None, Description = "Toparlanma sinyali yok" };
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        if (candles.Count < 50) return 0;

        var prices = candles.Select(c => c.Close).ToList();
        var volumes = candles.Select(c => c.Volume).ToList();

        // İndikatör Hesaplamaları
        var rsiResults = TechnicalIndicators.CalculateRsi(prices, _rsiPeriod);
        var stochRsi = TechnicalIndicators.CalculateStochasticRsi(prices, _rsiPeriod, _stochRsiPeriod);
        var volSma = TechnicalIndicators.CalculateSma(volumes, 20);
        var support = TechnicalIndicators.CalculateSupportLevel(candles, 20);

        var lastRsi = rsiResults.LastOrDefault();
        var prevRsi = rsiResults.Count >= 2 ? rsiResults[rsiResults.Count - 2] : null;
        var lastStochK = stochRsi.K.LastOrDefault();
        var prevStochK = stochRsi.K.Count >= 2 ? stochRsi.K[stochRsi.K.Count - 2] : null;
        var lastVolSma = volSma.LastOrDefault();
        var lastCandle = candles.Last();
        var prevCandle = candles.Count >= 2 ? candles[candles.Count - 2] : null;

        if (lastRsi == null || lastStochK == null || lastVolSma == null || support == null) return 0;

        decimal score = 0;
        decimal maxScore = 100;

        // 1. RSI Oversold Recovery (Ağırlık: 30)
        // RSI önceden 30 altındaydı ve şimdi yükseliyor
        if (prevRsi != null && prevRsi <= _oversoldLevel && lastRsi > prevRsi)
        {
            if (lastRsi <= 40) score += 30; // Henüz düşükken yakaladık
            else if (lastRsi <= 50) score += 25; // Biraz geç ama hala fırsat
            else score += 15; // Toparlanma başladı
        }
        else if (lastRsi <= _oversoldLevel)
        {
            score += 10; // Hala oversold, ama henüz dönüş yok
        }

        // 2. Stochastic RSI Dönüşü (Ağırlık: 25)
        if (prevStochK != null && lastStochK > prevStochK)
        {
            if (prevStochK <= 20 && lastStochK > 20) score += 25; // 20 seviyesini kırdı
            else if (lastStochK <= 30) score += 20; // Düşük bölgeden çıkış
            else score += 10; // Genel yükseliş
        }

        // 3. Destek Seviyesi Yakınlığı (Ağırlık: 20)
        // Fiyat destek seviyesine yakınsa ve tutunuyorsa
        decimal supportDistance = support.Value > 0 ? ((lastCandle.Close - support.Value) / support.Value) * 100 : 100;
        if (supportDistance >= 0 && supportDistance <= 2) score += 20; // Destek üzerinde, çok yakın
        else if (supportDistance > 2 && supportDistance <= 5) score += 15; // Yakın
        else if (supportDistance > 5 && supportDistance <= 10) score += 8; // Orta uzaklık

        // 4. Hacim Onayı (Ağırlık: 15)
        // Toparlanma sırasında hacim artmalı
        if (lastVolSma > 0)
        {
            decimal volRatio = lastCandle.Volume / lastVolSma.Value;
            if (volRatio >= 1.5m) score += 15; // Güçlü hacim artışı
            else if (volRatio >= 1.2m) score += 12;
            else if (volRatio >= 1.0m) score += 8;
        }

        // 5. Bullish Divergence Bonus (Ağırlık: 10)
        // Fiyat düşük yaparken RSI yükseliyor = Güçlü dönüş sinyali
        if (TechnicalIndicators.DetectBullishDivergence(candles, rsiResults, 10))
        {
            score += 10;
        }

        return Math.Min(score, maxScore);
    }
}
