namespace Kripteks.Core.DTOs;

/// <summary>
/// Sayfalanmış sonuç sarmalayıcısı. Tüm liste endpoint'leri bu formatta döner.
/// </summary>
public class PagedResult<T>
{
    public List<T> Items { get; set; } = [];
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalCount { get; set; }
    public bool HasMore => Page * PageSize < TotalCount;
    public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);
}

/// <summary>
/// Sayfalama isteği parametreleri.
/// </summary>
public class PaginationRequest
{
    private int _page = 1;
    private int _pageSize = 20;

    public int Page
    {
        get => _page;
        set => _page = value < 1 ? 1 : value;
    }

    public int PageSize
    {
        get => _pageSize;
        set => _pageSize = value switch
        {
            < 1 => 20,
            > 100 => 100,
            _ => value
        };
    }
}
