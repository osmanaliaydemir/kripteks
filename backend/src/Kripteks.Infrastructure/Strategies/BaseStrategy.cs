using Kripteks.Core.Interfaces;
using Kripteks.Core.Models.Strategy;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Strategies;

public abstract class BaseStrategy : IStrategy
{
    protected readonly ILogger Logger;

    protected BaseStrategy(ILogger logger)
    {
        Logger = logger;
    }

    public abstract string Id { get; }
    public abstract string Name { get; }
    public abstract string Description { get; }
    public virtual StrategyCategory Category => StrategyCategory.Trading;

    protected Dictionary<string, string> Parameters { get; private set; } = new();

    public void SetParameters(Dictionary<string, string> parameters)
    {
        Parameters = parameters;
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        if (!ValidateCandles(candles))
        {
            return new StrategyResult { Action = TradeAction.None, Description = "Yetersiz veya geçersiz veri." };
        }

        try
        {
            return OnAnalyze(candles, currentBalance, currentPositionAmount, entryPrice, currentStep);
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Strateji analizi sırasında hata: {StrategyName}", Name);
            return new StrategyResult { Action = TradeAction.None, Description = $"Hata: {ex.Message}" };
        }
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        if (!ValidateCandles(candles))
        {
            return 0;
        }

        try
        {
            return OnCalculateSignalScore(candles);
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Sinyal skoru hesaplanırken hata: {StrategyName}", Name);
            return 0;
        }
    }

    protected abstract StrategyResult OnAnalyze(List<Candle> candles, decimal currentBalance,
        decimal currentPositionAmount, decimal entryPrice, int currentStep);

    protected abstract decimal OnCalculateSignalScore(List<Candle> candles);

    protected virtual bool ValidateCandles(List<Candle> candles)
    {
        return candles.Count > 0;
    }

    protected T GetParameter<T>(string key, T defaultValue)
    {
        if (Parameters.TryGetValue(key, out var value))
        {
            try
            {
                return (T)Convert.ChangeType(value, typeof(T));
            }
            catch
            {
                Logger.LogWarning("Parametre dönüştürme hatası: {Key}. Varsayılan değer kullanılıyor: {Default}", key,
                    defaultValue);
            }
        }

        return defaultValue;
    }
}
