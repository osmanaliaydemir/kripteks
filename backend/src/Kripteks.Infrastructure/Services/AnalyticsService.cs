using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

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
        var losingTrades = totalTrades - winningTrades;
        var totalPnl = completedBots.Sum(b => b.CurrentPnl);

        var totalProfit = completedBots.Where(b => b.CurrentPnl > 0).Sum(b => b.CurrentPnl);
        var totalLoss = Math.Abs(completedBots.Where(b => b.CurrentPnl < 0).Sum(b => b.CurrentPnl));
        var profitFactor = totalLoss > 0 ? totalProfit / totalLoss : totalProfit;

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
            LosingTrades = losingTrades,
            WinRate = totalTrades > 0 ? (decimal)winningTrades / totalTrades * 100 : 0,
            TotalPnl = totalPnl,
            ProfitFactor = profitFactor,
            AvgTradePnL = totalTrades > 0 ? totalPnl / totalTrades : 0,
            BestPair = bestPair,
            MaxDrawdown = CalculateMaxDrawdown(completedBots.Select(b => b.CurrentPnl).ToList())
        };
    }

    public async Task<List<EquityPoint>> GetEquityCurveAsync()
    {
        var startDate = DateTime.UtcNow.AddDays(-30).Date;
        var completedBots = await _context.Bots
            .Where(b => (b.Status == BotStatus.Completed || b.Status == BotStatus.Stopped) && b.CreatedAt >= startDate)
            .OrderBy(b => b.CreatedAt)
            .ToListAsync();

        var points = new List<EquityPoint>();
        decimal cumulativePnl = 0;

        // Başlangıç noktası
        points.Add(new EquityPoint { Date = startDate.ToString("dd MMM HH:mm"), Balance = 0, DailyPnl = 0 });

        foreach (var bot in completedBots)
        {
            cumulativePnl += bot.CurrentPnl;
            points.Add(new EquityPoint
            {
                Date = bot.CreatedAt.ToString("dd MMM HH:mm"),
                Balance = cumulativePnl,
                DailyPnl = bot.CurrentPnl
            });
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
            .Select(g =>
            {
                var trades = g.ToList();
                var profit = trades.Where(t => t.CurrentPnl > 0).Sum(t => t.CurrentPnl);
                var loss = Math.Abs(trades.Where(t => t.CurrentPnl < 0).Sum(t => t.CurrentPnl));

                return new StrategyPerformance
                {
                    StrategyName = g.Key,
                    TotalTrades = trades.Count,
                    TotalPnl = trades.Sum(t => t.CurrentPnl),
                    WinRate = trades.Count > 0 ? (decimal)trades.Count(t => t.CurrentPnl > 0) / trades.Count * 100 : 0,
                    ProfitFactor = loss > 0 ? profit / loss : profit,
                    AvgTrade = trades.Count > 0 ? trades.Sum(t => t.CurrentPnl) / trades.Count : 0
                };
            })
            .ToList();
    }

    private decimal CalculateMaxDrawdown(List<decimal> pnlList)
    {
        if (!pnlList.Any()) return 0;

        decimal peak = 0;
        decimal maxDrawdown = 0;
        decimal currentEquity = 0;

        foreach (var pnl in pnlList)
        {
            currentEquity += pnl;
            if (currentEquity > peak) peak = currentEquity;

            decimal drawdown = peak - currentEquity;
            if (drawdown > maxDrawdown) maxDrawdown = drawdown;
        }

        return maxDrawdown;
    }
}
