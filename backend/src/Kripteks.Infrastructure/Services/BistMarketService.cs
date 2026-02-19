using Kripteks.Core.DTOs;
using Kripteks.Core.Interfaces;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Kripteks.Infrastructure.Services;

public class BistMarketService : IMarketDataService
{
    private static readonly List<string> Bist100Symbols = new()
    {
        "THYAO.IS", "ASELS.IS", "EREGL.IS", "KCHOL.IS", "GARAN.IS", 
        "AKBNK.IS", "SISE.IS", "BIMAS.IS", "TUPRS.IS", "SAHOL.IS",
        "YKBNK.IS", "ISCTR.IS", "ARCLK.IS", "FROTO.IS", "TOASO.IS",
        "PETKM.IS", "KOZAL.IS", "KOZAA.IS", "PGSUS.IS", "TKFEN.IS",
        "VAKBN.IS", "HALKB.IS", "EKGYO.IS", "DOHOL.IS", "SOKM.IS",
        "SASA.IS", "HEKTS.IS", "ENKAI.IS", "TTKOM.IS", "TCELL.IS"
        // Bu liste 100'e tamamlanabilir, örnek olarak en likitler eklendi.
    };

    public Task<List<CoinDto>> GetAvailablePairsAsync()
    {
        var list = new List<CoinDto>();
        foreach (var symbol in Bist100Symbols)
        {
            list.Add(new CoinDto
            {
                Id = symbol,
                Symbol = symbol,
                BaseAsset = symbol.Replace(".IS", ""),
                QuoteAsset = "TRY",
                CurrentPrice = 0 // Fiyat canlı çekilmediği sürece 0 veya mock
            });
        }
        return Task.FromResult(list);
    }

    public Task<decimal> GetPriceAsync(string symbol)
    {
        return Task.FromResult(100m); // Mock price
    }

    public Task StartSocketConnection(IEnumerable<string> symbols)
    {
        return Task.CompletedTask;
    }
}
