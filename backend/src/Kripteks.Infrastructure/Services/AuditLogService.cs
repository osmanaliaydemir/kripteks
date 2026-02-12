using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace Kripteks.Infrastructure.Services;

public class AuditLogService(
    IServiceScopeFactory scopeFactory,
    IHttpContextAccessor httpContextAccessor,
    ILogger<AuditLogService> logger) : IAuditLogService
{
    // ── Mevcut (geriye uyumluluk) ──
    public async Task LogAsync(string userId, string action, object? metadata = null)
    {
        // Mevcut çağrılarda kategoriyi otomatik belirle
        var category = InferCategory(action);
        await LogAsync(userId, action, category, AuditSeverity.Info, metadata);
    }

    public async Task LogAnonymousAsync(string action, object? metadata = null)
    {
        var category = InferCategory(action);
        await LogCoreAsync(null, "Anonymous", action, category, AuditSeverity.Info,
            metadata: metadata);
    }

    // ── Genişletilmiş ──
    public async Task LogAsync(string userId, string action, AuditCategory category,
        AuditSeverity severity = AuditSeverity.Info, object? metadata = null,
        string? entityId = null, string? entityType = null,
        string? oldValue = null, string? newValue = null)
    {
        try
        {
            using var scope = scopeFactory.CreateScope();
            var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();
            var user = await userManager.FindByIdAsync(userId);
            var userEmail = user?.Email ?? "Unknown";

            await LogCoreAsync(userId, userEmail, action, category, severity,
                metadata, entityId, entityType, oldValue, newValue);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Audit Log Error: {Action}", action);
        }
    }

    public async Task LogTradeAsync(string? userId, string symbol, string tradeAction,
        decimal price, decimal amount, Guid? botId = null, object? metadata = null)
    {
        var tradeMetadata = new
        {
            Symbol = symbol,
            TradeAction = tradeAction,
            Price = price,
            Amount = amount,
            BotId = botId?.ToString(),
            AdditionalData = metadata
        };

        await LogCoreAsync(userId, null, $"Trade {tradeAction}: {symbol}",
            AuditCategory.Trade, AuditSeverity.Info,
            tradeMetadata, botId?.ToString(), "Trade");
    }

    public async Task LogWalletChangeAsync(string? userId, string action,
        decimal oldBalance, decimal newBalance, decimal changeAmount,
        string? description = null)
    {
        var walletMetadata = new
        {
            Description = description,
            ChangeAmount = changeAmount
        };

        await LogCoreAsync(userId, null, action,
            AuditCategory.Wallet, AuditSeverity.Info,
            walletMetadata, entityType: "Wallet",
            oldValue: $"₿ {oldBalance:F2}",
            newValue: $"₿ {newBalance:F2}");
    }

    // ── Sorgulama ──
    public async Task<AuditQueryResult> QueryLogsAsync(AuditQueryRequest request)
    {
        try
        {
            using var scope = scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            var query = context.AuditLogs.AsNoTracking().AsQueryable();

            // Filtreler
            if (!string.IsNullOrWhiteSpace(request.UserId))
                query = query.Where(a => a.UserId == request.UserId);

            if (request.Category.HasValue)
                query = query.Where(a => a.Category == request.Category.Value);

            if (request.Severity.HasValue)
                query = query.Where(a => a.Severity == request.Severity.Value);

            if (request.StartDate.HasValue)
                query = query.Where(a => a.Timestamp >= request.StartDate.Value);

            if (request.EndDate.HasValue)
                query = query.Where(a => a.Timestamp <= request.EndDate.Value);

            if (!string.IsNullOrWhiteSpace(request.EntityType))
                query = query.Where(a => a.EntityType == request.EntityType);

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
                query = query.Where(a =>
                    a.Action.Contains(request.SearchTerm) ||
                    (a.Metadata != null && a.Metadata.Contains(request.SearchTerm)) ||
                    a.UserEmail.Contains(request.SearchTerm));

            var totalCount = await query.CountAsync();

            var items = await query
                .OrderByDescending(a => a.Timestamp)
                .Skip((request.Page - 1) * request.PageSize)
                .Take(request.PageSize)
                .Select(a => new AuditLogDto
                {
                    Id = a.Id,
                    UserId = a.UserId,
                    UserEmail = a.UserEmail,
                    Action = a.Action,
                    Category = a.Category.ToString(),
                    Severity = a.Severity.ToString(),
                    EntityId = a.EntityId,
                    EntityType = a.EntityType,
                    OldValue = a.OldValue,
                    NewValue = a.NewValue,
                    Metadata = a.Metadata,
                    IpAddress = a.IpAddress,
                    UserAgent = a.UserAgent,
                    Timestamp = a.Timestamp
                })
                .ToListAsync();

            return new AuditQueryResult
            {
                Items = items,
                TotalCount = totalCount,
                Page = request.Page,
                PageSize = request.PageSize
            };
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Audit Log Query Error");
            return new AuditQueryResult();
        }
    }

    // ── Compliance Rapor ──
    public async Task<ComplianceReport> GenerateComplianceReportAsync(
        string userId, DateTime startDate, DateTime endDate)
    {
        using var scope = scopeFactory.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();

        var user = await userManager.FindByIdAsync(userId);
        var report = new ComplianceReport
        {
            UserId = userId,
            UserEmail = user?.Email ?? "Unknown",
            StartDate = startDate,
            EndDate = endDate,
            GeneratedAt = DateTime.UtcNow
        };

        // 1. Trade loglarını çek
        var tradeLogs = await context.AuditLogs
            .AsNoTracking()
            .Where(a => a.Category == AuditCategory.Trade
                        && a.Timestamp >= startDate
                        && a.Timestamp <= endDate)
            .OrderBy(a => a.Timestamp)
            .ToListAsync();

        foreach (var log in tradeLogs)
        {
            if (string.IsNullOrEmpty(log.Metadata)) continue;

            try
            {
                var meta = JsonSerializer.Deserialize<JsonElement>(log.Metadata);
                var entry = new ComplianceTradeEntry
                {
                    Timestamp = log.Timestamp,
                    Symbol = meta.TryGetProperty("Symbol", out var sym) ? sym.GetString() ?? "" : "",
                    Action = meta.TryGetProperty("TradeAction", out var act) ? act.GetString() ?? "" : "",
                    Price = meta.TryGetProperty("Price", out var price) ? price.GetDecimal() : 0,
                    Amount = meta.TryGetProperty("Amount", out var amt) ? amt.GetDecimal() : 0,
                    BotId = meta.TryGetProperty("BotId", out var bid) ? bid.GetString() : null
                };
                entry.Total = entry.Price * entry.Amount;
                report.Trades.Add(entry);

                if (entry.Action.Equals("Buy", StringComparison.OrdinalIgnoreCase) ||
                    entry.Action.Equals("Alım", StringComparison.OrdinalIgnoreCase))
                {
                    report.BuyCount++;
                    report.TotalBuyVolume += entry.Total;
                }
                else
                {
                    report.SellCount++;
                    report.TotalSellVolume += entry.Total;
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Compliance trade parse error: {LogId}", log.Id);
            }
        }

        report.TotalTradeCount = report.BuyCount + report.SellCount;
        report.NetPnl = report.TotalSellVolume - report.TotalBuyVolume;

        // 2. Wallet değişikliklerini çek
        var walletLogs = await context.AuditLogs
            .AsNoTracking()
            .Where(a => a.Category == AuditCategory.Wallet
                        && a.Timestamp >= startDate
                        && a.Timestamp <= endDate)
            .OrderBy(a => a.Timestamp)
            .ToListAsync();

        decimal totalDeposits = 0;
        decimal totalWithdrawals = 0;

        foreach (var log in walletLogs)
        {
            var entry = new ComplianceWalletEntry
            {
                Timestamp = log.Timestamp,
                Action = log.Action
            };

            if (decimal.TryParse(log.OldValue?.Replace("₿ ", ""), out var oldVal))
                entry.OldBalance = oldVal;
            if (decimal.TryParse(log.NewValue?.Replace("₿ ", ""), out var newVal))
                entry.NewBalance = newVal;

            if (log.Metadata != null)
            {
                try
                {
                    var meta = JsonSerializer.Deserialize<JsonElement>(log.Metadata);
                    entry.ChangeAmount = meta.TryGetProperty("ChangeAmount", out var ca) ? ca.GetDecimal() : 0;
                    entry.Description = meta.TryGetProperty("Description", out var desc)
                        ? desc.GetString()
                        : null;
                }
                catch
                {
                    /* Eski format loglar */
                }
            }

            report.WalletChanges.Add(entry);

            if (entry.ChangeAmount > 0)
                totalDeposits += entry.ChangeAmount;
            else
                totalWithdrawals += Math.Abs(entry.ChangeAmount);
        }

        // 3. Özet
        var wallet = await context.Wallets.AsNoTracking().FirstOrDefaultAsync();
        var activePnl = await context.Bots
            .AsNoTracking()
            .Where(b => b.Status == BotStatus.Running)
            .SumAsync(b => b.CurrentPnl);

        report.Summary = new ComplianceSummary
        {
            EndingBalance = wallet?.Balance ?? 0,
            TotalDeposits = totalDeposits,
            TotalWithdrawals = totalWithdrawals,
            RealizedPnl = report.NetPnl,
            UnrealizedPnl = activePnl
        };

        return report;
    }

    // ── Dahili Yardımcı ──
    private async Task LogCoreAsync(string? userId, string? userEmail, string action,
        AuditCategory category, AuditSeverity severity,
        object? metadata = null, string? entityId = null, string? entityType = null,
        string? oldValue = null, string? newValue = null)
    {
        try
        {
            using var scope = scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            // UserEmail çözümle (userId varsa ama email yoksa)
            if (string.IsNullOrEmpty(userEmail) && !string.IsNullOrEmpty(userId))
            {
                var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();
                var user = await userManager.FindByIdAsync(userId);
                userEmail = user?.Email ?? "Unknown";
            }

            var httpContext = httpContextAccessor.HttpContext;

            var auditLog = new AuditLog
            {
                UserId = userId,
                UserEmail = userEmail ?? "System",
                Action = action,
                Category = category,
                Severity = severity,
                EntityId = entityId,
                EntityType = entityType,
                OldValue = oldValue,
                NewValue = newValue,
                Metadata = metadata != null ? JsonSerializer.Serialize(metadata) : null,
                IpAddress = httpContext is not null ? httpContext.Connection.RemoteIpAddress?.ToString() : null,
                UserAgent = httpContext is not null ? httpContext.Request.Headers.UserAgent.ToString() : null,
                Timestamp = DateTime.UtcNow
            };

            context.AuditLogs.Add(auditLog);
            await context.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Audit Log Core Error: {Action}", action);
        }
    }

    /// <summary>
    /// Mevcut action string'lerinden kategori çıkar (geriye uyumluluk).
    /// </summary>
    private static AuditCategory InferCategory(string action)
    {
        if (action.Contains("Giriş", StringComparison.OrdinalIgnoreCase) ||
            action.Contains("Şifre", StringComparison.OrdinalIgnoreCase) ||
            action.Contains("Login", StringComparison.OrdinalIgnoreCase) ||
            action.Contains("Kayıt", StringComparison.OrdinalIgnoreCase))
            return AuditCategory.Auth;

        if (action.Contains("Bot", StringComparison.OrdinalIgnoreCase))
            return AuditCategory.Bot;

        if (action.Contains("Ayar", StringComparison.OrdinalIgnoreCase) ||
            action.Contains("Setting", StringComparison.OrdinalIgnoreCase) ||
            action.Contains("API Anahtar", StringComparison.OrdinalIgnoreCase) ||
            action.Contains("Bildirim", StringComparison.OrdinalIgnoreCase))
            return AuditCategory.Settings;

        if (action.Contains("Kullanıcı", StringComparison.OrdinalIgnoreCase))
            return AuditCategory.Auth;

        return AuditCategory.System;
    }
}
