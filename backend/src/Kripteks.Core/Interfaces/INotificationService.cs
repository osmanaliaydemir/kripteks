using System.Threading.Tasks;

namespace Kripteks.Core.Interfaces;

public interface INotificationService
{
    Task NotifyBotUpdate(object bot); // Bot nesnesi
    Task NotifyLog(string botId, object log); // Log nesnesi
    Task NotifyWalletUpdate(object wallet); // Cüzdan nesnesi
}
