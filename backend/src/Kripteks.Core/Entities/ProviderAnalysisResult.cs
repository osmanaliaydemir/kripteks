namespace Kripteks.Core.Entities;

/// <summary>
/// Her bir AI sağlayıcısının bireysel analiz sonucunu temsil eder.
/// </summary>
public class ProviderAnalysisResult
{
    /// <summary>AI sağlayıcısının adı (örn: "DeepSeek R1", "Google Gemini 2.0")</summary>
    public string ProviderName { get; set; } = "";
    
    /// <summary>Duygu skoru: -1 (Bearish) ile 1 (Bullish) arasında</summary>
    public float Score { get; set; }
    
    /// <summary>Önerilen aksiyon: BUY, SELL, HOLD, PANIC SELL</summary>
    public string Action { get; set; } = "HOLD";
    
    /// <summary>Türkçe piyasa yorumu</summary>
    public string Summary { get; set; } = "";
    
    /// <summary>Analizin dayandığı veriler (örn: haber başlıkları)</summary>
    public string Reasoning { get; set; } = "";
}
