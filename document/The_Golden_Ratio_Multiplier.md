# The Golden Ratio Multiplier Stratejisi - Yapılacaklar Listesi

Philip Swift'in "The Golden Ratio Multiplier" stratejisi ve TradingView koduna dayalı, **basitleştirilmiş alım/satım kuralları** içeren uygulama adımları.

## 1. Parametreler ve Göstergeler

Strateji aşağıdaki göstergeleri hesaplamalıdır.

### Ana Göstergeler

- [ ] **SMA 111** (`sma(close, 111)`)
  - **Adı:** `SMA (close, 111)`
  - **Renk:** `gray`
  - **Kullanım:** **ALIM/SATIM SİNYAL TETİKLEYİCİSİ**
- [ ] **SMA 350** (`sma(close, 350)`)
  - **Adı:** `SMA (close, 350)`
  - **Renk:** `#ffb200`
- [ ] **Ek Göstergeler** (Görselleştirme için)
  - SMA 13, EMA 21, SMA 50, SMA 200

### Çarpanlar (Multipliers - Görselleştirme/Referans)

Temel hat: **SMA 350**

- [ ] **x0.702**
- [ ] **x1.618** (Golden Ratio)
- [ ] **x2.0**
- [ ] **x3.0**
- [ ] **x5.0**
- [ ] **x8.0**
- [ ] **x13.0**
- [ ] **x21.0**

## 2. Sinyal Mantığı (GÜNCELLENDİ)

Kullanıcı isteği üzerine strateji sinyalleri **sadece SMA 111**'e göre üretilecektir.

### Alım (Buy) Kuralı

- **KOŞUL:** Mum kapanışı **SMA 111** seviyesinin **ÜZERİNDE** gerçekleştiğinde.
  - `Close > SMA 111`

### Satış (Sell) Kuralı

- **KOŞUL:** Mum kapanışı **SMA 111** seviyesinin **ALTINDA** gerçekleştiğinde.
  - `Close < SMA 111`

> **Not:** Zaman dilimi (Timeframe) kullanıcı tarafından dışarıdan seçilecektir. Strateji kendisine gelen mum verilerine göre hesaplama yapar.

## 3. Uygulama Adımları (Backend)

- [ ] **Sınıf:** `GoldenRatioMultiplierStrategy.cs` oluştur.
- [ ] **Hesaplamalar:**
  - `TechnicalIndicators.CalculateSma` metodu kullanılacak.
  - Tüm SMA ve Multiplier değerleri `StrategyResult` içine `ExtraData` veya `Indicators` olarak eklenecek (UI'da çizim için).
- [ ] **Logic Implementasyonu:**
  - Son mumun kapanış değeri ile son SMA 111 değerini karşılaştır.
  - Al veya Sat kararı ver.

## 4. Entegrasyon

- [ ] `Program.cs`'e stratejiyi ekle.
