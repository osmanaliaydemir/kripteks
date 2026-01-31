using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Threading.Tasks;

namespace Kripteks.Infrastructure.Services;

public class LogService : ILogService
{
    private readonly IServiceScopeFactory _scopeFactory;

    public LogService(IServiceScopeFactory scopeFactory)
    {
        _scopeFactory = scopeFactory;
    }

    public async Task LogAsync(string message, LogLevel level = LogLevel.Info, Guid? botId = null)
    {
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            var log = new Log
            {
                Message = message,
                Level = level,
                BotId = botId ?? Guid.Empty,
                Timestamp = DateTime.UtcNow
            };

            context.Logs.Add(log);
            await context.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            // Log kaydederken hata oluşursa konsola yazalım ki loop'a girmesin
            Console.WriteLine($"Loglama Hatası: {ex.Message}");
        }
    }

    public async Task LogInfoAsync(string message, Guid? botId = null) => await LogAsync(message, LogLevel.Info, botId);
    public async Task LogWarningAsync(string message, Guid? botId = null) => await LogAsync(message, LogLevel.Warning, botId);
    public async Task LogErrorAsync(string message, Guid? botId = null) => await LogAsync(message, LogLevel.Error, botId);
}
