namespace Kripteks.Core.Entities;

public class NewsItem
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Title { get; set; } = string.Empty;
    public string Summary { get; set; } = string.Empty;
    public string Source { get; set; } = string.Empty; // "CryptoPanic", "Twitter" etc.
    public string Url { get; set; } = string.Empty;
    public DateTime PublishedAt { get; set; }
    
    // AI Analysis
    public float SentimentScore { get; set; } // -1 to 1
    public string AiSummary { get; set; } = string.Empty;
    public bool IsAnalyzed { get; set; } = false;
}
