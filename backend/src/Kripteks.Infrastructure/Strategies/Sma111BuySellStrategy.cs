using Kripteks.Core.Interfaces;
using Kripteks.Core.Models.Strategy;
using Kripteks.Infrastructure.Helpers;
using Microsoft.Extensions.Logging;

namespace Kripteks.Infrastructure.Strategies;

public class Sma111BuySellStrategy : BaseStrategy
{
    private const int Sma111Period = 111;
    private const int Sma350Period = 350;

    // Multipliers for visualization
    private readonly decimal[] _multipliers = { 0.702m, 1.618m, 2.0m, 3.0m, 5.0m, 8.0m, 13.0m, 21.0m };

    public Sma111BuySellStrategy(ILogger<Sma111BuySellStrategy> logger) : base(logger)
    {
    }

    public override string Id => "Sma111BuySellStrategy";
    public override string Name => "SMA 111 Kırılım Al-Sat";

    public override string Description =>
        "Fiyatın 111 günlük SMA'yı yukarı kestiğinde AL, aşağı kestiğinde SAT sinyali ürettiği trend takip stratejisi.";

    protected override StrategyResult OnAnalyze(List<Candle> candles, decimal currentBalance,
        decimal currentPositionAmount, decimal entryPrice, int currentStep)
    {
        // Yeterli veri kontrolü (en az SMA111 period + 1 mum gerekli ki bir önceki mumu kontrol edebilelim)
        if (candles.Count < Sma111Period + 1)
        {
            return new StrategyResult { Action = TradeAction.None, Description = "Yetersiz veri." };
        }

        var prices = candles.Select(c => c.Close).ToList();
        var lastCandle = candles.Last();
        var prevCandle = candles[candles.Count - 2];

        // SMA Hesaplamaları
        var sma111Values = TechnicalIndicators.CalculateSma(prices, Sma111Period);
        var sma350Values = TechnicalIndicators.CalculateSma(prices, Sma350Period);

        var currentSma111 = sma111Values.Last();
        var prevSma111 = sma111Values[sma111Values.Count - 2];
        var currentSma350 = sma350Values.Last();

        // Veri Validasyonu
        if (currentSma111 == null || prevSma111 == null || currentSma350 == null)
        {
            return new StrategyResult { Action = TradeAction.None, Description = "Yetersiz SMA verisi." };
        }

        // Görselleştirme Verileri
        var indicators = new Dictionary<string, object>
        {
            { "SMA111", currentSma111.Value },
            { "SMA350", currentSma350.Value }
        };

        foreach (var m in _multipliers)
        {
            indicators.Add($"x{m}", currentSma350.Value * m);
        }

        // Sinyal Mantığı: State Check yerine Crossover Check (Whipsaw önlemek için)
        // Kullanıcı talebi: "Tek işlem yapması lazım", yani sürekli gir-çık yapmamalı.
        // Bu yüzden sadece kesişim anında işlem açıyoruz.

        TradeAction action = TradeAction.None;
        string message = string.Empty;

        bool isBullishCross = prevCandle.Close <= prevSma111.Value && lastCandle.Close > currentSma111.Value;
        bool isBearishCross = prevCandle.Close >= prevSma111.Value && lastCandle.Close < currentSma111.Value;

        // Pozisyon Yönetimi ve Sinyal Üretimi
        if (currentPositionAmount == 0)
        {
            // Pozisyon yoksa, sadece ALIM kesişimi (Bullish Crossover) varsa işlem aç
            if (isBullishCross)
            {
                action = TradeAction.Buy;
                message =
                    $"SMA 111 KESİŞİMİ (YUKARI): Fiyat {prevCandle.Close:F8} -> {lastCandle.Close:F8}, SMA {currentSma111:F8}";
            }
            else
            {
                action = TradeAction.None;
                // Durum bilgisi (Opsiyonel: Kullanıcıya trendin ne olduğunu söylemek için)
                if (lastCandle.Close > currentSma111.Value)
                    message = "Trend YUKARI (Pozisyon yok, yeni kesişim bekleniyor)";
                else
                    message = "Trend AŞAĞI (Nötr)";
            }
        }
        else
        {
            // Pozisyon varsa, sadece SATIM kesişimi (Bearish Crossover) varsa işlem kapat
            if (isBearishCross)
            {
                action = TradeAction.Sell;
                message =
                    $"SMA 111 KESİŞİMİ (AŞAĞI): Fiyat {prevCandle.Close:F8} -> {lastCandle.Close:F8}, SMA {currentSma111:F8}. Pozisyon kapatılıyor.";
            }
            else
            {
                action = TradeAction.None;
                message = $"Pozisyon taşınıyor. Fiyat: {lastCandle.Close:F8} > SMA111: {currentSma111:F8}";
            }
        }

        return new StrategyResult
        {
            Action = action,
            Description = message,
            Price = lastCandle.Close,
            Time = lastCandle.OpenTime,
            Indicators = indicators
        };
    }

    protected override decimal OnCalculateSignalScore(List<Candle> candles)
    {
        // Basit skorlama: 
        // Fiyat SMA 111 üzerindeyse => 80
        // Fiyat SMA 111 altındaysa => 20
        // Veri yoksa => 0

        if (candles.Count < Sma111Period) return 0;

        var prices = candles.Select(c => c.Close).ToList();
        var sma111Values = TechnicalIndicators.CalculateSma(prices, Sma111Period);
        var currentSma111 = sma111Values.Last();
        var lastPrice = candles.Last().Close;

        if (currentSma111 == null) return 0;

        if (lastPrice > currentSma111.Value)
        {
            // Trend yukarı, güçlü alım/tutma bölgesi
            return 80;
        }
        else
        {
            // Trend aşağı
            return 20;
        }
    }
}
