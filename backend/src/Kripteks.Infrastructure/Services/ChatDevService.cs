using System.Net.Http.Json;
using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class ChatDevService : IChatDevService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ChatDevService> _logger;
    private readonly IConfiguration _configuration;
    private readonly string _baseUrl;

    public ChatDevService(HttpClient httpClient, IConfiguration configuration, ILogger<ChatDevService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _configuration = configuration;
        _baseUrl = configuration["AiBridge:BaseUrl"] ?? "http://localhost:8000";
    }

    public async Task<AiAnalysisResult> RunWorkflowAsync(string workflowYaml, string taskPrompt,
        Dictionary<string, string>? variables = null)
    {
        if (_configuration.GetValue<bool>("AiSettings:Enabled") == false)
        {
            return new AiAnalysisResult
            {
                Summary = "AI Bridge is disabled by configuration.",
                RecommendedAction = "HOLD"
            };
        }

        try
        {
            var request = new
            {
                workflow_yaml = workflowYaml,
                task_prompt = taskPrompt,
                variables
            };

            var response = await _httpClient.PostAsJsonAsync($"{_baseUrl}/run-workflow", request);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<ChatDevWorkflowResponse>();

            if (result?.Status == "success")
            {
                return new AiAnalysisResult
                {
                    Summary = result.Result ?? "No summary provided by ChatDev.",
                    RecommendedAction = ParseAction(result.Result),
                    SentimentScore = ParseSentiment(result.Result),
                    AnalyzedAt = DateTime.UtcNow
                };
            }

            throw new Exception($"ChatDev workflow failed: {result?.Error}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calling ChatDev AI Bridge: {Message}", ex.Message);
            return new AiAnalysisResult
            {
                Summary = $"AI Bridge Error: {ex.Message}",
                RecommendedAction = "HOLD"
            };
        }
    }

    public async Task<AiAnalysisResult> AnalyzeMarketSentimentAsync(string newsSummary)
    {
        // Sentiment analizi için önceden tanımlanmış bir workflow kullanabiliriz.
        return await RunWorkflowAsync("sentiment_analysis.yaml", newsSummary);
    }

    private string ParseAction(string? text)
    {
        if (text == null) return "HOLD";

        var upper = text.ToUpper();
        if (upper.Contains("BUY")) return "BUY";
        if (upper.Contains("SELL")) return "SELL";
        if (upper.Contains("PANIC")) return "PANIC";

        return "HOLD";
    }

    private float ParseSentiment(string? text)
    {
        if (text == null) return 0;

        var upper = text.ToUpper();
        if (upper.Contains("POSITIVE") || upper.Contains("BULLISH")) return 0.8f;
        if (upper.Contains("NEGATIVE") || upper.Contains("BEARISH")) return -0.8f;

        return 0;
    }

    private class ChatDevWorkflowResponse
    {
        public string Status { get; set; } = string.Empty;
        public string? Result { get; set; }
        public string? Error { get; set; }
    }
}
