using Microsoft.AspNetCore.SignalR;

namespace Kripteks.Api.Hubs;

public class BacktestHub : Hub
{
    public async Task JoinBacktestSession(string sessionId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"backtest-{sessionId}");
    }

    public async Task LeaveBacktestSession(string sessionId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"backtest-{sessionId}");
    }
}

public interface IBacktestHubClient
{
    Task ReceiveProgress(BacktestProgressDto progress);
    Task ReceiveOptimizationComplete(OptimizationCompleteDto result);
}

public class BacktestProgressDto
{
    public string SessionId { get; set; } = string.Empty;
    public int CurrentStep { get; set; }
    public int TotalSteps { get; set; }
    public string CurrentParameters { get; set; } = string.Empty;
    public decimal? CurrentPnlPercent { get; set; }
    public decimal? BestPnlPercent { get; set; }
    public string Status { get; set; } = "running"; // running, completed, error
    public int ProgressPercent => TotalSteps > 0 ? (int)((CurrentStep * 100.0) / TotalSteps) : 0;
}

public class OptimizationCompleteDto
{
    public string SessionId { get; set; } = string.Empty;
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
}
