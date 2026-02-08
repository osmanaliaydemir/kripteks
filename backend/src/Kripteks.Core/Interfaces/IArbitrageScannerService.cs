namespace Kripteks.Core.Interfaces;

public interface IArbitrageScannerService
{
    Task<List<ArbitrageOpportunityDto>> GetOpportunitiesAsync();
}

public class ArbitrageOpportunityDto
{
    public string Asset { get; set; } = string.Empty;
    public string Pair1 { get; set; } = string.Empty; // e.g. BTC/USDT
    public string Pair2 { get; set; } = string.Empty; // e.g. BTC/USDC
    public decimal Price1 { get; set; }
    public decimal Price2 { get; set; }
    public double DifferencePercent { get; set; }
    public decimal PotentialProfitUsd { get; set; } // Based on $1000 trade
}
