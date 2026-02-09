using Kripteks.Core.Interfaces;
using Microsoft.Extensions.Configuration;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;

namespace Kripteks.Infrastructure.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;

    public EmailService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task SendEmailAsync(string toEmail, string subject, string body)
    {
        var mailSettings = _configuration.GetSection("MailSettings");
        var fromEmail = mailSettings["Email"];
        // Eğer config boşsa veya test ortamındaysak gönderimi atla veya logla
        if (string.IsNullOrEmpty(fromEmail) || fromEmail.Contains("[EMAIL]"))
        {
            System.Console.WriteLine($"[MOCK EMAIL] To: {toEmail}, Subject: {subject}");
            return;
        }

        var password = mailSettings["Password"];
        var smtpHost = "smtp.gmail.com"; // Varsayılan Gmail, configden de alınabilir
        var smtpPort = 587;

        using var client = new SmtpClient(smtpHost, smtpPort)
        {
            Credentials = new NetworkCredential(fromEmail, password),
            EnableSsl = true
        };

        var mailMessage = new MailMessage
        {
            From = new MailAddress(fromEmail, "Kripteks Bot Engine"),
            Subject = subject,
            Body = body,
            IsBodyHtml = true
        };

        mailMessage.To.Add(toEmail);
        await client.SendMailAsync(mailMessage);
    }

    public async Task SendWelcomeEmailAsync(string toEmail, string firstName, string setupPasswordUrl)
    {
        var template = GetWelcomeTemplate(firstName, toEmail, setupPasswordUrl);
        await SendEmailAsync(toEmail, "Kripteks Yönetici Hesabınız Oluşturuldu 🚀", template);
    }

    public async Task SendResetCodeEmailAsync(string toEmail, string code)
    {
        var template = GetResetCodeTemplate(code);
        await SendEmailAsync(toEmail, "Şifre Sıfırlama Kodu - Kripteks 🛡️", template);
    }

    private string GetResetCodeTemplate(string code)
    {
        return $@"
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0f172a; margin: 0; padding: 0; }}
        .container {{ max-width: 600px; margin: 40px auto; background-color: #1e293b; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.5); border: 1px solid #334155; }}
        .header {{ background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); padding: 40px 20px; text-align: center; }}
        .header h1 {{ color: white; margin: 0; font-size: 28px; font-weight: 800; letter-spacing: 1px; }}
        .header p {{ color: rgba(255,255,255,0.9); margin-top: 10px; font-size: 14px; text-transform: uppercase; letter-spacing: 2px; }}
        .content {{ padding: 40px; color: #e2e8f0; text-align: center; }}
        .instruction-text {{ font-size: 16px; line-height: 1.6; margin-bottom: 30px; color: #94a3b8; }}
        .code-box {{ background-color: #0f172a; border: 2px dashed #f59e0b; border-radius: 12px; padding: 20px; margin: 30px 0; display: inline-block; }}
        .code-value {{ color: #f59e0b; font-family: 'JetBrains Mono', 'Consolas', monospace; font-size: 36px; font-weight: 800; letter-spacing: 8px; }}
        .footer {{ background-color: #0f172a; padding: 20px; text-align: center; color: #64748b; font-size: 12px; border-top: 1px solid #334155; }}
        .warning {{ font-size: 12px; color: #64748b; margin-top: 20px; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>KRIPTEKS</h1>
            <p>Güvenlik Doğrulaması</p>
        </div>
        <div class='content'>
            <h2 style='color: white; margin-bottom: 20px;'>Şifrenizi mi unuttunuz?</h2>
            <p class='instruction-text'>
                Sorun değil! Şifrenizi sıfırlamak için aşağıdaki 6 haneli doğrulama kodunu uygulamadaki ilgili alana giriniz.
            </p>
            
            <div class='code-box'>
                <span class='code-value'>{code}</span>
            </div>

            <p style='color: #94a3b8; font-size: 14px;'>
                Bu kod <strong>15 dakika</strong> boyunca geçerlidir.
            </p>

            <p class='warning'>
                Eğer bu isteği siz yapmadıysanız, lütfen bu e-postayı dikkate almayınız ve hesabınızın güvenliğini kontrol ediniz.
            </p>
        </div>
        <div class='footer'>
            &copy; 2026 Kripteks Inc. Tüm hakları saklıdır.<br>
            Kripteks AI Bot Engine Güvenlik Birimi
        </div>
    </div>
</body>
</html>
";
    }

    private string GetWelcomeTemplate(string name, string email, string setupPasswordUrl)
    {
        return $@"
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0f172a; margin: 0; padding: 0; }}
        .container {{ max-width: 600px; margin: 40px auto; background-color: #1e293b; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.5); border: 1px solid #334155; }}
        .header {{ background: linear-gradient(135deg, #06b6d4 0%, #3b82f6 100%); padding: 40px 20px; text-align: center; }}
        .header h1 {{ color: white; margin: 0; font-size: 28px; font-weight: 800; letter-spacing: 1px; }}
        .header p {{ color: rgba(255,255,255,0.9); margin-top: 10px; font-size: 14px; text-transform: uppercase; letter-spacing: 2px; }}
        .content {{ padding: 40px; color: #e2e8f0; }}
        .welcome-text {{ font-size: 18px; line-height: 1.6; margin-bottom: 30px; }}
        .credentials-box {{ background-color: #0f172a; border: 1px solid #334155; border-radius: 12px; padding: 25px; margin-bottom: 30px; }}
        .credential-item {{ margin-bottom: 15px; }}
        .credential-label {{ color: #94a3b8; font-size: 12px; text-transform: uppercase; font-weight: bold; margin-bottom: 5px; display: block; }}
        .credential-value {{ color: #38bdf8; font-family: 'Consolas', monospace; font-size: 16px; font-weight: bold; background: rgba(56, 189, 248, 0.1); padding: 5px 10px; border-radius: 6px; display: inline-block; }}
        .btn {{ display: block; width: 100%; text-align: center; background: linear-gradient(to right, #06b6d4, #3b82f6); color: white; text-decoration: none; padding: 15px 0; border-radius: 12px; font-weight: bold; font-size: 16px; transition: opacity 0.3s; }}
        .btn:hover {{ opacity: 0.9; }}
        .footer {{ background-color: #0f172a; padding: 20px; text-align: center; color: #64748b; font-size: 12px; border-top: 1px solid #334155; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>KRIPTEKS</h1>
            <p>Next Gen Bot Engine</p>
        </div>
        <div class='content'>
            <p class='welcome-text'>Merhaba <strong>{name}</strong>,</p>
            <p style='color: #94a3b8; line-height: 1.6;'>
                Kripteks Bot Engine sistemine yönetici olarak eklendiniz. Artık gelişmiş algoritmalarımızı kullanarak piyasayı 7/24 izleyebilir ve otonom ticaret yapabilirsiniz.
            </p>
            
            <div class='credentials-box'>
                <div class='credential-item'>
                    <span class='credential-label'>Giriş E-Postanız</span>
                    <span class='credential-value' style='color: #e2e8f0;'>{email}</span>
                </div>
            </div>

            <p style='color: #94a3b8; font-size: 14px; margin-bottom: 30px;'>
                Hesabınızı aktif etmek için aşağıdaki butona tıklayarak şifrenizi belirleyiniz. Bu link <strong>24 saat</strong> boyunca geçerlidir.
            </p>

            <a href='{setupPasswordUrl}' class='btn'>Şifremi Belirle</a>
        </div>
        <div class='footer'>
            &copy; 2026 Kripteks Inc. Tüm hakları saklıdır.<br>
            Bu e-postayı, sistem yöneticisi tarafından eklendiğiniz için aldınız.
        </div>
    </div>
</body>
</html>
        ";
    }
}
