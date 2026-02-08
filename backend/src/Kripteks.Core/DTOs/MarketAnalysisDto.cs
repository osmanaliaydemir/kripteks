namespace Kripteks.Core.DTOs;

public class MarketOverviewDto
{
    public decimal TotalMarketCap { get; set; }
    public decimal Volume24h { get; set; }
    public decimal BtcDominance { get; set; }
    public decimal EthDominance { get; set; }
    public int ActiveCryptos { get; set; }
    public string MarketTrend { get; set; } = "neutral";
}

public class TopMoverDto
{
    public string Symbol { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal ChangePercent24h { get; set; }
    public decimal Volume24h { get; set; }
}

public class VolumeDataDto
{
    public DateTime Timestamp { get; set; }
    public decimal Volume { get; set; }
}

public class MarketMetricsDto
{
    public double FearGreedIndex { get; set; }
    public string FearGreedLabel { get; set; } = "Neutral";
    public decimal TotalVolume24h { get; set; }
    public decimal BtcPrice { get; set; }
    public decimal EthPrice { get; set; }
    public int TradingPairs { get; set; }
}
