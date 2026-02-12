namespace Kripteks.Core.Entities;

public class AuditLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string? UserId { get; set; }
    public string UserEmail { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public AuditCategory Category { get; set; } = AuditCategory.System;
    public AuditSeverity Severity { get; set; } = AuditSeverity.Info;
    public string? EntityId { get; set; }
    public string? EntityType { get; set; }
    public string? OldValue { get; set; }
    public string? NewValue { get; set; }
    public string? Metadata { get; set; } // JSON string
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}

public enum AuditCategory
{
    Auth, // Giriş, çıkış, şifre işlemleri
    Trade, // Alım-satım işlemleri
    Wallet, // Bakiye değişimleri
    Settings, // Ayar değişiklikleri
    Bot, // Bot başlatma/durdurma
    System // Genel sistem işlemleri
}

public enum AuditSeverity
{
    Info,
    Warning,
    Critical
}
