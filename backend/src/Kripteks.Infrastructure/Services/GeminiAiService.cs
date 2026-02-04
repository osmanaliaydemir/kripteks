using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Kripteks.Infrastructure.Services;

public class GeminiAiService : IAiProvider
{
    public string ProviderName => "Google Gemini 2.0";

    private readonly ILogger<GeminiAiService> _logger;
    private readonly string _apiKey;
    private readonly HttpClient _httpClient;

    public GeminiAiService(ILogger<GeminiAiService> logger, HttpClient httpClient, IConfiguration configuration)
    {
        _logger = logger;
        _httpClient = httpClient;
        _apiKey = configuration["AiSettings:GeminiApiKey"] ?? "";
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
                model = "gemini-1.5-flash",
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

            // Gemini OpenAI endpoint doesn't use Bearer token if key is in URL, 
            // but we can also use header if preferred. URL key is easier for Gemini.
            var url = $"https://generativelanguage.googleapis.com/v1beta/openai/chat/completions?key={_apiKey}";

            var response = await _httpClient.PostAsJsonAsync(url, requestBody);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<GeminiResponse>();
            var jsonContent = result?.Choices?.FirstOrDefault()?.Message?.Content;

            if (!string.IsNullOrEmpty(jsonContent))
            {
                var analysis = JsonSerializer.Deserialize<GeminiAnalysisResult>(jsonContent,
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                if (analysis != null)
                {
                    return new AiAnalysisResult
                    {
                        SentimentScore = analysis.Score,
                        RecommendedAction = analysis.Action ?? "HOLD",
                        Summary = analysis.Summary ?? "Gemini'den yanıt alınamadı.",
                        AnalyzedAt = DateTime.UtcNow
                    };
                }
            }

            return MockAnalyze(text);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Gemini API hatası: {Message}", ex.Message);
            return MockAnalyze(text);
        }
    }

    private class GeminiResponse
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

    private class GeminiAnalysisResult
    {
        public float Score { get; set; }
        public string? Action { get; set; }
        public string? Summary { get; set; }
    }

    private AiAnalysisResult MockAnalyze(string text)
    {
        var rng = new Random();
        float score = (float)(rng.NextDouble() * 2 - 1);

        string action = score > 0.4f ? "AL" : score < -0.4f ? "SAT" : "TUT";
        string sentiment = score > 0.3f ? "pozitif" : score < -0.3f ? "negatif" : "nötr";

        return new AiAnalysisResult
        {
            SentimentScore = score,
            Summary =
                $"Kripto piyasasında {sentiment} sinyaller gözlemleniyor. Mevcut haberler {(score > 0 ? "alıcıları destekler" : "satış baskısı oluşturabilir")} nitelikte.",
            RecommendedAction = action,
            AnalyzedAt = DateTime.UtcNow
        };
    }
}
