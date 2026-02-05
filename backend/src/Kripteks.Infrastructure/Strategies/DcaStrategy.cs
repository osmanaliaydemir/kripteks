using Kripteks.Core.Interfaces;

namespace Kripteks.Infrastructure.Strategies;

public class DcaStrategy : IStrategy
{
    public string Id => "strategy-dca";
    public string Name => "DCA Bot (Martingale)";

    private int _maxDcaStep = 5;
    private decimal _priceDeviation = 2.0m; // %2 düşüşte al
    private decimal _amountScale = 2.0m; // Yatırımı 2 katına çıkar

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters.TryGetValue("dcaCount", out var v1) && int.TryParse(v1, out var c)) _maxDcaStep = c;
        if (parameters.TryGetValue("priceDeviation", out var v2) && decimal.TryParse(v2, out var d))
            _priceDeviation = d;
        if (parameters.TryGetValue("amountScale", out var v3) && decimal.TryParse(v3, out var s)) _amountScale = s;
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        var result = new StrategyResult();
        var currentPrice = candles.Last().Close;

        // Pozisyon yoksa hemen al (Basit başlangıç)
        // Veya RSI < 30 vb ekleyebiliriz ama DCA genelde hemen başlar.
        if (currentPositionAmount == 0)
        {
            result.Action = TradeAction.Buy;
            result.Description = "DCA Başlangıç Alımı";
            result.TargetPrice = currentPrice * 1.01m; // Kar al hedefi (Değişken olabilir)
            return result;
        }

        // Pozisyon varsa ve limit dolmadıysa düşüşlerde tekrar al
        if (currentStep < _maxDcaStep && entryPrice > 0)
        {
            // Ortalamadan ne kadar düştü?
            decimal deviation = ((currentPrice - entryPrice) / entryPrice) * 100;

            // Her adımda deviation artabilir (Örn: -2, -4, -6...)
            // Şimdilik lineer artış: Step 1 (-2%), Step 2 (-4%)
            // Şu anki adım 1 ise (yani 1 kez ek yapmışsak), bir sonraki hedef 2 * deviation

            decimal
                targetDeviation = -1 * _priceDeviation; // Hep sabit deviation kullanalım: Ortalamadan -%2 düştükçe al.
            // Ama ortalama düştükçe, yeni alım fiyatı da düşecek.
            // Martingale mantığı: Ortalama maliyetin X% altına düştükçe al.

            if (deviation <= targetDeviation)
            {
                result.Action = TradeAction.Buy;
                result.Description = $"DCA Step {currentStep + 1}: Ortalamadan %{Math.Abs(deviation):F2} düştü.";

                // Önerilen miktar: Mevcut pozisyonun X katı veya sabit scale
                // Genelde DCA: 1x, 2x, 4x, 8x... (Martingale)
                // currentPositionAmount bize "adet" veya "USD tutar" olarak gelmeli.
                // Interface'de "decimal currentPositionAmount" var. Bu Bot.Amount (USD) mi yoksa Quantity mi?
                // BotEngineService içinde: strategy.Analyze(candles, 0, bot.Amount / bot.EntryPrice);
                // Yani Quantity gönderiliyor gibi. (Amount / Price = Quantity)
                // Ama DCA genelde Amount üzerinden hesaplanır.
                // Biz basitçe: Botun ana parası (bot.Amount) bu stratejide "Toplam Yatırılan" olduğu için
                // Bir sonraki adımda ne kadar yatırılacağını hesaplayalım.
                // Ancak burada "currentPositionAmount" parametresinin aslında "Mevcut Yatırım Tutarı (USD)" olması daha mantıklı olurdu.
                // BotEngineService tarafını güncelleyip buraya "bot.Amount" (Toplam maliyet) göndermek daha iyi.

                result.Amount = currentPositionAmount * _amountScale; // Şimdilik gelen değeri scale edelim.
            }
        }

        // Pozisyon varsa ve Engine DCA kontrolü yapıyorsa:
        // Engine tarafında ortalama maliyete göre % düşüş hesaplanıp buraya parametre veya logic aktarılmalı
        // Ancak Interface gereği sadece 'candles' ve 'currentPositionAmount' alıyoruz.
        // Ortalama maliyeti bilmiyoruz!
        // Bu durumda IStrategy interface'ini 'AverageEntryPrice' alacak şekilde güncellememiz lazım
        // VEYA Engine tarafında bu hesabı yapıp, buraya "CurrentPnlPercent" verisi gibi bir şey geçmeliyiz.
        // Şimdilik BotEngineService içindeki CheckExitSignalAndPnl metodunda,
        // PNL negatif ise ve strateji DCA ise, tekrar Analyze çağırmak yerine direkt logic işletilebilir
        // VEYA IStrategy'yi güncelleyelim.

        return result;
    }

    public decimal CalculateSignalScore(List<Candle> candles) => 50; // Neutral for DCA
}
