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
            { UserName = model.Email, Email = model.Email,
              FirstName = InputSanitizer.Sanitize(model.FirstName),
              LastName = InputSanitizer.Sanitize(model.LastName) };
        var result = await _userManager.CreateAsync(user, model.Password);

        if (result.Succeeded)
        {
            return Ok(new { message = "Kayıt başarılı" });
        }

        return BadRequest(result.Errors);
    }

    [EnableRateLimiting("auth")]
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto model)
    {
        var user = await _userManager.FindByEmailAsync(model.Email);
        if (user == null)
        {
            await _auditLogService.LogAnonymousAsync("Giriş Denemesi Başarısız",
                new { model.Email, Reason = "Kullanıcı bulunamadı" });
            return Unauthorized("Giriş başarısız");
        }

        var result = await _signInManager.CheckPasswordSignInAsync(user, model.Password, false);

        if (result.Succeeded)
        {
            // Başarılı giriş - sayacı sıfırla
            _failedLoginAttempts.Remove(user.Id);

            var roles = await _userManager.GetRolesAsync(user);
            var primaryRole = roles.FirstOrDefault() ?? "User";
            var token = GenerateJwtToken(user, roles);

            await _auditLogService.LogAsync(user.Id, "Giriş Başarılı", new { user.Email });
            return Ok(new LoginResponseDto
            {
                Token = token,
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
        var user = await _userManager.FindByEmailAsync(model.Email);
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
        var user = await _userManager.FindByEmailAsync(model.Email);
        if (user == null || user.ResetCode != model.Code || user.ResetCodeExpiry < DateTime.UtcNow)
        {
            return BadRequest(new { message = "Geçersiz veya süresi dolmuş kod." });
        }

        return Ok(new { message = "Kod doğrulandı." });
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto model)
    {
        var user = await _userManager.FindByEmailAsync(model.Email);
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
    public UserDetailDto User { get; set; } = new();
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
