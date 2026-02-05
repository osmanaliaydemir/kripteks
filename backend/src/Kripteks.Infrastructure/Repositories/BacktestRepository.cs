using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Kripteks.Infrastructure.Repositories;

public class BacktestRepository : IBacktestRepository
{
    private readonly AppDbContext _context;

    public BacktestRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<BacktestResult> CreateAsync(BacktestResult result)
    {
        _context.BacktestResults.Add(result);
        await _context.SaveChangesAsync();
        return result;
    }

    public async Task<BacktestResult?> GetByIdAsync(Guid id)
    {
        return await _context.BacktestResults.FindAsync(id);
    }

    public async Task<List<BacktestResult>> GetByUserIdAsync(string userId, int skip = 0, int take = 50)
    {
        return await _context.BacktestResults
            .Where(b => b.UserId == userId)
            .OrderByDescending(b => b.CreatedAt)
            .Skip(skip)
            .Take(take)
            .ToListAsync();
    }

    public async Task<List<BacktestResult>> GetFavoritesByUserIdAsync(string userId)
    {
        return await _context.BacktestResults
            .Where(b => b.UserId == userId && b.IsFavorite)
            .OrderByDescending(b => b.CreatedAt)
            .ToListAsync();
    }

    public async Task<BacktestResult> UpdateAsync(BacktestResult result)
    {
        _context.BacktestResults.Update(result);
        await _context.SaveChangesAsync();
        return result;
    }

    public async Task DeleteAsync(Guid id)
    {
        var result = await _context.BacktestResults.FindAsync(id);
        if (result != null)
        {
            _context.BacktestResults.Remove(result);
            await _context.SaveChangesAsync();
        }
    }

    public async Task<int> GetCountByUserIdAsync(string userId)
    {
        return await _context.BacktestResults.CountAsync(b => b.UserId == userId);
    }
}
