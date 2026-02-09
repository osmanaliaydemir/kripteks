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
    public string Name => "Dipten Dönüş";

    public string Description =>
        "RSI ve Stochastic RSI aşırı satım bölgesinden (30 altı) toparlanma sinyali veren coinleri tespit eder. Destek seviyesi yakınında, hacim artışıyla birlikte yukarı dönüş yapan pariteleri yakalar. Pozisyondayken RSI normalleşirse (%65 üzeri + kâr) veya toparlanma başarısız olursa çıkış yapılır. Hedef: %12, Stop: %5.";

    public StrategyCategory Category => StrategyCategory.Scanner;

    private int _rsiPeriod = 14;
    private int _stochRsiPeriod = 14;
    private decimal _oversoldLevel = 30m;

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters.TryGetValue("RsiPeriod", out var rsi) && int.TryParse(rsi, out var rsiVal))
            _rsiPeriod = rsiVal;
        if (parameters.TryGetValue("StochRsiPeriod", out var stoch) && int.TryParse(stoch, out var stochVal))
            _stochRsiPeriod = stochVal;
        if (parameters.TryGetValue("OversoldLevel", out var level) && decimal.TryParse(level, out var levelVal))
            _oversoldLevel = levelVal;
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        if (candles.Count < 50) return new StrategyResult { Action = TradeAction.None };

        var lastPrice = candles.Last().Close;

        // POZİSYON VAR → Toparlanma gerçekleşti mi?
        if (currentPositionAmount > 0 && entryPrice > 0)
        {
            var prices = candles.Select(c => c.Close).ToList();
            var rsiResults = TechnicalIndicators.CalculateRsi(prices, _rsiPeriod);
            var lastRsi = rsiResults.LastOrDefault() ?? 50;
            decimal pnl = ((lastPrice - entryPrice) / entryPrice) * 100;

            // Kâr al: %12
            if (pnl >= 12)
                return new StrategyResult
                {
                    Action = TradeAction.Sell,
                    Description = $"DİP DÖNÜŞ KÂR AL: Toparlanma tamamlandı (%{pnl:F2})"
                };

            // RSI normalleşti → toparlanma tamamlanıyor (RSI > 65 ve kâr varsa)
            if (lastRsi > 65 && pnl > 5)
                return new StrategyResult
                {
                    Action = TradeAction.Sell,
                    Description = $"DİP DÖNÜŞ: RSI normalleşti ({lastRsi:F0}), kâr alınıyor (%{pnl:F2})"
                };

            // Daha da derinleşti: RSI tekrar düşüyorsa ve zarar büyüyorsa
            if (lastRsi < 20 && pnl <= -5)
                return new StrategyResult
                {
                    Action = TradeAction.Sell,
                    Description = $"DİP DÖNÜŞ STOP: Toparlanma başarısız, RSI {lastRsi:F0} (%{Math.Abs(pnl):F2} zarar)"
                };

            // Zarar durdur: %5
            if (pnl <= -5)
                return new StrategyResult
                {
                    Action = TradeAction.Sell,
                    Description = $"DİP DÖNÜŞ STOP: %{Math.Abs(pnl):F2} zarar"
                };

            return new StrategyResult
            {
                Action = TradeAction.None,
                Description = $"Dip dönüş pozisyonda: %{pnl:F2} (RSI: {lastRsi:F0})"
            };
        }

        // POZİSYON YOK → Giriş sinyali
        var score = CalculateSignalScore(candles);

        if (score >= 70)
        {
            return new StrategyResult
            {
                Action = TradeAction.Buy,
                TargetPrice = lastPrice * 1.12m,
                StopPrice = lastPrice * 0.95m,
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
