using Kripteks.Core.Entities;

namespace Kripteks.Core.Interfaces;

public interface INewsService
{
    // Son haberleri getir
    Task<List<NewsItem>> GetLatestNewsAsync(string symbol = "BTC");
}
