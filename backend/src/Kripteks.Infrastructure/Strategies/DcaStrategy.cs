using Kripteks.Core.Interfaces;

namespace Kripteks.Infrastructure.Strategies;

public class DcaStrategy : IStrategy
{
    public string Id => "strategy-dca";
    public string Name => "DCA Bot (Martingale)";

    public string Description =>
        "Dollar Cost Averaging (Maliyet Ortalaması) stratejisi. Fiyat ortalama maliyetin belirli bir yüzdesi altına düştüğünde kademeli ek alımlar yapar (varsayılan %2 aralıklarla, maks. 5 adım). Her adımda Martingale mantığıyla yatırım miktarı katlanır (1x→2x→4x→8x). Ortalama maliyetin %3 üzerinde kâr al, %15 altında zarar durdur hedefleri otomatik belirlenir.";

    public StrategyCategory Category => StrategyCategory.Trading;

    private int _maxDcaStep = 5;
    private decimal _priceDeviation = 2.0m; // %2 düşüşte ek alım
    private decimal _amountScale = 2.0m; // Her adımda yatırımı 2x katla
    private decimal _takeProfitPercent = 3.0m; // Ortalama maliyetin %3 üzerinde kâr al
    private decimal _stopLossPercent = 15.0m; // Ortalama maliyetin %15 altında zarar durdur

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters.TryGetValue("dcaCount", out var v1) && int.TryParse(v1, out var c)) _maxDcaStep = c;
        if (parameters.TryGetValue("priceDeviation", out var v2) && decimal.TryParse(v2, out var d))
            _priceDeviation = d;
        if (parameters.TryGetValue("amountScale", out var v3) && decimal.TryParse(v3, out var s)) _amountScale = s;
        if (parameters.TryGetValue("takeProfit", out var v4) && decimal.TryParse(v4, out var tp))
            _takeProfitPercent = tp;
        if (parameters.TryGetValue("stopLoss", out var v5) && decimal.TryParse(v5, out var sl))
            _stopLossPercent = sl;
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        var result = new StrategyResult();
        var currentPrice = candles.Last().Close;

        // ═══════════════════════════════════════════════
        // 1. POZİSYON YOK → İlk alım
        // ═══════════════════════════════════════════════
        if (currentPositionAmount == 0)
        {
            result.Action = TradeAction.Buy;
            result.TargetPrice = currentPrice * (1 + _takeProfitPercent / 100);
            result.StopPrice = currentPrice * (1 - _stopLossPercent / 100);
            result.Description = "DCA Başlangıç Alımı";
            return result;
        }

        // ═══════════════════════════════════════════════
        // 2. POZİSYON VAR → Kâr Al / Zarar Durdur / Ek Alım
        // entryPrice = BotEngine'den gelen ORTALAMA MALİYET
        // ═══════════════════════════════════════════════
        if (entryPrice <= 0)
        {
            result.Description = "DCA: Ortalama maliyet bilgisi bekleniyor";
            return result;
        }

        decimal pnlPercent = ((currentPrice - entryPrice) / entryPrice) * 100;

        // Kâr Al: Ortalama maliyetin üzerinde TP'ye ulaştıysa sat
        if (pnlPercent >= _takeProfitPercent)
        {
            result.Action = TradeAction.Sell;
            result.Description = $"DCA KÂR AL: %{pnlPercent:F2} kâr (Ortalama: ${entryPrice:F2})";
            return result;
        }

        // Zarar Durdur: Tüm DCA adımları tükendiyse ve hala düşüyorsa çık
        if (currentStep >= _maxDcaStep && pnlPercent <= -_stopLossPercent)
        {
            result.Action = TradeAction.Sell;
            result.Description =
                $"DCA STOP: Tüm adımlar tükendi, %{Math.Abs(pnlPercent):F2} zarar (Ortalama: ${entryPrice:F2})";
            return result;
        }

        // Ek Alım: Fiyat ortalama maliyetin deviation% altına düştüyse
        if (currentStep < _maxDcaStep)
        {
            // Her adım için kümülatif sapma: Step 0→-2%, Step 1→-4%, Step 2→-6%...
            decimal requiredDeviation = -_priceDeviation * (currentStep + 1);

            if (pnlPercent <= requiredDeviation)
            {
                // Martingale: Her adımda miktar katlanır (1x, 2x, 4x, 8x...)
                decimal scaleMultiplier = (decimal)Math.Pow((double)_amountScale, currentStep);
                result.Action = TradeAction.Buy;
                result.Amount = scaleMultiplier;
                result.TargetPrice = entryPrice * (1 + _takeProfitPercent / 100);
                result.StopPrice = entryPrice * (1 - _stopLossPercent / 100);
                result.Description =
                    $"DCA Adım {currentStep + 1}/{_maxDcaStep}: %{Math.Abs(pnlPercent):F2} düşüş, {scaleMultiplier}x alım";
            }
            else
            {
                result.Description =
                    $"DCA Bekleniyor: %{pnlPercent:F2} (Hedef: %{requiredDeviation:F1})";
            }
        }
        else
        {
            result.Description =
                $"DCA Tüm Adımlar Tamamlandı: %{pnlPercent:F2} PnL, TP bekleniyor";
        }

        return result;
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        // DCA her zaman nötr başlar; giriş zamanlaması stratejiye bağlı değil
        return 50;
    }
}
