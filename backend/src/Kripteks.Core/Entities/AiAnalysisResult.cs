namespace Kripteks.Core.Entities;

public class AiAnalysisResult
{
    public float SentimentScore { get; set; } // -1 (Bearish) to 1 (Bullish)
    public string Summary { get; set; } = string.Empty;
    public string RecommendedAction { get; set; } = "HOLD"; // BUY, SELL, HOLD, PANIC
    public DateTime AnalyzedAt { get; set; } = DateTime.UtcNow;

    /// <summary>Her AI sağlayıcısının bireysel analiz sonuçları</summary>
    public List<ProviderAnalysisResult> ProviderDetails { get; set; } = new();
}
