namespace Kripteks.Core.Entities;

/// <summary>
/// Kullanıcının portföyündeki her bir coin'i temsil eder.
/// Bot alımlarından otomatik olarak hesaplanır.
/// </summary>
public class PortfolioAsset
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    public string Symbol { get; set; } = string.Empty;       // "BTCUSDT"
    public string BaseAsset { get; set; } = string.Empty;     // "BTC"
    public string QuoteAsset { get; set; } = "USDT";          // "USDT"
    
    public decimal Quantity { get; set; }                      // Toplam adet
    public decimal AverageCost { get; set; }                   // Ortalama maliyet (USDT)
    public decimal TotalInvested { get; set; }                 // Toplam yatırım
    
    public DateTime FirstBuyDate { get; set; } = DateTime.UtcNow;
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
}
