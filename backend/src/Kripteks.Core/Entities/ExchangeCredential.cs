using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Kripteks.Core.Entities;

public class ExchangeCredential
{
    public int Id { get; set; }

    [Required]
    public string UserId { get; set; } = string.Empty; // AppUser ID'si

    [ForeignKey("UserId")]
    public AppUser? User { get; set; }

    [Required]
    public string ExchangeName { get; set; } = "Binance";

    [Required]
    public string ApiKey { get; set; } = string.Empty;

    [Required]
    public string ApiSecret { get; set; } = string.Empty; // Güvenlik için şifreli saklanmalı

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}
