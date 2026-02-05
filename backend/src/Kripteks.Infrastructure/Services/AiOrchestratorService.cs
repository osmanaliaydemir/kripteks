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
        var results = new List<(IAiProvider Provider, AiAnalysisResult Result, Exception? Error)>();

        foreach (var provider in providerList)
        {
            try
            {
                var result = await provider.AnalyzeTextAsync(text);
                results.Add((provider, result, null));
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "{Provider} analizi sırasında hata oluştu.", provider.ProviderName);
                results.Add((provider, null!, ex));
            }
        }

        var successfulResults = results.Where(r => r.Result != null).ToList();

        if (!successfulResults.Any())
        {
            var errors = string.Join(" | ", results.Select(r => $"{r.Provider.ProviderName}: {r.Error?.Message}"));
            throw new Exception($"Hiçbir AI servisi başarıyla yanıt vermedi. Hatalar: {errors}");
        }

        // Her sağlayıcının bireysel sonucunu kaydet
        var providerDetails = results.Select(r => new ProviderAnalysisResult
        {
            ProviderName = r.Provider.ProviderName,
            Score = r.Result?.SentimentScore ?? 0,
            Action = r.Result?.RecommendedAction ?? "ERROR",
            Summary = r.Result?.Summary ?? $"Hata: {r.Error?.Message}",
            Reasoning = text
        }).ToList();

        // Consensus Logic: Weighted Average of successful results
        float totalScore = successfulResults.Sum(r => r.Result.SentimentScore);
        float avgScore = totalScore / successfulResults.Count;

        // Determine action based on consensus score
        string action = "HOLD";
        if (avgScore > 0.5f) action = "BUY";
        else if (avgScore < -0.3f) action = "SELL";
        else if (avgScore < -0.7f) action = "PANIC SELL";

        _logger.LogInformation(
            "Multi-AI Konsensüs Tamamlandı. Başarılı Sağlayıcı Sayısı: {SuccessCount}/{TotalCount}, Ortalama Skor: {Score}",
            successfulResults.Count, providerList.Count, avgScore);

        return new AiAnalysisResult
        {
            SentimentScore = avgScore,
            RecommendedAction = action,
            Summary = successfulResults.First().Result.Summary,
            AnalyzedAt = DateTime.UtcNow,
            ProviderDetails = providerDetails
        };
    }


    public async Task<AiAnalysisResult> GetMarketSentimentAsync(string symbol = "BTC")
    {
        return await AnalyzeTextAsync($"Piyasa analizi: {symbol}");
    }
}
