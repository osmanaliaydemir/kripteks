using Kripteks.Core.Entities;

namespace Kripteks.Core.Interfaces;

public interface IBacktestRepository
{
    Task<BacktestResult> CreateAsync(BacktestResult result);
    Task<BacktestResult?> GetByIdAsync(Guid id);
    Task<List<BacktestResult>> GetByUserIdAsync(string userId, int skip = 0, int take = 50);
    Task<List<BacktestResult>> GetFavoritesByUserIdAsync(string userId);
    Task<BacktestResult> UpdateAsync(BacktestResult result);
    Task DeleteAsync(Guid id);
    Task<int> GetCountByUserIdAsync(string userId);
}
