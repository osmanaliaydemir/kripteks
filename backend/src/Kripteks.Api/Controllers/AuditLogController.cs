using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.Text;

namespace Kripteks.Api.Controllers;

[Authorize(Roles = "Admin")]
[ApiController]
[Route("api/[controller]")]
public class AuditLogController(IAuditLogService auditLogService) : ControllerBase
{
    /// <summary>
    /// Audit loglarını filtreli, sayfalı listeler.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetLogs(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        [FromQuery] string? userId = null,
        [FromQuery] AuditCategory? category = null,
        [FromQuery] AuditSeverity? severity = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] string? searchTerm = null,
        [FromQuery] string? entityType = null)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 200) pageSize = 50;

        var result = await auditLogService.QueryLogsAsync(new AuditQueryRequest
        {
            Page = page,
            PageSize = pageSize,
            UserId = userId,
            Category = category,
            Severity = severity,
            StartDate = startDate,
            EndDate = endDate,
            SearchTerm = searchTerm,
            EntityType = entityType
        });

        return Ok(result);
    }

    /// <summary>
    /// Compliance raporu üretir (vergi beyanı).
    /// </summary>
    [HttpGet("compliance")]
    public async Task<IActionResult> GetComplianceReport(
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate,
        [FromQuery] string? userId = null)
    {
        // Admin kendi userId'sini veya başka birininki
        var targetUserId = userId ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(targetUserId)) return Unauthorized();

        if (endDate < startDate)
            return BadRequest(new { message = "Bitiş tarihi başlangıçtan önce olamaz." });

        if ((endDate - startDate).TotalDays > 366)
            return BadRequest(new { message = "Maksimum 1 yıllık rapor üretilebilir." });

        var report = await auditLogService.GenerateComplianceReportAsync(
            targetUserId, startDate, endDate);

        return Ok(report);
    }

    /// <summary>
    /// Audit loglarını CSV formatında dışa aktarır.
    /// </summary>
    [HttpGet("export")]
    public async Task<IActionResult> ExportLogs(
        [FromQuery] AuditCategory? category = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] string? format = "csv")
    {
        var result = await auditLogService.QueryLogsAsync(new AuditQueryRequest
        {
            Page = 1,
            PageSize = 10000, // Dışa aktarma için büyük limit
            Category = category,
            StartDate = startDate,
            EndDate = endDate
        });

        if (format?.Equals("json", StringComparison.OrdinalIgnoreCase) == true)
        {
            return Ok(result.Items);
        }

        // CSV
        var csv = new StringBuilder();
        csv.AppendLine("Tarih,Kullanıcı,Eylem,Kategori,Önem,EntityType,EntityId,EskiDeger,YeniDeger,IP,Metadata");

        foreach (var log in result.Items)
        {
            csv.AppendLine(string.Join(",",
                Escape(log.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")),
                Escape(log.UserEmail),
                Escape(log.Action),
                Escape(log.Category),
                Escape(log.Severity),
                Escape(log.EntityType ?? ""),
                Escape(log.EntityId ?? ""),
                Escape(log.OldValue ?? ""),
                Escape(log.NewValue ?? ""),
                Escape(log.IpAddress ?? ""),
                Escape(log.Metadata ?? "")));
        }

        var bytes = Encoding.UTF8.GetBytes(csv.ToString());
        return File(bytes, "text/csv", $"audit_logs_{DateTime.UtcNow:yyyyMMdd}.csv");
    }

    /// <summary>
    /// Kategori bazlı özet istatistikler.
    /// </summary>
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        var start = startDate ?? DateTime.UtcNow.AddDays(-30);
        var end = endDate ?? DateTime.UtcNow;

        var categories = Enum.GetValues<AuditCategory>();
        var stats = new List<object>();

        foreach (var cat in categories)
        {
            var result = await auditLogService.QueryLogsAsync(new AuditQueryRequest
            {
                Page = 1,
                PageSize = 1,
                Category = cat,
                StartDate = start,
                EndDate = end
            });

            stats.Add(new
            {
                Category = cat.ToString(),
                Count = result.TotalCount
            });
        }

        return Ok(new { StartDate = start, EndDate = end, Categories = stats });
    }

    private static string Escape(string value)
    {
        if (value.Contains(',') || value.Contains('"') || value.Contains('\n'))
            return $"\"{value.Replace("\"", "\"\"")}\"";
        return value;
    }
}
