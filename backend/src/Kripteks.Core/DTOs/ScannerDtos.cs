
using Kripteks.Core.Models.Strategy;

namespace Kripteks.Core.DTOs;

public class ScannerRequestDto
{
    public List<string> Symbols { get; set; } = new();
    public string StrategyId { get; set; } = string.Empty;
    public string Interval { get; set; } = "1h";
    public int? MinScore { get; set; }
    public Dictionary<string, string>? StrategyParameters { get; set; }
}

public class ScannerResultDto
{
    public List<ScannerResultItemDto> Results { get; set; } = new();
}

public class ScannerResultItemDto
{
    public string Symbol { get; set; } = string.Empty;
    public decimal SignalScore { get; set; } // 0-100
    public TradeAction SuggestedAction { get; set; }
    public string Comment { get; set; } = string.Empty;
    public decimal LastPrice { get; set; }
}

public class ScannerFavoriteListDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public List<string> Symbols { get; set; } = new();
    public DateTime CreatedAt { get; set; }
}

public class SaveFavoriteListDto
{
    public Guid? Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public List<string> Symbols { get; set; } = new();
}

