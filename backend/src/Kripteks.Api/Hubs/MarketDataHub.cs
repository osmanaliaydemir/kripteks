using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Kripteks.Core.DTOs;

namespace Kripteks.Api.Hubs;

/// <summary>
/// Hub interface defining client-side methods for market data updates
/// </summary>
public interface IMarketDataHubClient
{
    Task ReceiveMarketOverview(MarketOverviewDto overview);
    Task ReceiveTopGainers(List<TopMoverDto> gainers);
    Task ReceiveTopLosers(List<TopMoverDto> losers);
    Task ReceiveVolumeUpdate(VolumeDataDto volumeData);
}

/// <summary>
/// SignalR Hub for real-time market data streaming to mobile clients
/// </summary>
[Authorize]
public class MarketDataHub : Hub<IMarketDataHubClient>
{
    private readonly ILogger<MarketDataHub> _logger;

    public MarketDataHub(ILogger<MarketDataHub> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Client subscribes to market data updates
    /// </summary>
    public async Task SubscribeToMarketData()
    {
        var userId = Context.UserIdentifier ?? Context.ConnectionId;
        _logger.LogInformation("Client {UserId} subscribed to market data", userId);
        
        // Client is automatically added to default group
        await Task.CompletedTask;
    }

    /// <summary>
    /// Client unsubscribes from market data updates
    /// </summary>
    public async Task UnsubscribeFromMarketData()
    {
        var userId = Context.UserIdentifier ?? Context.ConnectionId;
        _logger.LogInformation("Client {UserId} unsubscribed from market data", userId);
        
        await Task.CompletedTask;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.UserIdentifier ?? Context.ConnectionId;
        _logger.LogInformation("Market data client connected: {UserId}", userId);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.UserIdentifier ?? Context.ConnectionId;
        
        if (exception != null)
        {
            _logger.LogWarning(exception, "Client {UserId} disconnected with error", userId);
        }
        else
        {
            _logger.LogInformation("Client {UserId} disconnected normally", userId);
        }
        
        await base.OnDisconnectedAsync(exception);
    }
}
