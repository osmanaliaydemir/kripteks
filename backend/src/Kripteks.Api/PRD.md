# Kripteks - Product Requirements Document (PRD)

**Versiyon:** 1.0  
**Tarih:** 11 Şubat 2026  
**Hazırlayan:** Kripteks Geliştirme Ekibi  
**Durum:** Aktif Geliştirme  

---

## 1. Ürün Özeti

### 1.1 Vizyon
Kripteks, kripto para piyasasında otomatik alım-satım botları oluşturmayı, yönetmeyi ve analiz etmeyi sağlayan yapay zeka destekli bir trading platformudur. Platform, kullanıcılara teknik analiz stratejileri ile otomatik ticaret yapma, geçmiş verilere dayalı strateji testi (backtesting), piyasa tarama ve AI destekli duygu analizi gibi gelişmiş araçlar sunmaktadır.

### 1.2 Hedef Kitle
- **Bireysel Yatırımcılar:** Kripto para piyasasında algoritmik ticaret yapmak isteyen kullanıcılar
- **Trader'lar:** Stratejilerini otomatize ederek zaman kazanmak isteyen aktif trader'lar
- **Analiz Meraklıları:** Piyasa verilerini analiz etmek ve backtesting yapmak isteyen kişiler

### 1.3 Platform Hedefleri
- Kullanıcı dostu arayüz ile otomatik trading bot yönetimi
- 15+ teknik analiz stratejisi ile çeşitlendirilmiş ticaret
- Gerçek zamanlı piyasa verisi ve bildirim sistemi
- Yapay zeka destekli piyasa analizi ve duygu (sentiment) analizi
- Kapsamlı backtesting ve optimizasyon araçları
- Güvenli API anahtarı yönetimi ve rol tabanlı erişim kontrolü

---

## 2. Mimari Genel Bakış

### 2.1 Teknoloji Stack

| Katman | Teknoloji |
|--------|-----------|
| **Backend Framework** | .NET 9.0, ASP.NET Core Web API |
| **Frontend** | Next.js (React), TypeScript, Tailwind CSS |
| **Veritabanı** | Microsoft SQL Server (MSSQL) |
| **ORM** | Entity Framework Core 9.0 |
| **Gerçek Zamanlı İletişim** | SignalR |
| **Kimlik Doğrulama** | ASP.NET Identity + JWT Bearer Token |
| **Push Bildirimler** | Firebase Cloud Messaging (FCM) |
| **Borsa Entegrasyonu** | Binance API (REST + WebSocket) |
| **AI Servisleri** | OpenAI GPT-4o, Google Gemini 2.0, DeepSeek R1 |
| **Haber Servisi** | CryptoPanic API |
| **Şifreleme** | AES-256 |

### 2.2 Mimari Desen: Clean Architecture

```
Kripteks.Api (Sunum Katmanı)
    ↓
Kripteks.Infrastructure (Altyapı Katmanı)
    ↓
Kripteks.Core (Domain Katmanı)
```

**Uygulanan Prensipler:**
- Dependency Inversion (Bağımlılık Ters Çevirme)
- Separation of Concerns (Sorumluluk Ayrımı)
- Domain-Driven Design (DDD)
- Repository Pattern
- Strategy Pattern (Trading stratejileri)
- Factory Pattern (StrategyFactory)
- SOLID Prensipleri

---

## 3. Domain Modeli

### 3.1 Temel Varlıklar (Entities)

#### 3.1.1 AppUser (Kullanıcı)
| Alan | Tip | Açıklama |
|------|-----|----------|
| Id | string | Benzersiz kullanıcı kimliği (Identity) |
| Email | string | E-posta adresi |
| FirstName | string | Ad |
| LastName | string | Soyad |
| ResetCode | string? | Şifre sıfırlama kodu |
| ResetCodeExpiry | DateTime? | Sıfırlama kodu son kullanma tarihi |

**Roller:** Admin, Trader, User

#### 3.1.2 Bot (Trading Botu)
| Alan | Tip | Açıklama |
|------|-----|----------|
| Id | int | Benzersiz bot kimliği |
| Symbol | string | İşlem çifti (örn: BTCUSDT) |
| StrategyName | string | Kullanılan strateji adı |
| Amount | decimal | Yatırım miktarı (USDT) |
| Interval | string | Zaman dilimi (1m, 5m, 15m, 1h, 4h...) |
| StopLoss | decimal | Zarar durdur yüzdesi |
| TakeProfit | decimal | Kar al yüzdesi |
| Status | BotStatus | Bot durumu |
| EntryPrice | decimal? | Giriş fiyatı |
| CurrentPnl | decimal | Mevcut kar/zarar |
| CurrentPnlPercent | decimal | Mevcut kar/zarar yüzdesi |
| IsTrailingStop | bool | Trailing stop aktif mi |
| TrailingStopDistance | decimal? | Trailing stop mesafesi |
| MaxPriceReached | decimal? | Ulaşılan en yüksek fiyat |
| IsArchived | bool | Arşivlenmiş mi |
| StrategyParams | string? | Strateji parametreleri (JSON) |
| CurrentDcaStep | int | Mevcut DCA adımı |
| OrderType | OrderType | Emir tipi (Market/Limit) |

**Bot Durumları (BotStatus):**
- `Stopped` — Durdurulmuş
- `Running` — Çalışıyor (pozisyon açık)
- `Paused` — Duraklatılmış
- `Completed` — Tamamlandı (TP/SL tetiklendi)
- `WaitingForEntry` — Giriş sinyali bekleniyor

#### 3.1.3 Trade (İşlem)
| Alan | Tip | Açıklama |
|------|-----|----------|
| Id | int | Benzersiz işlem kimliği |
| BotId | int | İlişkili bot |
| Symbol | string | İşlem çifti |
| Type | TradeType | Alım/Satım |
| Price | decimal | İşlem fiyatı |
| Quantity | decimal | Miktar |
| Total | decimal | Toplam tutar |
| Timestamp | DateTime | İşlem zamanı |

#### 3.1.4 Wallet (Cüzdan)
| Alan | Tip | Açıklama |
|------|-----|----------|
| Id | int | Benzersiz cüzdan kimliği |
| Balance | decimal | Toplam bakiye |
| LockedBalance | decimal | Kilitli bakiye (aktif botlar) |
| AvailableBalance | decimal | Kullanılabilir bakiye |
| LastUpdated | DateTime | Son güncelleme |

#### 3.1.5 BacktestResult (Backtest Sonucu)
| Alan | Tip | Açıklama |
|------|-----|----------|
| Id | int | Benzersiz kimlik |
| UserId | string | Kullanıcı |
| Symbol | string | İşlem çifti |
| StrategyId | string | Strateji |
| TotalTrades | int | Toplam işlem sayısı |
| WinRate | decimal | Kazanma oranı |
| TotalPnl | decimal | Toplam kar/zarar |
| MaxDrawdown | decimal | Maksimum düşüş |
| SharpeRatio | decimal | Sharpe oranı |
| SortinoRatio | decimal | Sortino oranı |
| ProfitFactor | decimal | Kar faktörü |
| IsFavorite | bool | Favori mi |

#### 3.1.6 Diğer Varlıklar
- **WalletTransaction** — Cüzdan işlem geçmişi (Deposit, Withdraw, BotInvestment, BotReturn, Fee)
- **ExchangeCredential** — Şifreli borsa API anahtarları
- **SystemSetting** — Kullanıcı bazlı sistem ayarları (Telegram, bildirimler, risk yönetimi)
- **Notification** — Uygulama içi bildirimler (Info, Success, Warning, Error, Trade)
- **UserNotificationRead** — Kullanıcı başına okunma durumu
- **UserDevice** — FCM token ve cihaz bilgileri
- **UserFavoriteList** — Kullanıcı favori sembol listeleri
- **AuditLog** — Denetim kayıtları (IP, eylem, metadata)
- **Log** — Bot çalışma logları (Info, Warning, Error)
- **SentimentHistory** — Duygu analizi geçmişi
- **NewsItem** — Kripto haberler
- **AiAnalysisResult** — AI analiz sonuçları

---

## 4. Fonksiyonel Gereksinimler

### 4.1 Kimlik Doğrulama ve Yetkilendirme

#### FR-AUTH-001: Kullanıcı Kaydı
- **Endpoint:** `POST /api/auth/register`
- **Açıklama:** Yeni kullanıcı kaydı oluşturma
- **Rate Limit:** 5 istek / 30 saniye (IP bazlı)
- **Girdi:** Email, şifre, ad, soyad
- **Çıktı:** Başarı durumu

#### FR-AUTH-002: Kullanıcı Girişi
- **Endpoint:** `POST /api/auth/login`
- **Açıklama:** JWT token ile oturum açma
- **Rate Limit:** 5 istek / 30 saniye (IP bazlı)
- **Token Süresi:** 60 dakika (yapılandırılabilir)
- **Girdi:** Email, şifre
- **Çıktı:** JWT token, kullanıcı bilgileri

#### FR-AUTH-003: Şifre Sıfırlama Akışı
- `POST /api/auth/forgot-password` — Sıfırlama kodu gönderimi (e-posta)
- `POST /api/auth/verify-reset-code` — Kod doğrulama
- `POST /api/auth/reset-password` — Yeni şifre belirleme

#### FR-AUTH-004: Şifre Değiştirme
- **Endpoint:** `POST /api/auth/change-password`
- **Yetki:** Giriş yapmış kullanıcı

#### FR-AUTH-005: Rol Bazlı Erişim Kontrolü
| Rol | Yetkiler |
|-----|----------|
| **Admin** | Tüm işlemler, kullanıcı yönetimi, sistem ayarları, denetim kayıtları |
| **Trader** | Bot yönetimi, tarama, backtest, API anahtarı yönetimi |
| **User** | Okuma işlemleri, profil yönetimi |

---

### 4.2 Bot Yönetimi

#### FR-BOT-001: Bot Oluşturma ve Başlatma
- **Endpoint:** `POST /api/bots/start`
- **Yetki:** Admin, Trader
- **Girdi:** Symbol, strategyName, amount, interval, stopLoss, takeProfit, isTrailingStop, trailingStopDistance, strategyParams, orderType
- **İş Kuralları:**
  - Kullanılabilir bakiye kontrol edilir
  - Yatırım miktarı cüzdandan kilitlenir
  - Maksimum aktif bot sayısı kontrol edilir
  - Bot `WaitingForEntry` veya `Running` durumunda başlar (stratejiye göre)

#### FR-BOT-002: Bot Durdurma
- **Endpoint:** `POST /api/bots/{id}/stop`
- **Yetki:** Admin, Trader
- **İş Kuralları:**
  - Açık pozisyon varsa kapatılır
  - Kilitli bakiye serbest bırakılır
  - PnL hesaplanır ve cüzdana yansıtılır
  - Bildirim gönderilir

#### FR-BOT-003: Toplu Bot Durdurma
- **Endpoint:** `POST /api/bots/stop-all`
- **Yetki:** Admin, Trader

#### FR-BOT-004: Bot Listeleme
- **Endpoint:** `GET /api/bots`
- **Sayfalama:** PageNumber, PageSize
- **Filtreleme:** Aktif/Arşiv durumuna göre

#### FR-BOT-005: Bot Detayı ve Logları
- `GET /api/bots/{id}` — Bot detay bilgileri
- `GET /api/bots/{id}/logs` — Bot çalışma logları (sayfalı)

#### FR-BOT-006: Bot Geçmişi Arşivleme
- **Endpoint:** `POST /api/bots/clear-history`
- **Yetki:** Admin, Trader

---

### 4.3 Bot Motor Servisi (Background Service)

#### FR-ENGINE-001: Giriş Sinyali Algılama
- `WaitingForEntry` durumundaki botlar periyodik olarak kontrol edilir
- Seçili strateji giriş sinyali ürettiğinde pozisyon açılır
- Giriş fiyatı kaydedilir, bot `Running` durumuna geçer

#### FR-ENGINE-002: Çıkış Koşulları İzleme
Çalışan botlar için aşağıdaki çıkış koşulları sürekli izlenir:
- **Take Profit (TP):** Fiyat hedef kar yüzdesine ulaştığında
- **Stop Loss (SL):** Fiyat zarar durdur seviyesine düştüğünde
- **Trailing Stop:** Fiyat zirve noktasından belirli mesafe geri çekildiğinde
- **Strateji Sinyali:** Strateji çıkış sinyali ürettiğinde
- **Panik Modu:** AI duygu analizi kritik seviyeye düştüğünde

#### FR-ENGINE-003: DCA (Dollar Cost Averaging) Desteği
- Fiyat belirli sapma oranlarında düştüğünde ek alım yapılır
- DCA adımları ve ölçek faktörü yapılandırılabilir
- Ortalama maliyet fiyatı güncellenir

#### FR-ENGINE-004: Grid Trading Desteği
- Belirli fiyat aralığında grid emirleri oluşturulur
- Alt/üst fiyat ve grid sayısı yapılandırılabilir
- Her grid seviyesinde alım-satım yapılır

#### FR-ENGINE-005: PnL Takibi
- Her bot için gerçek zamanlı PnL hesaplaması
- Yüzde ve mutlak değer olarak takip
- SignalR ile frontend'e anlık güncelleme

---

### 4.4 Trading Stratejileri

Platform 15 yerleşik strateji sunmaktadır:

| # | Strateji | Kategori | Açıklama |
|---|----------|----------|----------|
| 1 | **SMA111 Strategy** | Trend Takip | Basit Hareketli Ortalama kesişimi |
| 2 | **Golden Cross Strategy** | Trend Takip | EMA altın kesişimi (50/200) |
| 3 | **Golden Rose Strategy** | Fibonacci | Fibonacci tabanlı giriş/çıkış |
| 4 | **Alpha Trend Strategy** | Karma | EMA + RSI kombinasyonu |
| 5 | **Breakout Hunter Strategy** | Kırılım | Fiyat kırılım tespiti |
| 6 | **Divergence Detector Strategy** | Uyumsuzluk | RSI uyumsuzluk tespiti |
| 7 | **Trend Surfer Strategy** | Trend Takip | Trend yönünde işlem |
| 8 | **Phoenix Momentum Strategy** | Momentum | Momentum toparlanma stratejisi |
| 9 | **Oversold Recovery Strategy** | Mean Reversion | Aşırı satım sıçraması |
| 10 | **Whale Accumulation Strategy** | Hacim | Büyük yatırımcı birikimi tespiti |
| 11 | **Scout Breakout Strategy** | Kırılım | Erken kırılım tespiti |
| 12 | **DCA Strategy** | Risk Yönetimi | Dollar Cost Averaging |
| 13 | **Grid Strategy** | Grid Trading | Fiyat ızgara ticareti |
| 14 | **Market Buy Strategy** | Anlık | Direkt piyasa emri |
| 15 | **Simulation Strategy** | Test | Demo/test amaçlı |

**Teknik İndikatörler:**
- SMA (Simple Moving Average)
- EMA (Exponential Moving Average)
- RSI (Relative Strength Index)
- MACD (Moving Average Convergence Divergence)
- Bollinger Bands
- Stochastic RSI
- ADX (Average Directional Index)
- ATR (Average True Range)
- OBV (On Balance Volume)
- Destek/Direnç Seviyeleri
- Uyumsuzluk (Divergence) Tespiti

---

### 4.5 Backtesting ve Optimizasyon

#### FR-BT-001: Tekli Backtest
- **Endpoint:** `POST /api/backtest/run`
- **Girdi:** Symbol, strategyId, interval, startDate, endDate, initialBalance, commissionRate, slippageRate, strategyParameters
- **Çıktı:** Detaylı performans metrikleri ve işlem listesi

#### FR-BT-002: Toplu Backtest Tarama
- **Endpoint:** `POST /api/backtest/scan`
- **Açıklama:** Birden fazla sembol üzerinde aynı anda backtest çalıştırma
- **Çıktı:** Sembol bazlı karşılaştırmalı sonuçlar

#### FR-BT-003: Parametre Optimizasyonu
- **Endpoint:** `POST /api/backtest/optimize`
- **Endpoint (SignalR):** `POST /api/backtest/optimize-with-progress/{sessionId}`
- **Açıklama:** Strateji parametrelerinin otomatik optimizasyonu
- **SignalR İlerleme:** `BacktestHub` üzerinden gerçek zamanlı ilerleme bildirimi

#### FR-BT-004: Monte Carlo Simülasyonu
- **Endpoint:** `POST /api/backtest/monte-carlo`
- **Açıklama:** İşlem sırasını rastgele karıştırarak risk analizi

#### FR-BT-005: Backtest Geçmişi Yönetimi
- `POST /api/backtest/save` — Sonuç kaydetme
- `GET /api/backtest/history` — Geçmiş listeleme (sayfalı)
- `GET /api/backtest/{id}` — Detay görüntüleme
- `POST /api/backtest/{id}/favorite` — Favori toggle
- `DELETE /api/backtest/{id}` — Silme

**Performans Metrikleri:**
- Toplam İşlem Sayısı
- Kazanan/Kaybeden İşlem Sayısı
- Kazanma Oranı (Win Rate)
- Toplam PnL ve PnL Yüzdesi
- Maksimum Düşüş (Max Drawdown)
- Sharpe Oranı
- Sortino Oranı
- Kar Faktörü (Profit Factor)
- Ortalama Kazanç / Ortalama Kayıp
- Maksimum Ardışık Kazanç/Kayıp
- Toplam Komisyon

---

### 4.6 Piyasa Tarayıcı (Scanner)

#### FR-SCAN-001: Piyasa Tarama
- **Endpoint:** `POST /api/scanner/scan`
- **Girdi:** Sembol listesi, strateji, zaman dilimi, minimum skor filtresi
- **Çıktı:** Sembol bazlı sinyal skorları, önerilen eylemler, analiz yorumları

#### FR-SCAN-002: Favori Listeler
- `GET /api/scanner/favorites` — Favori listeleri getir
- `POST /api/scanner/favorites` — Yeni liste kaydet
- `DELETE /api/scanner/favorites/{id}` — Liste sil

---

### 4.7 Piyasa Analizi

#### FR-MARKET-001: Piyasa Genel Bakışı
- **Endpoint:** `GET /api/market-analysis/overview`
- **Çıktı:** Genel piyasa durumu, toplam hacim, dominans

#### FR-MARKET-002: En Çok Kazanan/Kaybedenler
- `GET /api/market-analysis/top-gainers` — En çok yükselenler
- `GET /api/market-analysis/top-losers` — En çok düşenler

#### FR-MARKET-003: Hacim Analizi
- **Endpoint:** `GET /api/market-analysis/volume-history`
- **Parametre:** hours (saat bazlı geçmiş)

#### FR-MARKET-004: Piyasa Metrikleri
- **Endpoint:** `GET /api/market-analysis/metrics`

---

### 4.8 Yapay Zeka Entegrasyonu

#### FR-AI-001: Multi-Provider AI Konsensüs Sistemi
Platform, üç farklı AI sağlayıcısından alınan analizlerin ağırlıklı ortalaması ile karar üretir:
- **DeepSeek R1** — Derin reasoning modeli
- **Google Gemini 2.0** — Çoklu modal analiz
- **OpenAI GPT-4o** — Genel amaçlı analiz

#### FR-AI-002: Duygu (Sentiment) Analizi
- **Endpoint:** `GET /api/analytics/sentiment`
- **Geçmiş:** `GET /api/analytics/sentiment-history`
- **Arka Plan İşi:** Her 5 dakikada otomatik duygu analizi (SentimentAnalysisJob)
- **Veri Kaynağı:** CryptoPanic haberleri + AI analizi
- **Panik Modu:** Duygu skoru kritik seviyeye düştüğünde çalışan botlara otomatik çıkış sinyali

#### FR-AI-003: AI Sohbet
- **Endpoint:** `POST /api/ai-chat/ask`
- **Açıklama:** Kullanıcı sorularına AI destekli yanıt
- **Endpoint:** `GET /api/ai-chat/summary`
- **Açıklama:** Hızlı piyasa özeti

#### FR-AI-004: Haber Entegrasyonu
- **Endpoint:** `GET /api/analytics/news`
- **Kaynak:** CryptoPanic API
- **Parametre:** Symbol bazlı filtreleme

---

### 4.9 Balina Takibi (Whale Tracker)

#### FR-WHALE-001: Büyük İşlem Takibi
- **Endpoint:** `GET /api/whale-tracker`
- **Parametreler:** minUsdValue (minimum USD değeri), count (sonuç sayısı)
- **Açıklama:** Binance üzerindeki büyük hacimli işlemleri tespit eder

---

### 4.10 Arbitraj Tarayıcı

#### FR-ARB-001: Arbitraj Fırsatları
- **Endpoint:** `GET /api/arbitrage/opportunities`
- **Açıklama:** Farklı çiftler arasındaki fiyat farklılıklarını tespit eder

---

### 4.11 Analitik ve Raporlama

#### FR-ANALYTICS-001: Dashboard İstatistikleri
- **Endpoint:** `GET /api/analytics/stats`
- **Çıktı:** Aktif bot sayısı, toplam bakiye, işlem hacmi

#### FR-ANALYTICS-002: Equity Eğrisi
- **Endpoint:** `GET /api/analytics/equity`
- **Çıktı:** Kümülatif PnL grafiği verisi

#### FR-ANALYTICS-003: Strateji Performansı
- **Endpoint:** `GET /api/analytics/performance`
- **Çıktı:** Strateji bazlı karşılaştırmalı performans

#### FR-ANALYTICS-004: Özet İstatistikler
- **Endpoint:** `GET /api/summary-stats`

---

### 4.12 Cüzdan Yönetimi

#### FR-WALLET-001: Bakiye Görüntüleme
- **Endpoint:** `GET /api/wallet`
- **Çıktı:** Toplam bakiye, kullanılabilir bakiye, kilitli bakiye, toplam PnL

#### FR-WALLET-002: İşlem Geçmişi
- **Endpoint:** `GET /api/wallet/transactions`
- **Sayfalama:** Desteklenir
- **İşlem Tipleri:** Deposit, Withdraw, BotInvestment, BotReturn, Fee

---

### 4.13 Bildirim Sistemi

#### FR-NOTIF-001: Çok Kanallı Bildirim
Platform üç bildirim kanalı destekler:
- **Uygulama İçi (In-App):** SignalR ile gerçek zamanlı + veritabanında kalıcı depolama
- **Push Bildirimi:** Firebase Cloud Messaging (FCM)
- **E-posta:** Gmail SMTP (bakiye yetersizliği gibi kritik durumlar)

#### FR-NOTIF-002: Bildirim Tercihleri
Kullanıcılar aşağıdaki bildirim tiplerini ayrı ayrı açıp kapatabilir:
- Alım sinyalleri
- Satım sinyalleri
- Stop Loss uyarıları
- Take Profit bildirimleri
- Genel bildirimler
- Hata bildirimleri
- Push bildirimler

#### FR-NOTIF-003: Bildirim Yönetimi
- `GET /api/notifications` — Bildirimleri listele (sayfalı)
- `PUT /api/notifications/{id}/read` — Okundu işaretle
- `PUT /api/notifications/read-all` — Tümünü okundu işaretle

---

### 4.14 Ayarlar ve Yapılandırma

#### FR-SET-001: API Anahtarı Yönetimi
- `GET /api/settings/keys` — Maskelenmiş anahtarları getir
- `POST /api/settings/keys` — Anahtarları kaydet (AES-256 şifreleme)
- **Yetki:** Admin, Trader

#### FR-SET-002: Genel Sistem Ayarları
- `GET /api/settings/general` — Ayarları getir
- `POST /api/settings/general` — Ayarları güncelle
- **Yetki:** Sadece Admin
- **Ayarlar:** Telegram entegrasyonu, global stop loss, maks bot sayısı, varsayılan zaman dilimi, varsayılan miktar

#### FR-SET-003: Bildirim Ayarları
- `GET /api/settings/notifications` — Bildirim tercihlerini getir
- `PUT /api/settings/notifications` — Bildirim tercihlerini güncelle

#### FR-SET-004: FCM Token Yönetimi
- `POST /api/settings/fcm-token` — FCM token güncelle

#### FR-SET-005: Denetim Kayıtları
- `GET /api/settings/audit-logs` — Sistem denetim kayıtları
- **Yetki:** Sadece Admin

---

### 4.15 Kullanıcı Yönetimi (Admin)

#### FR-USER-001: Kullanıcı İşlemleri
- `GET /api/users` — Tüm kullanıcıları listele (Admin)
- `POST /api/users` — Yeni kullanıcı oluştur (Admin)
- `DELETE /api/users/{id}` — Kullanıcı sil (Admin)

---

### 4.16 Profil Yönetimi

#### FR-PROFILE-001: Profil İşlemleri
- `GET /api/profile` — Profil bilgilerini getir
- `PUT /api/profile` — Profil güncelle
- `POST /api/profile/change-password` — Şifre değiştir

---

## 5. Gerçek Zamanlı İletişim (SignalR)

### 5.1 Hub'lar

| Hub | Yol | Yetki | Açıklama |
|-----|-----|-------|----------|
| **BotHub** | `/bot-hub` | Authorize | Bot güncellemeleri, loglar, bildirimler |
| **BacktestHub** | `/backtest-hub` | Anonim | Optimizasyon ilerleme bildirimi |
| **MarketDataHub** | `/market-hub` | Anonim | Gerçek zamanlı piyasa verileri |

### 5.2 BotHub İstemci Metotları
| Metot | Açıklama |
|-------|----------|
| `ReceiveMessage` | Genel mesaj |
| `ReceiveNotification` | Bildirim |
| `ReceiveBotUpdate` | Bot durum güncellemesi |
| `ReceiveLog` | Yeni log kaydı |
| `ReceiveWalletUpdate` | Cüzdan bakiye güncellemesi |

### 5.3 BacktestHub İstemci Metotları
| Metot | Açıklama |
|-------|----------|
| `ReceiveProgress` | Optimizasyon ilerleme yüzdesi |
| `ReceiveOptimizationComplete` | Optimizasyon tamamlandı |

### 5.4 Bağlantı Yönetimi
- JWT token, SignalR bağlantısında `access_token` query parametresi üzerinden iletilir
- Bağlantı kopması durumunda frontend'de 10 saniyelik polling fallback mekanizması mevcuttur

---

## 6. Fonksiyonel Olmayan Gereksinimler

### 6.1 Güvenlik

| Gereksinim | Uygulama |
|------------|----------|
| **NFR-SEC-001:** Kimlik doğrulama | JWT Bearer Token (60 dk süre) |
| **NFR-SEC-002:** Yetkilendirme | Rol bazlı erişim kontrolü (Admin/Trader/User) |
| **NFR-SEC-003:** API anahtarı güvenliği | AES-256 şifreleme ile saklama |
| **NFR-SEC-004:** Rate limiting | Auth: 5 req/30s, API: 100 req/dk (IP bazlı) |
| **NFR-SEC-005:** Girdi doğrulama | HTML sanitization (InputSanitizer) |
| **NFR-SEC-006:** HTTPS | Production ortamında zorunlu |
| **NFR-SEC-007:** Denetim izleme | AuditLog ile tüm kritik işlemler kaydedilir |
| **NFR-SEC-008:** Şifre politikası | ASP.NET Identity varsayılan kuralları |

### 6.2 Performans

| Gereksinim | Uygulama |
|------------|----------|
| **NFR-PERF-001:** Gerçek zamanlı veri | Binance WebSocket + SignalR |
| **NFR-PERF-002:** Arka plan işleme | IHostedService (BotEngineService, BinanceWebSocketService) |
| **NFR-PERF-003:** Sayfalama | Tüm liste endpointlerinde PagedResult<T> |
| **NFR-PERF-004:** Singleton servisler | MarketData, Encryption, Logging singleton olarak kayıtlı |

### 6.3 Güvenilirlik

| Gereksinim | Uygulama |
|------------|----------|
| **NFR-REL-001:** Hata yönetimi | GlobalExceptionHandlerMiddleware |
| **NFR-REL-002:** Logging | Merkezi log servisi + bot bazlı log kaydı |
| **NFR-REL-003:** Graceful degradation | AI servisi devre dışıyken sistem çalışmaya devam eder |

### 6.4 Ölçeklenebilirlik

| Gereksinim | Uygulama |
|------------|----------|
| **NFR-SCALE-001:** Strateji genişletilebilirliği | IStrategy arayüzü ile plug-in strateji desteği |
| **NFR-SCALE-002:** AI sağlayıcı genişletilebilirliği | IAiProvider arayüzü ile yeni AI modelleri eklenebilir |
| **NFR-SCALE-003:** Veritabanı | EF Core migrations ile şema yönetimi |

---

## 7. API Endpoint Özet Tablosu

### 7.1 Kimlik Doğrulama (`/api/auth`)
| Metot | Yol | Yetki | Açıklama |
|-------|-----|-------|----------|
| POST | /register | Anonim | Kayıt ol |
| POST | /login | Anonim | Giriş yap |
| POST | /change-password | Authorize | Şifre değiştir |
| POST | /forgot-password | Anonim | Şifre sıfırlama kodu iste |
| POST | /verify-reset-code | Anonim | Sıfırlama kodunu doğrula |
| POST | /reset-password | Anonim | Şifre sıfırla |

### 7.2 Bot Yönetimi (`/api/bots`)
| Metot | Yol | Yetki | Açıklama |
|-------|-----|-------|----------|
| GET | / | Authorize | Bot listesi |
| GET | /{id} | Authorize | Bot detayı |
| GET | /{id}/logs | Authorize | Bot logları |
| POST | /start | Admin,Trader | Bot başlat |
| POST | /{id}/stop | Admin,Trader | Bot durdur |
| POST | /stop-all | Admin,Trader | Tüm botları durdur |
| POST | /{id}/clear-logs | Admin,Trader | Logları temizle |
| POST | /clear-history | Admin,Trader | Geçmişi arşivle |

### 7.3 Backtesting (`/api/backtest`)
| Metot | Yol | Yetki | Açıklama |
|-------|-----|-------|----------|
| POST | /run | Authorize | Backtest çalıştır |
| POST | /scan | Authorize | Toplu backtest |
| POST | /optimize | Authorize | Parametre optimizasyonu |
| POST | /optimize-with-progress/{sessionId} | Authorize | İlerlemeli optimizasyon |
| POST | /save | Authorize | Sonuç kaydet |
| GET | /history | Authorize | Geçmiş listele |
| GET | /{id} | Authorize | Detay |
| POST | /{id}/favorite | Authorize | Favori toggle |
| DELETE | /{id} | Authorize | Sil |
| POST | /monte-carlo | Authorize | Monte Carlo simülasyonu |

### 7.4 Cüzdan (`/api/wallet`)
| Metot | Yol | Yetki | Açıklama |
|-------|-----|-------|----------|
| GET | / | Authorize | Bakiye bilgisi |
| GET | /transactions | Authorize | İşlem geçmişi |

### 7.5 Bildirimler (`/api/notifications`)
| Metot | Yol | Yetki | Açıklama |
|-------|-----|-------|----------|
| GET | / | Authorize | Bildirim listesi |
| PUT | /{id}/read | Authorize | Okundu işaretle |
| PUT | /read-all | Authorize | Tümünü okundu |
| POST | /test | Authorize | Test bildirimi (broadcast) |
| POST | /test-personal | Authorize | Kişisel test bildirimi |
| POST | /test-push | Authorize | FCM test |
| GET | /firebase-diagnostics | Anonim | Firebase tanılama |

### 7.6 Ayarlar (`/api/settings`)
| Metot | Yol | Yetki | Açıklama |
|-------|-----|-------|----------|
| GET | /keys | Admin,Trader | API anahtarlarını getir |
| POST | /keys | Admin,Trader | API anahtarlarını kaydet |
| GET | /general | Admin | Genel ayarları getir |
| POST | /general | Admin | Genel ayarları kaydet |
| GET | /notifications | Admin,Trader | Bildirim ayarları |
| PUT | /notifications | Admin,Trader | Bildirim ayarlarını güncelle |
| POST | /fcm-token | Admin,Trader | FCM token güncelle |
| GET | /audit-logs | Admin | Denetim kayıtları |

### 7.7 Profil (`/api/profile`)
| Metot | Yol | Yetki | Açıklama |
|-------|-----|-------|----------|
| GET | / | Authorize | Profil getir |
| PUT | / | Authorize | Profil güncelle |
| POST | /change-password | Authorize | Şifre değiştir |

### 7.8 Kullanıcılar (`/api/users`)
| Metot | Yol | Yetki | Açıklama |
|-------|-----|-------|----------|
| GET | / | Admin | Kullanıcı listesi |
| POST | / | Admin | Kullanıcı oluştur |
| DELETE | /{id} | Admin | Kullanıcı sil |

### 7.9 Analitik (`/api/analytics`)
| Metot | Yol | Yetki | Açıklama |
|-------|-----|-------|----------|
| GET | /test-ai | Authorize | AI test |
| GET | /stats | Authorize | Dashboard istatistikleri |
| GET | /equity | Authorize | Equity eğrisi |
| GET | /performance | Authorize | Strateji performansı |
| GET | /news | Authorize | Haberler |
| GET | /sentiment | Authorize | Duygu analizi |
| GET | /sentiment-history | Authorize | Duygu geçmişi |

### 7.10 Piyasa Analizi (`/api/market-analysis`)
| Metot | Yol | Yetki | Açıklama |
|-------|-----|-------|----------|
| GET | /overview | Authorize | Piyasa genel bakışı |
| GET | /top-gainers | Authorize | En çok kazananlar |
| GET | /top-losers | Authorize | En çok kaybedenler |
| GET | /volume-history | Authorize | Hacim geçmişi |
| GET | /metrics | Authorize | Piyasa metrikleri |

### 7.11 Tarayıcı (`/api/scanner`)
| Metot | Yol | Yetki | Açıklama |
|-------|-----|-------|----------|
| GET | /favorites | Authorize | Favori listeleri |
| POST | /favorites | Authorize | Liste kaydet |
| DELETE | /favorites/{id} | Authorize | Liste sil |
| POST | /scan | Authorize | Tarama çalıştır |

### 7.12 Diğer Endpointler
| Metot | Yol | Yetki | Açıklama |
|-------|-----|-------|----------|
| GET | /api/strategies | Anonim | Stratejileri listele |
| GET | /api/strategies/{id} | Anonim | Strateji detayı |
| GET | /api/stocks | Anonim | İşlem çiftleri |
| GET | /api/summary-stats | Anonim | Özet istatistikler |
| GET | /api/whale-tracker | Authorize | Balina işlemleri |
| GET | /api/arbitrage/opportunities | Authorize | Arbitraj fırsatları |
| POST | /api/ai-chat/ask | Authorize | AI sohbet |
| GET | /api/ai-chat/summary | Authorize | Piyasa özeti |

---

## 8. Veritabanı Şeması

### 8.1 Tablo Listesi
| Tablo | Açıklama |
|-------|----------|
| AspNetUsers | Kullanıcılar (Identity) |
| AspNetRoles | Roller (Identity) |
| AspNetUserRoles | Kullanıcı-Rol ilişkisi |
| Bots | Trading botları |
| Trades | Bot işlemleri |
| Wallets | Kullanıcı cüzdanları |
| WalletTransactions | Cüzdan işlem geçmişi |
| Logs | Bot logları |
| ExchangeCredentials | Şifreli API anahtarları |
| SystemSettings | Sistem ayarları |
| Notifications | Bildirimler |
| UserNotificationReads | Okunma durumları |
| UserDevices | Cihaz FCM tokenları |
| AuditLogs | Denetim kayıtları |
| SentimentHistories | Duygu analizi geçmişi |
| BacktestResults | Backtest sonuçları |
| UserFavoriteLists | Favori sembol listeleri |

### 8.2 Önemli İlişkiler
- **Trade → Bot:** Bire çok (bir bot birden fazla trade üretebilir)
- **UserNotificationRead:** Bileşik anahtar (UserId + NotificationId)
- **UserDevice.FcmToken:** Benzersiz indeks

### 8.3 Veri Tipi Hassasiyetleri
- Miktar alanları: `decimal(18,8)` — Kripto hassasiyeti
- Yüzde alanları: `decimal(18,4)`
- Enum alanları: String olarak saklanır

---

## 9. Dış Sistem Entegrasyonları

### 9.1 Binance API
| Bağlantı Tipi | Kullanım Alanı |
|----------------|----------------|
| REST API | Mum verileri, emir yönetimi, piyasa bilgileri |
| WebSocket | Gerçek zamanlı fiyat akışı |

### 9.2 Firebase
| Servis | Kullanım |
|--------|----------|
| Cloud Messaging (FCM) | Push bildirimleri |
| Admin SDK | Sunucu taraflı bildirim gönderimi |

### 9.3 AI Sağlayıcıları
| Sağlayıcı | Model | Kullanım |
|-----------|-------|----------|
| OpenAI | GPT-4o | Piyasa analizi, sohbet |
| Google | Gemini 2.0 | Duygu analizi, çoklu modal |
| DeepSeek | R1 | Derin reasoning analizi |

### 9.4 CryptoPanic
| Servis | Kullanım |
|--------|----------|
| News API | Kripto haber akışı ve duygu analizi kaynağı |

### 9.5 Gmail SMTP
| Servis | Kullanım |
|--------|----------|
| E-posta | Şifre sıfırlama, hoş geldin mesajı, bakiye uyarıları |

---

## 10. Deployment ve Yapılandırma

### 10.1 Ortam Yapılandırması
| Anahtar | Açıklama |
|---------|----------|
| `ConnectionStrings:DefaultConnection` | SQL Server bağlantı dizesi |
| `JwtSettings:Secret` | JWT imza anahtarı (min 32 karakter) |
| `JwtSettings:Issuer` | Token yayıncısı (KripteksApi) |
| `JwtSettings:Audience` | Token hedef kitlesi (KripteksClient) |
| `JwtSettings:ExpiryMinutes` | Token süresi (varsayılan: 60) |
| `AiSettings:Enabled` | AI servislerini etkinleştir |
| `AiSettings:DeepSeekApiKey` | DeepSeek API anahtarı |
| `AiSettings:GeminiApiKey` | Gemini API anahtarı |
| `AiSettings:OpenAiApiKey` | OpenAI API anahtarı |
| `NewsSettings:CryptoPanicApiKey` | CryptoPanic API anahtarı |
| `Firebase:ServiceAccountPath` | Firebase servis hesabı dosya yolu |
| `MailSettings:Email` | SMTP e-posta adresi |
| `MailSettings:Password` | SMTP şifresi |

### 10.2 CORS Yapılandırması
| Ortam | İzin Verilen Originler |
|-------|------------------------|
| Production | `https://web-kripteks.runasp.net` |
| Development | `http://localhost:3000`, `http://localhost:5173` |

### 10.3 Seed Data (İlk Kurulum)
Uygulama başlangıcında otomatik olarak oluşturulur:
- **Roller:** Admin, User, Trader
- **Admin Kullanıcı:** admin@kripteks.com
- **Varsayılan Cüzdan:** 1000 USDT başlangıç bakiyesi

---

## 11. Gelecek Geliştirme Planı (Öneriler)

### 11.1 Kısa Vadeli
- [ ] Gerçek borsa emir entegrasyonu (şu an simülasyon)
- [ ] Deposit/Withdraw akışlarının tamamlanması
- [ ] Çoklu borsa desteği (Binance dışı)
- [ ] Kullanıcı başına cüzdan izolasyonu

### 11.2 Orta Vadeli
- [ ] Mobil uygulama (Flutter/React Native)
- [ ] Sosyal trading (strateji paylaşımı)
- [ ] Gelişmiş risk yönetimi paneli
- [ ] Portföy dengeleme (rebalancing)
- [ ] Webhook desteği (TradingView entegrasyonu)

### 11.3 Uzun Vadeli
- [ ] Kendi AI modellerinin eğitimi
- [ ] Copy trading mekanizması
- [ ] Paper trading modu
- [ ] Multi-exchange arbitraj
- [ ] API marketplace (üçüncü parti stratejiler)

---

## 12. Versiyon Geçmişi

| Versiyon | Tarih | Değişiklikler |
|----------|-------|---------------|
| 1.0 | 11 Şubat 2026 | İlk PRD dokümanı oluşturuldu |

---

> **Not:** Bu doküman, Kripteks platformunun mevcut durumunu yansıtmaktadır. Geliştirme sürecinde güncel tutulmalıdır.
