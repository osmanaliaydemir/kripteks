using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Helpers;

namespace Kripteks.Infrastructure.Strategies;

public class GoldenCrossStrategy : IStrategy
{
    public string Id => "strategy-golden-cross";
    public string Name => "Altın Kesişim (Golden Cross)";

    private int _shortPeriod = 50;
    private int _longPeriod = 200;

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters == null) return;

        if (parameters.TryGetValue("shortPeriod", out var sp) && int.TryParse(sp, out var shortPeriod))
            _shortPeriod = shortPeriod;

        if (parameters.TryGetValue("longPeriod", out var lp) && int.TryParse(lp, out var longPeriod))
            _longPeriod = longPeriod;
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        if (candles.Count < _longPeriod + 1)
            return new StrategyResult { Action = TradeAction.None, Description = "Yetersiz veri" };

        var prices = candles.Select(c => c.Close).ToList();
        var shortSmaList = TechnicalIndicators.CalculateSma(prices, _shortPeriod);
        var longSmaList = TechnicalIndicators.CalculateSma(prices, _longPeriod);

        var currentShortSma = shortSmaList.Last();
        var prevShortSma = shortSmaList[shortSmaList.Count - 2];

        var currentLongSma = longSmaList.Last();
        var prevLongSma = longSmaList[longSmaList.Count - 2];

        if (currentShortSma == null || prevShortSma == null || currentLongSma == null || prevLongSma == null)
            return new StrategyResult { Action = TradeAction.None };

        var currentPrice = candles.Last().Close;

        // Pozisyon yoksa ALIM sinyali ara
        if (currentPositionAmount == 0)
        {
            // Golden Cross (Kısa vade, Uzun vadeyi yukarı kesti)
            if (prevShortSma <= prevLongSma && currentShortSma > currentLongSma)
            {
                return new StrategyResult
                {
                    Action = TradeAction.Buy,
                    TargetPrice = currentPrice * 1.10m, // %10 Hedef (Uzun vadeli trend)
                    StopPrice = currentPrice * 0.92m,   // %8 Stop (Geniş stop)
                    Description = $"Altın Kesişim! SMA{_shortPeriod} SMA{_longPeriod}'yi yukarı kesti. (Fiyat: ${currentPrice:F2})"
                };
            }
        }
        else
        {
            // Ölüm Kesişimi (Death Cross) veya Stop/TP durumu
            if (prevShortSma >= prevLongSma && currentShortSma < currentLongSma)
            {
                return new StrategyResult
                {
                    Action = TradeAction.Sell,
                    Description = $"Ölüm Kesişimi! SMA{_shortPeriod} SMA{_longPeriod} altına düştü. (Fiyat: ${currentPrice:F2})"
                };
            }
        }

        string status = currentShortSma > currentLongSma ? "Boğa Trendi (Golden Cross)" : "Ayı Trendi";
        return new StrategyResult { Action = TradeAction.None, Description = status };
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        if (candles.Count < _longPeriod + 1) return 0;

        var prices = candles.Select(c => c.Close).ToList();
        var shortSmaList = TechnicalIndicators.CalculateSma(prices, _shortPeriod);
        var longSmaList = TechnicalIndicators.CalculateSma(prices, _longPeriod);

        // Son değerler
        var currentShort = shortSmaList.Last();
        var currentLong = longSmaList.Last();
        
        if (currentShort == null || currentLong == null) return 0;

        // Son 3 mum içinde kesişim var mı?
        bool hasRecentCrossover = false;
        for (int i = 0; i < 3; i++)
        {
            int currentIdx = shortSmaList.Count - 1 - i;
            int previousIdx = currentIdx - 1;

            if (previousIdx < 0) continue;
            
            var sCurr = shortSmaList[currentIdx];
            var sPrev = shortSmaList[previousIdx];
            var lCurr = longSmaList[currentIdx];
            var lPrev = longSmaList[previousIdx];

            if (sCurr == null || sPrev == null || lCurr == null || lPrev == null) continue;

            // Yukarı kesişim kontrolü
            if (sPrev <= lPrev && sCurr > lCurr)
            {
                hasRecentCrossover = true;
                break;
            }
        }

        if (hasRecentCrossover) return 100; // Tam sinyal anı

        // Trend devam ediyorsa
        if (currentShort > currentLong)
        {
            // Fiyat da ortalamaların üzerindeyse güçlü trend
            var currentPrice = candles.Last().Close;
            if (currentPrice > currentShort && currentPrice > currentLong)
                return 85; 
            
            return 70; // Trend pozitif ama fiyat biraz gevşemiş olabilir
        }

        return 0;
    }
}
