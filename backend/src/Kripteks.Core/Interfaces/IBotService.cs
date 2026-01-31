using Kripteks.Core.DTOs;

namespace Kripteks.Core.Interfaces;

public interface IBotService
{
    Task<List<BotDto>> GetAllBotsAsync();
    Task<BotDto> GetBotByIdAsync(Guid id);
    Task<BotDto> CreateBotAsync(CreateBotRequest request);
    Task StopBotAsync(Guid id);
    Task StopAllBotsAsync();
    Task ClearLogsAsync(Guid id);
}
