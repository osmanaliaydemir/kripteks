using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace Kripteks.Api.Hubs;

[Authorize]
public class BotHub : Hub
{
    // İstemciler (Frontend) canlı veri almak için bu Hub'a bağlanacak.
    // Şimdilik buraya özel bir metod yazmamıza gerek yok, 
    // Backend (Engine) burayı kullanarak istemcilere veri itecek (Push).
    
    public async Task SendMessage(string user, string message)
    {
        await Clients.All.SendAsync("ReceiveMessage", user, message);
    }
}
