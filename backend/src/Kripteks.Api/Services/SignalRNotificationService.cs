using Kripteks.Api.Hubs;
using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.SignalR;

namespace Kripteks.Api.Services;

public class SignalRNotificationService : INotificationService
{
    private readonly IHubContext<BotHub> _hubContext;

    public SignalRNotificationService(IHubContext<BotHub> hubContext)
    {
        _hubContext = hubContext;
    }

    public async Task NotifyBotUpdate(object bot)
    {
        await _hubContext.Clients.All.SendAsync("BotUpdated", bot);
    }

    public async Task NotifyLog(string botId, object log)
    {
        await _hubContext.Clients.All.SendAsync("LogAdded", botId, log);
    }

    public async Task NotifyWalletUpdate(object wallet)
    {
        await _hubContext.Clients.All.SendAsync("WalletUpdated", wallet);
    }
}
