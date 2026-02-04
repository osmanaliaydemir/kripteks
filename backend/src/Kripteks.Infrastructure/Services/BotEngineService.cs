using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Kripteks.Infrastructure.Strategies;
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
            catch (Exception ex)
            {
                _logger.LogError(ex, "Bot Döngüsünde Kritik Hata!");
            }

            await Task.Delay(_checkInterval, stoppingToken);
        }
    }

    private async Task ProcessBotsAsync(CancellationToken stoppingToken)
    {
        using (var scope = _serviceProvider.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var binanceClient = scope.ServiceProvider.GetRequiredService<IBinanceRestClient>();
            var marketService = scope.ServiceProvider.GetRequiredService<IMarketDataService>();
            var mailService = scope.ServiceProvider.GetRequiredService<IMailService>();
            var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();
            var logService = scope.ServiceProvider.GetRequiredService<ILogService>();
            var strategyFactory = scope.ServiceProvider.GetRequiredService<IStrategyFactory>();
            var sentimentState = scope.ServiceProvider.GetRequiredService<IMarketSentimentState>(); // <--- EKLENDİ

            var marketSentiment = sentimentState.CurrentSentiment;
            bool isPanicMode = marketSentiment.RecommendedAction == "PANIC SELL";

            // 1. Bekleyen Botları Kontrol Et (GİRİŞ ARA)
            var waitingBots = await dbContext.Bots
                .Where(b => b.Status == BotStatus.WaitingForEntry)
                .Include(b => b.Logs)
                .ToListAsync(stoppingToken);

            if (waitingBots.Any())
            {
                // Çok fazla log olmaması için sadece gerçekten işlem varsa log atılabilir veya
                // debug modunda açılabilir. Şimdilik sistemin yaşadığını görmek adına her döngüde değil,
                // işlem yapıldığında log atacağız (aşağıdaki metodlarda).
            }

            foreach (var bot in waitingBots)
            {
                if (isPanicMode)
                {
                    if (DateTime.UtcNow.Second % 30 == 0) // Log pollution prevention
                    {
                        await logService.LogWarningAsync(
                            $"AI PANIC MODU: {bot.Symbol} için alım sinyalleri geçici olarak durduruldu.", bot.Id);
                    }

                    continue;
                }

                await CheckEntrySignal(bot, binanceClient, dbContext, mailService, notificationService, logService,
                    strategyFactory);
            }

            // 2. Çalışan Botları Kontrol Et (ÇIKIŞ ARA & PNL GÜNCELLE)
            var runningBots = await dbContext.Bots
                .Where(b => b.Status == BotStatus.Running)
                .Include(b => b.Logs)
                .ToListAsync(stoppingToken);

            foreach (var bot in runningBots)
            {
                // Panic durumunda tüm botları kapat (Opsiyonel: Sadece News botları için olabilir ama şimdilik global risk filter)
                if (isPanicMode)
                {
                    await ClosePosition(bot, BotStatus.Stopped,
                        "🚨 AI GLOBAL PANIC: Piyasa riski nedeniyle pozisyon otomatik kapatıldı.", bot.CurrentPnl,
                        dbContext, notificationService, logService);
                    continue;
                }

                await CheckExitSignalAndPnl(bot, binanceClient, marketService, dbContext, notificationService,
                    logService, strategyFactory);
            }

            await dbContext.SaveChangesAsync(stoppingToken);
        }
    }

    private async Task CheckEntrySignal(Bot bot, IBinanceRestClient client, AppDbContext context,
        IMailService mailService, INotificationService notificationService, ILogService logService,
        IStrategyFactory strategyFactory)
    {
        try
        {
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
                return;
            }

            var candles = klines.Data.Select(k => new Candle
            {
                OpenTime = k.OpenTime, Open = k.OpenPrice, High = k.HighPrice, Low = k.LowPrice, Close = k.ClosePrice,
                Volume = k.Volume
            }).ToList();

            // NOTE: We pass bot.Amount as currentPositionAmount for initial check (it's 0 if waiting, but bot.Amount is the intended investment)
            // But wait, CheckEntrySignal called for 'WaitingForEntry', so position is 0.
            var signal = strategy.Analyze(candles, bot.Amount, 0);

            if (signal.Action == TradeAction.Buy)
            {
                // ... (MEVCUT KOD) ...

                var wallet = await context.Wallets.FirstOrDefaultAsync();
                decimal currentBalance = wallet?.Balance ?? 0;

                if (wallet == null || currentBalance < bot.Amount)
                {
                    _logger.LogWarning("Yetersiz Bakiye! {Symbol} işlemi açılamadı.", bot.Symbol);
                    await logService.LogWarningAsync($"Yetersiz Bakiye: {bot.Symbol} için ${bot.Amount} gerekli.",
                        bot.Id); // <--- LOG

                    var log = new Log
                    {
                        Message =
                            $"⚠️ ALIM SİNYALİ GELDİ ANCAK BAKİYE YETERSİZ! İstek: ${bot.Amount}, Mevcut: ${currentBalance}",
                        Level = BotLogLevel.Warning,
                        Timestamp = DateTime.UtcNow
                    };
                    bot.Logs.Add(log);

                    // Bildirimler
                    await notificationService.NotifyLog(bot.Id.ToString(), log);

                    _ = Task.Run(() => mailService.SendInsufficientBalanceEmailAsync(bot.Symbol, strategy.Name,
                        bot.Amount, currentBalance, bot.Amount - currentBalance));

                    return;
                }

                wallet.Balance -= bot.Amount;
                wallet.LockedBalance += bot.Amount;
                wallet.LastUpdated = DateTime.UtcNow;

                context.WalletTransactions.Add(new WalletTransaction
                {
                    WalletId = wallet.Id,
                    Amount = -bot.Amount,
                    Type = BotTransactionType.BotInvestment,
                    Description = $"Otomatik Alım: {bot.Symbol} ({bot.StrategyName})",
                    CreatedAt = DateTime.UtcNow
                });

                decimal currentPrice = candles.Last().Close;

                bot.Status = BotStatus.Running;
                bot.EntryPrice = currentPrice;
                bot.CurrentPnl = 0;
                bot.CurrentPnlPercent = 0;
                bot.MaxPriceReached = currentPrice; // İz süren stop için başlangıç fiyatı

                if (signal.TargetPrice > 0) bot.TakeProfit = ((signal.TargetPrice - currentPrice) / currentPrice) * 100;
                if (signal.StopPrice > 0) bot.StopLoss = ((currentPrice - signal.StopPrice) / currentPrice) * 100;

                var successLog = new Log
                {
                    Message = $"⚡ SİNYAL GELDİ: Alım Yapıldı! Fiyat: ${currentPrice}. Hedef: ${signal.TargetPrice:F8}",
                    Level = BotLogLevel.Info,
                    Timestamp = DateTime.UtcNow
                };
                bot.Logs.Add(successLog);

                // SİSTEM LOGU
                await logService.LogInfoAsync($"Bot İşlemi Başladı: {bot.Symbol} | Fiyat: {currentPrice}",
                    bot.Id); // <--- LOG

                // 🔥 CANLI GÜNCELLEME
                await notificationService.NotifyBotUpdate(ToDto(bot));
                await notificationService.NotifyWalletUpdate(wallet);
                await notificationService.NotifyLog(bot.Id.ToString(), successLog);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Giriş kontrol hatası: {Symbol}", bot.Symbol);
            await logService.LogErrorAsync($"Bot Hatası ({bot.Symbol}): {ex.Message}", bot.Id); // <--- LOG
        }
    }

    private async Task CheckExitSignalAndPnl(Bot bot, IBinanceRestClient client, IMarketDataService marketService,
        AppDbContext context, INotificationService notificationService, ILogService logService,
        IStrategyFactory strategyFactory)
    {
        try
        {
            decimal currentPrice = await marketService.GetPriceAsync(bot.Symbol);
            if (currentPrice == 0) return;

            decimal priceDiff = currentPrice - bot.EntryPrice;
            decimal pnlPercent = (priceDiff / bot.EntryPrice) * 100;
            decimal pnlAmount = bot.Amount * (pnlPercent / 100);

            // Sadece değişiklik varsa update atalım gereksiz trafik olmasın
            bool pnlChanged = Math.Abs(bot.CurrentPnl - pnlAmount) > 0.01m;

            bot.CurrentPnl = pnlAmount;
            bot.CurrentPnlPercent = pnlPercent;

            if (pnlChanged) await notificationService.NotifyBotUpdate(ToDto(bot));

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

            {
                var interval = GetKlineInterval(bot.Interval);
                var klines =
                    await client.SpotApi.ExchangeData.GetKlinesAsync(bot.Symbol.Replace("/", ""), interval, limit: 500);
                if (klines.Success)
                {
                    var candles = klines.Data.Select(k => new Candle
                    {
                        OpenTime = k.OpenTime, Open = k.OpenPrice, High = k.HighPrice, Low = k.LowPrice,
                        Close = k.ClosePrice, Volume = k.Volume
                    }).ToList();

                    // Pass Bot.Amount (Total Invested USD) instead of Quantity
                    var signal = strategy.Analyze(candles, 0, bot.Amount, bot.EntryPrice, bot.CurrentDcaStep);

                    if (signal.Action == TradeAction.Sell)
                    {
                        strategyExitSignal = true;
                        exitReason = signal.Description;
                    }
                    else if (signal.Action == TradeAction.Buy && bot.StrategyName == "strategy-dca")
                    {
                        // DCA RE-ENTRY LOGIC
                        await HandleDcaBuy(bot, signal, currentPrice, context, notificationService, logService);
                        // We continue execution, do not return. PnL might update.
                    }
                }
            }

            bool shouldExit = false;
            BotStatus finalStatus = BotStatus.Completed;

            if (strategyExitSignal)
            {
                shouldExit = true;
                finalStatus = BotStatus.Stopped;
                if (pnlAmount > 0) finalStatus = BotStatus.Completed;
            }
            // --- TRAILING STOP LOGIC ---
            else if (bot.IsTrailingStop && bot.TrailingStopDistance.HasValue)
            {
                if (bot.MaxPriceReached == null || currentPrice > bot.MaxPriceReached)
                {
                    bot.MaxPriceReached = currentPrice;
                    // Log atalım mı? Çok sık olmasın.
                }

                decimal trailingStopPrice = bot.MaxPriceReached.Value * (1 - (bot.TrailingStopDistance.Value / 100));

                if (currentPrice <= trailingStopPrice)
                {
                    shouldExit = true;
                    finalStatus = BotStatus.Stopped;
                    if (pnlAmount > 0) finalStatus = BotStatus.Completed;
                    exitReason =
                        $"📉 İZ SÜREN STOP TETİKLENDİ (%{bot.TrailingStopDistance:F2} mesafe, Tepe: {bot.MaxPriceReached:F2})";
                }
            }
            // ---------------------------
            else if (bot.TakeProfit.HasValue && pnlPercent >= bot.TakeProfit.Value)
            {
                shouldExit = true;
                finalStatus = BotStatus.Completed;
                exitReason = $"🎯 KAR AL (%{pnlPercent:F2})";
            }
            else if (bot.StopLoss.HasValue && pnlPercent <= -bot.StopLoss.Value)
            {
                shouldExit = true;
                finalStatus = BotStatus.Stopped;
                exitReason = $"🛑 ZARAR DURDUR (%{pnlPercent:F2})";
            }

            if (shouldExit)
            {
                await ClosePosition(bot, finalStatus, exitReason, pnlAmount, context, notificationService, logService);
            }
            else
            {
                if (DateTime.UtcNow.Second % 30 == 0)
                {
                    var lastLog = bot.Logs.LastOrDefault();
                    if (lastLog == null || (DateTime.UtcNow - lastLog.Timestamp).TotalMinutes > 5)
                    {
                        var infoLog = new Log
                        {
                            Message = $"[İşlemde] Fiyat: ${currentPrice} | PNL: %{pnlPercent:F2} (${pnlAmount:F2})",
                            Level = BotLogLevel.Info, Timestamp = DateTime.UtcNow
                        };
                        bot.Logs.Add(infoLog);
                        await notificationService.NotifyLog(bot.Id.ToString(), infoLog);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Çıkış kontrol hatası: {Symbol}", bot.Symbol);
            await logService.LogErrorAsync($"Bot Çıkış Hatası ({bot.Symbol}): {ex.Message}", bot.Id); // <--- LOG
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

        var wallet = await context.Wallets.FirstOrDefaultAsync();
        if (wallet != null)
        {
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
        await notificationService.NotifyLog(bot.Id.ToString(), log);
        await notificationService.NotifyBotUpdate(ToDto(bot));
        await logService.LogInfoAsync(
            $"DCA Yatırımı: {bot.Symbol} | Tutar: ${costNew} | Yeni Ort: {newEntryPrice}", bot.Id);
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
            CreatedAt = bot.CreatedAt, // Note: DTO uses CreatedAt
            Pnl = bot.CurrentPnl,
            PnlPercent = bot.CurrentPnlPercent,
            Logs = bot.Logs,
            IsTrailingStop = bot.IsTrailingStop,
            TrailingStopDistance = bot.TrailingStopDistance,
            MaxPriceReached = bot.MaxPriceReached
        };
    }
}
