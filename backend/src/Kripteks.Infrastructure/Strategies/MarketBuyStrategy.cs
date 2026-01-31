using Kripteks.Core.Interfaces;

namespace Kripteks.Infrastructure.Strategies;

public class MarketBuyStrategy : IStrategy
{
    public string Name => "Hemen Al (Market Buy)";

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount)
    {
        var result = new StrategyResult();

        // Eğer pozisyonda değilsek -> HEMEN AL
        if (currentPositionAmount == 0)
        {
            result.Action = TradeAction.Buy;
            result.Description = "Kullanıcı isteği ile anında alım (Market Buy)";
            
            // Hemen Al modunda otomatik hedef/stop yoktur, kullanıcı manuel belirler.
            // Ancak boş dönmemek adına 0 veriyoruz, BotEngine manuel değerleri koruyacaktır.
            result.TargetPrice = 0; 
            result.StopPrice = 0;
        }
        else
        {
            // Pozisyondaysak -> Sinyal yok, TP/SL kuralları (BotEngine) çalışsın
            result.Action = TradeAction.None;
        }

        return result;
    }
}
