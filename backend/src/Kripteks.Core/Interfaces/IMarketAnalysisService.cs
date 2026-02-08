using Kripteks.Core.DTOs;

namespace Kripteks.Core.Interfaces;

public interface IMarketAnalysisService
{
    Task<MarketOverviewDto> GetMarketOverviewAsync();
    Task<List<TopMoverDto>> GetTopGainersAsync(int count = 5);
    Task<List<TopMoverDto>> GetTopLosersAsync(int count = 5);
    Task<List<VolumeDataDto>> GetVolumeHistoryAsync(int hours = 24);
    Task<MarketMetricsDto> GetMarketMetricsAsync();
}
