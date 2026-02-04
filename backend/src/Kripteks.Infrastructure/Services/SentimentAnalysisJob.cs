using Kripteks.Core.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class SentimentAnalysisJob : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<SentimentAnalysisJob> _logger;
    private readonly IMarketSentimentState _sentimentState;

    public SentimentAnalysisJob(
        IServiceProvider serviceProvider, 
        ILogger<SentimentAnalysisJob> logger,
        IMarketSentimentState sentimentState)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
        _sentimentState = sentimentState;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Sentiment Analysis Job Başlatıldı. 🧠");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using (var scope = _serviceProvider.CreateScope())
                {
                    var aiService = scope.ServiceProvider.GetRequiredService<IAiService>();
                    var newsService = scope.ServiceProvider.GetRequiredService<INewsService>();

                    // Haberleri al
                    var news = await newsService.GetLatestNewsAsync();
                    
                    if (news.Any())
                    {
                        // En taze haberi veya haberlerin birleşimini analiz et
                        var combinedText = string.Join(". ", news.Take(3).Select(n => n.Title));
                        var analysis = await aiService.AnalyzeTextAsync(combinedText);
                        
                        _sentimentState.UpdateSentiment(analysis);
                        
                        _logger.LogInformation("Piyasa Duygu Durumu Güncellendi: {Score} ({Action})", 
                            analysis.SentimentScore, analysis.RecommendedAction);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Sentiment analizi sırasında hata oluştu.");
            }

            // Her 5 dakikada bir analiz yap (Hızlı test için 1 dk yapabiliriz)
            await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
        }
    }
}
