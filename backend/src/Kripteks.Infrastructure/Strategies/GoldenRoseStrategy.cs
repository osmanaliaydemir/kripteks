using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Helpers;

namespace Kripteks.Infrastructure.Strategies;

public class GoldenRoseStrategy : IStrategy
{
    public string Name => "Golden Rose Trend Strategy";

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount)
    {
        var result = new StrategyResult();
        
        // Yeterli veri yoksa bekle
        if (candles.Count < 350) return result;

        var prices = candles.Select(c => c.Close).ToList();
        
        // SMA Hesaplamaları
        var sma111 = TechnicalIndicators.CalculateSma(prices, 111);
        var sma200 = TechnicalIndicators.CalculateSma(prices, 200);
        var sma350 = TechnicalIndicators.CalculateSma(prices, 350);

        // Son anlık veriler
        var currentPrice = candles.Last().Close;
        var prevPrice = candles[candles.Count - 2].Close;
        
        decimal? lastSma111 = sma111.Last();
        decimal? lastSma200 = sma200.Last();
        decimal? lastSma350 = sma350.Last();
        decimal? prevSma111 = sma111[sma111.Count - 2];

        if (lastSma111 == null || lastSma200 == null || lastSma350 == null) return result;

        // --- ALIM MANTIĞI ---
        if (currentPositionAmount == 0) // Nakitteyiz, alış arıyoruz
        {
            // Senaryo: Fiyat SMA 111'i Yukarı Kesti (Kullanıcı Talebi: "İlk Mum Kapanışı")
            bool crossOverSma111 = prevPrice <= prevSma111 && currentPrice > lastSma111;

            if (crossOverSma111) // Şartlar sağlandı mı?
            {
                // HEDEF (Golden Rose): SMA 350 * 1.618
                // TradingView görselindeki formül: Sarı Çizgi (SMA350) * 1.618
                decimal targetPrice = lastSma350.Value * 1.618m;
                
                // Eğer SMA350 fiyatın çok üzerindeyse (Düşüş trendi), hedef çok yukarıda kalabilir.
                // Bu durumda mantıken SMA111 * 1.618 de kullanılabilir ama görsele sadık kalıyoruz.
                // Eğer hedef fiyat giriş fiyatının altındaysa (SMA350 çok aşağıdaysa), bu işlem mantıksız olur.
                if (targetPrice <= currentPrice) 
                {
                    // Fallback: Hedef girişin altındaysa, girişin %10 yukarısı olsun
                   targetPrice = currentPrice * 1.10m;
                }

                // STOP LOSS: SMA 111'in biraz altı veya %5 stop
                // Trend takibi olduğu için SMA 111 altına inerse stop olmak mantıklı
                decimal stopPrice = lastSma111.Value * 0.97m; // SMA 111'in %3 altı

                result.Action = TradeAction.Buy;
                result.TargetPrice = targetPrice;
                result.StopPrice = stopPrice;
                result.Description = $"Alım: SMA111 Kırılımı (${lastSma111:F2}) -> Hedef: GR (${targetPrice:F2})";
            }
        }
        else 
        {
            // --- SATIŞ MANTIĞI ---
            // 1. Hedefe Ulaşma zaten BacktestService (Engine) tarafından kontrol ediliyor (TargetPrice)
            // 2. Stop Olma da Engine tarafından kontrol ediliyor (StopPrice)
            
            // Ekstra Çıkış Kuralı: Eğer trend bozulursa (Fiyat SMA 111 altına sert inerse)
            if (currentPrice < lastSma111.Value * 0.98m)
            {
                result.Action = TradeAction.Sell;
                result.Description = "Satış: Fiyat SMA111 altına sarktı (Trend Bitti)";
            }
        }

        return result;
    }
}
