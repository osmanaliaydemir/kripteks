using Binance.Net.Interfaces.Clients;
using Kripteks.Infrastructure.Hubs;
using Kripteks.Core.DTOs;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

/// <summary>
/// Background service that maintains a WebSocket connection to Binance
/// and broadcasts real-time market data to SignalR hub
/// </summary>
public class BinanceWebSocketService : BackgroundService
{
    private readonly ILogger<BinanceWebSocketService> _logger;
    private readonly IServiceProvider _serviceProvider;
    private readonly IBinanceSocketClient _socketClient;
    private readonly TimeSpan _broadcastInterval = TimeSpan.FromSeconds(5);

    // In-memory cache for latest ticker data
    private readonly Dictionary<string, TickerData> _latestTickers = new();
    private readonly object _lock = new();

    public BinanceWebSocketService(
        ILogger<BinanceWebSocketService> logger,
        IServiceProvider serviceProvider,
        IBinanceSocketClient socketClient)
    {
        _logger = logger;
        _serviceProvider = serviceProvider;
        _socketClient = socketClient;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("🌐 BinanceWebSocketService started - connecting to all tickers stream...");

        try
        {
            // Subscribe to all market tickers stream
            var subscription = await _socketClient.SpotApi.ExchangeData.SubscribeToAllTickerUpdatesAsync(
                data =>
                {
                    // Update in-memory cache with latest ticker data
                    lock (_lock)
                    {
                        foreach (var ticker in data.Data)
                        {
                            var symbol = ticker.Symbol;

                            _latestTickers[symbol] = new TickerData
                            {
                                Symbol = symbol,
                                LastPrice = ticker.LastPrice,
                                PriceChangePercent = ticker.PriceChangePercent,
                                Volume = ticker.Volume,
                                QuoteVolume = ticker.QuoteVolume,
                                HighPrice = ticker.HighPrice,
                                LowPrice = ticker.LowPrice
                            };
                        }
                    }
                },
                stoppingToken);

            if (!subscription.Success)
            {
                _logger.LogError("Failed to subscribe to Binance WebSocket: {Error}", subscription.Error?.Message);
                return;
            }

            _logger.LogInformation("✅ Successfully subscribed to Binance all tickers stream");

            // Periodic broadcast loop
            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(_broadcastInterval, stoppingToken);
                await BroadcastMarketData(stoppingToken);
            }

            // Cleanup on stop
            await subscription.Data.CloseAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Critical error in BinanceWebSocketService");
        }
    }

    /// <summary>
    /// Calculate and broadcast market metrics to SignalR clients
    /// </summary>
    private async Task BroadcastMarketData(CancellationToken stoppingToken)
    {
        try
        {
            List<TickerData> snapshot;

            // Create snapshot of current ticker data
            lock (_lock)
            {
                if (_latestTickers.Count == 0)
                {
                    return; // No data yet
                }

                snapshot = _latestTickers.Values.ToList();
            }

            // Filter USDT pairs only
            var usdtPairs = snapshot
                .Where(t => t.Symbol.EndsWith("USDT"))
                .ToList();

            if (usdtPairs.Count == 0) return;

            // Calculate market overview
            // Calculate market overview
            var totalVolume = usdtPairs.Sum(t => t.QuoteVolume);
            var avgChange = usdtPairs.Average(t => t.PriceChangePercent);

            var marketOverview = new MarketOverviewDto
            {
                TotalMarketCap = 0, // Not available from ticker stream
                Volume24h = totalVolume,
                BtcDominance = 0, // Would need market cap data
                EthDominance = 0,
                ActiveCryptos = usdtPairs.Count,
                MarketTrend = avgChange > 0.5m ? "bullish" : avgChange < -0.5m ? "bearish" : "neutral"
            };

            // Top gainers (top 5)
            var topGainers = usdtPairs
                .OrderByDescending(t => t.PriceChangePercent)
                .Take(5)
                .Select(t => new TopMoverDto
                {
                    Symbol = t.Symbol,
                    Name = t.Symbol.Replace("USDT", ""),
                    Price = t.LastPrice,
                    ChangePercent24h = t.PriceChangePercent,
                    Volume24h = t.QuoteVolume
                })
                .ToList();

            // Top losers (bottom 5)
            var topLosers = usdtPairs
                .OrderBy(t => t.PriceChangePercent)
                .Take(5)
                .Select(t => new TopMoverDto
                {
                    Symbol = t.Symbol,
                    Name = t.Symbol.Replace("USDT", ""),
                    Price = t.LastPrice,
                    ChangePercent24h = t.PriceChangePercent,
                    Volume24h = t.QuoteVolume
                })
                .ToList();

            // Volume data point
            var volumeData = new VolumeDataDto
            {
                Timestamp = DateTime.UtcNow,
                Volume = totalVolume
            };

            // Broadcast to SignalR hub
            using var scope = _serviceProvider.CreateScope();
            var hubContext =
                scope.ServiceProvider.GetRequiredService<IHubContext<MarketDataHub, IMarketDataHubClient>>();

            await hubContext.Clients.All.ReceiveMarketOverview(marketOverview);
            await hubContext.Clients.All.ReceiveTopGainers(topGainers);
            await hubContext.Clients.All.ReceiveTopLosers(topLosers);
            await hubContext.Clients.All.ReceiveVolumeUpdate(volumeData);

            // Log once per minute to avoid spam
            if (DateTime.UtcNow.Second < 5)
            {
                _logger.LogInformation(
                    "📊 Market update broadcast: {PairCount} pairs, Volume: ${Volume:N0}, Trend: {Trend}",
                    usdtPairs.Count,
                    totalVolume,
                    marketOverview.MarketTrend);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error broadcasting market data");
        }
    }

    private class TickerData
    {
        public string Symbol { get; set; } = string.Empty;
        public decimal LastPrice { get; set; }
        public decimal PriceChangePercent { get; set; }
        public decimal Volume { get; set; }
        public decimal QuoteVolume { get; set; }
        public decimal HighPrice { get; set; }
        public decimal LowPrice { get; set; }
    }
}
