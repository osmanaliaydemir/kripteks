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
            throw new InvalidOperationException("Gemini API anahtarı ayarlanmamış.");
        }

        try
        {
            var prompt =
                $@"Sen deneyimli bir kripto piyasa analistisin. Verilen haber başlıklarını analiz et ve piyasa duyarlılığını değerlendir. 
yanıtını SADECE şu JSON formatında ver, markdown kullanma: 
{{""score"": float (-1.0 çok olumsuz, 0 nötr, 1.0 çok olumlu), ""action"": ""AL|TUT|SAT|PANİK SAT"", ""summary"": ""Türkçe detaylı piyasa yorumu (en az 2 cümle)""}}

Analiz edilecek haberler: {text}";

            var requestBody = new
            {
                contents = new[]
                {
                    new
                    {
                        parts = new[]
                        {
                            new { text = prompt }
                        }
                    }
                },
                generationConfig = new
                {
                    response_mime_type = "application/json"
                }
            };

            var url =
                $"https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key={_apiKey}";

            var response = await _httpClient.PostAsJsonAsync(url, requestBody);

            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                throw new Exception($"Gemini API Hatası ({response.StatusCode}): {errorBody}");
            }

            var result = await response.Content.ReadFromJsonAsync<GeminiNativeResponse>();
            var jsonContent = result?.Candidates?.FirstOrDefault()?.Content?.Parts?.FirstOrDefault()?.Text;

            if (string.IsNullOrEmpty(jsonContent))
            {
                throw new Exception("Gemini API'den boş yanıt döndü.");
            }

            // Temizlik (Markdown ```json ... ``` varsa kaldır)
            jsonContent = jsonContent.Replace("```json", "").Replace("```", "").Trim();

            var analysis = JsonSerializer.Deserialize<GeminiAnalysisResult>(jsonContent,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

            if (analysis == null) throw new Exception("Gemini yanıtı parse edilemedi.");

            return new AiAnalysisResult
            {
                SentimentScore = analysis.Score,
                RecommendedAction = analysis.Action ?? "HOLD",
                Summary = analysis.Summary ?? "Gemini verisi alındı.",
                AnalyzedAt = DateTime.UtcNow
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Gemini API hatası");
            throw;
        }
    }

    private class GeminiNativeResponse
    {
        [JsonPropertyName("candidates")] public List<Candidate>? Candidates { get; set; }
    }

    private class Candidate
    {
        [JsonPropertyName("content")] public Content? Content { get; set; }
    }

    private class Content
    {
        [JsonPropertyName("parts")] public List<Part>? Parts { get; set; }
    }

    private class Part
    {
        [JsonPropertyName("text")] public string? Text { get; set; }
    }

    private class GeminiAnalysisResult
    {
        public float Score { get; set; }
        public string? Action { get; set; }
        public string? Summary { get; set; }
    }
}

