namespace Kripteks.Core.Models.Strategy;

public class StrategyResult
{
    public TradeAction Action { get; set; } = TradeAction.None;
    public decimal TargetPrice { get; set; } // Hedef Fiyat (TP)
    public decimal StopPrice { get; set; } // Stop Fiyatı (SL)
    public decimal Amount { get; set; } // Önerilen miktar (DCA vb. için)
    public string Description { get; set; } = string.Empty; // "SMA111 Kırılımı" vb.
    public decimal Price { get; set; }
    public DateTime Time { get; set; }
    public Dictionary<string, object> Indicators { get; set; } = new();
}
