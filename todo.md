# 🚀 Kripteks - Proje Geliştirme ve İş Planı (Roadmap)

## 📜 Faz 1: Altyapı İyileştirmeleri (Foundation)

Mevcut yapıyı daha sağlam, hızlı ve genişletilebilir hale getirmek.

- [x] **Dinamik Strateji Yükleme (Plugin Yapısı)**
  - `BotEngineService` içindeki `switch-case` yapısını **Strategy Factory** pattern'ine çevirmek.
  - Kod değiştirmeden, dinamik olarak yeni strateji yüklenebilmesini sağlamak.
- [x] **Gelişmiş Emir Tipleri**
  - **Limit Emir**: Market emirleri yerine komisyon avantajı için limit emir desteği.
  - **OCO (One-Cancels-the-Other)**: Kar al ve zarar durdur emirlerinin aynı anda girilmesi.
- [x] **WebSocket ile Gerçek Zamanlı Tetikleme**
  - 30 saniyelik döngü (polling) yerine, Binance WebSocket verisiyle anlık fiyat değişimi reaksiyonu.

## 🌐 Faz 2: Borsalar ve Bot Çeşitliliği (Expansion)

Platformu sadece bir "indikatör botu" olmaktan çıkarıp kapsamlı bir terminale dönüştürmek.

- [ ] **Multi-Exchange (Çoklu Borsa) Desteği**
  - Binance haricinde **Bybit, OKX, Gate.io, KuCoin** entegrasyonları.
  - Borsalar arası arbitraj fırsatlarını izleme modülü.
- [ ] **Matematiksel Bot Modelleri**
- [x] **Grid Trading Bot** (Matematiksel alım-satım)
  - [x] Grid parametrelerinin (Lower, Upper, GridCount) alınması
  - [x] Sürekli işlem döngüsünün (Continuous Loop) bot engine'e entegresi
  - [x] **DCA (Dollar Cost Averaging) Bot**: Terste kalan işlemleri maliyet düşürerek kurtaran modül.

## 🧠 Faz 3: Yapay Zeka ve Veri Analitiği (AI & Analytics)

Rakiplerden ayrışmak için "Akıllı" özellikler eklemek.

- [ ] **Sentiment Analizi (Haber Botu)**
  - Twitter (X) ve CryptoPanic API entegrasyonu.
  - Kötü haber akışında botların otomatik **Panic Sell** moduna geçmesi.
- [ ] **AI Destekli Fiyat Tahmini**
  - Son 30 günlük veriyi işleyen LSTM/Machine Learning modeli.
  - Stratejilere "AI Onayı" filtresi eklenmesi.

## 📱 Faz 4: Kullanıcı Deneyimi ve Erişim (Client Side)

Kullanıcının sisteme her an ulaşabilmesi.

- [ ] **Mobil Uygulama (React Native)**
  - Mevcut API üzerine kurulu React Native mobil uygulaması.
  - Bildirimler ve acil durum butonları (Tümünü Sat vb.).
- [ ] **Telegram/Discord Asistanı**
  - Telefondan `/durum`, `/bakiye` komutlarıyla botları yönetebilme.
  - Anlık alım-satım bildirimlerinin Telegram'a düşmesi.

## ✅ Hemen Başlayabileceğimiz Aksiyonlar (Öncelikli)

- [x] **Grid Bot Stratejisi**: İndikatörsüz, matematiksel al-sat stratejisinin kodlanması.
- [ ] **Loglama Altyapısı**: Serilog ile dosya veya veriletanı tabanlı detaylı hata takibi.
- [ ] **Telegram Bildirim Entegrasyonu**: İşlem yapıldığında cep telefonuna mesaj gelmesi.
