using Kripteks.Core.Interfaces;

namespace Kripteks.Infrastructure.Strategies;

public class SimulationStrategy : IStrategy
{
    public string Id => "strategy-simulation";
    public string Name => "Simülasyon Stratejisi (Test)";

    public void SetParameters(Dictionary<string, string> parameters)
    {
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        return new StrategyResult
        {
            Action = TradeAction.Buy,
            Description = "Simülasyon verisi üzerinden alım sinyali üretildi.",
            TargetPrice = candles.Last().Close * 1.05m,
            StopPrice = candles.Last().Close * 0.95m
        };
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        // 70-100 arası rastgele skor üret (Test için her zaman görünür olsun)
        var random = new Random();
        return (decimal)random.Next(70, 100);
    }
}
