using Binance.Net.Interfaces.Clients;
using Kripteks.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class WhaleTrackerService : IWhaleTrackerService
{
    private readonly ILogger<WhaleTrackerService> _logger;
    private readonly IBinanceRestClient _binanceClient;

    public WhaleTrackerService(ILogger<WhaleTrackerService> logger, IBinanceRestClient binanceClient)
    {
        _logger = logger;
        _binanceClient = binanceClient;
    }

    public async Task<List<WhaleTradeDto>> GetRecentWhaleTradesAsync(int minUsdValue = 500000, int count = 20)
    {
        try
        {
            // Ana coinleri tara
            var topSymbols = new[] { "BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT", "XRPUSDT", "DOGEUSDT" };
            var whaleTrades = new List<WhaleTradeDto>();

            foreach (var symbol in topSymbols)
            {
                var trades = await _binanceClient.SpotApi.ExchangeData.GetRecentTradesAsync(symbol, limit: 100);
                if (trades.Success)
                {
                    foreach (var trade in trades.Data)
                    {
                        var usdValue = trade.Price * trade.BaseQuantity;
                        if (usdValue >= minUsdValue)
                        {
                            whaleTrades.Add(new WhaleTradeDto
                            {
                                Symbol = symbol.Replace("USDT", "/USDT"),
                                Price = trade.Price,
                                Quantity = trade.BaseQuantity,
                                UsdValue = usdValue,
                                Timestamp = trade.TradeTime,
                                IsBuyerMaker = trade.BuyerIsMaker
                            });
                        }
                    }
                }
            }

            return whaleTrades
                .OrderByDescending(t => t.Timestamp)
                .Take(count)
                .ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching whale trades");
            return new List<WhaleTradeDto>();
        }
    }
}
