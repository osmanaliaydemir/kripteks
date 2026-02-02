namespace Kripteks.Core.Interfaces;

public enum TradeAction
{
    None, // İşlem yok
    Buy, // Alım Sinyali
    Sell // Satış Sinyali (TP veya SL)
}

public class StrategyResult
{
    public TradeAction Action { get; set; } = TradeAction.None;
    public decimal TargetPrice { get; set; } // Hedef Fiyat (TP)
    public decimal StopPrice { get; set; } // Stop Fiyatı (SL)
    public string Description { get; set; } = string.Empty; // "SMA111 Kırılımı" vb.
}

public interface IStrategy
{
    string Name { get; }

    void SetParameters(Dictionary<string, string> parameters);

    // Mum verilerini alır, analiz eder ve sinyal döner
    StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount);
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
