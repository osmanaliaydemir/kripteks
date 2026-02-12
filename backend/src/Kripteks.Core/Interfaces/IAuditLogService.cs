using Kripteks.Core.Entities;

namespace Kripteks.Core.Interfaces;

public interface IAuditLogService
{
    // ── Mevcut (geriye uyumluluk) ──
    Task LogAsync(string userId, string action, object? metadata = null);
    Task LogAnonymousAsync(string action, object? metadata = null);

    // ── Genişletilmiş ──
    Task LogAsync(string userId, string action, AuditCategory category,
        AuditSeverity severity = AuditSeverity.Info, object? metadata = null,
        string? entityId = null, string? entityType = null,
        string? oldValue = null, string? newValue = null);

    /// <summary>
    /// Trade işlemlerini otomatik loglar (BotEngineService tarafından çağrılır).
    /// </summary>
    Task LogTradeAsync(string? userId, string symbol, string tradeAction,
        decimal price, decimal amount, Guid? botId = null, object? metadata = null);

    /// <summary>
    /// Bakiye değişikliklerini otomatik loglar.
    /// </summary>
    Task LogWalletChangeAsync(string? userId, string action,
        decimal oldBalance, decimal newBalance, decimal changeAmount,
        string? description = null);

    // ── Sorgulama ──
    Task<AuditQueryResult> QueryLogsAsync(AuditQueryRequest request);

    /// <summary>
    /// Vergi/compliance raporu üretir.
    /// </summary>
    Task<ComplianceReport> GenerateComplianceReportAsync(string userId,
        DateTime startDate, DateTime endDate);
}

// ── Sorgulama Model'leri ──
public class AuditQueryRequest
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 50;
    public string? UserId { get; set; }
    public AuditCategory? Category { get; set; }
    public AuditSeverity? Severity { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? SearchTerm { get; set; }
    public string? EntityType { get; set; }
}

public class AuditQueryResult
{
    public List<AuditLogDto> Items { get; set; } = [];
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}

public class AuditLogDto
{
    public Guid Id { get; set; }
    public string? UserId { get; set; }
    public string UserEmail { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Severity { get; set; } = string.Empty;
    public string? EntityId { get; set; }
    public string? EntityType { get; set; }
    public string? OldValue { get; set; }
    public string? NewValue { get; set; }
    public string? Metadata { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public DateTime Timestamp { get; set; }
}

// ── Compliance Report ──
public class ComplianceReport
{
    public string UserId { get; set; } = string.Empty;
    public string UserEmail { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;

    public int TotalTradeCount { get; set; }
    public int BuyCount { get; set; }
    public int SellCount { get; set; }
    public decimal TotalBuyVolume { get; set; }
    public decimal TotalSellVolume { get; set; }
    public decimal NetPnl { get; set; }

    public List<ComplianceTradeEntry> Trades { get; set; } = [];
    public List<ComplianceWalletEntry> WalletChanges { get; set; } = [];
    public ComplianceSummary Summary { get; set; } = new();
}

public class ComplianceTradeEntry
{
    public DateTime Timestamp { get; set; }
    public string Symbol { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal Amount { get; set; }
    public decimal Total { get; set; }
    public string? BotId { get; set; }
}

public class ComplianceWalletEntry
{
    public DateTime Timestamp { get; set; }
    public string Action { get; set; } = string.Empty;
    public decimal OldBalance { get; set; }
    public decimal NewBalance { get; set; }
    public decimal ChangeAmount { get; set; }
    public string? Description { get; set; }
}

public class ComplianceSummary
{
    public decimal StartingBalance { get; set; }
    public decimal EndingBalance { get; set; }
    public decimal TotalDeposits { get; set; }
    public decimal TotalWithdrawals { get; set; }
    public decimal TotalFees { get; set; }
    public decimal RealizedPnl { get; set; }
    public decimal UnrealizedPnl { get; set; }
}
