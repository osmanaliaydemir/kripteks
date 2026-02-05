using Kripteks.Core.Interfaces;
using Kripteks.Core.DTOs;
using Binance.Net.Clients;
using Binance.Net.Enums;
using Microsoft.Extensions.Logging;
using Kripteks.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Kripteks.Core.Entities;

namespace Kripteks.Infrastructure.Services;

public class ScannerService
{
    private readonly BinanceRestClient _client;
    private readonly ILogger<ScannerService> _logger;
    private readonly IStrategyFactory _strategyFactory;
    private readonly AppDbContext _dbContext;

    public ScannerService(ILogger<ScannerService> logger, IStrategyFactory strategyFactory, AppDbContext dbContext)
    {
        _logger = logger;
        _strategyFactory = strategyFactory;
        _dbContext = dbContext;
        _client = new BinanceRestClient();
    }

    public async Task<List<ScannerFavoriteListDto>> GetUserFavoritesAsync(string userId)
    {
        var lists = await _dbContext.UserFavoriteLists
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
        UserFavoriteList? entity;

        if (dto.Id.HasValue && dto.Id != Guid.Empty)
        {
            entity = await _dbContext.UserFavoriteLists.FirstOrDefaultAsync(x => x.Id == dto.Id && x.UserId == userId);
            if (entity == null) throw new Exception("Liste bulunamadı.");
        }
        else
        {
            entity = new UserFavoriteList { UserId = userId };
            _dbContext.UserFavoriteLists.Add(entity);
        }

        entity.Name = dto.Name;
        entity.Symbols = string.Join(",", dto.Symbols);

        await _dbContext.SaveChangesAsync();
        return entity.Id;
    }

    public async Task DeleteFavoriteListAsync(string userId, Guid id)
    {
        var entity = await _dbContext.UserFavoriteLists.FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);
        if (entity != null)
        {
            _dbContext.UserFavoriteLists.Remove(entity);
            await _dbContext.SaveChangesAsync();
        }
    }

    public async Task<ScannerResultDto> ScanAsync(ScannerRequestDto request)
    {
        var result = new ScannerResultDto();
        var strategy = _strategyFactory.GetStrategy(request.StrategyId);

        if (request.StrategyParameters != null)
            strategy.SetParameters(request.StrategyParameters);

        var interval = GetKlineInterval(request.Interval);

        var targetSymbols = request.Symbols;

        // If no symbols provided, fetch top symbols by 24h volume
        if (targetSymbols == null || !targetSymbols.Any())
        {
            var exchangeInfoTask = _client.SpotApi.ExchangeData.GetExchangeInfoAsync();
            var tickersTask = _client.SpotApi.ExchangeData.GetTickersAsync();

            await Task.WhenAll(exchangeInfoTask, tickersTask);

            var exchangeInfo = exchangeInfoTask.Result;
            var tickers = tickersTask.Result;

            if (exchangeInfo.Success && tickers.Success)
            {
                // 1. Get valid trading symbols
                var validSymbols = exchangeInfo.Data.Symbols
                    .Where(s => s.Status == SymbolStatus.Trading &&
                                s.QuoteAsset == "USDT" &&
                                !s.Name.EndsWith("UPUSDT") &&
                                !s.Name.EndsWith("DOWNUSDT") &&
                                !s.Name.EndsWith("BEARUSDT") &&
                                !s.Name.EndsWith("BULLUSDT") &&
                                !s.Name.Contains("TUSD") && // Optional: Exclude stablecoin pairs
                                !s.Name.Contains("USDC") &&
                                !s.Name.Contains("FDUSD") &&
                                !s.Name.Contains("EUR") &&
                                !s.Name.Contains("GBP") &&
                                !s.Name.Contains("DAI"))
                    .Select(s => s.Name)
                    .ToHashSet();

                // 2. Filter tickers by valid symbols and sort by volume
                targetSymbols = tickers.Data
                    .Where(x => validSymbols.Contains(x.Symbol))
                    .OrderByDescending(x => x.QuoteVolume) // Use QuoteVolume (USDT volume) for better ranking
                    .Take(100)
                    .Select(x => x.Symbol)
                    .ToList();
            }
        }

        if (targetSymbols == null || !targetSymbols.Any()) return result;

        foreach (var symbol in targetSymbols)
        {
            try
            {
                var cleanSymbol = symbol.Replace("/", "").ToUpper();
                var klines = await _client.SpotApi.ExchangeData.GetKlinesAsync(cleanSymbol, interval, limit: 100);

                if (!klines.Success || !klines.Data.Any())
                {
                    _logger.LogWarning("Could not fetch klines for {Symbol}", symbol);
                    continue;
                }

                var candles = klines.Data.Select(k => new Candle
                {
                    OpenTime = k.OpenTime,
                    Open = k.OpenPrice,
                    High = k.HighPrice,
                    Low = k.LowPrice,
                    Close = k.ClosePrice,
                    Volume = k.Volume
                }).ToList();

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
}
