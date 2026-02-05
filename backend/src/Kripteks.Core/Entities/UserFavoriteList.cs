using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Kripteks.Core.Entities;

public class UserFavoriteList
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    public string UserId { get; set; } = string.Empty;

    [ForeignKey("UserId")]
    public AppUser? User { get; set; }

    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty; // Örn: "Favorilerim", "Hızlı Liste"

    [Required]
    public string Symbols { get; set; } = string.Empty; // "BTCUSDT,ETHUSDT,BNBUSDT"

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
