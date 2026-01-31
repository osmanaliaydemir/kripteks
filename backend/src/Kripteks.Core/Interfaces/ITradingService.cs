using Kripteks.Core.Entities;

namespace Kripteks.Core.Interfaces;

public interface ITradingService
{
    Task<bool> PlaceBuyOrderAsync(Bot bot, decimal price, decimal quantity);
    Task<bool> PlaceSellOrderAsync(Bot bot, decimal price, decimal quantity);
    Task<decimal> GetCurrentPriceAsync(string symbol);
}
