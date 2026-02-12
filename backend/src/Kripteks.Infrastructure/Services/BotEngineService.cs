using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Binance.Net.Interfaces.Clients;
using Binance.Net.Enums;
using Kripteks.Core.DTOs;
using BotLogLevel = Kripteks.Core.Entities.LogLevel;
using BotTransactionType = Kripteks.Core.Entities.TransactionType;

namespace Kripteks.Infrastructure.Services;

public class BotEngineService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<BotEngineService> _logger;
    private readonly TimeSpan _checkInterval = TimeSpan.FromSeconds(5); // Socket sayesinde 5sn'ye düşürdük
    private readonly HashSet<Guid> _insufficientBalanceNotifiedBots = new();
    private readonly Dictionary<Guid, int> _consecutiveErrorCounts = new();
    private readonly HashSet<Guid> _apiErrorNotifiedBots = new();
    private const int ApiErrorThreshold = 3;
    private bool _criticalErrorNotified;

    public BotEngineService(IServiceProvider serviceProvider, ILogger<BotEngineService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Bot Engine Başlatıldı (Otomatik Al-Sat Modu) 🚀");

        // WebSocket Başlatma
        using (var scope = _serviceProvider.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var marketService = scope.ServiceProvider.GetRequiredService<IMarketDataService>();

            var activeSymbols = await dbContext.Bots
                .Where(b => b.Status == BotStatus.Running || b.Status == BotStatus.WaitingForEntry)
                .Select(b => b.Symbol)
                .Distinct()
                .ToListAsync(stoppingToken);

            if (activeSymbols.Any())
            {
                await marketService.StartSocketConnection(activeSymbols);
            }
        }

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessBotsAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation("Bot Engine Durduruluyor... 👋");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Bot Döngüsünde Kritik Hata!");

                if (!_criticalErrorNotified)
                {
                    _criticalErrorNotified = true;
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();
                        await notificationService.SendNotificationAsync(
                            "💀 Bot Engine Kritik Hata",
                            $"Ana döngüde beklenmeyen hata: {ex.Message[..Math.Min(150, ex.Message.Length)]}",
                            NotificationType.Error);
                    }
                    catch
                    {
                        // Bildirim gönderimi de başarısız olursa sessizce devam et
                    }
                }
            }

            await Task.Delay(_checkInterval, stoppingToken);
        }
    }

    private async Task ProcessBotsAsync(CancellationToken stoppingToken)
    {
        List<Guid> waitingBotIds;
        List<Guid> runningBotIds;
        AiAnalysisResult marketSentiment;

        using (var scope = _serviceProvider.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var sentimentState = scope.ServiceProvider.GetRequiredService<IMarketSentimentState>();

            waitingBotIds = await dbContext.Bots
                .Where(b => b.Status == BotStatus.WaitingForEntry)
                .Select(b => b.Id)
                .ToListAsync(stoppingToken);

            runningBotIds = await dbContext.Bots
                .Where(b => b.Status == BotStatus.Running)
                .Select(b => b.Id)
                .ToListAsync(stoppingToken);

            marketSentiment = sentimentState.CurrentSentiment;
        }

        bool isPanicMode = marketSentiment.RecommendedAction == "PANIC SELL";

        // 1. Bekleyen Botları Kontrol Et (GİRİŞ ARA)
        var waitingTasks = waitingBotIds.Select(async botId =>
        {
            if (isPanicMode)
            {
                if (DateTime.UtcNow.Second % 30 == 0) // Log pollution prevention
                {
                    await LogGeneralWarningAsync(botId, "AI PANIC MODU: Alım sinyalleri geçici olarak durduruldu.");
                }

                return;
            }

            await CheckEntrySignal(botId, stoppingToken);
        });

        // 2. Çalışan Botları Kontrol Et (ÇIKIŞ ARA & PNL GÜNCELLE)
        var runningTasks = runningBotIds.Select(async botId =>
        {
            if (isPanicMode)
            {
                await ClosePositionPanic(botId, stoppingToken);
                return;
            }

            await CheckExitSignalAndPnl(botId, stoppingToken);
        });

        await Task.WhenAll(waitingTasks.Concat(runningTasks));
    }

    private async Task LogGeneralWarningAsync(Guid botId, string message)
    {
        using var scope = _serviceProvider.CreateScope();
        var logService = scope.ServiceProvider.GetRequiredService<ILogService>();
        var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

        await logService.LogWarningAsync($"{message}", botId);
        await notificationService.SendNotificationAsync("⚠️ Bot Uyarısı", message, NotificationType.Warning, botId);
    }

    private async Task ClosePositionPanic(Guid botId, CancellationToken stoppingToken)
    {
        using var scope = _serviceProvider.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var bot = await dbContext.Bots.Include(b => b.Logs).FirstOrDefaultAsync(b => b.Id == botId);
        if (bot == null || bot.Status != BotStatus.Running) return;

        var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();
        var logService = scope.ServiceProvider.GetRequiredService<ILogService>();

        await ClosePosition(bot, BotStatus.Stopped,
            "🚨 AI GLOBAL PANIC: Piyasa riski nedeniyle pozisyon otomatik kapatıldı.", bot.CurrentPnl,
            dbContext, notificationService, logService);

        await dbContext.SaveChangesAsync(stoppingToken);
    }

    private async Task CheckEntrySignal(Guid botId, CancellationToken stoppingToken)
    {
        // 1. Bot Verilerini Ağ Gerektirmeyen Şekilde Çek (veya kısa scope kullan)
        Bot bot;
        using (var scope = _serviceProvider.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            bot = await dbContext.Bots.AsNoTracking().FirstOrDefaultAsync(b => b.Id == botId) ??
                  throw new InvalidOperationException($"Bot {botId} bulunamadı.");
        }

        if (bot == null) return;

        try
        {
            // 2. Ağ I/O (Uzun süren işlem - DB Bağlantısı YOK)
            using var scopeRest = _serviceProvider.CreateScope();
            var client = scopeRest.ServiceProvider.GetRequiredService<IBinanceRestClient>();
            var strategyFactory = scopeRest.ServiceProvider.GetRequiredService<IStrategyFactory>();

            IStrategy strategy = strategyFactory.GetStrategy(bot.StrategyName);
            if (!string.IsNullOrEmpty(bot.StrategyParams))
            {
                try
                {
                    var parameters =
                        System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, string>>(bot.StrategyParams);
                    if (parameters != null) strategy.SetParameters(parameters);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Strateji parametreleri yüklenirken hata: {Id}", bot.Id);
                }
            }

            var interval = GetKlineInterval(bot.Interval);
            var klines =
                await client.SpotApi.ExchangeData.GetKlinesAsync(bot.Symbol.Replace("/", ""), interval, limit: 500);

            if (!klines.Success)
            {
                _logger.LogWarning("Bot {Symbol} veri çekemedi: {Error}", bot.Symbol, klines.Error);
                await TrackApiErrorAsync(bot.Id, bot.Symbol, "Veri çekme hatası",
                    klines.Error?.Message ?? "Bilinmeyen hata");
                return;
            }

            // Başarılı veri çekimi - hata sayacını sıfırla
            ResetApiErrorCount(bot.Id);

            var candles = klines.Data.Select(k => new Candle
            {
                OpenTime = k.OpenTime, Open = k.OpenPrice, High = k.HighPrice, Low = k.LowPrice, Close = k.ClosePrice,
                Volume = k.Volume
            }).ToList();

            var signal = strategy.Analyze(candles, bot.Amount, 0);

            if (signal.Action == TradeAction.Buy)
            {
                // 3. Veritabanı İşlemleri (Kısa scope)
                using var scopeDb = _serviceProvider.CreateScope();
                var dbContext = scopeDb.ServiceProvider.GetRequiredService<AppDbContext>();
                var notificationService = scopeDb.ServiceProvider.GetRequiredService<INotificationService>();
                var logService = scopeDb.ServiceProvider.GetRequiredService<ILogService>();
                var mailService = scopeDb.ServiceProvider.GetRequiredService<IMailService>();

                // Botu tekrar fetch et (değişiklik yapmak için)
                var botToUpdate = await dbContext.Bots.Include(b => b.Logs).FirstOrDefaultAsync(b => b.Id == botId);
                if (botToUpdate == null || botToUpdate.Status != BotStatus.WaitingForEntry) return;

                var wallet = await dbContext.Wallets.FirstOrDefaultAsync();
                decimal currentBalance = wallet?.Balance ?? 0;

                if (wallet == null || currentBalance < botToUpdate.Amount)
                {
                    // Sadece daha önce bildirim gönderilmediyse işlem yap
                    if (!_insufficientBalanceNotifiedBots.Contains(botToUpdate.Id))
                    {
                        _logger.LogWarning("Yetersiz Bakiye! {Symbol} işlemi açılamadı.", botToUpdate.Symbol);
                        await logService.LogWarningAsync(
                            $"Yetersiz Bakiye: {botToUpdate.Symbol} için ${botToUpdate.Amount} gerekli.",
                            botToUpdate.Id);

                        var log = new Log
                        {
                            Message =
                                $"⚠️ ALIM SİNYALİ GELDİ ANCAK BAKİYE YETERSİZ! İstek: ${botToUpdate.Amount}, Mevcut: ${currentBalance}",
                            Level = BotLogLevel.Warning,
                            Timestamp = DateTime.UtcNow
                        };
                        botToUpdate.Logs.Add(log);

                        await notificationService.NotifyLog(botToUpdate.Id.ToString(), log);

                        await notificationService.SendNotificationAsync(
                            $"💰 Bakiye Yetersiz: {botToUpdate.Symbol}",
                            $"Alım sinyali geldi ama bakiye yetmiyor! Gerekli: ${botToUpdate.Amount}, Mevcut: ${currentBalance}",
                            NotificationType.Warning,
                            botToUpdate.Id);

                        _ = Task.Run(() => mailService.SendInsufficientBalanceEmailAsync(botToUpdate.Symbol,
                            strategy.Name,
                            botToUpdate.Amount, currentBalance, botToUpdate.Amount - currentBalance));

                        await dbContext.SaveChangesAsync(stoppingToken);

                        _insufficientBalanceNotifiedBots.Add(botToUpdate.Id);
                    }

                    return;
                }

                // Bakiye yeterli olduğu için listeden çıkar (tekrar düşerse yine mail atabilsin)
                if (_insufficientBalanceNotifiedBots.Contains(botToUpdate.Id))
                {
                    _insufficientBalanceNotifiedBots.Remove(botToUpdate.Id);
                }

                wallet.Balance -= botToUpdate.Amount;
                wallet.LockedBalance += botToUpdate.Amount;
                wallet.LastUpdated = DateTime.UtcNow;

                dbContext.WalletTransactions.Add(new WalletTransaction
                {
                    WalletId = wallet.Id,
                    Amount = -botToUpdate.Amount,
                    Type = BotTransactionType.BotInvestment,
                    Description = $"Otomatik Alım: {botToUpdate.Symbol} ({botToUpdate.StrategyName})",
                    CreatedAt = DateTime.UtcNow
                });

                decimal currentPrice = candles.Last().Close;

                botToUpdate.Status = BotStatus.Running;
                botToUpdate.EntryDate = DateTime.UtcNow;
                botToUpdate.EntryPrice = currentPrice;
                botToUpdate.CurrentPnl = 0;
                botToUpdate.CurrentPnlPercent = 0;
                botToUpdate.MaxPriceReached = currentPrice;

                if (signal.TargetPrice > 0 && botToUpdate.TakeProfit == null)
                    botToUpdate.TakeProfit = ((signal.TargetPrice - currentPrice) / currentPrice) * 100;
                if (signal.StopPrice > 0 && botToUpdate.StopLoss == null)
                    botToUpdate.StopLoss = ((currentPrice - signal.StopPrice) / currentPrice) * 100;

                var successLog = new Log
                {
                    Message = $"⚡ SİNYAL GELDİ: Alım Yapıldı! Fiyat: ${currentPrice}. Hedef: ${signal.TargetPrice:F8}",
                    Level = BotLogLevel.Info,
                    Timestamp = DateTime.UtcNow
                };
                botToUpdate.Logs.Add(successLog);

                await logService.LogInfoAsync($"Bot İşlemi Başladı: {botToUpdate.Symbol} | Fiyat: {currentPrice}",
                    botToUpdate.Id);
                await notificationService.NotifyBotUpdate(ToDto(botToUpdate));
                await notificationService.NotifyWalletUpdate(wallet);
                await notificationService.NotifyLog(botToUpdate.Id.ToString(), successLog);

                await notificationService.SendNotificationAsync(
                    $"⚡ Alım Yapıldı: {botToUpdate.Symbol}",
                    $"Fiyat: ${currentPrice} | Strateji: {botToUpdate.StrategyName}",
                    NotificationType.Trade,
                    botToUpdate.Id);

                // ── Audit Trail: Trade + Wallet ──
                try
                {
                    var auditService = scopeDb.ServiceProvider.GetRequiredService<IAuditLogService>();
                    await auditService.LogTradeAsync(null, botToUpdate.Symbol, "Alım",
                        currentPrice, botToUpdate.Amount, botToUpdate.Id,
                        new { strategy.Name, botToUpdate.Interval });
                    await auditService.LogWalletChangeAsync(null, "Bot Yatırımı",
                        wallet.Balance + botToUpdate.Amount, wallet.Balance, -botToUpdate.Amount,
                        $"Otomatik Alım: {botToUpdate.Symbol}");
                }
                catch (Exception auditEx)
                {
                    _logger.LogWarning(auditEx, "Trade audit log yazılamadı: {Symbol}", botToUpdate.Symbol);
                }

                await dbContext.SaveChangesAsync(stoppingToken);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Giriş kontrol hatası: {Symbol}", bot.Symbol);
            await TrackApiErrorAsync(bot.Id, bot.Symbol, "Giriş kontrol hatası", ex.Message);
        }
    }

    private async Task CheckExitSignalAndPnl(Guid botId, CancellationToken stoppingToken)
    {
        Bot bot;
        using (var scope = _serviceProvider.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            bot = await dbContext.Bots.AsNoTracking().FirstOrDefaultAsync(b => b.Id == botId) ??
                  throw new InvalidOperationException($"Bot {botId} bulunamadı.");
        }

        if (bot == null) return;

        try
        {
            using var scopeRest = _serviceProvider.CreateScope();
            var marketService = scopeRest.ServiceProvider.GetRequiredService<IMarketDataService>();
            var client = scopeRest.ServiceProvider.GetRequiredService<IBinanceRestClient>();
            var strategyFactory = scopeRest.ServiceProvider.GetRequiredService<IStrategyFactory>();

            decimal currentPrice = await marketService.GetPriceAsync(bot.Symbol);
            if (currentPrice == 0) return;

            decimal priceDiff = currentPrice - bot.EntryPrice;
            decimal pnlPercent = (priceDiff / bot.EntryPrice) * 100;
            decimal pnlAmount = bot.Amount * (pnlPercent / 100);

            bool strategyExitSignal = false;
            string exitReason = "";

            IStrategy strategy = strategyFactory.GetStrategy(bot.StrategyName);
            if (!string.IsNullOrEmpty(bot.StrategyParams))
            {
                try
                {
                    var parameters =
                        System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, string>>(bot.StrategyParams);
                    if (parameters != null) strategy.SetParameters(parameters);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Strateji parametreleri yüklenirken hata: {Id}", bot.Id);
                }
            }

            // Klines çekimi
            var interval = GetKlineInterval(bot.Interval);
            var klines =
                await client.SpotApi.ExchangeData.GetKlinesAsync(bot.Symbol.Replace("/", ""), interval, limit: 500);

            StrategyResult? signal = null;
            if (klines.Success)
            {
                var candles = klines.Data.Select(k => new Candle
                {
                    OpenTime = k.OpenTime, Open = k.OpenPrice, High = k.HighPrice, Low = k.LowPrice,
                    Close = k.ClosePrice, Volume = k.Volume
                }).ToList();

                signal = strategy.Analyze(candles, 0, bot.Amount, bot.EntryPrice, bot.CurrentDcaStep);
                if (signal.Action == TradeAction.Sell)
                {
                    strategyExitSignal = true;
                    exitReason = signal.Description;
                }
            }

            // Veritabanı Güncelleme (Scope açıyoruz)
            using (var scopeDb = _serviceProvider.CreateScope())
            {
                var dbContext = scopeDb.ServiceProvider.GetRequiredService<AppDbContext>();
                var notificationService = scopeDb.ServiceProvider.GetRequiredService<INotificationService>();
                var logService = scopeDb.ServiceProvider.GetRequiredService<ILogService>();

                var botToUpdate = await dbContext.Bots.Include(b => b.Logs).FirstOrDefaultAsync(b => b.Id == botId);
                if (botToUpdate == null || botToUpdate.Status != BotStatus.Running) return;

                bool pnlChanged = Math.Abs(botToUpdate.CurrentPnl - pnlAmount) > 0.01m;
                botToUpdate.CurrentPnl = pnlAmount;
                botToUpdate.CurrentPnlPercent = pnlPercent;

                if (pnlChanged) await notificationService.NotifyBotUpdate(ToDto(botToUpdate));

                if (signal != null && signal.Action == TradeAction.Buy && botToUpdate.StrategyName == "strategy-dca")
                {
                    await HandleDcaBuy(botToUpdate, signal, currentPrice, dbContext, notificationService, logService);
                }

                bool shouldExit = false;
                BotStatus finalStatus = BotStatus.Completed;

                if (strategyExitSignal)
                {
                    shouldExit = true;
                    finalStatus = BotStatus.Stopped;
                    if (pnlAmount > 0) finalStatus = BotStatus.Completed;
                }
                else if (botToUpdate.IsTrailingStop && botToUpdate.TrailingStopDistance.HasValue)
                {
                    if (botToUpdate.MaxPriceReached == null || currentPrice > botToUpdate.MaxPriceReached)
                    {
                        botToUpdate.MaxPriceReached = currentPrice;
                    }

                    decimal trailingStopPrice = botToUpdate.MaxPriceReached.Value *
                                                (1 - (botToUpdate.TrailingStopDistance.Value / 100));
                    if (currentPrice <= trailingStopPrice)
                    {
                        shouldExit = true;
                        finalStatus = BotStatus.Stopped;
                        if (pnlAmount > 0) finalStatus = BotStatus.Completed;
                        exitReason =
                            $"📉 İZ SÜREN STOP TETİKLENDİ (%{botToUpdate.TrailingStopDistance:F2} mesafe, Tepe: {botToUpdate.MaxPriceReached:F2})";
                    }
                }
                else if (botToUpdate.TakeProfit.HasValue && pnlPercent >= botToUpdate.TakeProfit.Value)
                {
                    shouldExit = true;
                    finalStatus = BotStatus.Completed;
                    exitReason = $"🎯 KAR AL (%{pnlPercent:F2})";
                }
                else if (botToUpdate.StopLoss.HasValue && pnlPercent <= -botToUpdate.StopLoss.Value)
                {
                    shouldExit = true;
                    finalStatus = BotStatus.Stopped;
                    exitReason = $"🛑 ZARAR DURDUR (%{pnlPercent:F2})";
                }

                if (shouldExit)
                {
                    await ClosePosition(botToUpdate, finalStatus, exitReason, pnlAmount, dbContext, notificationService,
                        logService);
                }
                else
                {
                    // Periyodik PNL Logu
                    if (DateTime.UtcNow.Second % 30 == 0)
                    {
                        var lastLog = botToUpdate.Logs.LastOrDefault();
                        if (lastLog == null || (DateTime.UtcNow - lastLog.Timestamp).TotalMinutes > 5)
                        {
                            var infoLog = new Log
                            {
                                Message = $"[İşlemde] Fiyat: ${currentPrice} | PNL: %{pnlPercent:F2} (${pnlAmount:F2})",
                                Level = BotLogLevel.Info, Timestamp = DateTime.UtcNow
                            };
                            botToUpdate.Logs.Add(infoLog);
                            await notificationService.NotifyLog(botToUpdate.Id.ToString(), new LogDto
                            {
                                Id = infoLog.Id,
                                Message = infoLog.Message,
                                Level = infoLog.Level.ToString(),
                                Timestamp = DateTime.SpecifyKind(infoLog.Timestamp, DateTimeKind.Utc)
                            });
                        }
                    }
                }

                await dbContext.SaveChangesAsync(stoppingToken);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Çıkış kontrol hatası: {Symbol}", bot.Symbol);
            await TrackApiErrorAsync(bot.Id, bot.Symbol, "Çıkış kontrol hatası", ex.Message);
        }
    }

    private async Task ClosePosition(Bot bot, BotStatus finalStatus, string reason, decimal pnlAmount,
        AppDbContext context, INotificationService notificationService, ILogService logService)
    {
        // Grid Botlar veya Sürekli Stratejiler İçin Logik
        if (bot.StrategyName == "strategy-grid")
        {
            await HandleGridClose(bot, reason, pnlAmount, context, notificationService, logService);
            return;
        }

        bot.Status = finalStatus;
        bot.ExitDate = DateTime.UtcNow;

        var wallet = await context.Wallets.FirstOrDefaultAsync();
        if (wallet != null)
        {
            var oldBalance = wallet.Balance;
            wallet.LockedBalance -= bot.Amount;
            decimal returnAmount = bot.Amount + pnlAmount;
            wallet.Balance += returnAmount;
            wallet.LastUpdated = DateTime.UtcNow;

            context.WalletTransactions.Add(new WalletTransaction
            {
                WalletId = wallet.Id,
                Amount = returnAmount,
                Type = BotTransactionType.BotReturn,
                Description = $"Bot Kapatıldı: {bot.Symbol} | {reason}",
                CreatedAt = DateTime.UtcNow
            });

            await notificationService.NotifyWalletUpdate(wallet);

            // ── Audit Trail: Trade Satış + Wallet ──
            try
            {
                using var auditScope = _serviceProvider.CreateScope();
                var auditService = auditScope.ServiceProvider.GetRequiredService<IAuditLogService>();
                await auditService.LogTradeAsync(null, bot.Symbol, "Satış",
                    bot.EntryPrice, bot.Amount, bot.Id,
                    new { Reason = reason, PnL = pnlAmount, PnlPercent = bot.CurrentPnlPercent });
                await auditService.LogWalletChangeAsync(null, "Bot İade",
                    oldBalance, wallet.Balance, returnAmount,
                    $"Bot Kapatıldı: {bot.Symbol} | PNL: ${pnlAmount:F2}");
            }
            catch (Exception auditEx)
            {
                _logger.LogWarning(auditEx, "Satış audit log yazılamadı: {Symbol}", bot.Symbol);
            }
        }

        var log1 = new Log
            { Message = reason, Level = BotLogLevel.Info, Timestamp = DateTime.UtcNow };
        var log2 = new Log
        {
            Message = $"🏁 İşlem Sonlandı. Kasa: {wallet?.Balance:F2}", Level = BotLogLevel.Info,
            Timestamp = DateTime.UtcNow
        };

        bot.Logs.Add(log1);
        bot.Logs.Add(log2);

        // SİSTEM LOGU
        await logService.LogInfoAsync($"Bot Kapandı: {bot.Symbol}. Sonuç: ${pnlAmount:F2}. Sebep: {reason}",
            bot.Id);

        await notificationService.NotifyLog(bot.Id.ToString(), log1);
        await notificationService.NotifyLog(bot.Id.ToString(), log2);
        await notificationService.NotifyBotUpdate(ToDto(bot));

        await notificationService.SendNotificationAsync(
            $"🏁 İşlem Sonlandı: {bot.Symbol}",
            $"{reason} | PNL: ${pnlAmount:F2} (%{bot.CurrentPnlPercent:F2})",
            pnlAmount >= 0 ? NotificationType.Info : NotificationType.Warning,
            bot.Id);
    }

    private async Task HandleGridClose(Bot bot, string reason, decimal pnlAmount,
        AppDbContext context, INotificationService notificationService, ILogService logService)
    {
        // Grid botlarda işlem kapandığında bot DURMAZ. 
        // Sadece kar realize edilir ve yeni giriş için "Running" veya "WaitingForEntry" moduna döner.
        // Mevcut yapıda "Running" modunda "Alım Yapılmış" varsayımı var.
        // Grid botu aslında sürekli "Running" ama pozisyonsuz da olabilir.
        // Şimdilik basitçe karı kasaya ekleyip, botu "WaitingForEntry" moduna çekerek tekrar alım yapmasını sağlayalım.

        bot.EntryPrice = 0; // Reset
        bot.EntryDate = null;
        bot.ExitDate = DateTime.UtcNow;
        bot.CurrentPnl = 0;
        bot.CurrentPnlPercent = 0;
        bot.Status = BotStatus.WaitingForEntry; // Tekrar sına

        var wallet = await context.Wallets.FirstOrDefaultAsync();
        if (wallet != null)
        {
            // Sadece karı serbest bırak, ana para kilitli kalmasın çünkü tekrar işleme girecek (waitingforentry'de tekrar kontrol ediliyor bakiye)
            // Ancak WaitingForEntry logic'i bakiyeyi tekrar düşüyor. O yüzden burada TAMAMINI iade etmeliyiz ki
            // CheckEntrySignal tekrar bakiye kilitleyebilsin.

            wallet.LockedBalance -= bot.Amount;
            decimal returnAmount = bot.Amount + pnlAmount;
            wallet.Balance += returnAmount;
            wallet.LastUpdated = DateTime.UtcNow;

            context.WalletTransactions.Add(new WalletTransaction
            {
                WalletId = wallet.Id,
                Amount = returnAmount,
                Type = BotTransactionType.BotReturn,
                Description = $"Grid/Döngü Kar: {bot.Symbol} | {reason}",
                CreatedAt = DateTime.UtcNow
            });

            await notificationService.NotifyWalletUpdate(wallet);
        }

        var log = new Log
        {
            Message = $"🔄 Grid/Döngü Tamamlandı. Kar: ${pnlAmount:F2}. Bot tekrar giriş arıyor.",
            Level = BotLogLevel.Info,
            Timestamp = DateTime.UtcNow
        };
        bot.Logs.Add(log);

        await logService.LogInfoAsync($"Grid Kur Döngüsü: {bot.Symbol}. Kar: ${pnlAmount:F2}", bot.Id);
        await notificationService.NotifyLog(bot.Id.ToString(), log);
        await notificationService.NotifyBotUpdate(ToDto(bot));
    }


    private KlineInterval GetKlineInterval(string interval)
    {
        return interval switch
        {
            "1m" => KlineInterval.OneMinute,
            "3m" => KlineInterval.ThreeMinutes,
            "5m" => KlineInterval.FiveMinutes,
            "15m" => KlineInterval.FifteenMinutes,
            "30m" => KlineInterval.ThirtyMinutes,
            "1h" => KlineInterval.OneHour,
            "2h" => KlineInterval.TwoHour,
            "4h" => KlineInterval.FourHour,
            "6h" => KlineInterval.SixHour,
            "8h" => KlineInterval.EightHour,
            "12h" => KlineInterval.TwelveHour,
            "1d" => KlineInterval.OneDay,
            _ => KlineInterval.OneHour
        };
    }

    private async Task HandleDcaBuy(Bot bot, StrategyResult signal, decimal currentPrice, AppDbContext context,
        INotificationService notificationService, ILogService logService)
    {
        // 1. Önerilen Miktarı Belirle
        decimal amountToBuy = signal.Amount;
        if (amountToBuy <= 0) amountToBuy = bot.Amount; // Default 1x (Double down)

        // 2. Bakiye Kontrol
        var wallet = await context.Wallets.FirstOrDefaultAsync();
        if (wallet == null || wallet.Balance < amountToBuy)
        {
            _logger.LogWarning("DCA için yetersiz bakiye! Gerekli: {Amount}, Mevcut: {Balance}", amountToBuy,
                wallet?.Balance);
            await logService.LogWarningAsync($"DCA Step {bot.CurrentDcaStep + 1} Başarısız: Yetersiz Bakiye.", bot.Id);

            await notificationService.SendNotificationAsync(
                $"💰 DCA Bakiye Yetersiz: {bot.Symbol}",
                $"Kademe {bot.CurrentDcaStep + 1} için ${amountToBuy:F2} gerekli, mevcut: ${wallet?.Balance:F2}",
                NotificationType.Warning,
                bot.Id);
            return;
        }

        // 3. Maliyet Hesaplama (Weighted Average)
        decimal totalCostOld = bot.Amount; // Şu ana kadar harcanan (USD)
        decimal quantityOld = totalCostOld / bot.EntryPrice; // Yaklaşık adet

        decimal costNew = amountToBuy;
        decimal quantityNew = costNew / currentPrice;

        decimal totalCostNew = totalCostOld + costNew;
        decimal totalQuantityNew = quantityOld + quantityNew;
        decimal newEntryPrice = totalCostNew / totalQuantityNew;

        // 4. Update Wallet
        wallet.Balance -= costNew;
        wallet.LockedBalance += costNew;
        wallet.LastUpdated = DateTime.UtcNow;

        context.WalletTransactions.Add(new WalletTransaction
        {
            WalletId = wallet.Id,
            Amount = -costNew,
            Type = BotTransactionType.BotInvestment,
            Description = $"DCA Step {bot.CurrentDcaStep + 1} Alımı: {bot.Symbol}",
            CreatedAt = DateTime.UtcNow
        });

        // 5. Update Bot
        bot.Amount = totalCostNew; // Toplam yatırım arttı
        bot.EntryPrice = newEntryPrice; // Maliyet düştü
        bot.CurrentDcaStep++;
        bot.Status = BotStatus.Running; // Zaten running ama olsun

        // Log
        var log = new Log
        {
            Message =
                $"➕ DCA EKLEME ({bot.CurrentDcaStep}. Adım): ${costNew:F2} alındı. Yeni Ort: ${newEntryPrice:F8}. Sebep: {signal.Description}",
            Level = BotLogLevel.Info,
            Timestamp = DateTime.UtcNow
        };
        bot.Logs.Add(log);

        // Notify
        await notificationService.NotifyWalletUpdate(wallet);

        var logDto = new LogDto
        {
            Id = log.Id,
            Message = log.Message,
            Level = log.Level.ToString(),
            Timestamp = DateTime.SpecifyKind(log.Timestamp, DateTimeKind.Utc)
        };

        await notificationService.NotifyLog(bot.Id.ToString(), logDto);
        await notificationService.NotifyBotUpdate(ToDto(bot));

        await notificationService.SendNotificationAsync(
            $"➕ DCA Ekleme: {bot.Symbol}",
            $"Kademe {bot.CurrentDcaStep} | Yeni Ort: ${newEntryPrice:F8}",
            NotificationType.Trade,
            bot.Id);

        await logService.LogInfoAsync(
            $"DCA Yatırımı: {bot.Symbol} | Tutar: ${costNew} | Yeni Ort: {newEntryPrice}", bot.Id);

        // ── Audit Trail: DCA Trade + Wallet ──
        try
        {
            using var auditScope = _serviceProvider.CreateScope();
            var auditService = auditScope.ServiceProvider.GetRequiredService<IAuditLogService>();
            await auditService.LogTradeAsync(null, bot.Symbol, "DCA Alım",
                currentPrice, costNew, bot.Id,
                new { DcaStep = bot.CurrentDcaStep, NewAvgPrice = newEntryPrice });
            await auditService.LogWalletChangeAsync(null, "DCA Yatırımı",
                wallet.Balance + costNew, wallet.Balance, -costNew,
                $"DCA Step {bot.CurrentDcaStep}: {bot.Symbol}");
        }
        catch (Exception auditEx)
        {
            _logger.LogWarning(auditEx, "DCA audit log yazılamadı: {Symbol}", bot.Symbol);
        }
    }

    /// <summary>
    /// Art arda API hatalarını takip et, eşik aşılırsa bildirim gönder
    /// </summary>
    private async Task TrackApiErrorAsync(Guid botId, string symbol, string context, string errorMessage)
    {
        _consecutiveErrorCounts.TryGetValue(botId, out int count);
        count++;
        _consecutiveErrorCounts[botId] = count;

        // Eşik aşıldı ve henüz bildirim gönderilmediyse
        if (count >= ApiErrorThreshold && !_apiErrorNotifiedBots.Contains(botId))
        {
            _apiErrorNotifiedBots.Add(botId);
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();
                await notificationService.SendNotificationAsync(
                    $"🔌 API Bağlantı Sorunu: {symbol}",
                    $"{context}: Art arda {count} hata! Son hata: {errorMessage[..Math.Min(100, errorMessage.Length)]}",
                    NotificationType.Error,
                    botId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "API hata bildirimi gönderilemedi");
            }
        }
    }

    /// <summary>
    /// Bot başarılı işlem yaptığında hata sayacını sıfırla
    /// </summary>
    private void ResetApiErrorCount(Guid botId)
    {
        _consecutiveErrorCounts.Remove(botId);
        _apiErrorNotifiedBots.Remove(botId);
    }

    private BotDto ToDto(Bot bot)
    {
        return new BotDto
        {
            Id = bot.Id,
            Symbol = bot.Symbol,
            StrategyName = bot.StrategyName,
            Amount = bot.Amount,
            Interval = bot.Interval,
            StopLoss = bot.StopLoss,
            TakeProfit = bot.TakeProfit,
            Status = bot.Status.ToString(),
            CreatedAt = DateTime.SpecifyKind(bot.CreatedAt, DateTimeKind.Utc),
            Pnl = bot.CurrentPnl,
            PnlPercent = bot.CurrentPnlPercent,
            EntryDate = bot.EntryDate.HasValue ? DateTime.SpecifyKind(bot.EntryDate.Value, DateTimeKind.Utc) : null,
            ExitDate = bot.ExitDate.HasValue ? DateTime.SpecifyKind(bot.ExitDate.Value, DateTimeKind.Utc) : null,
            Logs = bot.Logs.Select(l => new LogDto
            {
                Id = l.Id,
                Message = l.Message,
                Level = l.Level.ToString(),
                Timestamp = DateTime.SpecifyKind(l.Timestamp, DateTimeKind.Utc)
            }).ToList(),
            IsTrailingStop = bot.IsTrailingStop,
            TrailingStopDistance = bot.TrailingStopDistance,
            MaxPriceReached = bot.MaxPriceReached
        };
    }
}
