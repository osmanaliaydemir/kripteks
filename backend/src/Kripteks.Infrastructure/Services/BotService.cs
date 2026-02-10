using Kripteks.Core.DTOs;
using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Kripteks.Infrastructure.Services;

public class BotService : IBotService
{
    private readonly AppDbContext _context;
    private readonly INotificationService _notificationService;

    public BotService(AppDbContext context, INotificationService notificationService)
    {
        _context = context;
        _notificationService = notificationService;
    }

    public async Task<List<BotDto>> GetAllBotsAsync()
    {
        return await _context.Bots
            .Where(b => !b.IsArchived)
            .OrderByDescending(b => b.CreatedAt)
            .Select(b => new BotDto
            {
                Id = b.Id,
                Symbol = b.Symbol,
                StrategyName = b.StrategyName,
                Amount = b.Amount,
                Interval = b.Interval,
                StopLoss = b.StopLoss,
                TakeProfit = b.TakeProfit,
                Status = b.Status.ToString(),
                CreatedAt = DateTime.SpecifyKind(b.CreatedAt, DateTimeKind.Utc),
                Pnl = b.CurrentPnl,
                PnlPercent = b.CurrentPnlPercent,
                EntryPrice = b.EntryPrice,
                EntryDate = b.EntryDate.HasValue ? DateTime.SpecifyKind(b.EntryDate.Value, DateTimeKind.Utc) : null,
                ExitDate = b.ExitDate.HasValue ? DateTime.SpecifyKind(b.ExitDate.Value, DateTimeKind.Utc) : null,
                IsTrailingStop = b.IsTrailingStop,
                TrailingStopDistance = b.TrailingStopDistance,
                MaxPriceReached = b.MaxPriceReached,
                IsArchived = b.IsArchived,
                Logs = b.Logs
                    .OrderByDescending(l => l.Timestamp)
                    .Take(50)
                    .Select(l => new LogDto
                    {
                        Id = l.Id,
                        Message = l.Message,
                        Level = l.Level.ToString(),
                        Timestamp = DateTime.SpecifyKind(l.Timestamp, DateTimeKind.Utc)
                    })
                    .ToList()
            })
            .ToListAsync();
    }

    public async Task<BotDto> GetBotByIdAsync(Guid id)
    {
        var bot = await _context.Bots.FindAsync(id);
        if (bot == null) return null!;

        var logs = await _context.Logs
            .Where(l => l.BotId == id)
            .OrderByDescending(l => l.Timestamp)
            .ToListAsync();

        var trades = await _context.Trades
            .Where(t => t.BotId == id)
            .OrderByDescending(t => t.Timestamp)
            .ToListAsync();

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
            EntryPrice = bot.EntryPrice,
            EntryDate = bot.EntryDate.HasValue ? DateTime.SpecifyKind(bot.EntryDate.Value, DateTimeKind.Utc) : null,
            ExitDate = bot.ExitDate.HasValue ? DateTime.SpecifyKind(bot.ExitDate.Value, DateTimeKind.Utc) : null,
            Logs = logs.Select(l => new LogDto
            {
                Id = l.Id,
                Message = l.Message,
                Level = l.Level.ToString(),
                Timestamp = DateTime.SpecifyKind(l.Timestamp, DateTimeKind.Utc)
            }).ToList(),
            IsTrailingStop = bot.IsTrailingStop,
            TrailingStopDistance = bot.TrailingStopDistance,
            MaxPriceReached = bot.MaxPriceReached,
            IsArchived = bot.IsArchived,
            Trades = trades
        };
    }

    public async Task<BotDto> CreateBotAsync(CreateBotRequest request)
    {
        // 1. Cüzdan ve Bakiye Kontrolü
        var wallet = await _context.Wallets.FirstOrDefaultAsync();
        if (wallet == null) throw new Exception("Cüzdan bulunamadı!");

        // 2. Bakiye Kontrol ve Bloke Mantığı
        bool isImmediateBuy = request.StrategyId == "strategy-market-buy";

        if (isImmediateBuy)
        {
            // Hemen Al ise bakiyeyi kes
            if (wallet.Balance < request.Amount)
            {
                throw new InvalidOperationException(
                    $"Yetersiz Bakiye! Mevcut: {wallet.Balance}, İstenen: {request.Amount}");
            }

            wallet.Balance -= request.Amount;
            wallet.LockedBalance += request.Amount;
            wallet.LastUpdated = DateTime.UtcNow;

            var transaction = new WalletTransaction
            {
                WalletId = wallet.Id,
                Amount = -request.Amount,
                Type = TransactionType.BotInvestment,
                Description = $"Bot Başlatıldı (Hemen Al): {request.Symbol}",
                CreatedAt = DateTime.UtcNow
            };
            _context.WalletTransactions.Add(transaction);
        }

        // 3. Anlık fiyatı çek (Sadece bilgi amaçlı - İleride log için kullanılabilir)
        // decimal currentPrice = await _marketService.GetPriceAsync(request.Symbol);

        var bot = new Bot
        {
            Symbol = request.Symbol,
            StrategyName = request.StrategyId,
            Amount = request.Amount,
            Interval = request.Interval,
            StopLoss = request.StopLoss,
            TakeProfit = request.TakeProfit,
            IsTrailingStop = request.IsTrailingStop,
            TrailingStopDistance = request.TrailingStopDistance,
            Status = BotStatus.WaitingForEntry, // Pusu Modu
            EntryPrice = 0, // Henüz almadık
            CurrentPnl = 0,
            CurrentPnlPercent = 0,
            StrategyParams = request.StrategyParameters != null
                ? System.Text.Json.JsonSerializer.Serialize(request.StrategyParameters)
                : null,
            CreatedAt = DateTime.UtcNow,
            Logs = new List<Log>
            {
                new Log
                {
                    Message = $"👀 Bot Pusuya Yattı! {request.Symbol} için {request.StrategyId} sinyali bekleniyor...",
                    Level = LogLevel.Info,
                    Timestamp = DateTime.UtcNow
                }
            }
        };

        _context.Bots.Add(bot);
        await _context.SaveChangesAsync();

        await _notificationService.SendNotificationAsync(
            $"🚀 Bot Başlatıldı: {request.Symbol}",
            $"Strateji: {request.StrategyId} | Tutar: ${request.Amount} | Sinyal bekleniyor...",
            NotificationType.Info,
            bot.Id);

        return await GetBotByIdAsync(bot.Id);
    }

    public async Task StopBotAsync(Guid id)
    {
        var bot = await _context.Bots.FindAsync(id);
        if (bot == null) return;

        // Sadece Aktif Olanları Durdur (WaitingForEntry veya Running)
        if (bot.Status == BotStatus.Running || bot.Status == BotStatus.WaitingForEntry)
        {
            var oldStatus = bot.Status;
            bot.Status = BotStatus.Stopped;
            // bot.UpdatedAt = DateTime.UtcNow; // Entity'de yok

            var log = new Log
            {
                Message = "Bot kullanıcı tarafından manuel durduruldu.", Level = LogLevel.Warning,
                Timestamp = DateTime.UtcNow, BotId = bot.Id
            };
            _context.Logs.Add(log);

            bool shouldRefund =
                bot.Status == BotStatus.Running; // Running ise kesin pozisyondadır (veya bloke bakiyedir)

            // Eğer WaitingForEntry ise ve Market Al (Hemen Al) seçildiyse para başta kesilmişti.
            if (oldStatus == BotStatus.WaitingForEntry && bot.StrategyName == "strategy-market-buy")
            {
                shouldRefund = true;
            }

            if (shouldRefund)
            {
                var wallet = await _context.Wallets.FirstOrDefaultAsync();
                if (wallet != null)
                {
                    wallet.LockedBalance -= bot.Amount;

                    // Eğer pozisyon açıksa PNL'i de hesaba kat
                    decimal pnl = bot.CurrentPnl; // WaitingForEntry ise 0 dır zaten
                    decimal returnAmount = bot.Amount + pnl;

                    wallet.Balance += returnAmount;
                    wallet.LastUpdated = DateTime.UtcNow;

                    _context.WalletTransactions.Add(new WalletTransaction
                    {
                        WalletId = wallet.Id,
                        Amount = returnAmount,
                        Type = TransactionType.BotReturn,
                        Description = $"Manuel Durdurma: {bot.Symbol}",
                        CreatedAt = DateTime.UtcNow
                    });

                    await _notificationService.NotifyWalletUpdate(wallet);
                }
            }

            await _context.SaveChangesAsync();

            // Client'ı Bilgilendir
            await _notificationService.NotifyBotUpdate(new BotDto
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
                IsArchived = bot.IsArchived,
                Logs = bot.Logs.Select(l => new LogDto
                {
                    Id = l.Id,
                    Message = l.Message,
                    Level = l.Level.ToString(),
                    Timestamp = DateTime.SpecifyKind(l.Timestamp, DateTimeKind.Utc)
                }).ToList()
            });
            await _notificationService.NotifyLog(bot.Id.ToString(), new LogDto
            {
                Id = log.Id,
                Message = log.Message,
                Level = log.Level.ToString(),
                Timestamp = DateTime.SpecifyKind(log.Timestamp, DateTimeKind.Utc)
            });

            await _notificationService.SendNotificationAsync(
                $"⏹️ Bot Durduruldu: {bot.Symbol}",
                $"Manuel durdurma | PNL: ${bot.CurrentPnl:F2} (%{bot.CurrentPnlPercent:F2})",
                NotificationType.Warning,
                bot.Id);
        }
    }

    public async Task StopAllBotsAsync()
    {
        var activeBots = await _context.Bots
            .Where(b => b.Status == BotStatus.Running || b.Status == BotStatus.WaitingForEntry)
            .ToListAsync();

        foreach (var bot in activeBots)
        {
            await StopBotAsync(bot.Id);
        }

        if (activeBots.Count > 0)
        {
            await _notificationService.SendNotificationAsync(
                "⏹️ Tüm Botlar Durduruldu",
                $"{activeBots.Count} bot manuel olarak durduruldu.",
                NotificationType.Warning);
        }
    }

    public async Task ClearLogsAsync(Guid id)
    {
        var logs = await _context.Logs.Where(l => l.BotId == id).ToListAsync();
        _context.Logs.RemoveRange(logs);
        await _context.SaveChangesAsync();
    }

    public async Task ArchiveHistoryAsync()
    {
        var historyBots = await _context.Bots
            .Where(b => (b.Status == BotStatus.Stopped || b.Status == BotStatus.Completed) && !b.IsArchived)
            .ToListAsync();

        if (!historyBots.Any()) return;

        foreach (var bot in historyBots)
        {
            bot.IsArchived = true;
        }

        await _context.SaveChangesAsync();
    }
}
