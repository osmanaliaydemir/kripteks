using Kripteks.Core.Interfaces;

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
        var strategy = _strategies.FirstOrDefault(s => s.Id == id);
        // Eğer bulunamazsa Golden Rose varsayılan olarak döner (veya null dönüp yönetilebilir)
        // Mevcut yapıda fallback kullanılıyordu.
        return strategy ?? _strategies.First(s => s.Id == "strategy-golden-rose");
    }

    public IEnumerable<IStrategy> GetAllStrategies()
    {
        return _strategies;
    }
}
