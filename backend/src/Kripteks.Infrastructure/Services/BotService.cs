using Kripteks.Core.DTOs;
using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Kripteks.Infrastructure.Services;

public class BotService : IBotService
{
    private readonly AppDbContext _context;
    private readonly IMarketDataService _marketService;
    private readonly INotificationService _notificationService;

    public BotService(AppDbContext context, IMarketDataService marketService, INotificationService notificationService)
    {
        _context = context;
        _marketService = marketService;
        _notificationService = notificationService;
    }

    public async Task<List<BotDto>> GetAllBotsAsync()
    {
        var bots = await _context.Bots
            .OrderByDescending(b => b.CreatedAt)
            .ToListAsync();

        var botDtos = new List<BotDto>();
        foreach(var b in bots)
        {
            var logs = await _context.Logs
                .Where(l => l.BotId == b.Id)
                .OrderByDescending(l => l.Timestamp)
                .Take(50)
                .ToListAsync();

            botDtos.Add(new BotDto
            {
                Id = b.Id,
                Symbol = b.Symbol,
                StrategyName = b.StrategyName,
                Amount = b.Amount,
                Interval = b.Interval,
                StopLoss = b.StopLoss,
                TakeProfit = b.TakeProfit,
                Status = b.Status.ToString(),
                CreatedAt = b.CreatedAt,
                Pnl = b.CurrentPnl,
                PnlPercent = b.CurrentPnlPercent,
                Logs = logs
            });
        }
        return botDtos;
    }

    public async Task<BotDto> GetBotByIdAsync(Guid id)
    {
        var bot = await _context.Bots.FindAsync(id);
        if (bot == null) return null;

        var logs = await _context.Logs
            .Where(l => l.BotId == id)
            .OrderByDescending(l => l.Timestamp)
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
            CreatedAt = bot.CreatedAt,
            Pnl = bot.CurrentPnl,
            PnlPercent = bot.CurrentPnlPercent,
            Logs = logs
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
                 throw new InvalidOperationException($"Yetersiz Bakiye! Mevcut: {wallet.Balance}, İstenen: {request.Amount}");
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

        // 3. Anlık fiyatı çek (Sadece bilgi amaçlı)
        decimal currentPrice = await _marketService.GetPriceAsync(request.Symbol);

        var bot = new Bot
        {
            Symbol = request.Symbol,
            StrategyName = request.StrategyId, 
            Amount = request.Amount,
            Interval = request.Interval ?? "1h",
            StopLoss = request.StopLoss,
            TakeProfit = request.TakeProfit,
            Status = BotStatus.WaitingForEntry, // Pusu Modu
            EntryPrice = 0, // Henüz almadık
            CurrentPnl = 0,
            CurrentPnlPercent = 0,
            CreatedAt = DateTime.UtcNow,
            Logs = new List<Log>
            {
                new Log 
                { 
                    Message = $"👀 Bot Pusuya Yattı! {request.Symbol} için Golden Rose sinyali bekleniyor...",
                    Level = LogLevel.Info,
                    Timestamp = DateTime.UtcNow
                }
            }
        };

        _context.Bots.Add(bot);
        await _context.SaveChangesAsync();

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

            var log = new Log { Message = "Bot kullanıcı tarafından manuel durduruldu.", Level = LogLevel.Warning, Timestamp = DateTime.UtcNow, BotId = bot.Id };
            _context.Logs.Add(log);
            
            bool shouldRefund = bot.Status == BotStatus.Running; // Running ise kesin pozisyondadır (veya bloke bakiyedir)
            
            // Eğer WaitingForEntry ise ve Market Al (Hemen Al) seçildiyse para başta kesilmişti.
            if (oldStatus == BotStatus.WaitingForEntry && bot.StrategyName == "strategy-market-buy")
            {
                 shouldRefund = true;
            }

            if (shouldRefund) 
            {
                var wallet = await _context.Wallets.FirstOrDefaultAsync();
                if (wallet != null) {
                    wallet.LockedBalance -= bot.Amount;
                    
                    // Eğer pozisyon açıksa PNL'i de hesaba kat
                    decimal pnl = bot.CurrentPnl; // WaitingForEntry ise 0 dır zaten
                    decimal returnAmount = bot.Amount + pnl;
                    
                    wallet.Balance += returnAmount;
                    wallet.LastUpdated = DateTime.UtcNow;
                    
                    _context.WalletTransactions.Add(new WalletTransaction { 
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
            await _notificationService.NotifyBotUpdate(bot);
            await _notificationService.NotifyLog(bot.Id.ToString(), log);
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
    }

    public async Task ClearLogsAsync(Guid id)
    {
        var logs = await _context.Logs.Where(l => l.BotId == id).ToListAsync();
        _context.Logs.RemoveRange(logs);
        await _context.SaveChangesAsync();
    }
}
