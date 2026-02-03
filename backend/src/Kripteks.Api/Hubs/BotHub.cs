using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Kripteks.Core.Entities;

namespace Kripteks.Api.Hubs;

public interface IBotHubClient
{
    Task ReceiveMessage(string user, string message);
    Task ReceiveNotification(Notification notification);
    Task ReceiveBotUpdate(object bot);
    Task ReceiveLog(string botId, object log);
    Task ReceiveWalletUpdate(object wallet);
}

[Authorize]
public class BotHub : Hub<IBotHubClient>
{
    public async Task SendMessage(string user, string message)
    {
        await Clients.All.ReceiveMessage(user, message);
    }
}
