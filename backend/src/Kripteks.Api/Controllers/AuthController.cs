using System;
using Kripteks.Core.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Kripteks.Core.Interfaces;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.RateLimiting;
using System.ComponentModel.DataAnnotations;
using Kripteks.Core.Helpers;
using Microsoft.EntityFrameworkCore;
using NotificationType = Kripteks.Core.Entities.NotificationType;

namespace Kripteks.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<AppUser> _userManager;
    private readonly SignInManager<AppUser> _signInManager;
    private readonly IConfiguration _configuration;
    private readonly IAuditLogService _auditLogService;
    private readonly IEmailService _emailService;
    private readonly INotificationService _notificationService;
    private static readonly Dictionary<string, int> _failedLoginAttempts = new();
    private const int FailedLoginThreshold = 3;

    public AuthController(UserManager<AppUser> userManager, SignInManager<AppUser> signInManager,
        IConfiguration configuration, IAuditLogService auditLogService, IEmailService emailService,
        INotificationService notificationService)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _configuration = configuration;
        _auditLogService = auditLogService;
        _emailService = emailService;
        _notificationService = notificationService;
    }

    [EnableRateLimiting("auth")]
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDto model)
    {
        var user = new AppUser
        {
            UserName = model.Email, Email = model.Email,
            FirstName = InputSanitizer.Sanitize(model.FirstName),
            LastName = InputSanitizer.Sanitize(model.LastName),
            IsActive = false // Varsayılan olarak pasif
        };
        var result = await _userManager.CreateAsync(user, model.Password);

        if (result.Succeeded)
        {
            try
            {
                var admins = await _userManager.GetUsersInRoleAsync("Admin");
                foreach (var admin in admins)
                {
                    if (!string.IsNullOrEmpty(admin.Email))
                    {
                        await _emailService.SendNewUserNotificationAsync(admin.Email,
                            $"{user.FirstName} {user.LastName}", user.Email);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Admin notification error: {ex.Message}");
            }

            return Ok(new
            {
                message =
                    "Kullanıcı talebiniz oluşturuldu. Yönetici tarafından onaylandıktan sonra mail adresinize bilgi gelecektir. Sonra belirlediğiniz şifre ile giriş yapabileceksiniz."
            });
        }

        foreach (var error in result.Errors)
        {
            ModelState.AddModelError(error.Code, error.Description);
        }

        return BadRequest(ModelState);
    }

    [EnableRateLimiting("auth")]
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto model)
    {
        // 1. Kesin eşleşme için NormalizedEmail kullanıyoruz
        var user = await _userManager.FindByEmailAsync(model.Email);

        // Identity bazen UserName olarak tutuyor olabilir
        if (user == null)
        {
            user = await _userManager.FindByNameAsync(model.Email);
        }

        // 2. Teşhis için her girişi loglayalım
        if (user != null)
        {
            await _auditLogService.LogAnonymousAsync("Giriş Denemesi",
                new { Requested = model.Email, Found = user.Email, Match = true });
        }

        if (user == null)
        {
            await _auditLogService.LogAnonymousAsync("Giriş Denemesi Başarısız",
                new { model.Email, Reason = "Kullanıcı bulunamadı" });
            return Unauthorized("Giriş başarısız");
        }

        if (!user.IsActive)
        {
            await _auditLogService.LogAnonymousAsync("Giriş Denemesi Başarısız",
                new { model.Email, Reason = "Kullanıcı onaylanmamış" });
            return Unauthorized(
                "Kullanıcınız henüz yönetici tarafından onaylanmadı. Lütfen yöneticinin onaylamasını bekleyiniz.");
        }

        var result = await _signInManager.CheckPasswordSignInAsync(user, model.Password, false);

        if (result.Succeeded)
        {
            // Başarılı giriş - sayacı sıfırla
            _failedLoginAttempts.Remove(user.Id);

            var roles = await _userManager.GetRolesAsync(user);
            var primaryRole = roles.FirstOrDefault() ?? "User";
            var token = GenerateJwtToken(user, roles);
            var refreshToken = GenerateRefreshToken();

            user.RefreshToken = refreshToken;
            user.RefreshTokenExpiry = DateTime.UtcNow.AddDays(7); // Refresh token 7 gün geçerli
            await _userManager.UpdateAsync(user);

            await _auditLogService.LogAsync(user.Id, "Giriş Başarılı", new { user.Email });
            return Ok(new LoginResponseDto
            {
                Token = token,
                RefreshToken = refreshToken,
                User = new UserDetailDto
                {
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Email = user.Email ?? string.Empty,
                    Role = primaryRole
                }
            });
        }

        // Başarısız giriş - sayacı artır
        _failedLoginAttempts.TryGetValue(user.Id, out int count);
        count++;
        _failedLoginAttempts[user.Id] = count;

        await _auditLogService.LogAnonymousAsync("Giriş Denemesi Başarısız",
            new { model.Email, Reason = "Hatalı şifre", Attempt = count });

        if (count == FailedLoginThreshold)
        {
            await _notificationService.SendNotificationAsync(
                "🚫 Şüpheli Giriş Denemesi",
                $"Hesabınıza {count} başarısız giriş denemesi yapıldı. Şifrenizi kontrol edin.",
                NotificationType.Error,
                userId: user.Id);
        }

        return Unauthorized("Giriş başarısız");
    }

    private string GenerateJwtToken(AppUser user, IList<string> roles)
    {
        var jwtSettings = _configuration.GetSection("JwtSettings");
        var secretKey =
            jwtSettings["Secret"] ?? "super_secret_key_kripteks_bot_engine_2026_secure!"; // Fallback, ama config olmalı
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id),
            new Claim(JwtRegisteredClaimNames.Email, user.Email ?? ""),
            new Claim("name", $"{user.FirstName} {user.LastName}"),
            new Claim(ClaimTypes.NameIdentifier, user.Id),
        };

        foreach (var role in roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var token = new JwtSecurityToken(
            issuer: jwtSettings["Issuer"],
            audience: jwtSettings["Audience"],
            claims: claims,
            expires: DateTime.Now.AddMinutes(double.Parse(jwtSettings["ExpiryMinutes"] ?? "60")),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    [Authorize]
    [HttpPost("change-password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto model)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var user = await _userManager.FindByIdAsync(userId);
        if (user == null) return NotFound();

        var result = await _userManager.ChangePasswordAsync(user, model.CurrentPassword, model.NewPassword);
        if (result.Succeeded)
        {
            await _auditLogService.LogAsync(user.Id, "Şifre Değiştirildi");
            await _notificationService.SendNotificationAsync(
                "🔐 Şifre Değiştirildi",
                "Hesap şifreniz başarıyla değiştirildi. Bu işlemi siz yapmadıysanız hemen destek ile iletişime geçin.",
                NotificationType.Warning,
                userId: userId);
            return Ok(new { message = "Şifre başarıyla değiştirildi." });
        }

        return BadRequest(new { message = "Şifre değiştirilemedi.", errors = result.Errors });
    }

    [EnableRateLimiting("auth")]
    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto model)
    {
        var users = await _userManager.Users
            .Where(u => u.Email.Contains(model.Email) || model.Email.Contains(u.Email!))
            .ToListAsync();

        var user = users.FirstOrDefault(u => string.Equals(u.Email, model.Email, StringComparison.OrdinalIgnoreCase));

        if (user == null) return Ok(new { message = "Eğer hesap mevcutsa, kod gönderilecektir." });

        var code = System.Security.Cryptography.RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
        user.ResetCode = code;
        user.ResetCodeExpiry = DateTime.UtcNow.AddMinutes(15);
        await _userManager.UpdateAsync(user);

        await _emailService.SendResetCodeEmailAsync(user.Email!, code);
        await _auditLogService.LogAsync(user.Id, "Şifre Sıfırlama Kodu İstendi", new { user.Email });

        return Ok(new { message = "Sıfırlama kodu gönderildi." });
    }

    [EnableRateLimiting("auth")]
    [HttpPost("verify-reset-code")]
    public async Task<IActionResult> VerifyResetCode([FromBody] VerifyResetCodeDto model)
    {
        var users = await _userManager.Users
            .Where(u => u.Email.Contains(model.Email) || model.Email.Contains(u.Email!))
            .ToListAsync();

        var user = users.FirstOrDefault(u => string.Equals(u.Email, model.Email, StringComparison.OrdinalIgnoreCase));

        if (user == null || user.ResetCode != model.Code || user.ResetCodeExpiry < DateTime.UtcNow)
        {
            return BadRequest(new { message = "Geçersiz veya süresi dolmuş kod." });
        }

        return Ok(new { message = "Kod doğrulandı." });
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto model)
    {
        var users = await _userManager.Users
            .Where(u => u.Email.Contains(model.Email) || model.Email.Contains(u.Email!))
            .ToListAsync();

        var user = users.FirstOrDefault(u => string.Equals(u.Email, model.Email, StringComparison.OrdinalIgnoreCase));

        if (user == null || user.ResetCode != model.Code || user.ResetCodeExpiry < DateTime.UtcNow)
        {
            return BadRequest(new { message = "Geçersiz işlem." });
        }

        var resetToken = await _userManager.GeneratePasswordResetTokenAsync(user);
        var result = await _userManager.ResetPasswordAsync(user, resetToken, model.NewPassword);

        if (result.Succeeded)
        {
            user.ResetCode = null;
            user.ResetCodeExpiry = null;
            await _userManager.UpdateAsync(user);
            await _auditLogService.LogAsync(user.Id, "Şifre Sıfırlandı");
            await _notificationService.SendNotificationAsync(
                "🔐 Şifre Sıfırlandı",
                "Hesap şifreniz sıfırlama kodu ile başarıyla değiştirildi.",
                NotificationType.Warning,
                userId: user.Id);
            return Ok(new { message = "Şifreniz başarıyla sıfırlandı." });
        }

        return BadRequest(new { message = "Şifre sıfırlanamadı.", errors = result.Errors });
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshRequestDto model)
    {
        var user = await _userManager.Users.FirstOrDefaultAsync(u => u.RefreshToken == model.RefreshToken);

        if (user == null || user.RefreshTokenExpiry < DateTime.UtcNow)
        {
            return Unauthorized("Geçersiz veya süresi dolmuş oturum");
        }

        var roles = await _userManager.GetRolesAsync(user);
        var newToken = GenerateJwtToken(user, roles);
        var newRefreshToken = GenerateRefreshToken();

        user.RefreshToken = newRefreshToken;
        user.RefreshTokenExpiry = DateTime.UtcNow.AddDays(7);
        await _userManager.UpdateAsync(user);

        return Ok(new
        {
            token = newToken,
            refreshToken = newRefreshToken
        });
    }

    private string GenerateRefreshToken()
    {
        var randomNumber = new byte[32];
        using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);
        return Convert.ToBase64String(randomNumber);
    }
}

public class ChangePasswordDto
{
    [Required(ErrorMessage = "Mevcut şifre zorunludur.")]
    public string CurrentPassword { get; set; } = string.Empty;

    [Required(ErrorMessage = "Yeni şifre zorunludur.")]
    [StringLength(128, MinimumLength = 6, ErrorMessage = "Şifre en az 6, en fazla 128 karakter olmalıdır.")]
    public string NewPassword { get; set; } = string.Empty;
}

public class RegisterDto
{
    [Required(ErrorMessage = "E-posta zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz.")]
    [StringLength(256)]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Şifre zorunludur.")]
    [StringLength(128, MinimumLength = 6, ErrorMessage = "Şifre en az 6, en fazla 128 karakter olmalıdır.")]
    [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{6,}$",
        ErrorMessage = "Şifre en az bir büyük harf, bir küçük harf, bir rakam ve bir özel karakter içermelidir.")]
    public string Password { get; set; } = string.Empty;

    [Required(ErrorMessage = "Ad zorunludur.")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "Ad en az 2, en fazla 100 karakter olmalıdır.")]
    public string FirstName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Soyad zorunludur.")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "Soyad en az 2, en fazla 100 karakter olmalıdır.")]
    public string LastName { get; set; } = string.Empty;
}

public class LoginDto
{
    [Required(ErrorMessage = "E-posta zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Şifre zorunludur.")]
    public string Password { get; set; } = string.Empty;
}

public class LoginResponseDto
{
    public string Token { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public UserDetailDto User { get; set; } = new();
}

public class RefreshRequestDto
{
    public string RefreshToken { get; set; } = string.Empty;
}

public class UserDetailDto
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;

    [System.Text.Json.Serialization.JsonPropertyName("role")]
    public string Role { get; set; } = string.Empty;
}

public class ForgotPasswordDto
{
    [Required(ErrorMessage = "E-posta zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz.")]
    public string Email { get; set; } = string.Empty;
}

public class VerifyResetCodeDto
{
    [Required(ErrorMessage = "E-posta zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Doğrulama kodu zorunludur.")]
    [StringLength(6, MinimumLength = 6, ErrorMessage = "Kod 6 haneli olmalıdır.")]
    public string Code { get; set; } = string.Empty;
}

public class ResetPasswordDto
{
    [Required(ErrorMessage = "E-posta zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Doğrulama kodu zorunludur.")]
    [StringLength(6, MinimumLength = 6, ErrorMessage = "Kod 6 haneli olmalıdır.")]
    public string Code { get; set; } = string.Empty;

    [Required(ErrorMessage = "Yeni şifre zorunludur.")]
    [StringLength(128, MinimumLength = 6, ErrorMessage = "Şifre en az 6, en fazla 128 karakter olmalıdır.")]
    public string NewPassword { get; set; } = string.Empty;
}
