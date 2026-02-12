namespace Kripteks.Core.DTOs;

/// <summary>
/// Portföy genel özet bilgisi.
/// </summary>
public class PortfolioSummaryDto
{
    public decimal TotalValue { get; set; }              // Toplam portföy değeri (USDT)
    public decimal TotalInvested { get; set; }           // Toplam yatırılan
    public decimal TotalPnl { get; set; }                // Toplam kar/zarar
    public decimal TotalPnlPercent { get; set; }         // Toplam kar/zarar %
    public decimal DailyPnl { get; set; }                // Günlük değişim
    public decimal DailyPnlPercent { get; set; }         // Günlük %
    public int AssetCount { get; set; }                  // Farklı coin sayısı
    public List<PortfolioAssetDto> Assets { get; set; } = [];
    public PortfolioRiskMetricsDto RiskMetrics { get; set; } = new();
    public List<RebalanceSuggestionDto> RebalanceSuggestions { get; set; } = [];
}

/// <summary>
/// Portföydeki tek bir asset'in detayları.
/// </summary>
public class PortfolioAssetDto
{
    public string Symbol { get; set; } = string.Empty;       // "BTCUSDT"
    public string BaseAsset { get; set; } = string.Empty;    // "BTC"
    public decimal Quantity { get; set; }                     // Adet
    public decimal AverageCost { get; set; }                  // Ortalama maliyet
    public decimal CurrentPrice { get; set; }                 // Anlık fiyat
    public decimal CurrentValue { get; set; }                 // Anlık değer (Quantity * CurrentPrice)
    public decimal TotalInvested { get; set; }                // Toplam yatırım
    public decimal Pnl { get; set; }                          // Kar/Zarar USDT
    public decimal PnlPercent { get; set; }                   // Kar/Zarar %
    public decimal AllocationPercent { get; set; }            // Portföy içindeki pay %
    public decimal DailyChange { get; set; }                  // 24s değişim %
    public DateTime FirstBuyDate { get; set; }
}

/// <summary>
/// Portföy risk metrikleri.
/// </summary>
public class PortfolioRiskMetricsDto
{
    /// <summary>Riske göre düzeltilmiş getiri (tüm volatilite).</summary>
    public decimal SharpeRatio { get; set; }

    /// <summary>Riske göre düzeltilmiş getiri (sadece aşağı yönlü volatilite).</summary>
    public decimal SortinoRatio { get; set; }

    /// <summary>BTC'ye göre korelasyon katsayısı.</summary>
    public decimal Beta { get; set; }

    /// <summary>Zirveden en büyük düşüş yüzdesi.</summary>
    public decimal MaxDrawdown { get; set; }

    /// <summary>Portföy yoğunlaşma riski (Herfindahl-Hirschman Index). 0-1, yüksek = yoğun.</summary>
    public decimal ConcentrationRisk { get; set; }

    /// <summary>Portföy oynaklığı (standart sapma).</summary>
    public decimal Volatility { get; set; }

    /// <summary>Risk seviyesi metni: Düşük / Orta / Yüksek.</summary>
    public string RiskLevel { get; set; } = "Orta";
}

/// <summary>
/// Portföy dengeleme (rebalancing) önerisi.
/// </summary>
public class RebalanceSuggestionDto
{
    public string Symbol { get; set; } = string.Empty;
    public string BaseAsset { get; set; } = string.Empty;
    public decimal CurrentPercent { get; set; }     // Mevcut ağırlık %
    public decimal TargetPercent { get; set; }      // Hedef ağırlık %
    public decimal DeltaPercent { get; set; }       // Fark %
    public string Action { get; set; } = string.Empty; // "BUY" veya "SELL"
    public decimal SuggestedAmountUsdt { get; set; } // Önerilen işlem tutarı (USDT)
    public string Reason { get; set; } = string.Empty;
}
