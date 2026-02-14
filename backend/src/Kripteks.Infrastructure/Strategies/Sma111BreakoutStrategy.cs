using Kripteks.Core.Interfaces;
using Kripteks.Core.Models.Strategy;
using Kripteks.Infrastructure.Helpers;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Strategies;

public class Sma111BreakoutStrategy : BaseStrategy
{
    private const int SmaPeriod = 111;

    public Sma111BreakoutStrategy(ILogger<Sma111BreakoutStrategy> logger) : base(logger)
    {
    }

    public override string Id => "Sma111BreakoutStrategy";
    public override string Name => "SMA 111 Breakout (Scanner)";

    public override string Description =>
        "Fiyatın SMA 111 üzerine çıktığı durumları tarar. Yeni kırılımlar (100 Puan) en üstte yer alır, trend eskidikçe puan düşer.";

    public override StrategyCategory Category => StrategyCategory.Scanner;

    protected override StrategyResult OnAnalyze(List<Candle> candles, decimal currentBalance,
        decimal currentPositionAmount, decimal entryPrice, int currentStep)
    {
        if (candles.Count < SmaPeriod)
        {
            return new StrategyResult { Action = TradeAction.None, Description = "Yetersiz veri." };
        }

        var prices = candles.Select(c => c.Close).ToList();
        var smaValues = TechnicalIndicators.CalculateSma(prices, SmaPeriod);
        var currentSma = smaValues.Last();
        var lastPrice = candles.Last().Close;

        if (currentSma == null)
        {
            return new StrategyResult { Action = TradeAction.None, Description = "SMA hesaplanamadı." };
        }

        var indicators = new Dictionary<string, object>
        {
            { "SMA111", currentSma.Value }
        };

        TradeAction action = TradeAction.None;
        string message = string.Empty;

        // Basit kırılım mantığı: Fiyat SMA üzerindeyse AL/TUT
        if (lastPrice > currentSma.Value)
        {
            if (currentPositionAmount == 0)
            {
                action = TradeAction.Buy;
                message = $"SMA 111 Üzerinde: {lastPrice:F8} > {currentSma:F8}";
            }
            else
            {
                action = TradeAction.None;
                message = "Trend devam ediyor.";
            }
        }
        else
        {
            if (currentPositionAmount > 0)
            {
                action = TradeAction.Sell;
                message = $"SMA 111 Altına İndi: {lastPrice:F8} < {currentSma:F8}";
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
        // 1. Veri kontrolü
        if (candles.Count < SmaPeriod + 1) return 0;

        var prices = candles.Select(c => c.Close).ToList();
        var smaValues = TechnicalIndicators.CalculateSma(prices, SmaPeriod);

        // Son değerler
        var currentSma = smaValues.Last();
        var lastPrice = candles.Last().Close;

        // Fiyat SMA altındaysa direkt 0 puan
        if (currentSma == null || lastPrice < currentSma.Value) return 0;

        // 2. Geriye dönük tarama: Kırılımın kaç mum önce gerçekleştiğini bul
        int candlesSinceBreakout = 0;

        // Sondan başa doğru (current index = count - 1)
        // En son mum zaten SMA üzerinde (yukarıdaki if kontrolü geçti)
        // Bir önceki muma bakarak ne zaman altına indiğini bulacağız.

        for (int i = candles.Count - 2; i >= SmaPeriod - 1; i--)
        {
            var price = candles[i].Close;
            var sma = smaValues[i];

            if (sma == null) break;

            if (price < sma.Value)
            {
                // Bulduk! Bu mumun kapanışı SMA altındaymış.
                // Demek ki (i+1) indisli mumda (yani şimdikinden 'candlesSinceBreakout' kadar önce) yukarı çıkmışız.
                // i = candles.Count - 2 (bir önceki mum)
                // Eğer bir önceki mum SMA altındaysa, şimdiki ilk kırılım mumudur.
                break;
            }

            candlesSinceBreakout++;
        }

        // candlesSinceBreakout:
        // 0 -> Fiyat bir önceki mumda SMA altındaydı, şimdi üstünde (İLK MUM) -> 100 Puan
        // 1 -> Bir önceki de üstündeydi, ondan önceki altındaydı -> 95 Puan
        // ...

        // Puan Formülü: 100 - (mum_sayisi * 5)
        decimal score = 100 - (candlesSinceBreakout * 5);

        return Math.Max(score, 0); // Eksiye düşmesin
    }
}
