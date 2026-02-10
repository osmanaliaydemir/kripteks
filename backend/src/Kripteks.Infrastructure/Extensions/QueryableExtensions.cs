using Kripteks.Core.DTOs;
using Microsoft.EntityFrameworkCore;

namespace Kripteks.Infrastructure.Extensions;

public static class QueryableExtensions
{
    /// <summary>
    /// IQueryable'ı sayfalanmış sonuç olarak döndürür.
    /// Tek sorguda hem count hem de data çeker (2 SQL sorgusu).
    /// </summary>
    public static async Task<PagedResult<T>> ToPagedResultAsync<T>(
        this IQueryable<T> query,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var totalCount = await query.CountAsync(cancellationToken);

        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<T>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }
}
