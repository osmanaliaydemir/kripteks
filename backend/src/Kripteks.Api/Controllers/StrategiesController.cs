using Microsoft.AspNetCore.Mvc;

namespace Kripteks.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StrategiesController : ControllerBase
{
    [HttpGet]
    public IActionResult GetStrategies()
    {
        var strategies = new[]
        {
            new
            {
                id = "strategy-market-buy", name = "Hemen Al (Market Buy)",
                description = "Beklemeden o anki fiyattan alım yapar."
            },
            new
            {
                id = "strategy-golden-rose", name = "Golden Rose Trend Strategy",
                description =
                    "SMA 111, 200 ve 350 periyotluk hareketli ortalamaları kullanarak ana trend yönünü belirleyen kurumsal düzeyde bir strateji. Giriş sinyalleri için SMA 111 kırılımını, kâr alım hedefleri için ise Fibonacci 1.618 (Golden Ratio) genişleme seviyelerini baz alır. Özellikle Bitcoin halving döngüleri ve makro trend değişimleri için optimize edilmiştir."
            },
            new
            {
                id = "strategy-alpha-trend", name = "Alpha Trend (EMA + RSI)",
                description =
                    "EMA 20 (Hızlı) ve EMA 50 (Yavaş) üstel hareketli ortalama kesişimlerini temel alan trend takip stratejisi. Yanıltıcı sinyalleri elemek için RSI (14) momentum filtresi kullanır; RSI'ın 50 üzerindeki kalıcılığına ve hacim desteğine göre trend başlangıçlarını saptamaya çalışır."
            },
            new
            {
                id = "strategy-scout-breakout", name = "Scout Breakout (Volume & RSI)",
                description =
                    "20 periyotluk hacim ortalamasının 1.8x katı üzerindeki patlamaları yakalayan momentum stratejisi. RSI (14) indikatörünün 50-70 'ideal breakout' koridorunda olmasını veya RSI 30 seviyesinden güçlü hacimle dönüşü (oversold recovery) şart koşar. Puanlama %50 Hacim Faktörü, %50 RSI Momentum ağırlığı ile hesaplanır."
            },
            new
            {
                id = "SMA_111", name = "SMA 111 Basic", description = "Sadece SMA 111 kırılımına bakan basit strateji."
            },
            new
            {
                id = "RSI_SCALP", name = "RSI Scalper",
                description = "RSI 30-70 bandında işlem yapan yatay piyasa stratejisi."
            },
            new
            {
                id = "strategy-phoenix-momentum", name = "Phoenix Momentum Strategy",
                description =
                    "Hacim, RSI ve Bollinger indikatörlerini birleştirerek kısa vadeli sert yükseliş (pump) potansiyeli taşıyan pariteleri yakalar."
            }
        };

        return Ok(strategies);
    }
}
