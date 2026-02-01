using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces; // <--- EKLENDİ
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;

namespace Kripteks.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly UserManager<AppUser> _userManager;
    private readonly IEmailService _emailService; // <--- EKLENDİ
    private readonly ILogService _logger;

    public UsersController(UserManager<AppUser> userManager, IEmailService emailService,
        ILogService logger) // <--- EKLENDİ
    {
        _userManager = userManager;
        _emailService = emailService; // <--- EKLENDİ
        _logger = logger;
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
            FirstName = model.FirstName,
            LastName = model.LastName,
            EmailConfirmed = true
        };

        var result = await _userManager.CreateAsync(user, model.Password);

        if (result.Succeeded)
        {
            // Rol Atama
            var role = !string.IsNullOrEmpty(model.Role) ? model.Role : "User";
            await _userManager.AddToRoleAsync(user, role);

            await _logger.LogInfoAsync($"Yeni kullanıcı eklendi: {model.Email} ({role})"); // Loglama eklendi

            // Mail Gönderimi (Arka planda veya await ile)
            try
            {
                await _emailService.SendWelcomeEmailAsync(model.Email, model.FirstName, model.Password);
            }
            catch (Exception ex)
            {
                // Mail hatası akışı bozmasın, sadece loglayalım
                System.Console.WriteLine($"Mail gönderme hatası: {ex.Message}");
            }

            return Ok(new { message = "Kullanıcı başarıyla oluşturuldu ve bilgilendirme maili gönderildi." });
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
            await _logger.LogInfoAsync($"Kullanıcı silindi: {user.Email}");
            return Ok(new { message = "Kullanıcı başarıyla silindi." });
        }

        return BadRequest(new { message = "Silme işlemi başarısız.", errors = result.Errors });
    }
}

public class CreateUserDto
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Role { get; set; } = "User"; // Varsayılan rol
}
