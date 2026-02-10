# Kripteks Mobile - Iyilestirme ve Gelistirme Plani

## Mevcut Durum Ozeti

| Alan | Durum | Not |
|------|-------|-----|
| Mimari | Feature-based Clean Architecture | Saglam temel |
| State Management | Riverpod 3.x | Modern ve dogru tercih |
| Routing | GoRouter 17.x | Deklaratif, auth-redirect destekli |
| Network | Dio + SignalR | REST + Real-time |
| Auth | JWT + Biometric (FaceID/TouchID) | Guvenli |
| Lokalizasyon | TR/EN (flutter_localizations) | Eksik ceviriler var |
| Test Coverage | ~%2 (2 test dosyasi) | Kritik eksiklik |
| Ekran Sayisi | 25+ | 12 feature modul |
| Firebase | Crashlytics + Messaging | Hata takibi + Push |

---

## P0 - Kritik (Hemen Yapilmali)

> Bu maddeler uygulamanin guvenilirligi ve kullanici guveni icin kritik oneme sahiptir.
> Tahmini sure: 2-3 hafta

### 1. Error Handling Iyilestirme

**Sorun:** Bazi yerlerde `catch (_)` ile hatalar sessizce yutuluyor. Kullanici neyin yanlis gittigini anlamiyor. Farkli servislerde farkli hata yonetim yaklasimlari var.

**Yapilacaklar:**

- [x] Merkezi `AppException` hiyerarsisi olustur
  - `NetworkException` - Baglanti hatalari
  - `AuthException` - Kimlik dogrulama hatalari (401, 403)
  - `ValidationException` - Gecersiz veri hatalari
  - `ServerException` - Sunucu hatalari (500+)
  - `TimeoutException` - Zaman asimi hatalari
  - `UnknownException` - Bilinmeyen hatalar
  - `CancelledException` - Iptal edilen istekler
  - Lokasyon: `lib/core/error/exceptions.dart`

- [x] Dio Interceptor'da hata siniflandirmasi yap
  - HTTP status kodlarina gore exception tipi belirle
  - ASP.NET Core ProblemDetails/ValidationProblemDetails parse destegi
  - Debug modda LogInterceptor eklendi
  - Lokasyon: `lib/core/network/dio_client.dart`

- [x] Kullaniciya anlamli hata mesajlari goster
  - Her exception tipi icin kullanici dostu mesaj
  - Snackbar/Dialog ile tutarli gosterim (ikon, renk, sure exception tipine gore)
  - `ErrorHandler.handle()` servislerde, `ErrorHandler.showError()` UI'da
  - Lokasyon: `lib/core/error/error_handler.dart`

- [x] `catch (_)` kullanimlarini temizle
  - 11 servis dosyasinda `on DioException catch` ile degistirildi
  - 7 ekran dosyasinda `ErrorHandler.showError()` ile degistirildi
  - Crashlytics'e hata raporlamasi eklendi
  - Silent catch'ler debug log veya Crashlytics raporlamali hale getirildi

**Kabul Kriteri:** Hicbir hata sessizce yutulmuyor, kullanici her zaman anlamli bir geri bildirim aliyor.

---

### 2. Network Retry + Token Refresh Mekanizmasi

**Sorun:** Agbaglantisi koptiginda istek tekrarlanmiyor. 401 alindiginda direkt logout yapiliyor, refresh token denenmiyor. Sayfa degistiginde devam eden istekler iptal edilmiyor.

**Yapilacaklar:**

- [x] Retry interceptor ekle (Dio)
  - Network hatalari icin otomatik 3 deneme
  - Exponential backoff stratejisi (1s, 2s, 4s)
  - Sadece idempotent istekler icin (GET, PUT, DELETE, HEAD, OPTIONS) - POST haric
  - 408, 429, 500, 502, 503, 504 status kodlari icin retry
  - CancelToken kontrolu: delay sirasinda iptal edilmisse retry yapmaz
  - Lokasyon: `lib/core/network/interceptors/retry_interceptor.dart`

- [x] Token refresh mekanizmasi (client-side hazir, backend endpoint bekleniyor)
  - 401 alindiginda once refresh token dene
  - Refresh basariliysa istegi tekrarla
  - Refresh basarisizsa logout yap
  - QueuedInterceptor ile concurrent 401'lerde tek refresh istegi (queue pattern)
  - Auth endpoint'lerinde sonsuz dongu onleme
  - **NOT:** Backend'de `/auth/refresh-token` endpoint'i henuz yok. Client altyapisi hazir, backend eklendiginde otomatik calisacak.
  - Lokasyon: `lib/core/network/interceptors/auth_interceptor.dart`

- [x] Request cancellation
  - `cancelTokenProvider` (autoDispose) ile sayfa navigate edildiginde istekler otomatik iptal
  - `cancelTokenFamilyProvider` ile ayni sayfada farkli istekler icin key bazli CancelToken
  - 15 provider'a autoDispose + cancelToken eklendi (market_analysis, dashboard, wallet vb.)
  - Lokasyon: `lib/core/network/dio_client.dart`

- [x] SignalR reconnection iyilestirmesi
  - Exponential backoff + jitter: 1s, 2s, 4s, 8s, 16s, 32s, 60s (max) + random jitter
  - Maksimum 10 deneme sonrasi error statusune gecis
  - `manualReconnect()` metodu ile kullanici tetikli yeniden baglanti
  - `accessTokenFactory` her baglanmada guncel token okur
  - Hem `SignalRService` hem `MarketDataSignalRService` guncellendi
  - Lokasyon: `lib/core/network/signalr_service.dart`, `lib/core/network/market_data_signalr_service.dart`

**Kabul Kriteri:** Gecici ag kesintilerinde uygulama kendini toparliyor, token suresi dolunca kullanici otomatik yenileniyor.

---

## P1 - Yuksek Oncelik (1-2 Hafta Icinde)

> Uygulamanin olceklenebilirligi ve kullanici deneyimi icin onemli.
> Tahmini sure: 3-4 hafta

### 3. Pagination Eklenmesi

**Sorun:** Bot listesi, islem gecmisi, bildirimler gibi listelerde pagination yok. Veri buyudukce performans sorunu ve bellek tasmas riski olusur.

**Yapilacaklar:**

- [x] Generic paginated provider olustur ✅
  - `PaginatedAsyncNotifier<T>` base class
  - `loadMore()`, `refresh()`, `hasMore` destegi
  - Lokasyon: `lib/core/providers/paginated_provider.dart`

- [x] Infinite scroll widget olustur ✅
  - Liste sonuna yaklasinca otomatik yukleme
  - Loading indicator ve "daha fazla yok" durumu
  - Pull-to-refresh destegi
  - Lokasyon: `lib/core/widgets/paginated_list_view.dart`

- [x] Asagidaki ekranlara pagination ekle: ✅
  - [x] Bot Listesi (`features/bots/`)
  - [x] Islem Gecmisi / Wallet Transactions (`features/wallet/`)
  - [x] Bildirimler (`features/notifications/`)
  - [ ] Scanner Sonuclari (`features/scanner/`) — Scanner henüz backend'de pagination endpoint'i yok
  - [x] Bot Loglari (`features/bots/bot_detail_screen.dart`)

- [x] Backend API'lerinin pagination destegini dogrula ✅
  - `page`, `pageSize` parametreleri
  - Response'da `totalCount`, `hasMore` alanlari
  - `PagedResult<T>` generic DTO, `PaginationRequest` DTO olusturuldu
  - `IQueryable<T>.ToPagedResultAsync()` extension method eklendi
  - Frontend `PagedResult<T>` TypeScript interface'i ve tüm servis/bilesenler güncellendi

**Kabul Kriteri:** 1000+ kayit oldugunda bile liste akici calisiyor, bellek tuketimi sabit kaliyor.

---

### 4. Test Coverage Artirma

**Sorun:** Sadece 2 test dosyasi mevcut (~%2 coverage). Kripto trading uygulamasinda para islemleri, bot yonetimi gibi hassas alanlar test edilmeden production'a gikmak buyuk risk.

**Yapilacaklar:**

- [ ] Test altyapisini kur
  - Mock servisleri olustur (`MockDioClient`, `MockSecureStorage`)
  - Test helper'lari ve fixture'lar
  - Lokasyon: `test/helpers/`

- [ ] **Unit Testler - Servisler** (Oncelik: Yuksek)
  - [ ] `AuthService` testleri (login, logout, token yonetimi)
  - [ ] `BotService` testleri (CRUD, start/stop)
  - [ ] `WalletService` testleri (bakiye, islemler)
  - [ ] `ScannerService` testleri
  - [ ] `BacktestService` testleri

- [ ] **Unit Testler - Provider'lar** (Oncelik: Orta)
  - [ ] `AuthStateProvider` testleri
  - [ ] `BotListProvider` testleri
  - [ ] `NotificationsProvider` testleri
  - [ ] `WalletProvider` testleri

- [ ] **Widget Testler** (Oncelik: Orta)
  - [ ] Login/Signup akilari
  - [ ] Bot olusturma wizard'i
  - [ ] Dashboard ekrani
  - [ ] Wallet ekrani

- [ ] **Integration Testler** (Oncelik: Dusuk - sonraki faz)
  - [ ] Auth akisi (login -> dashboard -> logout)
  - [ ] Bot olusturma akisi (create -> start -> stop -> delete)

- [ ] CI/CD'ye test entegrasyonu
  - GitHub Actions'da her PR'da testleri calistir
  - Coverage raporu olustur
  - Minimum coverage esigi belirle (%60)

**Kabul Kriteri:** Kritik servisler ve provider'lar icin %70+ coverage, CI/CD'de otomatik test calistirma.

---

### 5. Offline Caching

**Sorun:** Network kesildiginde uygulama tamamen kullanilmaz hale geliyor. Kripto uygulamasinda kullanici en azindan son bilinen verileri gorebilmeli.

**Yapilacaklar:**

- [ ] Local veritabani entegrasyonu
  - `Hive` veya `Isar` paketini ekle
  - Her model icin cache adapter yaz
  - Lokasyon: `lib/core/cache/`

- [ ] Cache stratejisi belirle
  - **Cache-first:** Dashboard istatistikleri, bot listesi
  - **Network-first:** Canli fiyatlar, bildirimler
  - **Cache-only:** Kullanici ayarlari, favori listeler
  - TTL (Time-to-Live) politikasi: 5dk (fiyatlar), 1 saat (istatistik), 24 saat (ayarlar)

- [ ] Asagidaki veriler icin cache ekle:
  - [ ] Dashboard istatistikleri
  - [ ] Bot listesi ve detaylari
  - [ ] Wallet bakiye bilgisi
  - [ ] Kullanici profili ve ayarlari
  - [ ] Son bilinen market verileri

- [ ] Offline UI state
  - Offline durumda "Son guncelleme: X dk once" goster
  - Stale veriyi belirt (soluk renk veya badge)
  - Network geldiginde otomatik yenile

**Kabul Kriteri:** Ag kesildiginde kullanici son bilinen verileri gorebiliyor, ag geldiginde otomatik guncelleniyor.

---

## P2 - Orta Oncelik (3-4 Hafta Icinde)

> Mimari olgunluk ve gelistirici verimliligi icin onemli.
> Tahmini sure: 3-4 hafta

### 6. Repository Pattern Eklenmesi

**Sorun:** Servisler dogrudan API cagrisi yapiyor. Local cache ve remote veri kaynagi arasinda secim yapan bir soyutlama yok. Test edilebilirlik zayif.

**Yapilacaklar:**

- [ ] Repository interface'leri tanimla
  - `IBotRepository`, `IWalletRepository`, `IAuthRepository` vb.
  - Lokasyon: `lib/core/repositories/`

- [ ] Repository implementasyonlari
  - Remote data source (mevcut servisler)
  - Local data source (cache katmani)
  - Cache invalidation ve sync stratejisi
  - Lokasyon: `lib/features/*/repositories/`

- [ ] Provider'lari repository uzerinden calistir
  - Service yerine repository inject et
  - Cache-first veya network-first strateji uygula

**Kabul Kriteri:** Veri erisimi tek bir noktadan yonetiliyor, cache ve network seffaf sekilde calisyor.

---

### 7. Freezed + Code Generation Entegrasyonu

**Sorun:** Model siniflari manual `fromJson`, `toJson`, `==`, `hashCode` ile yazilmis. Hata riski yuksek, boilerplate kod fazla.

**Yapilacaklar:**

- [ ] `freezed`, `json_serializable`, `build_runner` paketlerini ekle

- [ ] Modelleri Freezed'e gecir (oncelik sirasina gore):
  - [ ] `Bot`, `BotLog` modelleri
  - [ ] `WalletDetails`, `WalletTransaction` modelleri
  - [ ] `BacktestResult`, `BacktestTrade` modelleri
  - [ ] `ScannerResult` modelleri
  - [ ] `DashboardStats` modeli
  - [ ] `NotificationModel` modeli

- [ ] Code generation pipeline'i kur
  - `build_runner` watch modu gelistirme sirasinda
  - CI/CD'de `build_runner build` adimi

**Faydalar:**
- Otomatik `copyWith`, `==`, `hashCode`
- Immutable modeller garanti
- Union types ile state yonetimi
- JSON serialization guvenli ve hatasiz

**Kabul Kriteri:** Tum modeller Freezed ile olusturuluyor, manual boilerplate yok.

---

### 8. Widget Extraction ve Kod Temizligi

**Sorun:** `dashboard_screen.dart` (445 satir) gibi dosyalar cok buyuk. Okunabilirligi ve bakim kolayligini azaltiyor.

**Yapilacaklar:**

- [ ] Buyuk ekranlari parca widgetlara bol:
  - [ ] `DashboardScreen` -> `DashboardHeader`, `DashboardStats`, `ActiveBotsCard`, `QuickActions`, `RecentActivity`
  - [ ] `BotDetailScreen` -> `BotInfoCard`, `BotLogList`, `BotControls`
  - [ ] `WalletScreen` -> `BalanceCard`, `PnlChart`, `TransactionList`
  - [ ] `MarketAnalysisScreen` -> `MarketOverview`, `TopMovers`, `VolumeChart`

- [ ] Ortak UI componentleri cikar:
  - [ ] `AppCard` - Standart kart componenti
  - [ ] `AppButton` - Primary, Secondary, Danger varyantlari
  - [ ] `AppLoadingState` - Tutarli yukleme gorunumu
  - [ ] `AppEmptyState` - Tutarli bos durum gorunumu
  - [ ] `AppErrorState` - Tutarli hata gorunumu
  - Lokasyon: `lib/core/widgets/`

- [ ] Dosya basina maksimum 200-250 satir kurali

**Kabul Kriteri:** Hicbir widget dosyasi 250 satirdan fazla degil, ortak componentler tekrar kullaniabiliyor.

---

### 9. Lokalizasyon Tamamlama

**Sorun:** Kodda hardcoded Turkce stringler var. Bazi ekranlarda lokalizasyon kullanilmamis.

**Yapilacaklar:**

- [ ] Tum hardcoded stringleri tespit et
  - Turkce karakter iceren tum dart dosyalarini tara
  - `AppLocalizations` kullanilmayan ekranlari listele

- [ ] Eksik cevirileri tamamla:
  - [ ] `app_en.arb` dosyasini guncelle
  - [ ] `app_tr.arb` dosyasini guncelle

- [ ] Tum ekranlari `AppLocalizations` uzerinden gecir:
  - [ ] Dashboard ekrani
  - [ ] Bot ekranlari
  - [ ] Wallet ekrani
  - [ ] Settings ekrani
  - [ ] Hata mesajlari
  - [ ] Snackbar/Toast mesajlari

- [ ] Lokalizasyon lint kurali ekle (hardcoded string uyarisi)

**Kabul Kriteri:** Uygulama tamamen EN ve TR destekli, hicbir hardcoded string yok.

---

## P3 - Dusuk Oncelik (Gelecek Sprint)

> Kullanici buyumesi ve rekabet avantaji icin degerli ozellikler.
> Tahmini sure: 4-6 hafta

### 10. Yeni Ozellikler

#### 10.1 Price Alerts (Fiyat Alarmlari)
- [ ] Belirli fiyata ulasinca push notification
- [ ] Alarm olusturma/duzenleme/silme ekrani
- [ ] Backend'de WebSocket ile fiyat izleme
- [ ] Gecmis alarm listesi

#### 10.2 Portfolio Tracker
- [ ] Toplam portfoy degeri gosterimi
- [ ] Coin bazli dagilim grafigi (pie chart)
- [ ] Gunluk/haftalik/aylik PnL grafigi
- [ ] Portfoy performans karsilastirmasi (BTC, ETH vs)

#### 10.3 Dark/Light Theme Toggle
- [ ] Light tema renk paleti olustur
- [ ] Theme provider ile dinamik tema degisimi
- [ ] Sistem temasina uyum secenegi
- [ ] Settings ekraninda tema secimi

#### 10.4 Onboarding Flow
- [ ] 3-4 adimlik tanitim ekranlari
- [ ] Animasyonlu gecisler
- [ ] Ilk kullanimda otomatik gosterim
- [ ] "Tekrar gosterme" secenegi

#### 10.5 Home Screen Widget (iOS/Android)
- [ ] Canli fiyat gosterimi
- [ ] Aktif bot durumu
- [ ] Portfoy ozeti
- [ ] iOS WidgetKit + Android App Widget

#### 10.6 Export/Share
- [ ] Raporlari PDF olarak disari aktar
- [ ] Islem gecmisini CSV olarak indir
- [ ] Sosyal medya paylasim butonu (PnL screenshot)

#### 10.7 Telegram/Discord Entegrasyonu
- [ ] `/durum` komutu ile bot durumu
- [ ] `/bakiye` komutu ile bakiye bilgisi
- [ ] Islem bildirimleri Telegram'a dusme
- [ ] Settings ekranindan Telegram bot token baglama

#### 10.8 Deep Linking ve Push Navigation
- [ ] Push notification'dan ilgili ekrana yonlendirme
  - Bildirim tipi: bot_update -> Bot detay ekrani
  - Bildirim tipi: trade -> Islem detay ekrani
  - Bildirim tipi: alert -> Alarm detay ekrani
- [ ] Universal Links (iOS) / App Links (Android)
- [ ] Dynamic Links ile paylasim

---

## Teknik Borc (Technical Debt)

Bu maddeler mevcut kodda tespit edilen ve zamanla cozulmesi gereken sorunlardir.

| # | Konu | Dosya/Alan | Aciklama |
|---|------|-----------|----------|
| 1 | ~~Silent error catch~~ | ~~Tum servisler~~ | ~~`catch (_)` kullanimlarini anlamli hata yonetimine cevir~~ ✅ Tamamlandi |
| 2 | StreamController leak riski | `signalr_service.dart`, `market_data_signalr_service.dart` | `autoDispose` modifier ekle, dispose kontrolu yap |
| 3 | Missing `autoDispose` | Cesitli provider'lar | Uzun omurlu provider'lara `autoDispose` ekle |
| 4 | Hardcoded stringler | Bircok ekran | Lokalizasyon sistemine tasi |
| 5 | Buyuk widget dosyalari | `dashboard_screen.dart` (445 satir) | Widget extraction ile parcala |
| 6 | Manual JSON serialization | Tum modeller | Freezed + json_serializable'a gecis |
| 7 | `path_provider_foundation` override | `pubspec.yaml` | Versiyon cakismasini kok nedeninden coz |
| 8 | Eksik input validation | Form ekranlari | Client-side validation guclendir |
| 9 | Tutarsiz loading states | Cesitli ekranlar | Standart loading/empty/error widget kullan |
| 10 | Eksik dispose | Bazi controller'lar | TextEditingController, ScrollController dispose kontrolu |

---

## Zaman Cizelgesi (Timeline)

```
Hafta 1-2:  [P0] Error Handling + Network Retry/Token Refresh
Hafta 3-4:  [P1] Pagination + Test Altyapisi
Hafta 5-6:  [P1] Test Coverage Artirma + Offline Caching
Hafta 7-8:  [P2] Repository Pattern + Freezed Entegrasyonu
Hafta 9-10: [P2] Widget Extraction + Lokalizasyon Tamamlama
Hafta 11+:  [P3] Yeni Ozellikler (Price Alerts, Portfolio, Theme...)
```

```
P0 ████████████████████░░  Hafta 1-2 (Error Handling ✅, Network Retry ✅)
P1 ░░░░░░░░████████████░░  Hafta 3-6 (Pagination ✅)
P2 ░░░░░░░░░░░░░░████████  Hafta 7-10
P3 ░░░░░░░░░░░░░░░░░░░░██  Hafta 11+
```

---

## Basari Metrikleri

| Metrik | Hedef | Olcum Yontemi |
|--------|-------|---------------|
| Test Coverage | %70+ | `flutter test --coverage` |
| Crash-free Rate | %99.5+ | Firebase Crashlytics |
| API Response Time (p95) | <500ms | Dio interceptor loglari |
| App Start Time | <2s | Flutter DevTools |
| Memory Usage | <150MB | Flutter DevTools |
| Frame Rate | 60fps | Flutter DevTools |
| Hata Mesaji Orani | %100 anlamli | Manuel review |
| Lokalizasyon Tamamlanma | %100 | ARB dosya karsilastirma |

---

## Notlar

- Bu plan canli bir dokumandır, sprint sonlarinda guncellenmeli.
- Her P0/P1 maddesi icin ayri bir branch acilmali ve PR ile merge edilmeli.
- Yeni ozellikler (P3) backend API desteği gerektiriyorsa, backend gelistirme ile paralel planlanmali.
- Her sprint sonunda code review ve retrospective yapilmali.
- `todo.md` dosyasindaki genel roadmap ile senkron tutulmali.
