using Microsoft.AspNetCore.Identity;

namespace Kripteks.Core.Entities;

public class AppUser : IdentityUser
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? ResetCode { get; set; }
    public DateTime? ResetCodeExpiry { get; set; }

    // Refresh Token Alanları
    public string? RefreshToken { get; set; }
    public DateTime? RefreshTokenExpiry { get; set; }
}
