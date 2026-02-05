using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Helpers;

namespace Kripteks.Infrastructure.Strategies;

public class ScoutBreakoutStrategy : IStrategy
{
    public string Id => "strategy-scout-breakout";
    public string Name => "Scout Breakout (Volume & RSI)";

    private int _rsiPeriod = 14;
    private int _volumeAvgPeriod = 20;
    private decimal _volumeMultiplier = 1.8m;
    private decimal _rsiLowerBound = 30;
    private decimal _rsiUpperBound = 70;

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters.TryGetValue("rsiPeriod", out var v1) && int.TryParse(v1, out var r)) _rsiPeriod = r;
        if (parameters.TryGetValue("volPeriod", out var v2) && int.TryParse(v2, out var vp)) _volumeAvgPeriod = vp;
        if (parameters.TryGetValue("volMult", out var v3) && decimal.TryParse(v3, out var vm)) _volumeMultiplier = vm;
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        var result = new StrategyResult();
        int maxPeriod = Math.Max(_volumeAvgPeriod, _rsiPeriod) + 1;

        if (candles.Count < maxPeriod) return result;

        var prices = candles.Select(c => c.Close).ToList();
        var volumes = candles.Select(c => c.Volume).ToList();

        var rsiList = TechnicalIndicators.CalculateRsi(prices, _rsiPeriod);
        var currentRsi = rsiList.Last() ?? 50;

        // Hacim Analizi
        var lastVolume = volumes.Last();
        var avgVolume = volumes.Skip(volumes.Count - _volumeAvgPeriod - 1).Take(_volumeAvgPeriod).Average();
        bool isVolumeSpike = lastVolume > (avgVolume * _volumeMultiplier);

        decimal currentPrice = prices.Last();

        // ALIM MANTIĞI (Aşırı satımdan dönüş veya Breakout başlangıcı)
        if (currentPositionAmount == 0)
        {
            bool isRsiBreakout = currentRsi > 50 && currentRsi < _rsiUpperBound;
            bool isRsiOversoldRecovery = currentRsi > _rsiLowerBound && rsiList[rsiList.Count - 2] <= _rsiLowerBound;

            if (isVolumeSpike && (isRsiBreakout || isRsiOversoldRecovery))
            {
                result.Action = TradeAction.Buy;
                result.TargetPrice = currentPrice * 1.03m; // Hızlı %3 hedef
                result.StopPrice = currentPrice * 0.98m; // %2 Stop
                result.Description = isRsiBreakout
                    ? $"SCOUT: Hacim Patlaması & RSI Breakout ({currentRsi:F1})"
                    : $"SCOUT: Hacim Patlaması & Dip Dönüşü ({currentRsi:F1})";
            }
            else if (isVolumeSpike)
            {
                result.Description = currentRsi >= _rsiUpperBound
                    ? $"SCOUT: Hacim Güçlü Ancak RSI ({currentRsi:F1}) Güvenli Bölge Üstünde (Overbought)"
                    : $"SCOUT: Hacim Patlaması Var Ancak Net Trend Teyidi Bekleniyor (RSI: {currentRsi:F1})";
            }
            else if (currentRsi < 30)
            {
                result.Description = "SCOUT: Dip Bölgesi, Hacim Desteği Bekleniyor";
            }
        }
        else
        {
            // SATIŞ MANTIĞI (Kâr Al veya Momentum Kaybı)
            if (currentRsi > 75 || (!isVolumeSpike && currentRsi < 50))
            {
                result.Action = TradeAction.Sell;
                result.Description =
                    currentRsi > 75 ? "SCOUT: Hedefe Ulaşıldı (Aşırı Alım)" : "SCOUT: Momentum Kaybedildi";
            }
        }

        return result;
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        int maxPeriod = Math.Max(_volumeAvgPeriod, _rsiPeriod) + 1;
        if (candles.Count < maxPeriod) return 50;

        var prices = candles.Select(c => c.Close).ToList();
        var volumes = candles.Select(c => c.Volume).ToList();

        var rsiList = TechnicalIndicators.CalculateRsi(prices, _rsiPeriod);
        var currentRsi = rsiList.Last() ?? 50;
        var lastVolume = volumes.Last();
        var avgVolume = volumes.Skip(volumes.Count - _volumeAvgPeriod - 1).Take(_volumeAvgPeriod).Average();

        decimal score = 50;

        // 1. Hacim Faktörü (En önemli faktör - %50 etki)
        decimal volRatio = lastVolume / (avgVolume > 0 ? avgVolume : 1);
        if (volRatio > 1)
        {
            score += Math.Min(volRatio * 15, 45); // Maksimum 45 puan hacimden gelebilir
        }

        // 2. RSI Faktörü (Breakout tespiti - %50 etki)
        if (currentRsi > 50 && currentRsi < 70)
        {
            // 50-70 arası ideal breakout bölgesidir
            score += 15;
            if (currentRsi > 60) score += 10;
        }
        else if (currentRsi > 70)
        {
            // Aşırı alıma giriyor, risk artıyor ama trend güçlü
            score += 5;
        }
        else if (currentRsi < 35)
        {
            // Dip dönüş potansiyeli
            score += 10;
        }

        return Math.Clamp(score, 0, 100);
    }
}
