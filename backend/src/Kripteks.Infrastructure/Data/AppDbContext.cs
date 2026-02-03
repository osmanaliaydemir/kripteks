using Kripteks.Core.Entities;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace Kripteks.Infrastructure.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : IdentityDbContext<AppUser>(options)
{
    public DbSet<Bot> Bots { get; set; }
    public DbSet<Trade> Trades { get; set; }
    public DbSet<Wallet> Wallets { get; set; }
    public DbSet<WalletTransaction> WalletTransactions { get; set; }
    public DbSet<Log> Logs { get; set; }
    public DbSet<ExchangeCredential> ExchangeCredentials { get; set; }
    public DbSet<SystemSetting> SystemSettings { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<AuditLog> AuditLogs { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Trade -> Bot Relationship
        modelBuilder.Entity<Trade>()
            .HasOne(t => t.Bot)
            .WithMany(b => b.Trades)
            .HasForeignKey(t => t.BotId);

        // Precision ayarları (Para birimleri için önemlidir)
        modelBuilder.Entity<Bot>().Property(p => p.Amount).HasPrecision(18, 8);
        modelBuilder.Entity<Bot>().Property(p => p.StopLoss).HasPrecision(18, 8);
        modelBuilder.Entity<Bot>().Property(p => p.TakeProfit).HasPrecision(18, 8);
        modelBuilder.Entity<Bot>().Property(p => p.EntryPrice).HasPrecision(18, 8);
        modelBuilder.Entity<Bot>().Property(p => p.CurrentPnl).HasPrecision(18, 8);
        modelBuilder.Entity<Bot>().Property(p => p.CurrentPnlPercent).HasPrecision(18, 8);
        modelBuilder.Entity<Bot>().Property(p => p.TrailingStopDistance).HasPrecision(18, 8);
        modelBuilder.Entity<Bot>().Property(p => p.MaxPriceReached).HasPrecision(18, 8);

        modelBuilder.Entity<Trade>().Property(p => p.Price).HasPrecision(18, 8);
        modelBuilder.Entity<Trade>().Property(p => p.Quantity).HasPrecision(18, 8);
        modelBuilder.Entity<Trade>().Property(p => p.Total).HasPrecision(18, 8);

        modelBuilder.Entity<Wallet>().Property(p => p.Balance).HasPrecision(18, 8);
        modelBuilder.Entity<Wallet>().Property(p => p.LockedBalance).HasPrecision(18, 8);

        modelBuilder.Entity<WalletTransaction>().Property(p => p.Amount).HasPrecision(18, 8);

        // Enum dönüşümleri (String olarak kaydetmek daha okunaklı olur)
        modelBuilder.Entity<Bot>()
            .Property(b => b.Status)
            .HasConversion<string>();

        modelBuilder.Entity<Trade>()
            .Property(t => t.Type)
            .HasConversion<string>();

        modelBuilder.Entity<Log>()
            .Property(l => l.Level)
            .HasConversion<string>();
        modelBuilder.Entity<SystemSetting>()
            .Property(s => s.GlobalStopLossPercent)
            .HasPrecision(18, 4);

        modelBuilder.Entity<SystemSetting>()
            .Property(s => s.DefaultAmount)
            .HasPrecision(18, 8);
    }
}
