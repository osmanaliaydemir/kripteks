using Binance.Net.Interfaces.Clients;
using Kripteks.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class ArbitrageScannerService : IArbitrageScannerService
{
    private readonly ILogger<ArbitrageScannerService> _logger;
    private readonly IBinanceRestClient _binanceClient;

    public ArbitrageScannerService(ILogger<ArbitrageScannerService> logger, IBinanceRestClient binanceClient)
    {
        _logger = logger;
        _binanceClient = binanceClient;
    }

    public async Task<List<ArbitrageOpportunityDto>> GetOpportunitiesAsync()
    {
        try
        {
            var tickers = await _binanceClient.SpotApi.ExchangeData.GetTickersAsync();
            if (!tickers.Success) return new List<ArbitrageOpportunityDto>();

            var tickerData = tickers.Data.ToDictionary(t => t.Symbol, t => t.LastPrice);
            var opportunities = new List<ArbitrageOpportunityDto>();

            // Ana assetleri kontrol et
            var assets = new[] { "BTC", "ETH", "BNB", "XRP", "ADA", "SOL", "DOT", "MATIC" };
            var stables = new[] { "USDT", "USDC", "FDUSD" };

            foreach (var asset in assets)
            {
                var prices = new Dictionary<string, decimal>();
                foreach (var stable in stables)
                {
                    var symbol = asset + stable;
                    if (tickerData.TryGetValue(symbol, out var price))
                    {
                        prices[stable] = price;
                    }
                }

                if (prices.Count > 1)
                {
                    // Farklı stablecoinler arasındaki farkları bul
                    var stableList = prices.Keys.ToList();
                    for (int i = 0; i < stableList.Count; i++)
                    {
                        for (int j = i + 1; j < stableList.Count; j++)
                        {
                            var s1 = stableList[i];
                            var s2 = stableList[j];
                            var p1 = prices[s1];
                            var p2 = prices[s2];

                            var diff = Math.Abs((double)((p1 - p2) / p2) * 100);
                            if (diff > 0.05) // %0.05'ten büyük farklar
                            {
                                opportunities.Add(new ArbitrageOpportunityDto
                                {
                                    Asset = asset,
                                    Pair1 = $"{asset}/{s1}",
                                    Pair2 = $"{asset}/{s2}",
                                    Price1 = p1,
                                    Price2 = p2,
                                    DifferencePercent = diff,
                                    PotentialProfitUsd = (decimal)(diff / 100) * 1000 // $1000 bazında
                                });
                            }
                        }
                    }
                }
            }

            return opportunities.OrderByDescending(o => o.DifferencePercent).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error scanning for arbitrage opportunities");
            return new List<ArbitrageOpportunityDto>();
        }
    }
}
