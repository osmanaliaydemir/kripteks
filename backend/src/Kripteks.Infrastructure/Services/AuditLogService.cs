using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using System.Text.Json;

namespace Kripteks.Infrastructure.Services;

public class AuditLogService(IServiceScopeFactory scopeFactory, IHttpContextAccessor httpContextAccessor) : IAuditLogService
{

    public async Task LogAsync(string userId, string action, object? metadata = null)
    {
        try
        {
            using var scope = scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();

            var user = await userManager.FindByIdAsync(userId);
            var userEmail = user?.Email ?? "Unknown";

            var auditLog = new AuditLog
            {
                UserId = userId,
                UserEmail = userEmail,
                Action = action,
                Metadata = metadata != null ? JsonSerializer.Serialize(metadata) : null,
                IpAddress = httpContextAccessor.HttpContext?.Connection?.RemoteIpAddress?.ToString(),
                Timestamp = DateTime.UtcNow
            };

            context.AuditLogs.Add(auditLog);
            await context.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Audit Log Error: {ex.Message}");
        }
    }

    public async Task LogAnonymousAsync(string action, object? metadata = null)
    {
        try
        {
            using var scope = scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            var auditLog = new AuditLog
            {
                UserId = null,
                UserEmail = "Anonymous",
                Action = action,
                Metadata = metadata != null ? JsonSerializer.Serialize(metadata) : null,
                IpAddress = httpContextAccessor.HttpContext?.Connection?.RemoteIpAddress?.ToString(),
                Timestamp = DateTime.UtcNow
            };

            context.AuditLogs.Add(auditLog);
            await context.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Audit Log Anonymous Error: {ex.Message}");
        }
    }
}
