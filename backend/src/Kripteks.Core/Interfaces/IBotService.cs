using Kripteks.Core.DTOs;

namespace Kripteks.Core.Interfaces;

public interface IBotService
{
    Task<PagedResult<BotDto>> GetAllBotsAsync(int page = 1, int pageSize = 20);
    Task<BotDto> GetBotByIdAsync(Guid id);
    Task<PagedResult<LogDto>> GetBotLogsAsync(Guid botId, int page = 1, int pageSize = 50);
    Task<BotDto> CreateBotAsync(CreateBotRequest request);
    Task StopBotAsync(Guid id);
    Task StopAllBotsAsync();
    Task ClearLogsAsync(Guid id);
    Task ArchiveHistoryAsync();
}
