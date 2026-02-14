using Kripteks.Core.Interfaces;
using Kripteks.Core.Models.Strategy;

namespace Kripteks.Infrastructure.Strategies;

public class StrategyFactory : IStrategyFactory
{
    private readonly IEnumerable<IStrategy> _strategies;

    public StrategyFactory(IEnumerable<IStrategy> strategies)
    {
        _strategies = strategies;
    }

    public IStrategy GetStrategy(string id)
    {
        var strategy = _strategies.FirstOrDefault(s =>
            string.Equals(s.Id, id, StringComparison.OrdinalIgnoreCase));

        if (strategy is null)
            throw new KeyNotFoundException(
                $"'{id}' ID'sine sahip strateji bulunamadı. Kayıtlı stratejiler: {string.Join(", ", _strategies.Select(s => s.Id))}");

        return strategy;
    }

    public IEnumerable<IStrategy> GetAllStrategies()
    {
        return _strategies;
    }

    public IEnumerable<IStrategy> GetStrategiesByCategory(StrategyCategory category)
    {
        return _strategies.Where(s => s.Category == category);
    }
}
