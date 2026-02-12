using Kripteks.Core.DTOs;

namespace Kripteks.Core.Interfaces;

public interface IPortfolioService
{
    /// <summary>
    /// Portföy özet bilgisini döndürür: asset dağılımı, risk metrikleri, rebalancing önerileri.
    /// </summary>
    Task<PortfolioSummaryDto> GetPortfolioSummaryAsync();
}
