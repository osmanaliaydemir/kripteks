using Binance.Net.Clients;
using Kripteks.Core.DTOs;
using Kripteks.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class BinanceMarketService : IMarketDataService
{
    private readonly ILogger<BinanceMarketService> _logger;
    private readonly BinanceRestClient _client;

    public BinanceMarketService(ILogger<BinanceMarketService> logger)
    {
        _logger = logger;
        _client = new BinanceRestClient(); // Public veri için API Key gerekmez
    }

    public async Task<List<CoinDto>> GetAvailablePairsAsync()
    {
        // Cache YOK - Her istekte taze veri çek
        // Binance API Limitlerine dikkat edilmeli (Dakikada 1200 ağırlık hakkımız var, bu istek ~2 ağırlık harcar, sorun olmaz)

        try
        {
            var exchangeInfoTask = _client.SpotApi.ExchangeData.GetExchangeInfoAsync();
            var pricesTask = _client.SpotApi.ExchangeData.GetPricesAsync();
            
            await Task.WhenAll(exchangeInfoTask, pricesTask);

            var exchangeInfo = exchangeInfoTask.Result;
            var prices = pricesTask.Result;

            if (!exchangeInfo.Success)
            {
                _logger.LogError("Binance ExchangeInfo hatası: {Error}", exchangeInfo.Error);
                return new List<CoinDto>();
            }

            // Fiyatları Dictionary'e al (Hızlı erişim için)
            var priceDict = new Dictionary<string, decimal>();
            if (prices.Success)
            {
               priceDict = prices.Data.ToDictionary(p => p.Symbol, p => p.Price);
            }

            var pairs = exchangeInfo.Data.Symbols
                .Where(s => s.Status == Binance.Net.Enums.SymbolStatus.Trading && s.QuoteAsset == "USDT") // Sadece USDT pariteleri ve aktif olanlar
                .Select(s => new CoinDto
                {
                    Id = s.Name,
                    Symbol = s.Name.Replace("USDT", "/USDT"),
                    BaseAsset = s.BaseAsset,
                    QuoteAsset = s.QuoteAsset,
                    MinQuantity = s.LotSizeFilter?.MinQuantity ?? 0,
                    MaxQuantity = s.LotSizeFilter?.MaxQuantity ?? 0,
                    CurrentPrice = priceDict.ContainsKey(s.Name) ? priceDict[s.Name] : 0
                })
                .OrderBy(s => s.Symbol)
                .ToList();

            return pairs;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Binance'dan veri çekilirken hata oluştu.");
            return new List<CoinDto>();
        }
    }

    public async Task<decimal> GetPriceAsync(string symbol)
    {
        // Symbol format temizliği (örn: BTC/USDT -> BTCUSDT)
        var cleanSymbol = symbol.Replace("/", "").ToUpper();
        
        var priceResult = await _client.SpotApi.ExchangeData.GetPriceAsync(cleanSymbol);
        if (priceResult.Success)
        {
            return priceResult.Data.Price;
        }
        
        return 0;
    }
}
