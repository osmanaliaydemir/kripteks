namespace Kripteks.Core.Entities;

public class Bot
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Symbol { get; set; } = string.Empty; // BTC/USDT
    public string StrategyName { get; set; } = string.Empty; // SMA_111
    public decimal Amount { get; set; }
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
}

public enum BotStatus
{
    Stopped,
    Running,        // Pozisyonda (Alım Yapılmış)
    Paused,
    Completed,
    WaitingForEntry // Sinyal Bekliyor (Henüz Alım Yapılmadı)
}
