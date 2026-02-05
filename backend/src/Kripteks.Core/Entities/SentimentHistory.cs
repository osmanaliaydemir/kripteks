namespace Kripteks.Core.Entities;

/// <summary>
/// Saatlik/dakikalık sentiment skorlarını saklar
/// </summary>
public class SentimentHistory
{
    public int Id { get; set; }
    
    /// <summary>Duygu skoru: -1 (Bearish) ile 1 (Bullish) arasında</summary>
    public float Score { get; set; }
    
    /// <summary>Önerilen aksiyon: BUY, SELL, HOLD, PANIC SELL</summary>
    public string Action { get; set; } = "HOLD";
    
    /// <summary>Analiz yapılan coin sembolü</summary>
    public string Symbol { get; set; } = "BTC";
    
    /// <summary>Konsensüs özeti</summary>
    public string Summary { get; set; } = "";
    
    /// <summary>Kaydedilme zamanı</summary>
    public DateTime RecordedAt { get; set; } = DateTime.UtcNow;
    
    /// <summary>Analizi yapan AI model sayısı</summary>
    public int ModelCount { get; set; } = 2;
}
