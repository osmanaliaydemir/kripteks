using Kripteks.Core.DTOs;

namespace Kripteks.Core.Interfaces;

public interface IMarketDataService
{
    Task<List<CoinDto>> GetAvailablePairsAsync();
    Task<decimal> GetPriceAsync(string symbol);
}
