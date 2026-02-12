using Kripteks.Core.DTOs;

namespace Kripteks.Core.Interfaces;

public interface IAlertService
{
    Task<List<AlertDto>> GetUserAlertsAsync(Guid userId);
    Task<AlertDto> CreateAlertAsync(Guid userId, CreateAlertDto createDto);
    Task<AlertDto?> UpdateAlertAsync(Guid userId, Guid alertId, UpdateAlertDto updateDto);
    Task<bool> DeleteAlertAsync(Guid userId, Guid alertId);
    Task ProcessAlertsAsync(); // To be called by a background job
}
