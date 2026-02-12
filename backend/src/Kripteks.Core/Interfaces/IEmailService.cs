using System.Threading.Tasks;

namespace Kripteks.Core.Interfaces;

public interface IEmailService
{
    Task SendEmailAsync(string toEmail, string subject, string body);
    Task SendWelcomeEmailAsync(string toEmail, string firstName, string setupPasswordUrl);
    Task SendResetCodeEmailAsync(string toEmail, string code);
    Task SendNewUserNotificationAsync(string adminEmail, string newUserName, string newUserEmail);
}
