using Kripteks.Core.DTOs;

namespace Kripteks.Core.Interfaces;

public interface IWhaleTrackerService
{
    Task<List<WhaleTradeDto>> GetRecentWhaleTradesAsync(int minUsdValue = 500000, int count = 20);
}

public class WhaleTradeDto
{
    public string Symbol { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal Quantity { get; set; }
    public decimal UsdValue { get; set; }
    public DateTime Timestamp { get; set; }
    public bool IsBuyerMaker { get; set; } // True = Sell, False = Buy (usually)
}
