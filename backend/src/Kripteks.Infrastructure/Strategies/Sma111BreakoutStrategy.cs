using Kripteks.Core.Interfaces;
using Kripteks.Core.Models.Strategy;
using Kripteks.Infrastructure.Helpers;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Strategies;

public class Sma111BreakoutStrategy : BaseStrategy
{
    private const int VolumeSmaPeriod = 21;

    // Default enabled
    private const string ParamUseSma111 = "use_sma111";

    // Optional Parameters defined in PineScript
    private const string ParamUseSma13 = "use_sma13";
    private const string ParamUseEma21 = "use_ema21";
    private const string ParamUseSma50 = "use_sma50";
    private const string ParamUseSma200 = "use_sma200";
    private const string ParamUseSma350 = "use_sma350";
    private const string ParamUseSma350x0702 = "use_sma350x0702";
    private const string ParamUseSma350x1618 = "use_sma350x1618";
    private const string ParamUseSma350x2 = "use_sma350x2";
    private const string ParamUseSma350x3 = "use_sma350x3";
    private const string ParamUseSma350x5 = "use_sma350x5";
    private const string ParamUseSma350x8 = "use_sma350x8";
    private const string ParamUseSma350x13 = "use_sma350x13";
    private const string ParamUseSma350x21 = "use_sma350x21";

    public Sma111BreakoutStrategy(ILogger<Sma111BreakoutStrategy> logger) : base(logger)
    {
    }

    public override string Id => "Sma111BreakoutStrategy";
    public override string Name => "Multi-MA Breakout Scanner";

    public override string Description =>
        "Seçilen Hareketli Ortalamaların (MA) veya SMA 350 Çarpanlarının üzerine atan pariteleri tarar.\n" +
        "Kural: Fiyat, seçilen çizginin üzerine yeni çıkmış olmalıdır.";

    public override StrategyCategory Category => StrategyCategory.Scanner;

    private List<(string Name, int Period, bool IsEma, decimal Multiplier)> GetEnabledMas()
    {
        var mas = new List<(string, int, bool, decimal)>();

        if (GetParameter(ParamUseSma13, "false") == "true") mas.Add(("SMA 13", 13, false, 1m));
        if (GetParameter(ParamUseEma21, "false") == "true") mas.Add(("EMA 21", 21, true, 1m));
        if (GetParameter(ParamUseSma50, "false") == "true") mas.Add(("SMA 50", 50, false, 1m));

        // SMA 111 default to true if not specified (backward compatibility)
        if (GetParameter(ParamUseSma111, "true") == "true") mas.Add(("SMA 111", 111, false, 1m));

        if (GetParameter(ParamUseSma200, "false") == "true") mas.Add(("SMA 200", 200, false, 1m));
        if (GetParameter(ParamUseSma350, "false") == "true") mas.Add(("SMA 350", 350, false, 1m));

        // Multipliers based on SMA 350
        if (GetParameter(ParamUseSma350x0702, "false") == "true") mas.Add(("SMA 350 x 0.702", 350, false, 0.702m));
        if (GetParameter(ParamUseSma350x1618, "false") == "true") mas.Add(("SMA 350 x 1.618", 350, false, 1.618m));
        if (GetParameter(ParamUseSma350x2, "false") == "true") mas.Add(("SMA 350 x 2", 350, false, 2m));
        if (GetParameter(ParamUseSma350x3, "false") == "true") mas.Add(("SMA 350 x 3", 350, false, 3m));
        if (GetParameter(ParamUseSma350x5, "false") == "true") mas.Add(("SMA 350 x 5", 350, false, 5m));
        if (GetParameter(ParamUseSma350x8, "false") == "true") mas.Add(("SMA 350 x 8", 350, false, 8m));
        if (GetParameter(ParamUseSma350x13, "false") == "true") mas.Add(("SMA 350 x 13", 350, false, 13m));
        if (GetParameter(ParamUseSma350x21, "false") == "true") mas.Add(("SMA 350 x 21", 350, false, 21m));

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

        int closedCandleIndex = candles.Count - 2;
        decimal closedPrice = candles[closedCandleIndex].Close;

        foreach (var ma in enabledMas)
        {
            List<decimal?> maValues = ma.IsEma
                ? TechnicalIndicators.CalculateEma(prices, ma.Period)
                : TechnicalIndicators.CalculateSma(prices, ma.Period);

            var currentMa = maValues.Last();
            var closedMa = maValues[closedCandleIndex];

            if (currentMa == null || closedMa == null) continue;

            var closedTargetValue = closedMa.Value * ma.Multiplier;

            indicators[ma.Name] = currentMa.Value * ma.Multiplier;

            if (closedPrice > closedTargetValue)
            {
                // To match scoring rule, verify it actually broke out and is not just a long time trend
                // but for simple signal generation, we just state it is above based on the closed candle.
                triggeredMas.Add(ma.Name);
            }
        }

        TradeAction action = TradeAction.None;
        string message = string.Empty;

        // Tüm seçili hareketli ortalamaların üzerinde mi? (AND mantığı)
        if (triggeredMas.Count == enabledMas.Count)
        {
            if (currentPositionAmount == 0)
            {
                action = TradeAction.Buy;
                message = $"Kırılım yakalandı: {string.Join(", ", triggeredMas)} üzerinde.";
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
                message = "Fiyat seçili göstergelerin tamamının üzerinde değil.";
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
        if (candles.Count < maxPeriod + 2) return 0;

        var prices = candles.Select(c => c.Close).ToList();

        decimal totalScore = 0;
        int closedCandleIndex = candles.Count - 2;

        foreach (var ma in enabledMas)
        {
            List<decimal?> maValues = ma.IsEma
                ? TechnicalIndicators.CalculateEma(prices, ma.Period)
                : TechnicalIndicators.CalculateSma(prices, ma.Period);

            var closedMa = maValues[closedCandleIndex];
            var closedPrice = candles[closedCandleIndex].Close;

            if (closedMa == null) continue;

            var targetValue = closedMa.Value * ma.Multiplier;

            if (closedPrice < targetValue)
            {
                // Eğer seçilen MA'lardan herhangi birisi KAPANMIŞ mumda kırılmamışsa direkt 0 döner (AND mantığı)
                return 0;
            }

            // Trend is UP for this line. Find when the REAL breakout occurred.
            // We ignore temporary dips (less than 3 candles below the MA).
            int candlesSinceBreakout = 0;
            bool foundBreakout = false;
            int consecutiveBelow = 0;
            int lastAboveIndex = closedCandleIndex;

            // Scan backwards
            // We start checking from the candle before the closed one (closedCandleIndex - 1)
            for (int i = closedCandleIndex - 1; i >= maxPeriod - 1; i--)
            {
                if (i >= maValues.Count) break;

                var oldMa = maValues[i];
                var oldPrice = candles[i].Close;

                if (oldMa == null) break;

                var oldTargetValue = oldMa.Value * ma.Multiplier;

                if (oldPrice < oldTargetValue)
                {
                    consecutiveBelow++;
                    // Require at least 3 consecutive closes below the MA to consider the previous trend broken.
                    // This prevents whipsaws (1 or 2 day dips) from resetting the breakout score to 100.
                    if (consecutiveBelow >= 3)
                    {
                        foundBreakout = true;
                        candlesSinceBreakout = closedCandleIndex - lastAboveIndex;
                        break;
                    }
                }
                else
                {
                    consecutiveBelow = 0;
                    lastAboveIndex = i;
                }
            }

            if (!foundBreakout)
            {
                // It was always above in the scanned range (or at least never dropped below for 3+ candles)
                candlesSinceBreakout = closedCandleIndex - lastAboveIndex;
            }

            decimal score = 100;
            if (foundBreakout)
            {
                // Score strictly decreases from 100 (fresh) down to 70 (old breakout)
                // We use Math.Min(candlesSinceBreakout, 15) to cap the penalty at 30 points (15 * 2)
                score = 100 - Math.Min(candlesSinceBreakout, 15) * 2;
            }
            else
            {
                // Established trend, but giving it a decreasing score based on how long it's been above
                score = 100 - Math.Min(candlesSinceBreakout, 15) * 2;
                if (score < 40)
                    score = 40; // Floor so established trends aren't completely killed, but lower than fresh ones
            }

            totalScore += score;
        }

        // Tüm ortalamaların skorlarının ortalamasını al
        decimal avgScore = totalScore / enabledMas.Count;
        return Math.Max(avgScore, 0);
    }
}
