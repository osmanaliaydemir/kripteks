using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Helpers;

namespace Kripteks.Infrastructure.Strategies;

public class Sma111Strategy : IStrategy
{
    public string Id => "strategy-sma-111-breakout";
    public string Name => "SMA 111 Kırılım";

    public string Description =>
        "Fiyatın SMA 111 (Basit Hareketli Ortalama) seviyesini yukarı yönlü kırmasını takip eder. Güçlü bir trend başlangıcı sinyali olarak kabul edilir.";

    public StrategyCategory Category => StrategyCategory.Scanner;

    private int _period = 111;

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters != null && parameters.TryGetValue("period", out var p) && int.TryParse(p, out var period))
            _period = period;
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        if (candles.Count < _period + 1) return new StrategyResult { Action = TradeAction.None, Description = "Yetersiz veri" };

        var prices = candles.Select(c => c.Close).ToList();
        var smaList = TechnicalIndicators.CalculateSma(prices, _period);

        var currentSma = smaList.Last();
        var prevSma = smaList[smaList.Count - 2];

        if (currentSma == null || prevSma == null) return new StrategyResult { Action = TradeAction.None };

        var currentPrice = candles.Last().Close;
        var prevPrice = candles[candles.Count - 2].Close;

        if (currentPositionAmount == 0)
        {
            // Cross Over (Fiyat SMA'yı yukarı kesti)
            if (prevPrice <= prevSma.Value && currentPrice > currentSma.Value)
            {
                return new StrategyResult
                {
                    Action = TradeAction.Buy,
                    TargetPrice = currentPrice * 1.05m, // Varsayılan %5 TP
                    StopPrice = currentPrice * 0.95m,  // Varsayılan %5 SL
                    Description = $"SMA {_period} Kırılımı Gerçekleşti (Fiyat: ${currentPrice:F2})"
                };
            }
        }
        else
        {
            // Cross Under (Fiyat SMA'yı aşağı kesti)
            if (prevPrice >= prevSma.Value && currentPrice < currentSma.Value)
            {
                return new StrategyResult
                {
                    Action = TradeAction.Sell,
                    Description = $"Fiyat SMA {_period} Altına Düştü (Fiyat: ${currentPrice:F2})"
                };
            }
        }

        return new StrategyResult { Action = TradeAction.None, Description = currentPrice > currentSma ? "Trend Üzerinde" : "Trend Altında" };
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        if (candles.Count < _period + 1) return 0;

        var prices = candles.Select(c => c.Close).ToList();
        var smaList = TechnicalIndicators.CalculateSma(prices, _period);

        var currentSma = smaList.Last();
        var prevSma = smaList[smaList.Count - 2];

        if (currentSma == null || prevSma == null) return 0;

        var currentPrice = candles.Last().Close;
        var prevPrice = candles[candles.Count - 2].Close;

        // Check for crossover in the last 3 candles
        bool hasRecentCrossover = false;
        for (int i = 0; i < 3; i++)
        {
            int currentIdx = smaList.Count - 1 - i;
            int previousIdx = currentIdx - 1;

            if (previousIdx < 0 || smaList[currentIdx] == null || smaList[previousIdx] == null) continue;

            if (candles[previousIdx].Close <= smaList[previousIdx].Value && 
                candles[currentIdx].Close > smaList[currentIdx].Value)
            {
                hasRecentCrossover = true;
                break;
            }
        }

        if (hasRecentCrossover) return 100;
        
        // Boğa bölgesinde (SMA üstünde)
        if (currentPrice > currentSma.Value)
        {
            // SMA'ya yakınlık bonusu (Giriş fırsatı olabilir)
            decimal distance = (currentPrice - currentSma.Value) / currentSma.Value;
            if (distance < 0.01m) return 90; // Çok yakın
            if (distance < 0.03m) return 80; // Yakın
            return 70; // Güvenli bölge
        }

        return 0;
    }
}
