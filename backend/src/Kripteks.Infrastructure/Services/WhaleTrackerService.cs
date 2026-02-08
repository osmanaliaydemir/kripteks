using System.Collections.Concurrent;
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

    public async Task<List<WhaleTradeDto>> GetRecentWhaleTradesAsync(int minUsdValue = 100000, int count = 20)
    {
        try
        {
            // 1. Piyasadaki tüm pariteleri ve 24s hacimlerini çek
            var tickerResult = await _binanceClient.SpotApi.ExchangeData.GetTickersAsync();
            if (!tickerResult.Success)
            {
                _logger.LogWarning("Failed to fetch tickers: {Error}", tickerResult.Error);
                return new List<WhaleTradeDto>();
            }

            // 2. USDT çiftlerini filtrele ve hacme göre ilk 100'ü seç
            var topSymbols = tickerResult.Data
                .Where(t => t.Symbol.EndsWith("USDT"))
                .OrderByDescending(t => t.Volume * t.LastPrice)
                .Take(100)
                .Select(t => t.Symbol)
                .ToList();

            var whaleTrades = new ConcurrentBag<WhaleTradeDto>();

            // 3. Paralel olarak (limitli) işlemleri tara
            // Rate limit dostu olması için gruplandırarak gideceğiz (Semaphore de kullanılabilir)
            var tasks = topSymbols.Select(async symbol =>
            {
                try
                {
                    var trades = await _binanceClient.SpotApi.ExchangeData.GetRecentTradesAsync(symbol, limit: 500);
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
                catch (Exception ex)
                {
                    _logger.LogWarning("Error scanning {Symbol}: {Message}", symbol, ex.Message);
                }
            });

            await Task.WhenAll(tasks);

            return whaleTrades
                .OrderByDescending(t => t.Timestamp)
                .Take(count)
                .ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in dynamic whale tracking");
            return new List<WhaleTradeDto>();
        }
    }
}
