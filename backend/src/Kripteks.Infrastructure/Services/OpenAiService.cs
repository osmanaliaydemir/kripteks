using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace Kripteks.Infrastructure.Services;

/// <summary>
/// OpenAI GPT-4o tabanlı AI analiz servisi
/// </summary>
public class OpenAiService : IAiProvider
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<OpenAiService> _logger;
    private readonly string _apiKey;

    public string ProviderName => "OpenAI GPT-4o";

    public OpenAiService(HttpClient httpClient, ILogger<OpenAiService> logger, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _logger = logger;
        _apiKey = configuration["AiSettings:OpenAiApiKey"] ?? "";
    }

    public async Task<AiAnalysisResult> AnalyzeTextAsync(string text)
    {
        if (string.IsNullOrEmpty(_apiKey))
        {
            throw new InvalidOperationException(
                "OpenAI API anahtarı ayarlanmamış. Lütfen appsettings.json dosyasını kontrol edin.");
        }

        try
        {
            _httpClient.DefaultRequestHeaders.Clear();
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);

            var requestBody = new
            {
                model = "gpt-4o-mini",
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
                temperature = 0.3,
                max_tokens = 500
            };

            var json = JsonSerializer.Serialize(requestBody);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync("https://api.openai.com/v1/chat/completions", content);

            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                throw new Exception($"OpenAI API Hatası ({response.StatusCode}): {errorBody}");
            }

            var responseJson = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(responseJson);
            var messageContent = doc.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString() ?? "";

            if (string.IsNullOrEmpty(messageContent))
            {
                throw new Exception("OpenAI API'den boş yanıt döndü.");
            }

            // Parse the AI response
            using var aiResponse = JsonDocument.Parse(messageContent);
            var score = aiResponse.RootElement.GetProperty("score").GetSingle();
            var action = aiResponse.RootElement.GetProperty("action").GetString() ?? "TUT";
            var summary = aiResponse.RootElement.GetProperty("summary").GetString() ?? "";

            _logger.LogInformation("OpenAI analizi tamamlandı: Skor={Score}, Aksiyon={Action}", score, action);

            return new AiAnalysisResult
            {
                SentimentScore = score,
                Summary = summary,
                RecommendedAction = action,
                AnalyzedAt = DateTime.UtcNow
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "OpenAI analiz hatası.");
            throw;
        }
    }

    public async Task<string> TranslateTextAsync(string text, string targetLanguage)
    {
        if (string.IsNullOrEmpty(_apiKey)) return text;

        try
        {
            _httpClient.DefaultRequestHeaders.Clear();
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);

            var requestBody = new
            {
                model = "gpt-4o-mini",
                messages = new[]
                {
                    new
                    {
                        role = "system",
                        content =
                            $"Sen profesyonel bir çevirmensin. Verilen metni {targetLanguage} diline çevir. SADECE çevrilmiş metni döndür, başka hiçbir şey ekleme."
                    },
                    new { role = "user", content = text }
                },
                temperature = 0.3
            };

            var json = JsonSerializer.Serialize(requestBody);
            var content = new StringContent(json, Encoding.UTF8, "application/json");
            var response = await _httpClient.PostAsync("https://api.openai.com/v1/chat/completions", content);

            if (!response.IsSuccessStatusCode) return text;

            var responseJson = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(responseJson);
            return doc.RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString()
                ?.Trim() ?? text;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "OpenAI çeviri hatası");
            return text;
        }
    }
}

