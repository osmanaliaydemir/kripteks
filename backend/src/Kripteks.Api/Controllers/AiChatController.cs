using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class AiChatController : ControllerBase
{
    private readonly IAiService _aiService;
    private readonly INewsService _newsService;
    private readonly IMarketSentimentState _sentimentState;

    public AiChatController(IAiService aiService, INewsService newsService, IMarketSentimentState sentimentState)
    {
        _aiService = aiService;
        _newsService = newsService;
        _sentimentState = sentimentState;
    }

    /// <summary>
    /// Kullanıcıdan gelen soruyu AI ile yanıtlar
    /// </summary>
    [HttpPost("ask")]
    public async Task<IActionResult> Ask([FromBody] ChatRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Message))
        {
            return BadRequest(new { error = "Mesaj boş olamaz." });
        }

        try
        {
            // Son haberleri al
            var news = await _newsService.GetLatestNewsAsync("BTC");
            var newsContext = string.Join(". ", news.Take(3).Select(n => n.Title));
            
            // Mevcut sentiment durumu
            var currentSentiment = _sentimentState.CurrentSentiment;
            
            // Kullanıcı sorusuyla birleştir
            var enrichedPrompt = $"""
                Mevcut Piyasa Durumu:
                - Sentiment Skoru: {currentSentiment?.SentimentScore:F2}
                - Önerilen Aksiyon: {currentSentiment?.RecommendedAction}
                - Son Haberler: {newsContext}
                
                Kullanıcı Sorusu: {request.Message}
                
                Lütfen Türkçe ve yardımcı bir şekilde yanıt ver. Piyasa durumunu da dikkate al.
                """;

            var analysis = await _aiService.AnalyzeTextAsync(enrichedPrompt);

            return Ok(new ChatResponse
            {
                Reply = analysis.Summary,
                SentimentScore = analysis.SentimentScore,
                RecommendedAction = analysis.RecommendedAction,
                Timestamp = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = "AI yanıtı alınamadı.", details = ex.Message });
        }
    }

    /// <summary>
    /// Hızlı piyasa özeti al
    /// </summary>
    [HttpGet("summary")]
    public async Task<IActionResult> GetQuickSummary()
    {
        var sentiment = _sentimentState.CurrentSentiment;
        var news = await _newsService.GetLatestNewsAsync("BTC");

        return Ok(new
        {
            sentiment = new
            {
                score = sentiment?.SentimentScore ?? 0,
                action = sentiment?.RecommendedAction ?? "HOLD",
                summary = sentiment?.Summary ?? "Veri yok"
            },
            latestNews = news.Take(3).Select(n => new { n.Title, n.Source, n.PublishedAt }),
            timestamp = DateTime.UtcNow
        });
    }

    public record ChatRequest(string Message);

    public class ChatResponse
    {
        public string Reply { get; set; } = "";
        public float SentimentScore { get; set; }
        public string RecommendedAction { get; set; } = "HOLD";
        public DateTime Timestamp { get; set; }
    }
}
