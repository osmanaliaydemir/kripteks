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
            // Simulation Strategies
            new
            {
                id = "strategy-market-buy", name = "Anlık Alım",
                description = "Beklemeden o anki fiyattan alım yapar.",
                category = "simulation"
            },
            new
            {
                id = "strategy-golden-rose", name = "Altın Kesişim Trendi",
                description =
                    "SMA 111, 200 ve 350 periyotluk hareketli ortalamaları kullanarak ana trend yönünü belirleyen kurumsal düzeyde bir strateji. Giriş sinyalleri için SMA 111 kırılımını, kâr alım hedefleri için ise Fibonacci 1.618 (Golden Ratio) genişleme seviyelerini baz alır. Özellikle Bitcoin halving döngüleri ve makro trend değişimleri için optimize edilmiştir.",
                category = "simulation"
            },
            new
            {
                id = "strategy-alpha-trend", name = "Alfa Trend Takibi",
                description =
                    "EMA 20 (Hızlı) ve EMA 50 (Yavaş) üstel hareketli ortalama kesişimlerini temel alan trend takip stratejisi. Yanıltıcı sinyalleri elemek için RSI (14) momentum filtresi kullanır; RSI'ın 50 üzerindeki kalıcılığına ve hacim desteğine göre trend başlangıçlarını saptamaya çalışır.",
                category = "simulation"
            },
            new
            {
                id = "strategy-golden-cross", name = "Altın Kesişim (Golden Cross)",
                description =
                    "Klasik SMA 50 ve SMA 200 kesişim stratejisi. SMA 50, SMA 200'ü yukarı kestiğinde alım (Golden Cross), aşağı kestiğinde satış (Death Cross) sinyali üretir. Uzun vadeli trend takibi için idealdir.",
                category = "simulation"
            },
            // Scanner Strategies
            new
            {
                id = "strategy-scout-breakout", name = "İzci Kırılımı",
                description =
                    "20 periyotluk hacim ortalamasının 1.8x katı üzerindeki patlamaları yakalayan momentum stratejisi. RSI (14) indikatörünün 50-70 'ideal breakout' koridorunda olmasını veya RSI 30 seviyesinden güçlü hacimle dönüşü (oversold recovery) şart koşar. Puanlama %50 Hacim Faktörü, %50 RSI Momentum ağırlığı ile hesaplanır.",
                category = "scanner"
            },
            new
            {
                id = "strategy-phoenix-momentum", name = "Anka Kuşu Patlaması",
                description =
                    "Hacim, RSI ve Bollinger indikatörlerini birleştirerek kısa vadeli sert yükseliş (pump) potansiyeli taşıyan pariteleri yakalar.",
                category = "scanner"
            },
            new
            {
                id = "strategy-whale-accumulation", name = "Balina Biriktirmesi",
                description =
                    "Düşük volatilite dönemlerinde (Bollinger sıkışması) OBV'nin yükseliş trendinde olduğu coinleri tespit eder. Büyük yatırımcıların sessizce birikim yaptığı potansiyel kırılım adaylarını yakalar.",
                category = "scanner"
            },
            new
            {
                id = "strategy-oversold-recovery", name = "Dipten Dönüş",
                description =
                    "RSI ve Stochastic RSI aşırı satım bölgesinden (30 altı) toparlanma sinyali veren coinleri tespit eder. Destek seviyesi yakınında, hacim artışıyla birlikte yukarı dönüş yapan pariteleri yakalar.",
                category = "scanner"
            },
            new
            {
                id = "strategy-trend-surfer", name = "Trend Sörfçüsü",
                description =
                    "ADX (Average Directional Index) ile trend gücünü ölçer, EMA 50/200 ile trend yönünü belirler. Güçlü yükseliş trendindeki coinleri tespit ederek trende binme fırsatı sunar.",
                category = "scanner"
            },
            new
            {
                id = "strategy-breakout-hunter", name = "Kırılım Avcısı",
                description =
                    "Bollinger Band sıkışması (düşük bandwidth) ve ATR daralması ile konsolidasyon tespit eder. Hacim patlamasıyla birlikte üst bandı kıran coinleri yakalar.",
                category = "scanner"
            },
            new
            {
                id = "strategy-divergence-detector", name = "Uyumsuzluk Dedektörü",
                description =
                    "Fiyat ve RSI/MACD arasındaki uyumsuzlukları tespit eder. Fiyat düşerken RSI yükseliyorsa (bullish divergence) trend dönüşü sinyali verir. Erken giriş fırsatları sunar.",
                category = "scanner"
            },
            new
            {
                id = "strategy-sma-111-breakout", name = "SMA 111 Kırılım",
                description =
                    "Fiyatın SMA 111 (Basit Hareketli Ortalama) seviyesini yukarı yönlü kırmasını takip eder. Güçlü bir trend başlangıcı sinyali olarak kabul edilir.",
                category = "scanner"
            },
            // Basic Strategies (Both)
            new
            {
                id = "SMA_111", name = "Temel SMA 111",
                description = "Sadece SMA 111 kırılımına bakan basit strateji.",
                category = "simulation"
            },
            new
            {
                id = "strategy-simulation", name = "Simülasyon Stratejisi",
                description = "Gerçek veri olmasa bile test verisi üreterek sistemin akışını kontrol etmenizi sağlar.",
                category = "both"
            },
            new
            {
                id = "RSI_SCALP", name = "RSI Skalper",
                description = "RSI 30-70 bandında işlem yapan yatay piyasa stratejisi.",
                category = "both"
            }
        };

        return Ok(strategies);
    }
}
