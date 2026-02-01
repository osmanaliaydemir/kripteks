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

namespace Kripteks.Infrastructure.Services;

public class BotEngineService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<BotEngineService> _logger;
    private readonly TimeSpan _checkInterval = TimeSpan.FromSeconds(30);

    public BotEngineService(IServiceProvider serviceProvider, ILogger<BotEngineService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Bot Engine Başlatıldı (Otomatik Al-Sat Modu) 🚀");

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
            var logService = scope.ServiceProvider.GetRequiredService<ILogService>(); // <--- EKLENDİ

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
                await CheckEntrySignal(bot, binanceClient, dbContext, mailService, notificationService, logService);
            }

            // 2. Çalışan Botları Kontrol Et (ÇIKIŞ ARA & PNL GÜNCELLE)
            var runningBots = await dbContext.Bots
                .Where(b => b.Status == BotStatus.Running)
                .Include(b => b.Logs)
                .ToListAsync(stoppingToken);

            foreach (var bot in runningBots)
            {
                await CheckExitSignalAndPnl(bot, binanceClient, marketService, dbContext, notificationService,
                    logService);
            }

            await dbContext.SaveChangesAsync(stoppingToken);
        }
    }

    private async Task CheckEntrySignal(Bot bot, IBinanceRestClient client, AppDbContext context,
        IMailService mailService, INotificationService notificationService, ILogService logService)
    {
        try
        {
            IStrategy strategy = GetStrategy(bot.StrategyName);
            if (strategy == null) return;

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
                        Level = Kripteks.Core.Entities.LogLevel.Warning,
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
                    Type = Kripteks.Core.Entities.TransactionType.BotInvestment,
                    Description = $"Otomatik Alım: {bot.Symbol} ({bot.StrategyName})",
                    CreatedAt = DateTime.UtcNow
                });

                decimal currentPrice = candles.Last().Close;

                bot.Status = BotStatus.Running;
                bot.EntryPrice = currentPrice;
                bot.CurrentPnl = 0;
                bot.CurrentPnlPercent = 0;

                if (signal.TargetPrice > 0) bot.TakeProfit = ((signal.TargetPrice - currentPrice) / currentPrice) * 100;
                if (signal.StopPrice > 0) bot.StopLoss = ((currentPrice - signal.StopPrice) / currentPrice) * 100;

                var successLog = new Log
                {
                    Message = $"⚡ SİNYAL GELDİ: Alım Yapıldı! Fiyat: ${currentPrice}. Hedef: ${signal.TargetPrice:F8}",
                    Level = Kripteks.Core.Entities.LogLevel.Info,
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
        AppDbContext context, INotificationService notificationService, ILogService logService)
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

            IStrategy strategy = GetStrategy(bot.StrategyName);
            if (strategy != null)
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

                    var signal = strategy.Analyze(candles, 0, bot.Amount / bot.EntryPrice);

                    if (signal.Action == TradeAction.Sell)
                    {
                        strategyExitSignal = true;
                        exitReason = signal.Description;
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
                            Level = Kripteks.Core.Entities.LogLevel.Info, Timestamp = DateTime.UtcNow
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
                Type = Kripteks.Core.Entities.TransactionType.BotReturn,
                Description = $"Bot Kapatıldı: {bot.Symbol} | {reason}",
                CreatedAt = DateTime.UtcNow
            });

            await notificationService.NotifyWalletUpdate(wallet);
        }

        var log1 = new Log
            { Message = reason, Level = Kripteks.Core.Entities.LogLevel.Info, Timestamp = DateTime.UtcNow };
        var log2 = new Log
        {
            Message = $"🏁 İşlem Sonlandı. Kasa: {wallet?.Balance:F2}", Level = Kripteks.Core.Entities.LogLevel.Info,
            Timestamp = DateTime.UtcNow
        };

        bot.Logs.Add(log1);
        bot.Logs.Add(log2);

        // SİSTEM LOGU
        await logService.LogInfoAsync($"Bot Kapandı: {bot.Symbol}. Sonuç: ${pnlAmount:F2}. Sebep: {reason}",
            bot.Id); // <--- LOG

        await notificationService.NotifyLog(bot.Id.ToString(), log1);
        await notificationService.NotifyLog(bot.Id.ToString(), log2);
        await notificationService.NotifyBotUpdate(ToDto(bot));
    }

    private IStrategy GetStrategy(string id)
    {
        if (id == "strategy-market-buy") return new MarketBuyStrategy();
        if (id == "strategy-golden-rose") return new GoldenRoseStrategy();
        return new GoldenRoseStrategy(); // Fallback
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
            Logs = bot.Logs
        };
    }
}
