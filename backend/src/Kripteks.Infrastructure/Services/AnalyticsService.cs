using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Kripteks.Infrastructure.Services;

public class AnalyticsService : IAnalyticsService
{
    private readonly AppDbContext _context;

    public AnalyticsService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<DashboardStats> GetDashboardStatsAsync()
    {
        var completedBots = await _context.Bots
            .Where(b => b.Status == BotStatus.Completed || b.Status == BotStatus.Stopped)
            .ToListAsync();

        if (!completedBots.Any()) return new DashboardStats();

        var totalTrades = completedBots.Count;
        var winningTrades = completedBots.Count(b => b.CurrentPnl > 0);
        var totalPnl = completedBots.Sum(b => b.CurrentPnl);
        
        // En iyi pariteyi bul
        var bestPair = completedBots
            .GroupBy(b => b.Symbol)
            .Select(g => new { Symbol = g.Key, Pnl = g.Sum(b => b.CurrentPnl) })
            .OrderByDescending(x => x.Pnl)
            .FirstOrDefault()?.Symbol ?? "-";

        return new DashboardStats
        {
            TotalTrades = totalTrades,
            WinningTrades = winningTrades,
            WinRate = totalTrades > 0 ? (decimal)winningTrades / totalTrades * 100 : 0,
            TotalPnl = totalPnl,
            BestPair = bestPair
        };
    }

    public async Task<List<EquityPoint>> GetEquityCurveAsync()
    {
        var transactions = await _context.WalletTransactions
            .OrderBy(t => t.CreatedAt)
            .ToListAsync();

        var wallet = await _context.Wallets.FirstOrDefaultAsync();
        decimal currentBalance = wallet?.Balance ?? 0; // Şu anki bakiye (kilitli dahil değil, net varlık lazım aslında)
        
        // Equity Curve hesabı için cüzdanın 'toplam değeri'ni (Locked + Free) kullanmak daha doğru olur.
        // Ancak basitlik adına transaction history üzerinden gideceğiz.
        // Başlangıç bakiyesi = Şu anki - (Tüm işlemlerin toplamı)
        
        // Daha basit yöntem: Her günün sonundaki bakiyeyi hesaplalayalım.
        // Varsayalım başlangıç 1000 USDT.
        // İşlemleri kümülatif toplayalım.
        
        var points = new List<EquityPoint>();
        decimal runningBalance = 1000; // Varsayılan başlangıç, bunu aslında ilk transaction öncesi bakiye olarak bulmalıyız.
        
        // Veya tersten gidelim: Şu anki bakiye belli. Geriye doğru işlemleri çıkartırsak geçmiş bakiyeyi buluruz.
        // Ama grafik soldan sağa çizilir.
        
        // Şöyle yapalım: Sadece BotReturn işlemlerini (Realized PNL) grafiğe dökelim.
        // "Kasa Büyümesi" grafiği.
        
        decimal pnlSum = 0;
        
        // Son 30 gün
        var startDate = DateTime.UtcNow.AddDays(-30);

        // Her gün için veri noktası oluştur
        for (int i = 0; i <= 30; i++)
        {
            var date = startDate.AddDays(i).Date;
            var dailyPnl = transactions
                .Where(t => t.CreatedAt.Date == date && t.Type == TransactionType.BotReturn)
                .Sum(t => 
                {
                    // BotReturn, "Anapara + Kar" döner. Biz sadece karı bulmak istiyoruz.
                    // Bu yapı biraz zor, çünkü transactionda sadece toplam tutar var.
                    // Bot tablosundan gitmek daha mantıklı!
                    return 0; 
                });
        }

        // YÖNTEM DEĞİŞİKLİĞİ: Transaction yerine Bot History üzerinden PNL grafiği
        var bots = await _context.Bots
             .Where(b => (b.Status == BotStatus.Completed || b.Status == BotStatus.Stopped) && b.CreatedAt >= startDate)
             .OrderBy(b => b.CreatedAt) // Kapanış tarihi yerine açılış kullanıyoruz (MVP)
             .ToListAsync();

        decimal cumulativePnl = 0;
        
        // Her bot kapandığında grafiğe bir nokta ekle
        foreach (var bot in bots)
        {
            cumulativePnl += bot.CurrentPnl;
            points.Add(new EquityPoint 
            {
                Date = bot.CreatedAt.ToString("dd MMM HH:mm"),
                Balance = cumulativePnl 
            });
        }
        
        // Eğer hiç işlem yoksa boş dönebilir veya 0 noktası
        if (!points.Any())
        {
             points.Add(new EquityPoint { Date = DateTime.Now.ToString("dd MMM"), Balance = 0 });
        }

        return points;
    }

    public async Task<List<StrategyPerformance>> GetStrategyPerformanceAsync()
    {
        var bots = await _context.Bots
            .Where(b => b.Status == BotStatus.Completed || b.Status == BotStatus.Stopped)
            .ToListAsync();

        return bots
            .GroupBy(b => b.StrategyName)
            .Select(g => new StrategyPerformance
            {
                StrategyName = g.Key,
                TotalTrades = g.Count(),
                TotalPnl = g.Sum(b => b.CurrentPnl),
                WinRate = g.Count() > 0 ? (decimal)g.Count(b => b.CurrentPnl > 0) / g.Count() * 100 : 0
            })
            .ToList();
    }
}
