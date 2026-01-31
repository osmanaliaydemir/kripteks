namespace Kripteks.Core.DTOs;

public class CoinDto
{
    public string Id { get; set; } = string.Empty;
    public string Symbol { get; set; } = string.Empty;
    public string BaseAsset { get; set; } = string.Empty;
    public string QuoteAsset { get; set; } = string.Empty;
    public decimal MinQuantity { get; set; }
    public decimal MaxQuantity { get; set; }
    public decimal CurrentPrice { get; set; }
}
