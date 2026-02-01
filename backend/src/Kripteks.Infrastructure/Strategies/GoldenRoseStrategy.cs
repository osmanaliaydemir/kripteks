using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Helpers;

namespace Kripteks.Infrastructure.Strategies;

public class GoldenRoseStrategy : IStrategy
{
    public string Name => "Golden Rose Trend Strategy";

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount)
    {
        var result = new StrategyResult();

        // Yeterli veri yoksa bekle (Pine Script'te 350 mumluk SMA var)
        if (candles.Count < 350) return result;

        var prices = candles.Select(c => c.Close).ToList();

        // --- İNDİKATÖRLER (Pine Script'ten) ---
        // sma350 = sma(close, 350)
        // sma111 = sma(close, 111)
        var sma111List = TechnicalIndicators.CalculateSma(prices, 111);
        var sma350List = TechnicalIndicators.CalculateSma(prices, 350);

        // Son ve önceki değerler
        decimal? currentSma111 = sma111List.Last();
        decimal? currentSma350 = sma350List.Last();

        // Bir önceki mum değerleri (Kesişim kontrolü için)
        decimal? prevSma111 = sma111List[sma111List.Count - 2];
        decimal? prevSma350 = sma350List[sma350List.Count - 2];

        if (currentSma111 == null || currentSma350 == null || prevSma111 == null || prevSma350 == null)
            return result;

        decimal sma350 = currentSma350.Value;
        decimal sma111 = currentSma111.Value;

        // Fiyat verileri
        decimal currentPrice = candles.Last().Close;
        decimal prevPrice = candles[candles.Count - 2].Close;

        // Pine Script: x2 = sma350 * 2
        decimal x2 = sma350 * 2;
        decimal prevX2 = prevSma350.Value * 2;

        // --- ALIM MANTIĞI (BUY) ---
        // Pine Script aslında Top Detector (Satış) odaklıdır.
        // Alım için Trend Takibi kullanıyoruz: Fiyat SMA 111'i yukarı kestiğinde.
        if (currentPositionAmount == 0)
        {
            // CrossOver: Önceki fiyat SMA111 altında veya eşit, Şu anki fiyat SMA111 üstünde
            bool priceCrossOverSma111 = prevPrice <= prevSma111.Value && currentPrice > sma111;

            // Alternatif Güvenli Giriş: Fiyat SMA350 üzerinde olmalı (Uzun vade trend)
            bool isAboveLongTrend = currentPrice > sma350;

            if (priceCrossOverSma111 && isAboveLongTrend)
            {
                // HEDEFLER (Golden Ratio Multipliers)
                // Hedef 1: 1.618 (Altın Oran)
                decimal targetPrice = sma350 * 1.618m;

                // Eğer hedef çok yakınsa veya fiyat zaten oradaysa bir sonraki hedefi (x2) seç
                if (targetPrice <= currentPrice * 1.02m) targetPrice = sma350 * 2m;

                // STOP LOSS
                // Trend takibi: SMA 111'in %3 altı
                decimal stopPrice = sma111 * 0.97m;

                result.Action = TradeAction.Buy;
                result.TargetPrice = targetPrice;
                result.StopPrice = stopPrice;
                result.Description = $"ALIM: SMA111 Kırılımı (${sma111:F2}) -> Hedef: 1.618x (${targetPrice:F2})";
            }
        }
        else
        {
            // --- SATIŞ MANTIĞI (SELL) ---

            // 1. TOP DETECTED (Tepe Tespiti)
            // Pine Script: top_detected = crossunder(x2, sma111)
            // Anlamı: SMA 111 çizgisi, (SMA 350 * 2) çizgisini YUKARIDAN AŞAĞIYA kestiğinde.
            // Bu çok nadir ve büyük bir döngü tepesi sinyalidir.
            bool topDetected = (prevSma111 > prevX2) && (sma111 <= x2);

            if (topDetected)
            {
                result.Action = TradeAction.Sell;
                result.Description = "SATIŞ: TEPE TESPİT EDİLDİ (Cycle Top Detected)!";
                return result;
            }

            // 2. Erken Çıkış / Trend Bozulması
            // Fiyat SMA 111'in altına sarkarsa trend zayıflamıştır.
            if (currentPrice < sma111 * 0.98m)
            {
                result.Action = TradeAction.Sell;
                result.Description = "SATIŞ: Trend Bozuldu (Fiyat < SMA111)";
            }
        }

        return result;
    }
}
