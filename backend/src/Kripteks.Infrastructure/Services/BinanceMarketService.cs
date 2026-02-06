using Binance.Net.Clients;
using Binance.Net.Interfaces.Clients;
using Kripteks.Core.DTOs;
using Kripteks.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class BinanceMarketService : IMarketDataService
{
    private readonly ILogger<BinanceMarketService> _logger;
    private readonly IBinanceRestClient _client;
    private readonly IBinanceSocketClient _socketClient;
    private readonly System.Collections.Concurrent.ConcurrentDictionary<string, decimal> _priceCache = new();

    public BinanceMarketService(ILogger<BinanceMarketService> logger, IBinanceSocketClient socketClient,
        IBinanceRestClient client)
    {
        _logger = logger;
        _socketClient = socketClient;
        _client = client;
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

            // Stabil coin listesi (BaseAsset olarak filtrelenecek)
            var stableCoins = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "USDT", "USDC", "BUSD", "DAI", "TUSD", "USDP", "FDUSD", "USDD",
                "GUSD", "PAX", "FRAX", "LUSD", "MIM", "UST", "PYUSD", "USDJ",
                "SUSD", "EURS", "EURT", "AEUR", "USTC", "CUSD", "CEUR", "RSR",
                "UU", "U", "USD1", "USDE", "RLUSD", "BFUSD", "XUSD" // Yeni eklenen stabil coinler
            };

            var pairs = exchangeInfo.Data.Symbols
                .Where(s => s.Status == Binance.Net.Enums.SymbolStatus.Trading &&
                            s.QuoteAsset == "USDT" &&
                            !stableCoins.Contains(s.BaseAsset) && // Stabil coinleri BaseAsset olarak hariç tut
                            !s.Name.EndsWith("UPUSDT") &&
                            !s.Name.EndsWith("DOWNUSDT") &&
                            !s.Name.EndsWith("BEARUSDT") &&
                            !s.Name.EndsWith("BULLUSDT") &&
                            !s.Name.Contains("EUR") &&
                            !s.Name.Contains(
                                "GBP")) // Sadece USDT pariteleri ve aktif olanlar, kaldıraçlı/stable/fiat hariç
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

        // Cache kontrolü
        if (_priceCache.TryGetValue(cleanSymbol, out var cachedPrice))
        {
            return cachedPrice;
        }

        var priceResult = await _client.SpotApi.ExchangeData.GetPriceAsync(cleanSymbol);
        if (priceResult.Success)
        {
            _priceCache[cleanSymbol] = priceResult.Data.Price; // Cache'i güncelle
            return priceResult.Data.Price;
        }

        return 0;
    }

    public async Task StartSocketConnection(IEnumerable<string> symbols)
    {
        var cleanSymbols = symbols.Select(s => s.Replace("/", "").ToUpper()).Distinct().ToList();
        if (!cleanSymbols.Any()) return;

        _logger.LogInformation("WebSocket Aboneliği Başlatılıyor: {Count} Sembol", cleanSymbols.Count);

        var subscription = await _socketClient.SpotApi.ExchangeData.SubscribeToMiniTickerUpdatesAsync(cleanSymbols,
            data => { _priceCache[data.Data.Symbol] = data.Data.LastPrice; });

        if (!subscription.Success)
        {
            _logger.LogError("WebSocket Abonelik Hatası: {Error}", subscription.Error);
        }
        else
        {
            _logger.LogInformation("WebSocket Bağlantısı Başarılı! ⚡");
        }
    }
}
