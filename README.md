# 🚀 Kripteks - Otomatik Kripto Trading Platformu

**Kripteks**, kripto para piyasalarında otomatik alım-satım stratejileri uygulayan, Next.js ve .NET 8 ile geliştirilmiş modern bir trading botları yönetim sistemidir.

## ✨ Özellikler

### 🤖 Bot Yönetimi

- **Multi-Strategy Support**: Golden Rose, SMA Crossover ve Hemen Al stratejileri
- **Real-Time Monitoring**: SignalR ile canlı bot durumu ve PnL takibi
- **Akıllı Risk Yönetimi**: Take Profit ve Stop Loss ayarları
- **Sinyal Bazlı İşlem**: Belirli koşulları bekleyip otomatik pozisyon açma

### 📊 Analitik & Raporlama

- **TradingView Entegrasyonu**: Strateji bazlı otomatik indikatörler
- **Detaylı Loglar**: Her işlem için ayrıntılı log kayıtları
- **Performans Raporları**: Kazanç/Zarar grafikleri ve istatistikler
- **Backtest Sistemi**: Stratejileri geçmiş verilerle test etme

### 💼 Kullanıcı Yönetimi

- **Rol Tabanlı Erişim**: Admin, Trader, User rolleri
- **JWT Authentication**: Güvenli kimlik doğrulama
- **Multi-User Support**: Birden fazla kullanıcı desteği

### 💰 Cüzdan & İşlem Yönetimi

- **Bakiye Takibi**: Mevcut, kilitli ve toplam bakiye görüntüleme
- **İşlem Geçmişi**: Tüm yatırım ve gelir hareketlerini kaydetme
- **Binance API Entegrasyonu**: Güvenli API bağlantısı

## 🛠️ Teknolojiler

### Backend

- **.NET 8** - Modern, performanslı API
- **Entity Framework Core** - ORM
- **MS SQL Server** - Veritabanı
- **SignalR** - Real-time iletişim
- **Binance.Net** - Binance API Integration

### Frontend

- **Next.js 14** (App Router) - React framework
- **TypeScript** - Tip güvenliği
- **Tailwind CSS** - Modern UI styling
- **Framer Motion** - Animasyonlar
- **TradingView Widget** - Profesyonel grafik görünümü
- **Sonner** - Toast notifications

## 📦 Kurulum

### Gereksinimler

- Node.js 18+
- .NET 8 SDK
- MS SQL Server

### Backend Kurulumu

```bash
cd backend-api/src/Kripteks.Api
dotnet restore
dotnet ef database update
dotnet run --urls "http://localhost:5001"
```

### Frontend Kurulumu

```bash
cd client-next
npm install
npm run dev
```

## 🔐 Güvenlik

- API anahtarları veritabanında şifrelenmiş olarak saklanır
- JWT token bazlı kimlik doğrulama
- Rol tabanlı yetkilendirme
- Para çekme izni önerilmez (Sadece trading izinleri)

## 📝 Lisans

Bu proje özel kullanım içindir.

## 👨‍💻 Geliştirici

**Osman Ali Aydemir**

---

⚡ **Kripteks** - Automated Trading Engine v2.0
