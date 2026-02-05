using Kripteks.Core.Interfaces;

namespace Kripteks.Infrastructure.Strategies;

public class GridStrategy : IStrategy
{
    public string Id => "strategy-grid";
    public string Name => "Grid Trading Bot";

    private int _gridCount = 10;
    private decimal _lowerPrice = 0;
    private decimal _upperPrice = 0;

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

        // Parametreler eksikse işlem yapma
        if (_lowerPrice == 0 || _upperPrice == 0 || _gridCount <= 1)
            return result;

        decimal gridStep = (_upperPrice - _lowerPrice) / _gridCount;

        // Basit Grid Mantığı (Simülasyon):
        // Fiyat bir grid seviyesine düştüyse AL
        // Fiyat bir grid seviyesine çıktıysa SAT

        // Bu basit implementasyonda, pozisyon yoksa ve fiyat grid aralığındaysa AL
        if (currentPositionAmount == 0)
        {
            if (currentPrice >= _lowerPrice && currentPrice <= _upperPrice)
            {
                result.Action = TradeAction.Buy;
                result.TargetPrice = currentPrice + gridStep; // Bir üst gridde sat
                result.StopPrice = _lowerPrice * 0.95m; // Grid dışına çıkarsa stop ol
                result.Description = $"GRID ALIM: Fiyat aralıkta ({_lowerPrice}-{_upperPrice})";
            }
        }
        else
        {
            // Grid botu aslında sürekli al-sat yapar. 
            // BotEngine şu an tek işlem desteklediği için, burada TP (TargetPrice) geldiğinde satacak.
            // TP zaten analiz sonucunda belirlendiği için burada ek bir logic kurmaya gerek olmayabilir 
            // ama özel bir çıkış koşulu varsa eklenebilir.
        }

        return result;
    }

    public decimal CalculateSignalScore(List<Candle> candles)
    {
        var currentPrice = candles.Last().Close;
        if (_lowerPrice > 0 && _upperPrice > 0 && currentPrice >= _lowerPrice && currentPrice <= _upperPrice)
            return 70; // Bullish if in range
        return 40;
    }
}
