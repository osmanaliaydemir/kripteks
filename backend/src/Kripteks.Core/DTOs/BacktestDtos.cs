namespace Kripteks.Core.DTOs;

public class BacktestRequestDto
{
    public string Symbol { get; set; } = "BTC/USDT";
    public string StrategyId { get; set; } = string.Empty;
    public string Period { get; set; } = "7d";
    public string? StartDate { get; set; } // YYYY-MM-DD
    public string? EndDate { get; set; } // YYYY-MM-DD
    public string Interval { get; set; } = "15m"; // 3m, 5m, 15m, 1h...
    public decimal InitialBalance { get; set; } = 1000;
    public Dictionary<string, string>? StrategyParameters { get; set; }

    // New fields for realistic simulation
    public decimal CommissionRate { get; set; } = 0.001m; // 0.1% Binance default
    public decimal SlippageRate { get; set; } = 0.0005m; // 0.05% default
}

public class BacktestResultDto
{
    public int TotalTrades { get; set; }
    public int WinningTrades { get; set; }
    public int LosingTrades { get; set; }
    public decimal TotalPnl { get; set; }
    public decimal TotalPnlPercent { get; set; }
    public decimal WinRate { get; set; }
    public decimal MaxDrawdown { get; set; }
    public decimal InitialBalance { get; set; }
    public decimal TotalCommissionPaid { get; set; }

    // Advanced Metrics (Phase 2)
    public decimal SharpeRatio { get; set; }
    public decimal SortinoRatio { get; set; }
    public decimal ProfitFactor { get; set; }
    public decimal AverageWin { get; set; }
    public decimal AverageLoss { get; set; }
    public int MaxConsecutiveWins { get; set; }
    public int MaxConsecutiveLosses { get; set; }

    public List<BacktestTradeDto> Trades { get; set; } = new();
    public List<BacktestCandleDto> Candles { get; set; } = new();
}

public class BacktestCandleDto
{
    public DateTime Time { get; set; }
    public decimal Open { get; set; }
    public decimal High { get; set; }
    public decimal Low { get; set; }
    public decimal Close { get; set; }
}

public class BacktestTradeDto
{
    public string Type { get; set; } = string.Empty;
    public DateTime EntryDate { get; set; }
    public DateTime ExitDate { get; set; }
    public decimal EntryPrice { get; set; }
    public decimal ExitPrice { get; set; }
    public decimal Pnl { get; set; }
    public decimal Commission { get; set; }
}

public class OptimizationResultDto
{
    public Dictionary<string, string> BestParameters { get; set; } = new();
    public decimal BestPnlPercent { get; set; } = -999;
    public BacktestResultDto? Result { get; set; }
}

public class BatchBacktestRequestDto
{
    public List<string> Symbols { get; set; } = new();
    public string StrategyId { get; set; } = string.Empty;
    public string? StartDate { get; set; }
    public string? EndDate { get; set; }
    public string Interval { get; set; } = "15m";
    public decimal InitialBalance { get; set; } = 1000;
    public Dictionary<string, string>? StrategyParameters { get; set; }
    public decimal CommissionRate { get; set; } = 0.001m;
    public decimal SlippageRate { get; set; } = 0.0005m;
}

public class BatchBacktestResultDto
{
    public List<BatchBacktestResultItemDto> Results { get; set; } = new();
}

public class BatchBacktestResultItemDto
{
    public string Symbol { get; set; } = string.Empty;
    public decimal TotalPnlPercent { get; set; }
    public decimal WinRate { get; set; }
    public int TotalTrades { get; set; }
    public decimal MaxDrawdown { get; set; }
    public decimal ProfitFactor { get; set; }
    public decimal SharpeRatio { get; set; }
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
}
