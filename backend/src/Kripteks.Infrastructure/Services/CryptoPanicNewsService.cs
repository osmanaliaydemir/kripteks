using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Kripteks.Infrastructure.Services;

public class CryptoPanicNewsService : INewsService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<CryptoPanicNewsService> _logger;
    private readonly string _apiKey;

    public CryptoPanicNewsService(HttpClient httpClient, ILogger<CryptoPanicNewsService> logger,
        IConfiguration configuration)
    {
        _httpClient = httpClient;
        _logger = logger;
        _apiKey = configuration["NewsSettings:CryptoPanicApiKey"] ?? "";
    }

    public async Task<List<NewsItem>> GetLatestNewsAsync(string symbol = "BTC")
    {
        if (string.IsNullOrEmpty(_apiKey))
        {
            throw new InvalidOperationException(
                "CryptoPanic API anahtarı ayarlanmamış. Lütfen appsettings.json dosyasını kontrol edin.");
        }

        try
        {
            var url =
                $"https://cryptopanic.com/api/developer/v2/posts/?auth_token={_apiKey}&currencies={symbol}&kind=news&public=true";
            var response = await _httpClient.GetAsync(url);

            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                throw new Exception($"CryptoPanic API Hatası ({response.StatusCode}): {error}");
            }

            var json = await response.Content.ReadAsStringAsync();
            var result = JsonSerializer.Deserialize<CryptoPanicResponse>(json,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

            if (result?.Results == null || !result.Results.Any())
            {
                return new List<NewsItem>();
            }

            var news = result.Results.Take(10).Select(r => new NewsItem
            {
                Id = r.Id?.ToString() ?? Guid.NewGuid().ToString(),
                Title = r.Title ?? "",
                Summary = r.Description ?? r.Title ?? "",
                Source = r.Source?.Title ?? "CryptoPanic",
                Url = r.Url ?? "",
                PublishedAt = r.PublishedAt ?? DateTime.UtcNow,
                SentimentScore = 0,
                IsAnalyzed = false
            }).ToList();

            _logger.LogInformation("CryptoPanic V2'den {Count} haber alındı: {Symbol}", news.Count, symbol);
            return news;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CryptoPanic API çağrısı sırasında hata oluştu.");
            throw;
        }
    }

    // CryptoPanic API Response DTOs
    private class CryptoPanicResponse
    {
        [JsonPropertyName("results")] public List<CryptoPanicPost>? Results { get; set; }
    }

    private class CryptoPanicPost
    {
        [JsonPropertyName("id")] public long? Id { get; set; }

        [JsonPropertyName("title")] public string? Title { get; set; }

        [JsonPropertyName("description")] public string? Description { get; set; }

        [JsonPropertyName("url")] public string? Url { get; set; }

        [JsonPropertyName("published_at")] public DateTime? PublishedAt { get; set; }

        [JsonPropertyName("source")] public CryptoPanicSource? Source { get; set; }
    }

    private class CryptoPanicSource
    {
        [JsonPropertyName("title")] public string? Title { get; set; }
    }
}

