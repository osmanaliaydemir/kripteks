using Kripteks.Core.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Kripteks.Core.DTOs;
using Binance.Net.Clients;
using Binance.Net.Enums;
using Microsoft.Extensions.Logging;
using Kripteks.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Kripteks.Core.Entities;
using Binance.Net.Interfaces.Clients;
using Kripteks.Core.Models.Strategy;

namespace Kripteks.Infrastructure.Services;

public class ScannerService
{
    private readonly IBinanceRestClient _client;
    private readonly ILogger<ScannerService> _logger;
    private readonly IStrategyFactory _strategyFactory;
    private readonly IServiceScopeFactory _scopeFactory;

    public ScannerService(ILogger<ScannerService> logger, IStrategyFactory strategyFactory,
        IBinanceRestClient client, IServiceScopeFactory scopeFactory)
    {
        _logger = logger;
        _strategyFactory = strategyFactory;
        _client = client;
        _scopeFactory = scopeFactory;
    }

    public async Task<List<ScannerFavoriteListDto>> GetUserFavoritesAsync(string userId)
    {
        using var scope = _scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var lists = await dbContext.UserFavoriteLists
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return lists.Select(x => new ScannerFavoriteListDto
        {
            Id = x.Id,
            Name = x.Name,
            Symbols = x.Symbols.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList(),
            CreatedAt = x.CreatedAt
        }).ToList();
    }

    public async Task<Guid> SaveFavoriteListAsync(string userId, SaveFavoriteListDto dto)
    {
        using var scope = _scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        UserFavoriteList? entity;

        if (dto.Id.HasValue && dto.Id != Guid.Empty)
        {
            entity = await dbContext.UserFavoriteLists.FirstOrDefaultAsync(x => x.Id == dto.Id && x.UserId == userId);
            if (entity == null) throw new Exception("Liste bulunamadı.");
        }
        else
        {
            entity = new UserFavoriteList { UserId = userId };
            dbContext.UserFavoriteLists.Add(entity);
        }

        entity.Name = dto.Name;
        entity.Symbols = string.Join(",", dto.Symbols);

        await dbContext.SaveChangesAsync();
        return entity.Id;
    }

    public async Task DeleteFavoriteListAsync(string userId, Guid id)
    {
        using var scope = _scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var entity = await dbContext.UserFavoriteLists.FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);
        if (entity != null)
        {
            dbContext.UserFavoriteLists.Remove(entity);
            await dbContext.SaveChangesAsync();
        }
    }

    public async Task<ScannerResultDto> ScanAsync(ScannerRequestDto request)
    {
        _logger.LogInformation(
            "Scan request received. Strategy: {StrategyId}, Interval: {Interval}, MinScore: {MinScore}, Symbols Count: {SymbolsCount}",
            request.StrategyId, request.Interval, request.MinScore, request.Symbols?.Count ?? 0);

        var result = new ScannerResultDto();
        var strategy = _strategyFactory.GetStrategy(request.StrategyId);

        if (request.StrategyParameters != null)
            strategy.SetParameters(request.StrategyParameters);

        var interval = GetKlineInterval(request.Interval);

        var targetSymbols = request.Symbols;

        // If no symbols provided, fetch top symbols by 24h volume
        if (targetSymbols == null || !targetSymbols.Any())
        {
            _logger.LogInformation("No symbols provided. Fetching top 100 symbols by volume.");
            var exchangeInfoTask = _client.SpotApi.ExchangeData.GetExchangeInfoAsync();
            var tickersTask = _client.SpotApi.ExchangeData.GetTickersAsync();

            await Task.WhenAll(exchangeInfoTask, tickersTask);

            var exchangeInfo = exchangeInfoTask.Result;
            var tickers = tickersTask.Result;

            if (exchangeInfo.Success && tickers.Success)
            {
                // Stabil coin listesi (BaseAsset olarak filtrelenecek)
                var stableCoins = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
                {
                    "USDT", "USDC", "BUSD", "DAI", "TUSD", "USDP", "FDUSD", "USDD",
                    "GUSD", "PAX", "FRAX", "LUSD", "MIM", "UST", "PYUSD", "USDJ",
                    "SUSD", "EURS", "EURT", "AEUR", "USTC", "CUSD", "CEUR", "RSR",
                    "UU", "U", "USD1", "USDE", "RLUSD", "BFUSD", "XUSD"
                };

                // 1. Get valid trading symbols
                var validSymbols = exchangeInfo.Data.Symbols
                    .Where(s => s.Status == SymbolStatus.Trading &&
                                s.QuoteAsset == "USDT" &&
                                !stableCoins.Contains(s.BaseAsset) &&
                                !s.Name.EndsWith("UPUSDT") &&
                                !s.Name.EndsWith("DOWNUSDT") &&
                                !s.Name.EndsWith("BEARUSDT") &&
                                !s.Name.EndsWith("BULLUSDT") &&
                                !s.Name.Contains("EUR") &&
                                !s.Name.Contains("GBP"))
                    .Select(s => s.Name)
                    .ToHashSet();

                // 2. Filter tickers by valid symbols and sort by volume
                targetSymbols = tickers.Data
                    .Where(x => validSymbols.Contains(x.Symbol))
                    .OrderByDescending(x => x.QuoteVolume) // Use QuoteVolume (USDT volume) for better ranking
                    .Take(500)
                    .Select(x => x.Symbol)
                    .ToList();

                _logger.LogInformation("Fethed {Count} top symbols.", targetSymbols.Count);
            }
            else
            {
                _logger.LogError(
                    "Failed to fetch exchange info or tickers. ExchangeInfo Success: {ExSuccess}, Tickers Success: {TickersSuccess}",
                    exchangeInfo.Success, tickers.Success);
            }
        }

        if (targetSymbols == null || !targetSymbols.Any())
        {
            if (request.StrategyId == "strategy-simulation")
            {
                targetSymbols = new List<string>
                    { "BTCUSDT", "ETHUSDT", "BNBUSDT", "SOLUSDT", "XRPUSDT", "ADAUSDT", "AVAXUSDT", "DOTUSDT" };
                _logger.LogInformation("Target symbols list is empty. Using dummy symbols for simulation.");
            }
            else
            {
                _logger.LogWarning("Target symbols list is empty. Returning empty result.");
                return result;
            }
        }

        foreach (var symbol in targetSymbols)
        {
            try
            {
                var cleanSymbol = symbol.Replace("/", "").ToUpper();
                var klines = await _client.SpotApi.ExchangeData.GetKlinesAsync(cleanSymbol, interval, limit: 500);

                List<Candle> candles;
                if (!klines.Success || klines.Data == null)
                {
                    if (request.StrategyId == "strategy-simulation")
                    {
                        candles = GenerateDummyCandles();
                    }
                    else
                    {
                        var errorMsg = klines.Error?.Message ?? "Unknown Error";
                        _logger.LogWarning("Binance API Error for {Symbol}: {Error}", symbol, errorMsg);
                        continue;
                    }
                }
                else
                {
                    candles = klines.Data.Select(k => new Candle
                    {
                        OpenTime = k.OpenTime,
                        Open = k.OpenPrice,
                        High = k.HighPrice,
                        Low = k.LowPrice,
                        Close = k.ClosePrice,
                        Volume = k.Volume
                    }).ToList();
                }

                var score = strategy.CalculateSignalScore(candles);

                // Filter by MinScore if provided
                if (request.MinScore.HasValue && score < request.MinScore.Value)
                    continue;

                var lastPrice = candles.Last().Close;

                // Determine suggested action based on analysis of last candle
                var analysis = strategy.Analyze(candles, 1000, 0); // Dummy balance

                result.Results.Add(new ScannerResultItemDto
                {
                    Symbol = symbol,
                    SignalScore = score,
                    SuggestedAction = analysis.Action,
                    Comment = analysis.Description,
                    LastPrice = lastPrice
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error scanning {Symbol}", symbol);
            }
        }

        // Sort by score descending
        result.Results = result.Results.OrderByDescending(r => r.SignalScore).ToList();
        _logger.LogInformation("Scan completed. Found {Count} results.", result.Results.Count);
        return result;
    }

    private KlineInterval GetKlineInterval(string interval) => interval switch
    {
        "1m" => KlineInterval.OneMinute,
        "3m" => KlineInterval.ThreeMinutes,
        "5m" => KlineInterval.FiveMinutes,
        "15m" => KlineInterval.FifteenMinutes,
        "30m" => KlineInterval.ThirtyMinutes,
        "1h" => KlineInterval.OneHour,
        "2h" => KlineInterval.TwoHour,
        "4h" => KlineInterval.FourHour,
        "1d" => KlineInterval.OneDay,
        _ => KlineInterval.OneHour
    };

    private List<Candle> GenerateDummyCandles()
    {
        var candles = new List<Candle>();
        var random = new Random();
        var price = 100m;
        var now = DateTime.UtcNow;

        for (int i = 0; i < 100; i++)
        {
            var change = (decimal)(random.NextDouble() * 2 - 1); // -1% to +1%
            var open = price;
            price += price * (change / 100);
            var close = price;
            var high = Math.Max(open, close) * 1.005m;
            var low = Math.Min(open, close) * 0.995m;

            candles.Add(new Candle
            {
                OpenTime = now.AddHours(-100 + i),
                Open = open,
                High = high,
                Low = low,
                Close = close,
                Volume = (decimal)random.Next(1000, 10000)
            });
        }

        return candles;
    }
}
