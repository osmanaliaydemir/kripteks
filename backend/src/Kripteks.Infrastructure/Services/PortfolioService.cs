using Binance.Net.Interfaces.Clients;
using Kripteks.Core.DTOs;
using Kripteks.Core.Entities;
using Kripteks.Core.Interfaces;
using Kripteks.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Services;

public class PortfolioService : IPortfolioService
{
    private readonly AppDbContext _context;
    private readonly IBinanceRestClient _binanceClient;
    private readonly ILogger<PortfolioService> _logger;

    public PortfolioService(
        AppDbContext context,
        IBinanceRestClient binanceClient,
        ILogger<PortfolioService> logger)
    {
        _context = context;
        _binanceClient = binanceClient;
        _logger = logger;
    }

    public async Task<PortfolioSummaryDto> GetPortfolioSummaryAsync()
    {
        // 1. Aktif pozisyonları al (Running botlardan)
        var activeBots = await _context.Bots
            .Where(b => b.Status == BotStatus.Running)
            .ToListAsync();

        if (!activeBots.Any())
        {
            return new PortfolioSummaryDto
            {
                RiskMetrics = new PortfolioRiskMetricsDto { RiskLevel = "Yok" }
            };
        }

        // 2. Coin bazlı gruplama
        var assetGroups = activeBots
            .GroupBy(b => b.Symbol)
            .ToList();

        // 3. Binance'den anlık fiyatları al
        var prices = await GetCurrentPricesAsync(assetGroups.Select(g => g.Key).ToList());

        // 4. 24 saat değişim oranlarını al
        var dailyChanges = await Get24HourChangesAsync(assetGroups.Select(g => g.Key).ToList());

        // 5. Asset DTO'ları oluştur
        var assets = new List<PortfolioAssetDto>();
        decimal totalValue = 0;
        decimal totalInvested = 0;

        foreach (var group in assetGroups)
        {
            var symbol = group.Key;
            var baseAsset = ExtractBaseAsset(symbol);
            var bots = group.ToList();

            // Ortalama maliyet hesabı (weighted average)
            var totalQuantity = bots.Sum(b => b.Amount / (b.EntryPrice > 0 ? b.EntryPrice : 1));
            var avgCost = totalQuantity > 0
                ? bots.Sum(b => b.Amount) / totalQuantity
                : 0;
            var invested = bots.Sum(b => b.Amount);

            var currentPrice = prices.GetValueOrDefault(symbol, avgCost);
            var currentValue = totalQuantity * currentPrice;
            var pnl = currentValue - invested;
            var pnlPercent = invested > 0 ? (pnl / invested) * 100 : 0;

            var firstBuyDate = bots.Min(b => b.EntryDate ?? b.CreatedAt);
            var dailyChange = dailyChanges.GetValueOrDefault(symbol, 0m);

            assets.Add(new PortfolioAssetDto
            {
                Symbol = symbol,
                BaseAsset = baseAsset,
                Quantity = totalQuantity,
                AverageCost = avgCost,
                CurrentPrice = currentPrice,
                CurrentValue = currentValue,
                TotalInvested = invested,
                Pnl = pnl,
                PnlPercent = pnlPercent,
                DailyChange = dailyChange,
                FirstBuyDate = firstBuyDate
            });

            totalValue += currentValue;
            totalInvested += invested;
        }

        // 6. Allocation yüzdelerini hesapla
        foreach (var asset in assets)
        {
            asset.AllocationPercent = totalValue > 0
                ? (asset.CurrentValue / totalValue) * 100
                : 0;
        }

        // 7. Sıralama: değere göre büyükten küçüğe
        assets = assets.OrderByDescending(a => a.CurrentValue).ToList();

        // 8. Risk metrikleri
        var riskMetrics = CalculateRiskMetrics(activeBots, assets, totalValue);

        // 9. Rebalancing önerileri
        var rebalanceSuggestions = CalculateRebalanceSuggestions(assets, totalValue);

        // 10. Günlük P&L (ağırlıklı ortalama)
        var dailyPnl = assets.Sum(a =>
            a.CurrentValue * (a.DailyChange / 100));
        var dailyPnlPercent = totalValue > 0 ? (dailyPnl / totalValue) * 100 : 0;

        var totalPnl = totalValue - totalInvested;
        var totalPnlPercent = totalInvested > 0 ? (totalPnl / totalInvested) * 100 : 0;

        return new PortfolioSummaryDto
        {
            TotalValue = totalValue,
            TotalInvested = totalInvested,
            TotalPnl = totalPnl,
            TotalPnlPercent = totalPnlPercent,
            DailyPnl = dailyPnl,
            DailyPnlPercent = dailyPnlPercent,
            AssetCount = assets.Count,
            Assets = assets,
            RiskMetrics = riskMetrics,
            RebalanceSuggestions = rebalanceSuggestions
        };
    }

    /// <summary>
    /// Binance'den anlık fiyatları çeker.
    /// </summary>
    private async Task<Dictionary<string, decimal>> GetCurrentPricesAsync(List<string> symbols)
    {
        var result = new Dictionary<string, decimal>();
        try
        {
            var tickers = await _binanceClient.SpotApi.ExchangeData.GetTickersAsync();
            if (tickers.Success)
            {
                foreach (var symbol in symbols)
                {
                    // Symbol formatını normalize et: "BTC/USDT" → "BTCUSDT"
                    var normalized = symbol.Replace("/", "");
                    var ticker = tickers.Data.FirstOrDefault(t =>
                        string.Equals(t.Symbol, normalized, StringComparison.OrdinalIgnoreCase));

                    if (ticker != null)
                    {
                        result[symbol] = ticker.LastPrice;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Binance fiyat verileri alınamadı.");
        }

        return result;
    }

    /// <summary>
    /// 24 saatlik değişim yüzdelerini çeker.
    /// </summary>
    private async Task<Dictionary<string, decimal>> Get24HourChangesAsync(List<string> symbols)
    {
        var result = new Dictionary<string, decimal>();
        try
        {
            var tickers = await _binanceClient.SpotApi.ExchangeData.GetTickersAsync();
            if (tickers.Success)
            {
                foreach (var symbol in symbols)
                {
                    var normalized = symbol.Replace("/", "");
                    var ticker = tickers.Data.FirstOrDefault(t =>
                        string.Equals(t.Symbol, normalized, StringComparison.OrdinalIgnoreCase));

                    if (ticker != null)
                    {
                        result[symbol] = ticker.PriceChangePercent;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "24s değişim verileri alınamadı.");
        }

        return result;
    }

    /// <summary>
    /// Sembol string'inden base asset'i çıkarır. "BTC/USDT" → "BTC", "ETHUSDT" → "ETH"
    /// </summary>
    private static string ExtractBaseAsset(string symbol)
    {
        if (symbol.Contains('/'))
            return symbol.Split('/')[0];

        // "BTCUSDT" → "BTC"
        var quoteAssets = new[] { "USDT", "USDC", "BUSD", "BTC", "ETH", "BNB", "FDUSD" };
        foreach (var q in quoteAssets)
        {
            if (symbol.EndsWith(q, StringComparison.OrdinalIgnoreCase))
                return symbol[..^q.Length];
        }

        return symbol;
    }

    /// <summary>
    /// Portföy risk metriklerini hesaplar.
    /// </summary>
    private PortfolioRiskMetricsDto CalculateRiskMetrics(
        List<Bot> activeBots,
        List<PortfolioAssetDto> assets,
        decimal totalValue)
    {
        var metrics = new PortfolioRiskMetricsDto();

        // ── Concentration Risk (HHI - Herfindahl Index) ──
        // HHI = Σ(wi²), Wi = asset allocation yüzdesi
        // 0-0.15: Düşük yoğunlaşma, 0.15-0.25: Orta, 0.25+: Yüksek
        if (assets.Any())
        {
            metrics.ConcentrationRisk = assets.Sum(a =>
            {
                var weight = a.AllocationPercent / 100;
                return weight * weight;
            });
        }

        // ── Tamamlanan botlardan tarihsel getiri hesapla ──
        var completedBots = _context.Bots
            .Where(b => b.Status == BotStatus.Completed || b.Status == BotStatus.Stopped)
            .Where(b => !b.IsArchived)
            .OrderBy(b => b.ExitDate ?? b.CreatedAt)
            .ToList();

        if (completedBots.Count >= 2)
        {
            var returns = completedBots
                .Where(b => b.Amount > 0)
                .Select(b => b.CurrentPnl / b.Amount)
                .ToList();

            if (returns.Count >= 2)
            {
                var avgReturn = returns.Average();
                var stdDev = CalculateStdDev(returns);

                // ── Sharpe Ratio ──
                // (Ortalama Getiri - Risksiz Oran) / Standart Sapma
                var riskFreeRate = 0.0001m; // Günlük ~%0.01
                metrics.SharpeRatio = stdDev > 0
                    ? (avgReturn - riskFreeRate) / stdDev
                    : 0;

                // ── Sortino Ratio ──
                // Aşağı yönlü sapma kullanır (sadece negatif getiriler)
                var downside = returns.Where(r => r < 0).ToList();
                var downsideDev = downside.Any()
                    ? (decimal)Math.Sqrt((double)downside.Average(d => d * d))
                    : 0;

                metrics.SortinoRatio = downsideDev > 0
                    ? (avgReturn - riskFreeRate) / downsideDev
                    : (avgReturn > 0 ? 3.0m : 0); // Negatif yoksa yüksek skor

                // ── Volatilite (yıllıklandırılmış) ──
                metrics.Volatility = stdDev * (decimal)Math.Sqrt(252);

                // ── Max Drawdown ──
                metrics.MaxDrawdown = CalculateMaxDrawdown(returns);
            }
        }

        // ── Beta (BTC korelasyonu için basitleştirilmiş yaklaşım) ──
        // Portföydeki BTC ağırlığına göre beta tahmini
        var btcAllocation = assets
            .Where(a => a.BaseAsset == "BTC")
            .Sum(a => a.AllocationPercent) / 100;

        var altcoinAllocation = 1 - btcAllocation;
        // Altcoinler genellikle BTC'ye göre β > 1 davranır
        metrics.Beta = btcAllocation * 1.0m + altcoinAllocation * 1.5m;

        // ── Risk Seviyesi ──
        metrics.RiskLevel = DetermineRiskLevel(metrics);

        return metrics;
    }

    /// <summary>
    /// Standart sapma hesaplar.
    /// </summary>
    private static decimal CalculateStdDev(List<decimal> values)
    {
        if (values.Count < 2) return 0;

        var avg = values.Average();
        var sumOfSquares = values.Sum(v => (v - avg) * (v - avg));
        return (decimal)Math.Sqrt((double)(sumOfSquares / (values.Count - 1)));
    }

    /// <summary>
    /// Maximum drawdown hesaplar.
    /// </summary>
    private static decimal CalculateMaxDrawdown(List<decimal> returns)
    {
        decimal peak = 0;
        decimal maxDrawdown = 0;
        decimal currentEquity = 0;

        foreach (var r in returns)
        {
            currentEquity += r;
            if (currentEquity > peak) peak = currentEquity;

            var drawdown = peak > 0 ? (peak - currentEquity) / peak * 100 : 0;
            if (drawdown > maxDrawdown) maxDrawdown = drawdown;
        }

        return maxDrawdown;
    }

    /// <summary>
    /// Risk metriklerinden genel risk seviyesini belirler.
    /// </summary>
    private static string DetermineRiskLevel(PortfolioRiskMetricsDto m)
    {
        int riskScore = 0;

        // Yoğunlaşma riski
        if (m.ConcentrationRisk > 0.5m) riskScore += 3;
        else if (m.ConcentrationRisk > 0.25m) riskScore += 2;
        else if (m.ConcentrationRisk > 0.15m) riskScore += 1;

        // Volatilite
        if (m.Volatility > 1.0m) riskScore += 3;
        else if (m.Volatility > 0.5m) riskScore += 2;
        else if (m.Volatility > 0.2m) riskScore += 1;

        // Max Drawdown
        if (m.MaxDrawdown > 30) riskScore += 3;
        else if (m.MaxDrawdown > 15) riskScore += 2;
        else if (m.MaxDrawdown > 5) riskScore += 1;

        // Beta
        if (m.Beta > 2.0m) riskScore += 2;
        else if (m.Beta > 1.5m) riskScore += 1;

        return riskScore switch
        {
            >= 8 => "Çok Yüksek",
            >= 6 => "Yüksek",
            >= 4 => "Orta",
            >= 2 => "Düşük",
            _ => "Çok Düşük"
        };
    }

    /// <summary>
    /// Portföy dengeleme önerilerini hesaplar.
    /// Eşit dağılım hedefi ile karşılaştırır ve büyük sapmalarda öneri üretir.
    /// </summary>
    private static List<RebalanceSuggestionDto> CalculateRebalanceSuggestions(
        List<PortfolioAssetDto> assets,
        decimal totalValue)
    {
        if (assets.Count < 2 || totalValue <= 0)
            return [];

        var suggestions = new List<RebalanceSuggestionDto>();

        // Hedef: market cap ve risk bazlı basit model
        // Büyük coinler (BTC, ETH) → daha yüksek ağırlık
        // Diğer altcoinler → eşit dağılım
        var targetWeights = CalculateTargetWeights(assets);

        const decimal threshold = 5m; // %5'ten fazla sapma varsa öneri üret

        foreach (var asset in assets)
        {
            var target = targetWeights.GetValueOrDefault(asset.BaseAsset, 0m);
            var delta = asset.AllocationPercent - target;

            if (Math.Abs(delta) < threshold) continue;

            var suggestedAmount = totalValue * (Math.Abs(delta) / 100);
            var action = delta > 0 ? "SELL" : "BUY";

            var reason = delta > 0
                ? $"{asset.BaseAsset} portföyde aşırı ağırlıkta (%{asset.AllocationPercent:F1} vs hedef %{target:F1}). Riski azaltmak için bir miktar kâr realize edilebilir."
                : $"{asset.BaseAsset} portföyde eksik ağırlıkta (%{asset.AllocationPercent:F1} vs hedef %{target:F1}). Daha dengeli bir dağılım için ekleme yapılabilir.";

            suggestions.Add(new RebalanceSuggestionDto
            {
                Symbol = asset.Symbol,
                BaseAsset = asset.BaseAsset,
                CurrentPercent = asset.AllocationPercent,
                TargetPercent = target,
                DeltaPercent = Math.Abs(delta),
                Action = action,
                SuggestedAmountUsdt = Math.Round(suggestedAmount, 2),
                Reason = reason
            });
        }

        return suggestions.OrderByDescending(s => s.DeltaPercent).ToList();
    }

    /// <summary>
    /// Basit ağırlık hedefi hesaplar:
    /// BTC → %40, ETH → %25, diğerleri → kalan eşit dağılım.
    /// </summary>
    private static Dictionary<string, decimal> CalculateTargetWeights(List<PortfolioAssetDto> assets)
    {
        var weights = new Dictionary<string, decimal>();
        var majors = new Dictionary<string, decimal>
        {
            { "BTC", 40m },
            { "ETH", 25m }
        };

        decimal majorTotal = 0;
        var altcoins = new List<string>();

        foreach (var asset in assets)
        {
            if (majors.TryGetValue(asset.BaseAsset, out var majorWeight))
            {
                weights[asset.BaseAsset] = majorWeight;
                majorTotal += majorWeight;
            }
            else
            {
                altcoins.Add(asset.BaseAsset);
            }
        }

        // Kalan yüzdeyi altcoinlere eşit dağıt
        var remaining = 100m - majorTotal;
        if (altcoins.Count > 0)
        {
            var perAlt = remaining / altcoins.Count;
            foreach (var alt in altcoins)
            {
                weights[alt] = perAlt;
            }
        }
        else if (!weights.Any())
        {
            // Hiç major yoksa eşit dağıt
            var perAsset = 100m / assets.Count;
            foreach (var asset in assets)
            {
                weights[asset.BaseAsset] = perAsset;
            }
        }

        return weights;
    }
}
