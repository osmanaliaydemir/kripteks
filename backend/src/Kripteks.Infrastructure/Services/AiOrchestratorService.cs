using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class AiOrchestratorService : IAiService
{
    private readonly IEnumerable<IAiProvider> _providers;
    private readonly ILogger<AiOrchestratorService> _logger;

    public AiOrchestratorService(IEnumerable<IAiProvider> providers, ILogger<AiOrchestratorService> logger)
    {
        _providers = providers;
        _logger = logger;
    }

    public async Task<AiAnalysisResult> AnalyzeTextAsync(string text)
    {
        var providerList = _providers.ToList();
        var tasks = providerList.Select(p => p.AnalyzeTextAsync(text)).ToList();
        var results = await Task.WhenAll(tasks);

        if (!results.Any())
        {
            return new AiAnalysisResult
                { Summary = "Hiçbir AI servisinden yanıt alınamadı.", RecommendedAction = "HOLD" };
        }

        // Her sağlayıcının bireysel sonucunu kaydet
        var providerDetails = new List<ProviderAnalysisResult>();
        for (int i = 0; i < providerList.Count; i++)
        {
            var provider = providerList[i];
            var result = results[i];
            providerDetails.Add(new ProviderAnalysisResult
            {
                ProviderName = provider.ProviderName,
                Score = result.SentimentScore,
                Action = result.RecommendedAction,
                Summary = result.Summary,
                Reasoning = text // Analiz edilen metin (haber başlıkları)
            });
        }

        // Consensus Logic: Weighted Average
        float totalScore = results.Sum(r => r.SentimentScore);
        float avgScore = totalScore / results.Length;

        // Determine action based on consensus score
        string action = "HOLD";
        if (avgScore > 0.5f) action = "BUY";
        else if (avgScore < -0.7f) action = "PANIC SELL";
        else if (avgScore < -0.3f) action = "SELL";

        _logger.LogInformation("Multi-AI Konsensüs Tamamlandı. Sağlayıcı Sayısı: {Count}, Ortalama Skor: {Score}",
            results.Length, avgScore);

        return new AiAnalysisResult
        {
            SentimentScore = avgScore,
            RecommendedAction = action,
            Summary = results.First().Summary,
            AnalyzedAt = DateTime.UtcNow,
            ProviderDetails = providerDetails
        };
    }

    public async Task<AiAnalysisResult> GetMarketSentimentAsync(string symbol = "BTC")
    {
        return await AnalyzeTextAsync($"Piyasa analizi: {symbol}");
    }
}
