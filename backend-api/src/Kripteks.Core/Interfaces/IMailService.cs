using System.Threading.Tasks;

namespace Kripteks.Core.Interfaces;

public interface IMailService
{
    Task SendInsufficientBalanceEmailAsync(string symbol, string strategyName, decimal requiredAmount, decimal currentBalance, decimal missingAmount);
}
