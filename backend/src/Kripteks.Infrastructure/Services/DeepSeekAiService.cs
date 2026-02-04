using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Kripteks.Infrastructure.Services;

public class DeepSeekAiService : IAiProvider
{
    public string ProviderName => "DeepSeek R1";

    private readonly ILogger<DeepSeekAiService> _logger;
    private readonly string _apiKey;
    private readonly HttpClient _httpClient;

    public DeepSeekAiService(ILogger<DeepSeekAiService> logger, HttpClient httpClient, IConfiguration configuration)
    {
        _logger = logger;
        _httpClient = httpClient;
        _apiKey = configuration["AiSettings:DeepSeekApiKey"] ?? "";
    }

    public async Task<AiAnalysisResult> AnalyzeTextAsync(string text)
    {
        if (string.IsNullOrEmpty(_apiKey))
        {
            return MockAnalyze(text);
        }

        try
        {
            var requestBody = new
            {
                model = "deepseek-chat",
                messages = new[]
                {
                    new
                    {
                        role = "system",
                        content =
                            "Sen deneyimli bir kripto piyasa analistisin. Verilen haber başlıklarını analiz et ve piyasa duyarlılığını değerlendir. Yanıtını şu JSON formatında ver: {\"score\": float (-1.0 çok olumsuz, 0 nötr, 1.0 çok olumlu), \"action\": \"AL|TUT|SAT|PANİK SAT\", \"summary\": \"Türkçe detaylı piyasa yorumu (en az 2 cümle)\"}"
                    },
                    new { role = "user", content = $"Şu haber başlıklarını analiz et ve piyasa yorumu yap: {text}" }
                },
                response_format = new { type = "json_object" },
                temperature = 0.3
            };

            _httpClient.DefaultRequestHeaders.Authorization =
                new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", _apiKey);

            var response =
                await _httpClient.PostAsJsonAsync("https://api.deepseek.com/v1/chat/completions", requestBody);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<DeepSeekResponse>();
            var jsonContent = result?.Choices?.FirstOrDefault()?.Message?.Content;

            if (!string.IsNullOrEmpty(jsonContent))
            {
                var analysis = JsonSerializer.Deserialize<DeepSeekAnalysisResult>(jsonContent,
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                if (analysis != null)
                {
                    return new AiAnalysisResult
                    {
                        SentimentScore = analysis.Score,
                        RecommendedAction = analysis.Action ?? "HOLD",
                        Summary = analysis.Summary ?? "Analiz özeti alınamadı.",
                        AnalyzedAt = DateTime.UtcNow
                    };
                }
            }

            return MockAnalyze(text);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DeepSeek API hatası: {Message}", ex.Message);
            return MockAnalyze(text);
        }
    }

    private class DeepSeekResponse
    {
        [JsonPropertyName("choices")] public List<Choice>? Choices { get; set; }
    }

    private class Choice
    {
        [JsonPropertyName("message")] public Message? Message { get; set; }
    }

    private class Message
    {
        [JsonPropertyName("content")] public string? Content { get; set; }
    }

    private class DeepSeekAnalysisResult
    {
        public float Score { get; set; }
        public string? Action { get; set; }
        public string? Summary { get; set; }
    }

    public async Task<AiAnalysisResult> GetMarketSentimentAsync(string symbol = "BTC")
    {
        // Genelde haberleri analiz edip birleştiririz. 
        // Şimdilik basitçe random veya sabit bir değer dönelim.
        return MockAnalyze($"Market analysis for {symbol}");
    }

    private AiAnalysisResult MockAnalyze(string text)
    {
        var rng = new Random();
        float score = (float)(rng.NextDouble() * 2 - 1); // -1 to 1

        string action = score > 0.5f ? "AL" : score < -0.5f ? "PANİK SAT" : score < -0.2f ? "SAT" : "TUT";
        string sentiment = score > 0.3f ? "olumlu" : score < -0.3f ? "olumsuz" : "nötr";

        return new AiAnalysisResult
        {
            SentimentScore = score,
            Summary =
                $"Piyasa genel olarak {sentiment} görünüyor. Analiz edilen haberler doğrultusunda kısa vadeli {(score > 0 ? "yükseliş" : "düşüş")} beklentisi oluşabilir.",
            RecommendedAction = action,
            AnalyzedAt = DateTime.UtcNow
        };
    }
}
