using Kripteks.Core.Models.Strategy;

namespace Kripteks.Core.Interfaces;

public interface IStrategy
{
    string Id { get; }
    string Name { get; }
    string Description { get; }
    StrategyCategory Category { get; }

    void SetParameters(Dictionary<string, string> parameters);

    /// <summary>
    /// Mum verilerini analiz eder ve alım/satım sinyali döner.
    /// </summary>
    /// <param name="candles">Mum verileri (en eski → en yeni sıralı)</param>
    /// <param name="currentBalance">Kullanılabilir bakiye (USDT)</param>
    /// <param name="currentPositionAmount">Mevcut pozisyon miktarı (coin adedi). 0 ise pozisyon yok.</param>
    /// <param name="entryPrice">DCA stratejileri için ortalama maliyet; diğer stratejiler için ilk giriş fiyatı.</param>
    /// <param name="currentStep">DCA adım sayısı (kaç kez ek alım yapıldı). DCA dışı stratejilerde 0.</param>
    StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0);

    /// <summary>
    /// Sinyal gücünü hesaplar.
    /// 0 = Kesinlikle sinyal yok, 50 = Nötr/Belirsiz, 100 = Çok güçlü sinyal.
    /// Yetersiz veri durumunda 0 döner.
    /// </summary>
    decimal CalculateSignalScore(List<Candle> candles);
}
