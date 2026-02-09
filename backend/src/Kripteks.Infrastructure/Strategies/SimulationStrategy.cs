using Kripteks.Core.Interfaces;

namespace Kripteks.Infrastructure.Strategies;

/// <summary>
/// Simülasyon Stratejisi - Test Amaçlı
/// Pozisyon yokken alım, pozisyondayken %5 TP / %5 SL mantığıyla çalışır.
/// Gerçek veri olmasa bile sistemin akışını doğrulamak için kullanılır.
/// </summary>
public class SimulationStrategy : IStrategy
{
    public string Id => "strategy-simulation";
    public string Name => "Simülasyon Stratejisi";

    public string Description =>
        "Sistemin alım-satım akışını test etmek için kullanılır. Pozisyon yokken otomatik alım, pozisyondayken %5 kâr al / %5 zarar durdur kurallarıyla çalışır. Gerçek para kullanmadan bot mekanizmasını doğrulamak için idealdir.";

    public StrategyCategory Category => StrategyCategory.Both;

    public void SetParameters(Dictionary<string, string> parameters)
    {
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        var currentPrice = candles.Last().Close;

        // Pozisyon yoksa → Al
        if (currentPositionAmount == 0)
        {
            return new StrategyResult
            {
                Action = TradeAction.Buy,
                Description = "Simülasyon: Alım sinyali üretildi.",
                TargetPrice = currentPrice * 1.05m,
                StopPrice = currentPrice * 0.95m
            };
        }

        // Pozisyon varsa → TP/SL kontrolü
        if (entryPrice > 0)
        {
            decimal pnl = ((currentPrice - entryPrice) / entryPrice) * 100;

            if (pnl >= 5)
            {
                return new StrategyResult
                {
                    Action = TradeAction.Sell,
                    Description = $"Simülasyon: Kâr Al (%{pnl:F2})"
                };
            }

            if (pnl <= -5)
            {
                return new StrategyResult
                {
                    Action = TradeAction.Sell,
                    Description = $"Simülasyon: Zarar Durdur (%{pnl:F2})"
                };
            }
        }

        return new StrategyResult
        {
            Action = TradeAction.None,
            Description = "Simülasyon: Pozisyonda, TP/SL bekleniyor."
        };
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        // Test amaçlı: 60-90 arası deterministic skor (mum sayısına göre)
        if (candles.Count == 0) return 0;
        return 60 + (candles.Count % 31); // 60-90 arası, her seferinde aynı veriyle aynı sonuç
    }
}
