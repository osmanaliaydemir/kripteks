# Golden Rose Trend Stratejisi (Golden Rose Trend Strategy)

Bu doküman, Kripteks projesinde kullanılan "Golden Rose" algoritmik ticaret stratejisinin çalışma mantığını, teknik kurallarını ve kod tabanındaki implementasyon detaylarını içerir.

## 1. Strateji Mantığı ve Kurallar 📊

Bu strateji, orta-uzun vadeli trend takibi (Trend Following) mantığına dayanır. Hareketli ortalamaların (SMA) kesişimlerini giriş sinyali olarak kullanır ve Fibonacci oranlarına dayalı dinamik bir kar alma (Take Profit) hedefini takip eder.

### Temel İndikatörler

Strateji aşağıdaki teknik indikatörler üzerine kuruludur:

* **SMA 111 (Beyaz Çizgi):** Kısa vadeli trend yönünü ve giriş/çıkış (Stop) seviyelerini belirler.
* **SMA 350 (Sarı Çizgi):** Ana trendin yönünü ve "Golden Rose" olarak adlandırılan ana kar hedefini hesaplamak için referans noktasıdır.

### İşlem Kuralları

#### 🟢 Alım (Giriş) Koşulu

* **Kural:** Fiyat, **SMA 111** hareketli ortalamasını aşağıdan yukarıya doğru kesip üzerinde mum kapattığında (Crossover).
* **Mantık:** Fiyatın SMA 111 üzerine atması, kısa-orta vadeli düşüş trendinin bittiği ve yükselişin başladığına dair güçlü bir sinyal olarak kabul edilir.

#### 🎯 Satış (Kar Al - Take Profit) Koşulu

* **Hedef Fiyat (Golden Rose):** `SMA 350 Değeri * 1.618`
* **Kural:** Fiyat bu seviyeye ulaştığı veya geçtiği anda pozisyon kapatılır.
* **Mantık:** SMA 350'nin Fibonacci Altın Oranı (1.618) ile çarpılması, fiyatın gidebileceği potansiyel "aşırı alım" veya "doygunluk" noktasını (Golden Rose) belirler. Bu nokta genellikle güçlü bir dirençtir ve maksimum karı almak için ideal çıkış yeridir.

#### 🛑 Satış (Zarar Durdur - Stop Loss) Koşulu

* **Stop Seviyesi:** SMA 111'in %2-3 altı veya stratejiye göre trendin bozulduğu nokta.
* **Kural:** Fiyat, giriş yaptıktan sonra hedefe gidemez ve tekrar **SMA 111'in altına sarkarsa** pozisyon zararına kapatılır.
* **Mantık:** Fiyatın tekrar SMA 111 altına inmesi, trendin sahte olduğunu (Fakeout) veya trendin bittiğini gösterir. Sermayeyi korumak için işlemden çıkılır.

---

## 2. Kod İmplementasyonu ve Referanslar 💻

Projede bu strateji, **Strategy Pattern** (Strateji Tasarım Deseni) kullanılarak modüler bir yapıda geliştirilmiştir. Bu sayede `BacktestService` veya canlı `BotEngineService`, hangi stratejinin çalıştığını bilmeden sadece `Analyze` metodunu çağırarak sinyal alabilir.

### 📁 İlgili Dosyalar

| Dosya Yolu | Görevi |
| :--- | :--- |
| `src/Kripteks.Core/Interfaces/IStrategy.cs` | Tüm stratejilerin uyması gereken ortak arayüz (Interface). |
| `src/Kripteks.Infrastructure/Strategies/GoldenRoseStrategy.cs` | **Ana Strateji Kodu.** Mantığın (SMA Kesişimi, Hedef Hesaplama) yazıldığı yer. |
| `src/Kripteks.Infrastructure/Services/BacktestService.cs` | Stratejiyi geçmiş verilerle (Binance History) çalıştıran motor. |
| `src/Kripteks.Infrastructure/Helpers/TechnicalIndicators.cs` | SMA hesaplamalarını yapan matematiksel yardımcı sınıf. |

### 🔍 Kod Detayları

#### 1. Arayüz Tanımı (`IStrategy.cs`)

Tüm stratejilerin bir `Analyze` metodu olmak zorundadır. Bu metod mum verilerini alır ve bir `StrategyResult` (Al/Sat/Bekle) döner.

```csharp
public interface IStrategy
{
    string Name { get; }
    StrategyResult Analyze(List<Candle> candles, decimal currentBalance, decimal currentPositionAmount);
}
```

#### 2. Strateji Mantığı (`GoldenRoseStrategy.cs`)

Burası stratejinin beynidir.

* **SMA Hesaplama:**

    ```csharp
    var sma111 = TechnicalIndicators.CalculateSma(prices, 111);
    var sma350 = TechnicalIndicators.CalculateSma(prices, 350);
    ```

* **Alım Sinyali Kontrolü (Crossover):**

    ```csharp
    // Önceki mum SMA111 altında (veya eşit), şu anki mum SMA111 üstünde mi?
    bool crossOverSma111 = prevPrice <= prevSma111 && currentPrice > lastSma111;
    
    if (crossOverSma111) {
        result.Action = TradeAction.Buy;
        // ...
    }
    ```

* **Hedef Fiyat (Golden Rose) Hesaplama:**

    ```csharp
    // Hedef: SMA 350 * 1.618
    decimal targetPrice = lastSma350.Value * 1.618m;
    ```

* **Stop Loss (Çıkış) Kontrolü:**

    ```csharp
    // Eğer fiyat SMA 111 altına sarkarsa (%2 tolerans ile)
    if (currentPrice < lastSma111.Value * 0.98m)
    {
        result.Action = TradeAction.Sell; // Trend Bozuldu, Çık.
    }
    ```

#### 3. Backtest Motoru (`BacktestService.cs`)

Backtest servisi, seçilen stratejiyi (`GoldenRoseStrategy`) yükler ve Binance'den gelen mumları döngüye sokar.

```csharp
// 1. Stratejiyi Seç
IStrategy strategy = new GoldenRoseStrategy();

// 2. Döngü (Geçmişten Bugüne)
for (int i = warmUpPeriod; i < candles.Count; i++)
{
    // ...
    // 3. Stratejiye "Ne Yapayım?" diye sor
    var signal = strategy.Analyze(history, currentBalance, positionAmount);
    
    // 4. Sinyale göre sanal işlem aç/kapat
    if (signal.Action == TradeAction.Buy) { /* Sanal Alış Yap */ }
    else if (signal.Action == TradeAction.Sell) { /* Sanal Satış Yap */ }
    
    // 5. Hedef (TP) veya Stop (SL) kontrolü
    if (inPosition && currentCandle.High >= targetPrice) { /* Hedef Geldi, Sat */ }
}
```

## 3. Özet

Bu yapı sayesinde, stratejinin kuralları tek bir dosyada (`GoldenRoseStrategy.cs`) merkezi olarak tutulur. Eğer stratejide bir değişiklik yapmak isterseniz (örneğin SMA 111 yerine SMA 200 kullanmak), sadece bu dosyayı güncellemeniz yeterlidir. Hem Backtest hem de gelecekteki Canlı Bot bu güncellemeyi otomatik olarak kullanacaktır.
