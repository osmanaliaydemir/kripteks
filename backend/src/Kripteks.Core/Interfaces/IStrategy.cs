namespace Kripteks.Core.Interfaces;

public enum TradeAction
{
    None, // İşlem yok
    Buy, // Alım Sinyali
    Sell // Satış Sinyali (TP veya SL)
}

public enum StrategyCategory
{
    Simulation, // Simülasyon & backtesting
    Trading, // Canlı bot trading
    Scanner, // Piyasa tarama
    Both // Tüm alanlar
}

public class StrategyResult
{
    public TradeAction Action { get; set; } = TradeAction.None;
    public decimal TargetPrice { get; set; } // Hedef Fiyat (TP)
    public decimal StopPrice { get; set; } // Stop Fiyatı (SL)
    public decimal Amount { get; set; } // Önerilen miktar (DCA vb. için)
    public string Description { get; set; } = string.Empty; // "SMA111 Kırılımı" vb.
}

public interface IStrategy
{
    string Id { get; }
    string Name { get; }
    string Description { get; }
    StrategyCategory Category { get; }

    void SetParameters(Dictionary<string, string> parameters);

    // Mum verilerini alır, analiz eder ve sinyal döner
    StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0);

    // Sinyal gücünü hesaplar (0-100 arası skor)
    decimal CalculateSignalScore(List<Candle> candles);
}

// Mum verisi için basit bir model (Eğer yoksa)
public class Candle
{
    public DateTime OpenTime { get; set; }
    public decimal Open { get; set; }
    public decimal High { get; set; }
    public decimal Low { get; set; }
    public decimal Close { get; set; }
    public decimal Volume { get; set; }
}
