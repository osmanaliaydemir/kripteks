namespace Kripteks.Core.Entities;

public class Bot
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Symbol { get; set; } = string.Empty; // BTC/USDT
    public string StrategyName { get; set; } = string.Empty; // SMA_111
    public decimal Amount { get; set; }
    public string Interval { get; set; } = "1h"; // 1m, 5m, 15m, 1h, 4h, 1d
    public decimal? StopLoss { get; set; }
    public decimal? TakeProfit { get; set; }
    public BotStatus Status { get; set; } = BotStatus.Stopped;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Yeni Alanlar
    public decimal EntryPrice { get; set; } // İşleme Giriş Fiyatı
    public decimal CurrentPnl { get; set; } // Anlık Kar/Zarar (USDT)
    public decimal CurrentPnlPercent { get; set; } // Anlık Kar/Zarar (%)

    // Navigation Properties
    public List<Trade> Trades { get; set; } = new();
    public List<Log> Logs { get; set; } = new();

    // Trailing Stop Alanları
    public bool IsTrailingStop { get; set; } = false;
    public decimal? TrailingStopDistance { get; set; } // % cinsinden (Örn: 2)
    public decimal? MaxPriceReached { get; set; } // Takip edilen en yüksek fiyat
    public bool IsArchived { get; set; } = false;
    public string? StrategyParams { get; set; } // JSON formatlı strateji parametreleri
    public int CurrentDcaStep { get; set; } = 0; // Mevcut DCA kademesi

    // Emir Tipi
    public OrderType OrderType { get; set; } = OrderType.Market;
}

public enum BotStatus
{
    Stopped,
    Running, // Pozisyonda (Alım Yapılmış)
    Paused,
    Completed,
    WaitingForEntry // Sinyal Bekliyor (Henüz Alım Yapılmadı)
}

public enum OrderType
{
    Market,
    Limit
}
