using System.Threading.Tasks;

namespace Kripteks.Core.Interfaces;

public interface IEmailService
{
    Task SendEmailAsync(string toEmail, string subject, string body);
    Task SendWelcomeEmailAsync(string toEmail, string firstName, string password);
}
