using Kripteks.Core.Models.Strategy;

namespace Kripteks.Core.Interfaces;

public interface IStrategyFactory
{
    IStrategy GetStrategy(string id);
    IEnumerable<IStrategy> GetAllStrategies();
    IEnumerable<IStrategy> GetStrategiesByCategory(StrategyCategory category);
}
