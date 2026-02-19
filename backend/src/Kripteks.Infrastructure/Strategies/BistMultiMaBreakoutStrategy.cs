using Kripteks.Core.Interfaces;
using Kripteks.Core.Models.Strategy;
using Kripteks.Infrastructure.Helpers;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Strategies;

public class BistMultiMaBreakoutStrategy : BaseStrategy
{
    // Default enabled
    private const string ParamUseSma111 = "use_sma111";

    // Optional
    private const string ParamUseSma13 = "use_sma13";
    private const string ParamUseEma21 = "use_ema21";
    private const string ParamUseSma50 = "use_sma50";
    private const string ParamUseSma200 = "use_sma200";
    private const string ParamUseSma350 = "use_sma350";

    public BistMultiMaBreakoutStrategy(ILogger<BistMultiMaBreakoutStrategy> logger) : base(logger)
    {
    }

    public override string Id => "BistMultiMaBreakoutStrategy";
    public override string Name => "BIST Multi-MA Breakout Scanner";

    public override string Description =>
        "BIST Hisseleri için seçilen Hareketli Ortalamaların (MA) üzerine atan pariteleri tarar.\n" +
        "Kural: Fiyat > MA (Hacim filtresi BIST verilerindeki dalgalanmalar nedeniyle kapatılmıştır).";

    public override StrategyCategory Category => StrategyCategory.Scanner;

    private List<(string Name, int Period, bool IsEma)> GetEnabledMas()
    {
        var mas = new List<(string, int, bool)>();

        if (GetParameter(ParamUseSma13, "false") == "true") mas.Add(("SMA 13", 13, false));
        if (GetParameter(ParamUseEma21, "false") == "true") mas.Add(("EMA 21", 21, true));
        if (GetParameter(ParamUseSma50, "false") == "true") mas.Add(("SMA 50", 50, false));

        // SMA 111 default to true if not specified (backward compatibility)
        if (GetParameter(ParamUseSma111, "true") == "true") mas.Add(("SMA 111", 111, false));

        if (GetParameter(ParamUseSma200, "false") == "true") mas.Add(("SMA 200", 200, false));
        if (GetParameter(ParamUseSma350, "false") == "true") mas.Add(("SMA 350", 350, false));

        return mas;
    }

    protected override StrategyResult OnAnalyze(List<Candle> candles, decimal currentBalance,
        decimal currentPositionAmount, decimal entryPrice, int currentStep)
    {
        var enabledMas = GetEnabledMas();
        if (!enabledMas.Any())
        {
            return new StrategyResult { Action = TradeAction.None, Description = "Hiçbir MA seçilmedi." };
        }

        int maxPeriod = enabledMas.Max(m => m.Period);
        if (candles.Count < maxPeriod)
        {
            return new StrategyResult
                { Action = TradeAction.None, Description = $"Yetersiz veri (Gerekli: {maxPeriod})." };
        }

        var prices = candles.Select(c => c.Close).ToList();

        var indicators = new Dictionary<string, object>();
        var triggeredMas = new List<string>();
        decimal lastPrice = candles.Last().Close;

        foreach (var ma in enabledMas)
        {
            List<decimal?> maValues = ma.IsEma
                ? TechnicalIndicators.CalculateEma(prices, ma.Period)
                : TechnicalIndicators.CalculateSma(prices, ma.Period);

            var currentMa = maValues.Last();
            if (currentMa == null) continue;

            indicators[ma.Name] = currentMa.Value;

            if (lastPrice > currentMa.Value)
            {
                triggeredMas.Add(ma.Name);
            }
        }

        TradeAction action = TradeAction.None;
        string message = string.Empty;

        if (triggeredMas.Any())
        {
            if (currentPositionAmount == 0)
            {
                action = TradeAction.Buy;
                message = $"Fiyat {string.Join(", ", triggeredMas)} üzerinde.";
            }
            else
            {
                action = TradeAction.None;
                message = "Trend devam ediyor (" + string.Join(", ", triggeredMas) + ").";
            }
        }
        else
        {
            if (currentPositionAmount > 0)
            {
                action = TradeAction.Sell;
                message = "Fiyat tüm seçili ortalamaların altında.";
            }
        }

        return new StrategyResult
        {
            Action = action,
            Description = message,
            Price = lastPrice,
            Time = candles.Last().OpenTime,
            Indicators = indicators
        };
    }

    protected override decimal OnCalculateSignalScore(List<Candle> candles)
    {
        var enabledMas = GetEnabledMas();
        if (!enabledMas.Any()) return 0;

        int maxPeriod = enabledMas.Max(m => m.Period);
        if (candles.Count < maxPeriod + 1) return 0;

        var prices = candles.Select(c => c.Close).ToList();

        decimal maxScore = 0;

        // Calculate score for each MA and take the best one
        // Score = 100 - (candles since breakout * 5)
        foreach (var ma in enabledMas)
        {
            List<decimal?> maValues = ma.IsEma
                ? TechnicalIndicators.CalculateEma(prices, ma.Period)
                : TechnicalIndicators.CalculateSma(prices, ma.Period);

            var currentMa = maValues.Last();
            var lastPrice = candles.Last().Close;

            if (currentMa == null || lastPrice < currentMa.Value) continue;

            // Trend is UP for this MA. Find when it broke out.
            int candlesSinceBreakout = 0;
            bool foundBreakout = false;

            // Scan backwards
            for (int i = candles.Count - 2; i >= maxPeriod - 1; i--)
            {
                if (i >= maValues.Count) break;

                var oldMa = maValues[i];
                var oldPrice = candles[i].Close;

                if (oldMa == null) break;

                if (oldPrice < oldMa.Value)
                {
                    // Found the breakout candle! (Previously below)
                    foundBreakout = true;
                    break;
                }

                candlesSinceBreakout++;
            }

            // If it never went below in the available history, consider it an established trend
            decimal score = 100;
            if (foundBreakout)
            {
                // Score strictly decreases from 100 (fresh) down to 70 (old breakout)
                score = 100 - Math.Min(candlesSinceBreakout, 15) * 2;
            }
            else
            {
                // It was always above in the scanned range; give it a solid trend score
                score = 70;
            }

            if (score > maxScore) maxScore = score;
        }

        return Math.Max(maxScore, 0);
    }
}
