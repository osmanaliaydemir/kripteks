using Kripteks.Core.Entities;
using System;
using System.Threading.Tasks;

namespace Kripteks.Core.Interfaces;

public interface ILogService
{
    Task LogAsync(string message, LogLevel level = LogLevel.Info, Guid? botId = null);
    Task LogInfoAsync(string message, Guid? botId = null);
    Task LogWarningAsync(string message, Guid? botId = null);
    Task LogErrorAsync(string message, Guid? botId = null);
}
