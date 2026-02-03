using System;
using System.Threading.Tasks;

namespace Kripteks.Core.Interfaces;

public interface IAuditLogService
{
    Task LogAsync(string userId, string action, object? metadata = null);
    Task LogAnonymousAsync(string action, object? metadata = null);
}
