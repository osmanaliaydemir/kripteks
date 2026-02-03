using System;

namespace Kripteks.Core.Entities;

public class AuditLog
{
    public Guid Id { get; set; }
    public string? UserId { get; set; }
    public string UserEmail { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string? Metadata { get; set; } // JSON string
    public string? IpAddress { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
