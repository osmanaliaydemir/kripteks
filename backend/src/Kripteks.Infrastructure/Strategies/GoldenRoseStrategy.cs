using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Helpers;

namespace Kripteks.Infrastructure.Strategies;

public class GoldenRoseStrategy : IStrategy
{
    public string Id => "strategy-golden-rose";
    public string Name => "Golden Rose Trend Strategy";

    private int _sma1 = 111;
    private int _sma2 = 350;
    private decimal _tpMultiplier = 1.618m;
    private decimal _cycleTopMultiplier = 2m;

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters.TryGetValue("sma1", out var v1) && int.TryParse(v1, out var sma1)) _sma1 = sma1;
        if (parameters.TryGetValue("sma2", out var v2) && int.TryParse(v2, out var sma2)) _sma2 = sma2;
        if (parameters.TryGetValue("tp", out var vtp) && decimal.TryParse(vtp, out var tp)) _tpMultiplier = tp;
        if (parameters.TryGetValue("cycleTop", out var vct) && decimal.TryParse(vct, out var ct))
            _cycleTopMultiplier = ct;
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        var result = new StrategyResult();

        // Yeterli veri yoksa bekle (En büyük SMA kadar mum lazım)
        int maxSma = Math.Max(_sma1, _sma2);
        if (candles.Count < maxSma) return result;

        var prices = candles.Select(c => c.Close).ToList();

        // --- İNDİKATÖRLER (Pine Script'ten) ---
        // sma1 = sma(close, 111)
        // sma2 = sma(close, 350)
        var sma1List = TechnicalIndicators.CalculateSma(prices, _sma1);
        var sma2List = TechnicalIndicators.CalculateSma(prices, _sma2);

        // Son ve önceki değerler
        decimal? currentSma1 = sma1List.Last();
        decimal? currentSma2 = sma2List.Last();

        // Bir önceki mum değerleri (Kesişim kontrolü için)
        decimal? prevSma1 = sma1List[sma1List.Count - 2];
        decimal? prevSma2 = sma2List[sma2List.Count - 2];

        if (currentSma1 == null || currentSma2 == null || prevSma1 == null || prevSma2 == null)
            return result;

        decimal sma2 = currentSma2.Value;
        decimal sma1 = currentSma1.Value;

        // Fiyat verileri
        decimal currentPrice = candles.Last().Close;
        decimal prevPrice = candles[candles.Count - 2].Close;

        // Pine Script: x2 = sma2 * 2
        decimal x2 = sma2 * _cycleTopMultiplier;
        decimal prevX2 = prevSma2.Value * _cycleTopMultiplier;

        // --- ALIM MANTIĞI (BUY) ---
        // Alım için Trend Takibi kullanıyoruz: Fiyat SMA1'i yukarı kestiğinde.
        if (currentPositionAmount == 0)
        {
            // CrossOver: Önceki fiyat SMA1 altında veya eşit, Şu anki fiyat SMA1 üstünde
            bool priceCrossOverSma1 = prevPrice <= prevSma1.Value && currentPrice > sma1;

            // Alternatif Güvenli Giriş: Fiyat SMA2 üzerinde olmalı (Uzun vade trend)
            bool isAboveLongTrend = currentPrice > sma2;

            if (priceCrossOverSma1 && isAboveLongTrend)
            {
                // HEDEFLER (Golden Ratio Multipliers)
                // Hedef 1: Default 1.618 (Altın Oran)
                decimal targetPrice = sma2 * _tpMultiplier;

                // Eğer hedef çok yakınsa veya fiyat zaten oradaysa bir sonraki hedefi (x2) seç
                if (targetPrice <= currentPrice * 1.02m) targetPrice = sma2 * _cycleTopMultiplier;

                // STOP LOSS
                // Trend takibi: SMA1'in %3 altı
                decimal stopPrice = sma1 * 0.97m;

                result.Action = TradeAction.Buy;
                result.TargetPrice = targetPrice;
                result.StopPrice = stopPrice;
                result.Description =
                    $"ALIM: SMA{_sma1} Kırılımı (${sma1:F2}) -> Hedef: {_tpMultiplier}x (${targetPrice:F2})";
            }
        }
        else
        {
            // --- SATIŞ MANTIĞI (SELL) ---

            // 1. TOP DETECTED (Tepe Tespiti)
            // Pine Script: top_detected = crossunder(x2, sma1)
            // Anlamı: SMA1 çizgisi, (SMA2 * Mult) çizgisini YUKARIDAN AŞAĞIYA kestiğinde.
            bool topDetected = (prevSma1 > prevX2) && (sma1 <= x2);

            if (topDetected)
            {
                result.Action = TradeAction.Sell;
                result.Description = "SATIŞ: TEPE TESPİT EDİLDİ (Cycle Top Detected)!";
                return result;
            }

            // 2. Erken Çıkış / Trend Bozulması
            // Fiyat SMA1'in altına sarkarsa trend zayıflamıştır.
            if (currentPrice < sma1 * 0.98m)
            {
                result.Action = TradeAction.Sell;
                result.Description = $"SATIŞ: Trend Bozuldu (Fiyat < SMA{_sma1})";
            }
        }

        return result;
    }
}
