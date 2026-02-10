using Kripteks.Core.DTOs;

namespace Kripteks.Core.Extensions;

public static class QueryableExtensions
{
    /// <summary>
    /// Zaten materialize edilmiş bir listeyi sayfalanmış sonuca çevirir.
    /// </summary>
    public static PagedResult<T> ToPagedResult<T>(
        this List<T> items,
        int page,
        int pageSize,
        int totalCount)
    {
        return new PagedResult<T>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }
}
