namespace Kripteks.Core.Entities;

public class Trade
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid BotId { get; set; }
    public string Symbol { get; set; } = string.Empty;
    public TradeType Type { get; set; }
    public decimal Price { get; set; }
    public decimal Quantity { get; set; }
    public decimal Total { get; set; } // Fee dahil net tutar
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public Bot Bot { get; set; } = null!;
}

public enum TradeType
{
    Buy,
    Sell
}
