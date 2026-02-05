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
            throw new InvalidOperationException(
                "DeepSeek API anahtarı ayarlanmamış. Lütfen appsettings.json dosyasını kontrol edin.");
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

            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                throw new Exception($"DeepSeek API Hatası ({response.StatusCode}): {errorBody}");
            }

            var result = await response.Content.ReadFromJsonAsync<DeepSeekResponse>();
            var jsonContent = result?.Choices?.FirstOrDefault()?.Message?.Content;

            if (string.IsNullOrEmpty(jsonContent))
            {
                throw new Exception("DeepSeek API'den boş yanıt döndü.");
            }

            var analysis = JsonSerializer.Deserialize<DeepSeekAnalysisResult>(jsonContent,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            if (analysis == null)
            {
                throw new Exception("DeepSeek yanıtı parse edilemedi.");
            }

            return new AiAnalysisResult
            {
                SentimentScore = analysis.Score,
                RecommendedAction = analysis.Action ?? "HOLD",
                Summary = analysis.Summary ?? "Analiz özeti alınamadı.",
                AnalyzedAt = DateTime.UtcNow
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DeepSeek API hatası: {Message}", ex.Message);
            throw;
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
        throw new NotImplementedException(
            "Market sentiment direct call is not supported. Use orchestrator with news text.");
    }
}

