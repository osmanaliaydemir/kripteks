using Kripteks.Core.Entities;
using Microsoft.Extensions.DependencyInjection;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;

namespace Kripteks.Infrastructure.Services;

public class SentimentAnalysisJob : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<SentimentAnalysisJob> _logger;
    private readonly IMarketSentimentState _sentimentState;
    private readonly IConfiguration _configuration;
    private bool _wasPanicMode;

    public SentimentAnalysisJob(
        IServiceProvider serviceProvider,
        ILogger<SentimentAnalysisJob> logger,
        IMarketSentimentState sentimentState,
        IConfiguration configuration)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
        _sentimentState = sentimentState;
        _configuration = configuration;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Sentiment Analysis Job Başlatıldı. 🧠");

        while (!stoppingToken.IsCancellationRequested)
        {
            if (_configuration.GetValue<bool>("AiSettings:Enabled") == false)
            {
                _logger.LogInformation("AI Analizi devre dışı, bekleniyor...");
                try
                {
                    await Task.Delay(TimeSpan.FromMinutes(10), stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    _logger.LogInformation("Sentiment Analysis Job kapatılıyor...");
                    break;
                }

                continue;
            }

            try
            {
                // 1. Haberleri al (Ağ I/O - DB gerekmiyorsa dışarıda yapılabilir)
                List<NewsItem> news = new();
                using (var scope = _serviceProvider.CreateScope())
                {
                    var newsService = scope.ServiceProvider.GetRequiredService<INewsService>();
                    news = await newsService.GetLatestNewsAsync();
                }

                if (news.Any())
                {
                    // 2. AI Analizi (Yavaş Ağ I/O - DB Bağlantısı YOK)
                    var combinedText = string.Join(". ", news.Take(5).Select(n => n.Title));

                    AiAnalysisResult analysis;
                    using (var scope = _serviceProvider.CreateScope())
                    {
                        var aiService = scope.ServiceProvider.GetRequiredService<IAiService>();
                        analysis = await aiService.AnalyzeTextAsync(combinedText);
                    }

                    if (analysis != null)
                    {
                        // 3. Kaydetme (Kısa DB Scope)
                        using (var scope = _serviceProvider.CreateScope())
                        {
                            var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                            var previousAction = _sentimentState.CurrentSentiment?.RecommendedAction;
                            _sentimentState.UpdateSentiment(analysis);

                            var historyEntry = new SentimentHistory
                            {
                                Score = analysis.SentimentScore,
                                Action = analysis.RecommendedAction,
                                Symbol = "BTC",
                                Summary = analysis.Summary,
                                RecordedAt = DateTime.UtcNow,
                                ModelCount = analysis.ProviderDetails?.Count ?? 2
                            };

                            dbContext.SentimentHistories.Add(historyEntry);
                            await dbContext.SaveChangesAsync(stoppingToken);

                            // Panik moda GİRİŞ bildirimi (sadece ilk geçişte)
                            bool isPanicNow = analysis.RecommendedAction == "PANIC SELL";
                            if (isPanicNow && !_wasPanicMode)
                            {
                                var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();
                                await notificationService.SendNotificationAsync(
                                    "🚨 PANIC MOD AKTİF",
                                    $"AI piyasa riski tespit etti! Skor: {analysis.SentimentScore:F1} | Tüm alımlar durduruldu, açık pozisyonlar kapatılıyor.",
                                    NotificationType.Error);
                            }
                            // Panik moddan ÇIKIŞ bildirimi
                            else if (!isPanicNow && _wasPanicMode)
                            {
                                var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();
                                await notificationService.SendNotificationAsync(
                                    "✅ Panic Mod Sona Erdi",
                                    $"Piyasa riski azaldı. Skor: {analysis.SentimentScore:F1} | Botlar normal çalışmaya devam ediyor.",
                                    NotificationType.Success);
                            }
                            _wasPanicMode = isPanicNow;

                            _logger.LogInformation("Piyasa Duygu Durumu Güncellendi ve Kaydedildi: {Score} ({Action})",
                                analysis.SentimentScore, analysis.RecommendedAction);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Sentiment analizi sırasında hata oluştu.");
            }

            // Her 5 dakikada bir analiz yap
            await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
        }
    }
}
