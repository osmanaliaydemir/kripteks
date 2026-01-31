using System.Net;
using System.Net.Mail;
using Kripteks.Core.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

using Microsoft.Extensions.Hosting;

namespace Kripteks.Infrastructure.Services;

public class GmailMailService : IMailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<GmailMailService> _logger;
    private readonly IHostEnvironment _env;

    public GmailMailService(IConfiguration configuration, ILogger<GmailMailService> logger, IHostEnvironment env)
    {
        _configuration = configuration;
        _logger = logger;
        _env = env;
    }

    public async Task SendInsufficientBalanceEmailAsync(string symbol, string strategyName, decimal requiredAmount, decimal currentBalance, decimal missingAmount)
    {
        try
        {
            var mailSettings = _configuration.GetSection("MailSettings");
            var fromEmail = mailSettings["Email"];
            var password = mailSettings["Password"];
            var toEmails = mailSettings.GetSection("ToEmails").Get<string[]>();

            if (string.IsNullOrEmpty(fromEmail) || string.IsNullOrEmpty(password) || toEmails == null || toEmails.Length == 0)
            {
                _logger.LogWarning("Mail ayarları eksik! Mail gönderilemedi.");
                return;
            }

            var subject = $"⚠️ Bakiye Yetersiz: {symbol} İşlemi Açılamadı";
            
            // Template Okuma ve Doldurma
            var templatePath = Path.Combine(_env.ContentRootPath, "EmailTemplate", "InsufficientBalance.html");
            
            string body = "";
            if (File.Exists(templatePath))
            {
                body = await File.ReadAllTextAsync(templatePath);
                body = body.Replace("{{Symbol}}", symbol)
                           .Replace("{{StrategyName}}", strategyName)
                           .Replace("{{RequiredAmount}}", requiredAmount.ToString("N2"))
                           .Replace("{{CurrentBalance}}", currentBalance.ToString("N2"))
                           .Replace("{{MissingAmount}}", missingAmount.ToString("N2"))
                           .Replace("{{Year}}", DateTime.Now.Year.ToString());
            }
            else
            {
                // Fallback (Dosya bulunamazsa basit text)
                _logger.LogWarning("Mail şablonu bulunamadı: {Path}", templatePath);
                body = $"<h3>İşlem Başarısız: {symbol}</h3><p>Bakiye yetersiz. Gereken: {requiredAmount}, Mevcut: {currentBalance}</p>";
            }

            using (var client = new SmtpClient("smtp.gmail.com", 587))
            {
                client.EnableSsl = true;
                client.Credentials = new NetworkCredential(fromEmail, password);

                var mailMessage = new MailMessage
                {
                    From = new MailAddress(fromEmail, "Kripteks Bot"),
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                };

                foreach (var email in toEmails)
                {
                    mailMessage.To.Add(email);
                }

                await client.SendMailAsync(mailMessage);
                _logger.LogInformation("Yetersiz bakiye maili başarıyla gönderildi: {Recipients}", string.Join(", ", toEmails));
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Mail gönderilirken hata oluştu!");
        }
    }
}
