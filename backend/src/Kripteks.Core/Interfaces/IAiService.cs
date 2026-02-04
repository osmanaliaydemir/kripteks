using Kripteks.Core.Entities;

namespace Kripteks.Core.Interfaces;

public interface IAiService
{
    // Metni analiz et ve skorla
    Task<AiAnalysisResult> AnalyzeTextAsync(string text);
    
    // Belirli bir sembol için genel piyasa duygu durumunu getir (Cache'den veya taze)
    Task<AiAnalysisResult> GetMarketSentimentAsync(string symbol = "BTC");
}
