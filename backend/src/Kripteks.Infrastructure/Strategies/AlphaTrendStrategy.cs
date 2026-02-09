using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Helpers;

namespace Kripteks.Infrastructure.Strategies;

public class AlphaTrendStrategy : IStrategy
{
    public string Id => "strategy-alpha-trend";
    public string Name => "Alfa Trend Takibi";

    public string Description =>
        "EMA 20 (Hızlı) ve EMA 50 (Yavaş) üstel hareketli ortalama kesişimlerini temel alan trend takip stratejisi. Giriş için RSI (14) filtresini kullanır (aşırı alımda girmez). Çıkış için EMA negatif kesişim (Death Cross) veya RSI aşırı alım + EMA yakınlaşması (trend zayıflaması) koşullarını birlikte değerlendirir. Hedef: %5, Stop: %3.";

    public StrategyCategory Category => StrategyCategory.Trading;

    private int _fastEma = 20;
    private int _slowEma = 50;
    private int _rsiPeriod = 14;
    private decimal _rsiBuyThreshold = 65;
    private decimal _rsiSellThreshold = 75;

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters.TryGetValue("fastEma", out var v1) && int.TryParse(v1, out var f)) _fastEma = f;
        if (parameters.TryGetValue("slowEma", out var v2) && int.TryParse(v2, out var s)) _slowEma = s;
        if (parameters.TryGetValue("rsiPeriod", out var v3) && int.TryParse(v3, out var r)) _rsiPeriod = r;
        if (parameters.TryGetValue("rsiBuy", out var v4) && decimal.TryParse(v4, out var rb)) _rsiBuyThreshold = rb;
        if (parameters.TryGetValue("rsiSell", out var v5) && decimal.TryParse(v5, out var rs)) _rsiSellThreshold = rs;
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        var result = new StrategyResult();
        int maxPeriod = Math.Max(_slowEma, _rsiPeriod) + 1;

        if (candles.Count < maxPeriod) return result;

        var prices = candles.Select(c => c.Close).ToList();

        var fastEmaList = TechnicalIndicators.CalculateEma(prices, _fastEma);
        var slowEmaList = TechnicalIndicators.CalculateEma(prices, _slowEma);
        var rsiList = TechnicalIndicators.CalculateRsi(prices, _rsiPeriod);

        var currentFast = fastEmaList.Last();
        var currentSlow = slowEmaList.Last();
        var currentRsi = rsiList.Last();

        var prevFast = fastEmaList[fastEmaList.Count - 2];
        var prevSlow = slowEmaList[slowEmaList.Count - 2];

        if (!currentFast.HasValue || !currentSlow.HasValue || !currentRsi.HasValue || !prevFast.HasValue ||
            !prevSlow.HasValue)
            return result;

        decimal currentPrice = prices.Last();

        // ALIM MANTIĞI
        if (currentPositionAmount == 0)
        {
            // Golden Cross: Fast EMA, Slow EMA'yı yukarı keserse
            bool isGoldenCross = prevFast <= prevSlow && currentFast > currentSlow;

            // RSI kontrolü: Aşırı alımda değilsek gir
            bool isRsiOk = currentRsi < _rsiBuyThreshold;

            if (isGoldenCross && isRsiOk)
            {
                result.Action = TradeAction.Buy;
                result.TargetPrice = currentPrice * 1.05m; // %5 Kar Al (Minimalist)
                result.StopPrice = currentPrice * 0.97m; // %3 Zarar Durdur
                result.Description = $"ALIM: EMA Kesişimi & RSI OK ({currentRsi:F1})";
            }
        }
        else
        {
            // SATIŞ MANTIĞI
            // 1. Death Cross: Fast EMA, Slow EMA'yı aşağı keserse → Kesin satış
            bool isDeathCross = prevFast >= prevSlow && currentFast < currentSlow;

            if (isDeathCross)
            {
                result.Action = TradeAction.Sell;
                result.Description = "SATIŞ: EMA Negatif Kesişim (Death Cross)";
            }
            // 2. RSI Overbought + EMA yakınlaşması → Trend zayıflıyor
            // Tek başına RSI yüksek olması güçlü trendde normaldir.
            // RSI satışı ancak trend de zayıflıyorsa tetiklenmeli.
            else if (currentRsi > _rsiSellThreshold)
            {
                // EMA farkı daralıyorsa → trend zayıflıyor
                decimal emaGap = (currentFast.Value - currentSlow.Value) / currentSlow.Value * 100;
                decimal prevEmaGap = (prevFast.Value - prevSlow.Value) / prevSlow.Value * 100;

                // EMA farkı daralmaya başladıysa ve RSI çok yüksekse → momentum kaybı
                if (emaGap < prevEmaGap || currentRsi > 80)
                {
                    result.Action = TradeAction.Sell;
                    result.Description =
                        $"SATIŞ: RSI Aşırı Alım ({currentRsi:F1}) + Trend Zayıflıyor (EMA Gap: %{emaGap:F2})";
                }
            }
        }

        return result;
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        int maxPeriod = Math.Max(_slowEma, _rsiPeriod) + 1;
        if (candles.Count < maxPeriod) return 0;

        var prices = candles.Select(c => c.Close).ToList();
        var fastEmaList = TechnicalIndicators.CalculateEma(prices, _fastEma);
        var slowEmaList = TechnicalIndicators.CalculateEma(prices, _slowEma);
        var rsiList = TechnicalIndicators.CalculateRsi(prices, _rsiPeriod);

        decimal currentFast = fastEmaList.Last() ?? 0;
        decimal currentSlow = slowEmaList.Last() ?? 0;
        decimal currentRsi = rsiList.Last() ?? 50;

        decimal score = 50;

        // EMA Trend
        if (currentFast > currentSlow) score += 20;
        else score -= 20;

        // RSI Factor (Inverse: Lower RSI is better for buying)
        if (currentRsi < _rsiBuyThreshold)
        {
            score += (50 - (currentRsi / 2)); // Lower RSI = Higher Score
        }
        else if (currentRsi > _rsiSellThreshold)
        {
            score -= (currentRsi - 50) / 2;
        }

        return Math.Clamp(score, 0, 100);
    }
}
