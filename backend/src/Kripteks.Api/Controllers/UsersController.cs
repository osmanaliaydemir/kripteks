using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using Kripteks.Core.Helpers;

namespace Kripteks.Api.Controllers;

[Authorize(Roles = "Admin")]
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly UserManager<AppUser> _userManager;
    private readonly IEmailService _emailService;
    private readonly ILogService _logger;
    private readonly IAuditLogService _auditLogService;
    private readonly INotificationService _notificationService;

    public UsersController(UserManager<AppUser> userManager, IEmailService emailService,
        ILogService logger, IAuditLogService auditLogService, INotificationService notificationService)
    {
        _userManager = userManager;
        _emailService = emailService;
        _logger = logger;
        _auditLogService = auditLogService;
        _notificationService = notificationService;
    }

    // GET: api/users
    [HttpGet]
    public async Task<IActionResult> GetUsers()
    {
        var users = await _userManager.Users.ToListAsync();
        var userDtos = new List<object>();

        foreach (var user in users)
        {
            var roles = await _userManager.GetRolesAsync(user);
            userDtos.Add(new
            {
                user.Id,
                user.FirstName,
                user.LastName,
                user.Email,
                user.IsActive,
                role = roles.FirstOrDefault() ?? "User"
            });
        }

        return Ok(userDtos);
    }

    // POST: api/users
    [HttpPost]
    public async Task<IActionResult> CreateUser([FromBody] CreateUserDto model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var existingUser = await _userManager.FindByEmailAsync(model.Email);
        if (existingUser != null)
            return BadRequest(new { message = "Bu email adresi zaten kullanımda." });

        var user = new AppUser
        {
            UserName = model.Email,
            Email = model.Email,
            FirstName = InputSanitizer.Sanitize(model.FirstName),
            LastName = InputSanitizer.Sanitize(model.LastName),
            EmailConfirmed = true
        };

        var result = await _userManager.CreateAsync(user, model.Password);

        if (result.Succeeded)
        {
            // Rol Atama
            var role = !string.IsNullOrEmpty(model.Role) ? model.Role : "User";
            await _userManager.AddToRoleAsync(user, role);

            var adminId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (adminId != null)
            {
                await _auditLogService.LogAsync(adminId, "Yeni Kullanıcı Oluşturuldu",
                    new { model.Email, Role = role });
            }

            await _logger.LogInfoAsync($"Yeni kullanıcı eklendi: {model.Email} ({role})");

            // Kullanıcıya özel hoşgeldin bildirimi
            await _notificationService.SendNotificationAsync(
                "👋 Hoş Geldiniz!",
                $"Selam, {model.FirstName}, Kripteks ailesine hoş geldiniz! Başlamak için ayarlardan API anahtarlarınızı ekleyin.",
                NotificationType.Info,
                userId: user.Id);

            // Şifre belirleme linki oluştur (şifre e-postada gönderilmez)
            try
            {
                var resetToken = await _userManager.GeneratePasswordResetTokenAsync(user);
                var encodedToken = System.Net.WebUtility.UrlEncode(resetToken);
                var encodedEmail = System.Net.WebUtility.UrlEncode(model.Email);
                var setupUrl =
                    $"https://web-kripteks.runasp.net/set-password?token={encodedToken}&email={encodedEmail}";

                await _emailService.SendWelcomeEmailAsync(model.Email, model.FirstName, setupUrl);
            }
            catch (Exception ex)
            {
                // Mail hatası akışı bozmasın, sadece loglayalım
                System.Console.WriteLine($"Mail gönderme hatası: {ex.Message}");
            }

            return Ok(new { message = "Kullanıcı başarıyla oluşturuldu ve şifre belirleme linki gönderildi." });
        }

        return BadRequest(new { message = "Kullanıcı oluşturulurken bir hata oluştu.", errors = result.Errors });
    }

    // DELETE: api/users/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(string id)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound(new { message = "Kullanıcı bulunamadı." });

        // Yönetici silinemez kuralı
        var roles = await _userManager.GetRolesAsync(user);
        if (roles.Contains("Admin"))
        {
            return BadRequest(new { message = "Yönetici yetkisine sahip kullanıcılar silinemez!" });
        }

        var result = await _userManager.DeleteAsync(user);
        if (result.Succeeded)
        {
            var adminId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (adminId != null)
            {
                await _auditLogService.LogAsync(adminId, "Kullanıcı Silindi", new { user.Email });
            }

            await _logger.LogInfoAsync($"Kullanıcı silindi: {user.Email}");
            return Ok(new { message = "Kullanıcı başarıyla silindi." });
        }

        return BadRequest(new { message = "Silme işlemi başarısız.", errors = result.Errors });
    }

    // PUT: api/users/{id}
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(string id, [FromBody] UpdateUserDto model)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound(new { message = "Kullanıcı bulunamadı." });

        user.FirstName = InputSanitizer.Sanitize(model.FirstName);
        user.LastName = InputSanitizer.Sanitize(model.LastName);
        user.IsActive = model.IsActive;

        var result = await _userManager.UpdateAsync(user);

        if (result.Succeeded)
        {
            // Rol Güncelleme
            var currentRoles = await _userManager.GetRolesAsync(user);
            await _userManager.RemoveFromRolesAsync(user, currentRoles);
            await _userManager.AddToRoleAsync(user, model.Role);

            await _auditLogService.LogAsync(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!,
                "Kullanıcı Güncellendi", new { user.Email, model.Role, model.IsActive });
            return Ok(new { message = "Kullanıcı başarıyla güncellendi." });
        }

        return BadRequest(new { message = "Güncelleme başarısız.", errors = result.Errors });
    }
}

public class UpdateUserDto
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Role { get; set; } = "User";
    public bool IsActive { get; set; }
}

public class CreateUserDto
{
    [System.ComponentModel.DataAnnotations.Required(ErrorMessage = "Ad zorunludur.")]
    [System.ComponentModel.DataAnnotations.StringLength(100, MinimumLength = 2)]
    public string FirstName { get; set; } = string.Empty;

    [System.ComponentModel.DataAnnotations.Required(ErrorMessage = "Soyad zorunludur.")]
    [System.ComponentModel.DataAnnotations.StringLength(100, MinimumLength = 2)]
    public string LastName { get; set; } = string.Empty;

    [System.ComponentModel.DataAnnotations.Required(ErrorMessage = "E-posta zorunludur.")]
    [System.ComponentModel.DataAnnotations.EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi giriniz.")]
    [System.ComponentModel.DataAnnotations.StringLength(256)]
    public string Email { get; set; } = string.Empty;

    [System.ComponentModel.DataAnnotations.Required(ErrorMessage = "Şifre zorunludur.")]
    [System.ComponentModel.DataAnnotations.StringLength(128, MinimumLength = 6)]
    public string Password { get; set; } = string.Empty;

    [System.ComponentModel.DataAnnotations.RegularExpression("^(Admin|Trader|User)$",
        ErrorMessage = "Rol Admin, Trader veya User olmalıdır.")]
    public string Role { get; set; } = "User";
}
