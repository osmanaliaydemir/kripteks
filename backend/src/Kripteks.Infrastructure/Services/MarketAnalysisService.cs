using Binance.Net.Clients;
using Binance.Net.Interfaces.Clients;
using Kripteks.Core.DTOs;
using Kripteks.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class MarketAnalysisService : IMarketAnalysisService
{
    private readonly ILogger<MarketAnalysisService> _logger;
    private readonly IBinanceRestClient _binanceClient;
    private readonly IMarketDataService _marketDataService;

    public MarketAnalysisService(
        ILogger<MarketAnalysisService> logger,
        IBinanceRestClient binanceClient,
        IMarketDataService marketDataService)
    {
        _logger = logger;
        _binanceClient = binanceClient;
        _marketDataService = marketDataService;
    }

    public async Task<MarketOverviewDto> GetMarketOverviewAsync()
    {
        try
        {
            var pairs = await _marketDataService.GetAvailablePairsAsync();
            var prices = await _binanceClient.SpotApi.ExchangeData.GetPricesAsync();
            var tickers = await _binanceClient.SpotApi.ExchangeData.GetTickersAsync();

            if (!prices.Success || !tickers.Success)
            {
                _logger.LogWarning("Failed to fetch market data from Binance");
                return new MarketOverviewDto();
            }

            var usdtPairs = tickers.Data
                .Where(t => t.Symbol.EndsWith("USDT"))
                .ToList();

            var totalVolume = usdtPairs.Sum(t => t.Volume * t.LastPrice);

            // BTC ve ETH dominance hesapla
            var btcPrice = prices.Data.FirstOrDefault(p => p.Symbol == "BTCUSDT")?.Price ?? 0;
            var ethPrice = prices.Data.FirstOrDefault(p => p.Symbol == "ETHUSDT")?.Price ?? 0;

            var btcTicker = tickers.Data.FirstOrDefault(t => t.Symbol == "BTCUSDT");
            var ethTicker = tickers.Data.FirstOrDefault(t => t.Symbol == "ETHUSDT");

            var btcVolume = btcTicker != null ? btcTicker.Volume * btcPrice : 0;
            var ethVolume = ethTicker != null ? ethTicker.Volume * ethPrice : 0;

            var btcDominance = totalVolume > 0 ? (btcVolume / totalVolume) * 100 : 0;
            var ethDominance = totalVolume > 0 ? (ethVolume / totalVolume) * 100 : 0;

            // Market trend hesapla (yükselenler vs düşenler)
            var gainers = usdtPairs.Count(t => t.PriceChangePercent > 0);
            var losers = usdtPairs.Count(t => t.PriceChangePercent < 0);
            var marketTrend = gainers > losers ? "bullish" : losers > gainers ? "bearish" : "neutral";

            return new MarketOverviewDto
            {
                TotalMarketCap = totalVolume * 10, // Rough estimate
                Volume24h = totalVolume,
                BtcDominance = btcDominance,
                EthDominance = ethDominance,
                ActiveCryptos = pairs.Count,
                MarketTrend = marketTrend
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching market overview");
            return new MarketOverviewDto();
        }
    }

    public async Task<List<TopMoverDto>> GetTopGainersAsync(int count = 5)
    {
        try
        {
            var tickers = await _binanceClient.SpotApi.ExchangeData.GetTickersAsync();

            if (!tickers.Success)
            {
                _logger.LogWarning("Failed to fetch tickers from Binance");
                return new List<TopMoverDto>();
            }

            var stableCoins = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "USDT", "USDC", "BUSD", "DAI", "TUSD", "FDUSD", "USDD", "UU", "USDE", "RLUSD", "BFUSD", "XUSD"
            };

            return tickers.Data
                .Where(t => t.Symbol.EndsWith("USDT") &&
                            !stableCoins.Any(sc =>
                                t.Symbol.Replace("USDT", "").Equals(sc, StringComparison.OrdinalIgnoreCase)) &&
                            t.Volume > 1000000) // Minimum volume filter
                .OrderByDescending(t => t.PriceChangePercent)
                .Take(count)
                .Select(t => new TopMoverDto
                {
                    Symbol = t.Symbol.Replace("USDT", "/USDT"),
                    Name = t.Symbol.Replace("USDT", ""),
                    Price = t.LastPrice,
                    ChangePercent24h = t.PriceChangePercent,
                    Volume24h = t.Volume * t.LastPrice
                })
                .ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching top gainers");
            return new List<TopMoverDto>();
        }
    }

    public async Task<List<TopMoverDto>> GetTopLosersAsync(int count = 5)
    {
        try
        {
            var tickers = await _binanceClient.SpotApi.ExchangeData.GetTickersAsync();

            if (!tickers.Success)
            {
                _logger.LogWarning("Failed to fetch tickers from Binance");
                return new List<TopMoverDto>();
            }

            var stableCoins = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "USDT", "USDC", "BUSD", "DAI", "TUSD", "FDUSD", "USDD", "UU", "USDE", "RLUSD", "BFUSD", "XUSD"
            };

            return tickers.Data
                .Where(t => t.Symbol.EndsWith("USDT") &&
                            !stableCoins.Any(sc =>
                                t.Symbol.Replace("USDT", "").Equals(sc, StringComparison.OrdinalIgnoreCase)) &&
                            t.Volume > 1000000) // Minimum volume filter
                .OrderBy(t => t.PriceChangePercent)
                .Take(count)
                .Select(t => new TopMoverDto
                {
                    Symbol = t.Symbol.Replace("USDT", "/USDT"),
                    Name = t.Symbol.Replace("USDT", ""),
                    Price = t.LastPrice,
                    ChangePercent24h = t.PriceChangePercent,
                    Volume24h = t.Volume * t.LastPrice
                })
                .ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching top losers");
            return new List<TopMoverDto>();
        }
    }

    public async Task<List<VolumeDataDto>> GetVolumeHistoryAsync(int hours = 24)
    {
        try
        {
            // Binance kline data kullanarak 1 saatlik hacim verilerini çek
            var symbol = "BTCUSDT"; // Genel piyasa için BTC kullan
            var interval = Binance.Net.Enums.KlineInterval.OneHour;
            var startTime = DateTime.UtcNow.AddHours(-hours);

            var klines = await _binanceClient.SpotApi.ExchangeData.GetKlinesAsync(
                symbol,
                interval,
                startTime,
                limit: hours
            );

            if (!klines.Success)
            {
                _logger.LogWarning("Failed to fetch klines from Binance");
                return new List<VolumeDataDto>();
            }

            return klines.Data
                .Select(k => new VolumeDataDto
                {
                    Timestamp = k.OpenTime,
                    Volume = k.Volume
                })
                .ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching volume history");
            return new List<VolumeDataDto>();
        }
    }

    public async Task<MarketMetricsDto> GetMarketMetricsAsync()
    {
        try
        {
            var prices = await _binanceClient.SpotApi.ExchangeData.GetPricesAsync();
            var tickers = await _binanceClient.SpotApi.ExchangeData.GetTickersAsync();
            var pairs = await _marketDataService.GetAvailablePairsAsync();

            if (!prices.Success || !tickers.Success)
            {
                _logger.LogWarning("Failed to fetch market metrics from Binance");
                return new MarketMetricsDto();
            }

            var btcPrice = prices.Data.FirstOrDefault(p => p.Symbol == "BTCUSDT")?.Price ?? 0;
            var ethPrice = prices.Data.FirstOrDefault(p => p.Symbol == "ETHUSDT")?.Price ?? 0;

            var usdtPairs = tickers.Data.Where(t => t.Symbol.EndsWith("USDT")).ToList();
            var totalVolume = usdtPairs.Sum(t => t.Volume * t.LastPrice);

            // Fear & Greed Index hesapla (basit bir yöntem)
            // Gerçek Fear & Greed Index için alternative.me API'si kullanılabilir
            var avgPriceChange = usdtPairs.Average(t => t.PriceChangePercent);
            var fearGreedIndex = 50 + ((double)avgPriceChange * 2); // -25% -> 0, 0% -> 50, +25% -> 100
            fearGreedIndex = Math.Max(0, Math.Min(100, fearGreedIndex)); // 0-100 arası clamp

            string fearGreedLabel;
            if (fearGreedIndex < 25) fearGreedLabel = "Extreme Fear";
            else if (fearGreedIndex < 45) fearGreedLabel = "Fear";
            else if (fearGreedIndex < 55) fearGreedLabel = "Neutral";
            else if (fearGreedIndex < 75) fearGreedLabel = "Greed";
            else fearGreedLabel = "Extreme Greed";

            return new MarketMetricsDto
            {
                FearGreedIndex = fearGreedIndex,
                FearGreedLabel = fearGreedLabel,
                TotalVolume24h = totalVolume,
                BtcPrice = btcPrice,
                EthPrice = ethPrice,
                TradingPairs = pairs.Count
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching market metrics");
            return new MarketMetricsDto();
        }
    }
}
