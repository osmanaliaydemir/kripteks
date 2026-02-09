using Kripteks.Core.Interfaces;

namespace Kripteks.Infrastructure.Strategies;

/// <summary>
/// Grid Trading Bot - Izgara Ticaret Stratejisi
/// Belirlenen fiyat aralığını eşit grid seviyelerine böler.
/// Fiyat bir seviyenin altına indiğinde alır, bir üst seviyeye çıktığında satar.
/// BotEngine tek pozisyon desteklediği için, her döngüde en yakın grid seviyesine göre işlem yapar.
/// </summary>
public class GridStrategy : IStrategy
{
    public string Id => "strategy-grid";
    public string Name => "Grid Trading Bot";

    public string Description =>
        "Belirlenen alt ve üst fiyat aralığını eşit grid seviyelerine böler. Fiyat alt yarıdayken alım yapar, bir üst grid seviyesine çıktığında satış gerçekleştirir. Aralık dışına çıkıldığında otomatik koruma devreye girer. Yatay (range-bound) piyasalarda kâr üretmeye optimize edilmiştir. Kullanım için lowerPrice, upperPrice ve gridCount parametreleri gereklidir.";

    public StrategyCategory Category => StrategyCategory.Trading;

    private int _gridCount = 10;
    private decimal _lowerPrice;
    private decimal _upperPrice;

    public void SetParameters(Dictionary<string, string> parameters)
    {
        if (parameters.TryGetValue("gridCount", out var v1) && int.TryParse(v1, out var c)) _gridCount = c;
        if (parameters.TryGetValue("lowerPrice", out var v2) && decimal.TryParse(v2, out var l)) _lowerPrice = l;
        if (parameters.TryGetValue("upperPrice", out var v3) && decimal.TryParse(v3, out var u)) _upperPrice = u;
    }

    public StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount,
        decimal entryPrice = 0, int currentStep = 0)
    {
        var result = new StrategyResult();
        var currentPrice = candles.Last().Close;

        // ═══════════════════════════════════════════════
        // Parametre doğrulama
        // ═══════════════════════════════════════════════
        if (_lowerPrice <= 0 || _upperPrice <= 0)
        {
            result.Description = "GRID HATA: Alt ve üst fiyat parametreleri gerekli (lowerPrice, upperPrice)";
            return result;
        }

        if (_upperPrice <= _lowerPrice)
        {
            result.Description = "GRID HATA: Üst fiyat, alt fiyattan büyük olmalı";
            return result;
        }

        if (_gridCount < 2)
        {
            result.Description = "GRID HATA: Grid sayısı en az 2 olmalı";
            return result;
        }

        decimal gridStep = (_upperPrice - _lowerPrice) / _gridCount;

        // Mevcut fiyatın hangi grid seviyesinde olduğunu hesapla
        // Grid 0 = _lowerPrice, Grid N = _upperPrice
        int currentGridLevel = (int)((currentPrice - _lowerPrice) / gridStep);
        currentGridLevel = Math.Clamp(currentGridLevel, 0, _gridCount);

        // ═══════════════════════════════════════════════
        // Fiyat grid aralığı dışında
        // ═══════════════════════════════════════════════
        if (currentPrice < _lowerPrice * 0.95m) // %5 tolerans altında
        {
            if (currentPositionAmount > 0)
            {
                result.Action = TradeAction.Sell;
                result.Description = "GRID STOP: Fiyat grid aralığının çok altına düştü";
                return result;
            }

            result.Description = "GRID: Fiyat aralık dışında (altında), bekleniyor";
            return result;
        }

        if (currentPrice > _upperPrice * 1.05m) // %5 tolerans üstünde
        {
            if (currentPositionAmount > 0)
            {
                result.Action = TradeAction.Sell;
                result.Description = "GRID KÂR: Fiyat grid aralığının üstüne çıktı";
                return result;
            }

            result.Description = "GRID: Fiyat aralık dışında (üstünde), bekleniyor";
            return result;
        }

        // ═══════════════════════════════════════════════
        // POZİSYON YOK → Alım sinyali
        // ═══════════════════════════════════════════════
        if (currentPositionAmount == 0)
        {
            // Grid aralığında ve alt yarıdaysa al (düşük seviye = iyi giriş)
            if (currentPrice <= _lowerPrice + gridStep * (_gridCount / 2m))
            {
                decimal nearestGridAbove = _lowerPrice + (currentGridLevel + 1) * gridStep;
                nearestGridAbove = Math.Min(nearestGridAbove, _upperPrice);

                result.Action = TradeAction.Buy;
                result.TargetPrice = nearestGridAbove; // Bir üst grid seviyesinde sat
                result.StopPrice = _lowerPrice * 0.95m; // Grid altına çıkarsa stop
                result.Description =
                    $"GRID ALIM: Seviye {currentGridLevel}/{_gridCount} (Hedef: ${nearestGridAbove:F2})";
            }
            else
            {
                result.Description =
                    $"GRID BEKLİYOR: Fiyat üst yarıda ({currentGridLevel}/{_gridCount}), düşüş bekleniyor";
            }
        }
        // ═══════════════════════════════════════════════
        // POZİSYON VAR → Satış sinyali
        // ═══════════════════════════════════════════════
        else
        {
            if (entryPrice <= 0)
            {
                result.Description = "GRID: Giriş fiyatı bilgisi bekleniyor";
                return result;
            }

            // Giriş fiyatının grid seviyesini hesapla
            int entryGridLevel = (int)((entryPrice - _lowerPrice) / gridStep);
            entryGridLevel = Math.Clamp(entryGridLevel, 0, _gridCount);

            // En az 1 grid yukarı çıktıysa sat (grid kârı)
            if (currentGridLevel > entryGridLevel)
            {
                result.Action = TradeAction.Sell;
                decimal profit = ((currentPrice - entryPrice) / entryPrice) * 100;
                result.Description =
                    $"GRID SATIŞ: {entryGridLevel} → {currentGridLevel} seviye (%{profit:F2} kâr)";
            }
            // Fiyat giriş grid'inin 2 altına düştüyse stop
            else if (currentGridLevel < entryGridLevel - 1 && currentPrice < entryPrice * 0.97m)
            {
                result.Action = TradeAction.Sell;
                result.Description = $"GRID STOP: Fiyat {entryGridLevel - currentGridLevel} grid aşağı düştü";
            }
            else
            {
                decimal pnl = ((currentPrice - entryPrice) / entryPrice) * 100;
                decimal targetGrid = _lowerPrice + (entryGridLevel + 1) * gridStep;
                result.Description =
                    $"GRID POZİSYONDA: Seviye {currentGridLevel} (%{pnl:F2}), Hedef: ${targetGrid:F2}";
            }
        }

        return result;
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        if (_lowerPrice <= 0 || _upperPrice <= 0 || _gridCount < 2)
            return 0;

        var currentPrice = candles.Last().Close;

        // Fiyat grid aralığında değilse sinyal yok
        if (currentPrice < _lowerPrice || currentPrice > _upperPrice)
            return 0;

        // Fiyat alt yarıda → iyi giriş fırsatı → yüksek skor
        decimal position = (currentPrice - _lowerPrice) / (_upperPrice - _lowerPrice);

        if (position <= 0.3m) return 85; // Alt %30 = güçlü alım bölgesi
        if (position <= 0.5m) return 70; // Alt yarı = iyi bölge
        if (position <= 0.7m) return 50; // Orta bölge
        return 30; // Üst bölge = alım için ideal değil
    }
}
