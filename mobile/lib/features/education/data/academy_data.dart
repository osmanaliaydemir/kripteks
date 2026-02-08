import 'package:flutter/material.dart';
import 'package:mobile/features/education/models/education_models.dart';
import 'package:mobile/core/theme/app_colors.dart';

class AcademyData {
  static final List<AcademyCategory> categories = [
    AcademyCategory(
      type: EducationTopicCategory.indicators,
      title: 'İndikatör Akademi',
      description:
          'Teknik göstergeleri anlamanıza ve yorumlamanıza yardımcı olur.',
      icon: Icons.auto_graph_rounded,
      color: AppColors.primary,
    ),
    AcademyCategory(
      type: EducationTopicCategory.strategies,
      title: 'Strateji Kütüphanesi',
      description:
          'Başarılı işlem stratejilerini ve uygulama yöntemlerini öğrenin.',
      icon: Icons.lightbulb_outline_rounded,
      color: AppColors.success,
    ),
    AcademyCategory(
      type: EducationTopicCategory.fundamentals,
      title: 'Temel Kavramlar',
      description:
          'Kripto para piyasasının temel işleyişini ve terimlerini keşfedin.',
      icon: Icons.menu_book_rounded,
      color: Colors.orange,
    ),
    AcademyCategory(
      type: EducationTopicCategory.appTraining,
      title: 'Kripteks Uygulama Eğitimleri',
      description:
          'Kripteks platformunu en verimli şekilde nasıl kullanacağınızı öğrenin.',
      icon: Icons.rocket_launch_rounded,
      color: AppColors.purple,
    ),
  ];

  static final List<EducationTopic> topics = [
    // İndikatörler
    EducationTopic(
      id: 'rsi',
      title: 'RSI (Göreceli Güç Endeksi)',
      description:
          'Aşırı alım ve aşırı satım bölgelerini belirlemek için kullanılır.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Osilatörler',
      icon: Icons.show_chart,
      content: '''
# RSI Nedir?
Göreceli Güç Endeksi (RSI), bir varlığın fiyat hareketlerinin hızını ve değişimini ölçen bir momentum osilatörüdür.

## Nasıl Yorumlanır?
RSI genellikle 0 ile 100 arasında bir değer alır:
- **70 ve Üzeri:** Aşırı alım bölgesi olarak kabul edilir. Fiyatın düzeltme yapabileceği sinyalini verebilir.
- **30 ve Altı:** Aşırı satım bölgesi olarak kabul edilir. Fiyatın tepki alımı yapabileceği sinyalini verebilir.

## Kripteks'te RSI
Kripteks botları, RSI değerlerini diğer indikatörlerle birleştirerek en güvenli giriş noktalarını belirler.
''',
    ),
    EducationTopic(
      id: 'ema-sma',
      title: 'EMA ve SMA Farkı',
      description: 'Hareketli ortalamaların türleri ve kullanım alanları.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Trendler',
      icon: Icons.trending_up,
      content: '''
# Hareketli Ortalamalar
Fiyatın belirli bir zaman dilimindeki ortalama değerini gösterir ve gürültüyü azaltarak trendi netleştirir.

## SMA (Basit Hareketli Ortalama)
Tüm fiyatları eşit ağırlıkta değerlendirir. Daha yavaş tepki verir.

## EMA (Üstel Hareketli Ortalama)
Son fiyatlara daha fazla ağırlık verir. Daha hızlı tepki verir ve kısa vadeli trendleri yakalamada etkilidir.

## Kripteks Kullanımı
Kripteks tarayıcısında "SMA 111 Kesişimi" stratejisi, fiyatın bu hareketli ortalamayı kestiği anları tespit eder.
''',
    ),
    EducationTopic(
      id: 'stochastic-oscillator',
      title: 'Stochastic Osilatör',
      description:
          'Fiyatın belirli bir aralıktaki konumunu ölçen momentum indikatörü.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Osilatörler',
      icon: Icons.waves_rounded,
      content: '''
# Stochastic Nedir?
Mevcut fiyatın, belirli bir dönemdeki en yüksek ve en düşük fiyat aralığında nerede olduğunu gösterir.

## %K ve %D Hatları
- **%K:** Ana stochastic hattı (hızlı).
- **%D:** %K'nın hareketli ortalaması (yavaş, sinyal hattı).

## Yorumlama
- **80 Üzeri:** Aşırı alım bölgesi. Satış sinyali yakın olabilir.
- **20 Altı:** Aşırı satım bölgesi. Alım fırsatı doğabilir.
- **Kesişimler:** %K'nın %D'yi yukarı kesmesi AL, aşağı kesmesi SAT sinyali olarak değerlendirilir.

## Kripteks İpucu
RSI ile birlikte kullanıldığında çift onay sinyalleri oluşturur ve yanlış sinyalleri azaltır.
''',
    ),
    EducationTopic(
      id: 'atr-indicator',
      title: 'ATR (Average True Range)',
      description:
          'Piyasa volatilitesini ölçen ve stop-loss mesafesi belirlemeye yarayan indikatör.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Volatilite',
      icon: Icons.height_rounded,
      content: '''
# ATR Nedir?
Ortalama Gerçek Aralık, bir varlığın belirli bir dönemdeki fiyat hareketlerinin ortalama genişliğini gösterir.

## Nasıl Kullanılır?
- **Yüksek ATR:** Volatilite yüksek, fiyat hareketleri geniş. Risk yönetimi için stop-loss mesafesini artırmalısınız.
- **Düşük ATR:** Volatilite düşük, fiyat yatay seyrediyor. Dar stop-loss kullanılabilir.

## Stop-Loss Hesaplama
Giriş fiyatından ± (2 x ATR) mesafe koyarak, normal fiyat dalgalanmalarından erken çıkmayı engellersiniz.

## Grid Bot Optimizasyonu
ATR değerine göre ızgara aralıklarını ayarlayarak piyasa koşullarına uyum sağlayabilirsiniz.
''',
    ),
    EducationTopic(
      id: 'volume-profile',
      title: 'Hacim Profili (Volume Profile)',
      description: 'Fiyat seviyelerinde işlem gören hacim dağılımını gösterir.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Hacim',
      icon: Icons.bar_chart_rounded,
      content: '''
# Volume Profile Nedir?
Geleneksel hacim çubukları zamanı gösterirken, hacim profili hangi fiyat seviyelerinde ne kadar işlem yapıldığını gösterir.

## Kritik Kavramlar
- **POC (Point of Control):** En yüksek hacmin olduğu fiyat seviyesi. Güçlü bir mıknatıs görevi görür.
- **Value Area:** İşlemlerin %70'inin gerçekleştiği fiyat aralığı.
- **Low Volume Nodes:** Düşük hacimli bölgeler, fiyat bu bölgelerden hızla geçer.

## Strateji
POC seviyesine yaklaşan fiyatlar genellikle burada tepki verir. Destek/direnç olarak kullanılabilir.
''',
    ),
    EducationTopic(
      id: 'obv-indicator',
      title: 'OBV (On-Balance Volume)',
      description:
          'Hacim akışını takip ederek fiyat hareketlerini önceden tahmin etmeye çalışır.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Hacim',
      icon: Icons.trending_up_rounded,
      content: '''
# OBV Nedir?
Fiyat yükseldiğinde günlük hacmi ekleyen, düştüğünde çıkaran kümülatif bir indikatördür.

## Nasıl Yorumlanır?
- **OBV Yükseliyor, Fiyat Yatay:** Akıllı para birikim yapıyor, yakında yükseliş gelebilir.
- **OBV Düşüyor, Fiyat Yatay:** Dağıtım var, düşüş yakın olabilir.
- **Divergence (Uyumsuzluk):** Fiyat yeni zirve yaparken OBV yapmıyorsa, trend zayıflıyor demektir.

## Kripteks Kullanımı
Tarayıcıda hacim filtrelerini aktif ederek OBV ile uyumlu güçlü trendleri yakalayabilirsiniz.
''',
    ),
    EducationTopic(
      id: 'ichimoku-cloud',
      title: 'Ichimoku Bulutu',
      description:
          'Tek başına destek, direnç, trend ve momentum bilgisi veren Japon indikatörü.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Trendler',
      icon: Icons.cloud_rounded,
      content: '''
# Ichimoku Kinko Hyo
"Bir bakışta denge grafiği" anlamına gelir ve 5 bileşenden oluşur.

## Bileşenler
- **Tenkan-sen (Dönüşüm Hattı):** Kısa vadeli trend.
- **Kijun-sen (Temel Hat):** Orta vadeli trend.
- **Senkou Span A & B:** "Bulut" oluşturur, destek/direnç görevi görür.
- **Chikou Span:** Gecikmeli kapanış, onay sinyali verir.

## Sinyal Üretme
- Fiyat bulutun üzerindeyse: Yükseliş trendi.
- Fiyat bulutun altındaysa: Düşüş trendi.
- Tenkan, Kijun'u yukarı keserse: AL sinyali.

## Uyarı
Karmaşık görünse de, tüm bilgileri tek bir grafikte topladığı için profesyoneller tarafından çok kullanılır.
''',
    ),
    EducationTopic(
      id: 'parabolic-sar',
      title: 'Parabolic SAR',
      description:
          'Trend dönüş noktalarını ve trailing stop seviyelerini belirler.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Trendler',
      icon: Icons.circle_outlined,
      content: '''
# Parabolic SAR (Stop and Reverse)
Fiyatın üstünde veya altında görünen noktalardan oluşur ve trend değişimlerini işaret eder.

## Nasıl Çalışır?
- **Noktalar Fiyatın Altında:** Yükseliş trendi devam ediyor.
- **Noktalar Fiyatın Üstüne Geçti:** Trend tersine döndü, pozisyon kapatılmalı veya short açılmalı.

## Trailing Stop Olarak Kullanım
SAR noktalarını stop-loss seviyesi olarak kullanarak, trend devam ettikçe kârınızı korursunuz.

## Dezavantaj
Yatay piyasalarda çok fazla yanlış sinyal üretir. Trend filtresi (ADX gibi) ile birlikte kullanılmalıdır.
''',
    ),
    EducationTopic(
      id: 'adx-indicator',
      title: 'ADX (Average Directional Index)',
      description: 'Trendin gücünü ölçer, yönünü değil.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Trendler',
      icon: Icons.speed_rounded,
      content: '''
# ADX Nedir?
Trendin ne kadar güçlü olduğunu 0-100 arası bir değerle gösterir.

## Yorumlama
- **25 Altı:** Zayıf veya yok trend, yatay piyasa.
- **25-50:** Güçlü trend var.
- **50 Üzeri:** Çok güçlü trend, momentum stratejileri için ideal.

## +DI ve -DI Hatları
- **+DI > -DI:** Yükseliş trendi.
- **-DI > +DI:** Düşüş trendi.

## Kripteks Stratejisi
ADX > 25 olduğunda trend takip botları (DCA, Grid) daha verimli çalışır. ADX < 25 ise sinyal botları tercih edilmelidir.
''',
    ),
    EducationTopic(
      id: 'cci-indicator',
      title: 'CCI (Commodity Channel Index)',
      description:
          'Fiyatın istatistiksel ortalamadan ne kadar saptığını ölçer.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Osilatörler',
      icon: Icons.compare_arrows_rounded,
      content: '''
# CCI Nedir?
Fiyatın hareketli ortalamasından ne kadar uzaklaştığını standart sapma ile ölçer.

## Seviyeler
- **+100 Üzeri:** Aşırı alım, düzeltme gelebilir.
- **-100 Altı:** Aşırı satım, toparlanma beklenebilir.
- **0 Civarı:** Normal fiyat hareketi.

## Divergence Sinyalleri
Fiyat yeni dip yaparken CCI daha yüksek dip yaparsa, güçlü bir yükseliş dönüşü sinyalidir.

## Kullanım Alanı
Özellikle emtia ve kripto gibi yüksek volatiliteli piyasalarda etkilidir.
''',
    ),
    EducationTopic(
      id: 'williams-r',
      title: 'Williams %R',
      description:
          'Stochastic\'e benzer ancak ters ölçekli momentum osilatörü.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Osilatörler',
      icon: Icons.percent_rounded,
      content: '''
# Williams %R Nedir?
Mevcut kapanışın, belirli bir dönemdeki en yüksek fiyata göre konumunu -100 ile 0 arasında gösterir.

## Yorumlama
- **-20 ile 0 Arası:** Aşırı alım bölgesi.
- **-80 ile -100 Arası:** Aşırı satım bölgesi.

## Sinyal Üretme
- -80'in altından yukarı çıkış: AL sinyali.
- -20'nin üzerinden aşağı iniş: SAT sinyali.

## Avantajı
Stochastic'ten daha hızlı tepki verir, kısa vadeli işlemler için uygundur.
''',
    ),
    EducationTopic(
      id: 'keltner-channels',
      title: 'Keltner Kanalları',
      description: 'ATR tabanlı volatilite kanalları, Bollinger\'a alternatif.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Volatilite',
      icon: Icons.view_week_rounded,
      content: '''
# Keltner Channels Nedir?
EMA etrafında ATR mesafesinde çizilen üst ve alt bantlardan oluşur.

## Bollinger'dan Farkı
Bollinger standart sapma kullanırken, Keltner ATR kullanır. Bu sayede daha az yanlış sinyal üretir.

## Kullanım
- Fiyat üst bandı kırarsa: Güçlü yükseliş, momentum devam edebilir.
- Fiyat alt bandı kırarsa: Güçlü düşüş.
- Bantlar içinde kalırsa: Konsolidasyon, breakout beklenebilir.

## Grid Bot Uygulaması
Keltner kanallarını ızgara sınırları olarak kullanarak dinamik grid stratejileri oluşturabilirsiniz.
''',
    ),
    EducationTopic(
      id: 'vwap-indicator',
      title: 'VWAP (Hacim Ağırlıklı Ortalama Fiyat)',
      description: 'Günlük işlemlerin hacim bazlı ortalama fiyatını gösterir.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Hacim',
      icon: Icons.analytics_outlined,
      content: '''
# VWAP Nedir?
Kurumsal yatırımcıların ve algoritmik botların referans aldığı, hacim ağırlıklı ortalama fiyattır.

## Nasıl Kullanılır?
- **Fiyat VWAP Üzerinde:** Alıcılar kontrolde, yükseliş trendi.
- **Fiyat VWAP Altında:** Satıcılar kontrolde, düşüş trendi.
- **VWAP'a Dönüş:** Fiyat VWAP'a yaklaştığında genellikle tepki verir (mıknatıs etkisi).

## Gün İçi İşlemler
VWAP özellikle gün içi (intraday) işlemler için kritiktir. Kurumsal emirler genellikle VWAP civarında yoğunlaşır.

## Kripteks Notu
24 saat açık olan kripto piyasalarında VWAP'ı 24 saatlik veya 4 saatlik periyotlarda kullanmak daha etkilidir.
''',
    ),
    EducationTopic(
      id: 'supertrend-indicator',
      title: 'Supertrend İndikatörü',
      description:
          'ATR tabanlı, net AL/SAT sinyalleri üreten trend takip aracı.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Trendler',
      icon: Icons.arrow_upward_rounded,
      content: '''
# Supertrend Nedir?
ATR ve hareketli ortalama kombinasyonu ile çalışan, fiyatın üstünde veya altında görünen bir çizgidir.

## Sinyal Mantığı
- **Yeşil Çizgi (Fiyatın Altında):** Yükseliş trendi, pozisyon tutun veya AL.
- **Kırmızı Çizgi (Fiyatın Üstünde):** Düşüş trendi, pozisyon kapatın veya SAT.

## Parametre Ayarları
- **Periyot:** Genellikle 10 kullanılır.
- **Çarpan:** 3 standart değerdir. Artırırsanız daha az sinyal ama daha güvenilir olur.

## Kripteks Kullanımı
Supertrend sinyallerini tarayıcıda filtre olarak ekleyerek sadece trend yönünde işlem yapan botlar oluşturabilirsiniz.
''',
    ),
    EducationTopic(
      id: 'macd',
      title: 'MACD',
      description:
          'Trend yönünü ve gücünü takip etmek için kullanılan indikatör.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Trendler',
      icon: Icons.multiline_chart,
      content: '''
# MACD Nedir?
Moving Average Convergence Divergence (MACD), iki hareketli ortalamanın birbirine yaklaşması veya uzaklaşması üzerinden trend değişimlerini yakalar.

## Bileşenleri
- **MACD Hattı:** Hızlı ve yavaş ortalamalar arasındaki fark.
- **Sinyal Hattı:** MACD hattının hareketli ortalaması.
- **Histogram:** Trendin gücünü görselleştiren çubuklar.

## Strateji
MACD hattı sinyal hattını yukarı kestiğinde "AL", aşağı kestiğinde ise "SAT" sinyali olarak değerlendirilebilir.
''',
    ),
    EducationTopic(
      id: 'bollinger',
      title: 'Bollinger Bantları',
      description:
          'Piyasa volatilitesini ve fiyatın göreceli yüksek/düşük seviyelerini ölçer.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Volatilite',
      icon: Icons.stacked_line_chart_rounded,
      content: '''
# Bollinger Bantları Nedir?
John Bollinger tarafından geliştirilen bu indikatör, bir hareketli ortalamanın üstüne ve altına çizilen iki standart sapma bandından oluşur.

## Nasıl Okunur?
- **Daralan Bantlar:** Piyasanın "sıkıştığını" ve yakında büyük bir patlama (volatilite) olabileceğini gösterir.
- **Genişleyen Bantlar:** Volatilitenin arttığını ve mevcut trendin güçlendiğini simgeler.
- **Bant Temasları:** Fiyat üst banda değerse "pahalı", alt banda değerse "ucuz" olarak yorumlanabilir.

## Kripteks İpucu
Kripteks Grid botları, Bollinger bantlarını kullanarak ızgara aralıklarını dinamik olarak belirleyebilir.
''',
    ),
    EducationTopic(
      id: 'fibonacci',
      title: 'Fibonacci Düzeltmesi',
      description:
          'Fiyatın geri çekilme yapabileceği destek ve direnç seviyeleri.',
      category: EducationTopicCategory.indicators,
      subCategory: 'Trendler',
      icon: Icons.architecture_rounded,
      content: '''
# Fibonacci Seviyeleri
Doğadaki matematiksel oranların finansal piyasalara uyarlanmış halidir. Önemli bir yükseliş veya düşüş sonrası fiyatın nereden dönebileceğini tahmin etmeye yarar.

## Kritik Seviyeler
- **0.618 (Altın Oran):** En güçlü dönüş sinyali beklenen seviyedir.
- **0.382 ve 0.5:** Diğer önemli izleme noktalarıdır.

## Kullanım Alanı
Yatırımcılar genellikle bu seviyeleri "Alım Emri" veya "Durdurma Emri" koymak için gizli birer harita gibi kullanırlar.
''',
    ),

    // Stratejiler
    EducationTopic(
      id: 'head-and-shoulders',
      title: 'OBO ve TOBO Formasyonları',
      description:
          'Trend dönüşünün en güvenilir habercisi olan Omuz-Baş-Omuz formasyonu.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Grafik Formasyonları',
      icon: Icons.person_rounded,
      content: '''
# OBO (Omuz Baş Omuz)
Yükselen bir trendin sona erdiğini ve düşüşün başlayacağını gösterir.
- **Sol Omuz:** Fiyat yükselir ve geri çekilir.
- **Baş:** Fiyat daha yükseğe çıkar ve geri çekilir.
- **Sağ Omuz:** Fiyat tekrar yükselir ama baş seviyesini geçemez.
- **Boyun Çizgisi:** Kırıldığında işlem (Short) açılır.

# TOBO (Ters Omuz Baş Omuz)
Düşen trendin bitip yükselişin başlayacağını gösterir (Long fırsatı).
''',
    ),
    EducationTopic(
      id: 'double-top-bottom',
      title: 'İkili Tepe ve İkili Dip (W & M)',
      description:
          'Fiyatın bir seviyeyi iki kez deneyip geçemediği güçlü dönüş sinyalleri.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Grafik Formasyonları',
      icon: Icons.filter_2_rounded,
      content: '''
# İkili Tepe (M Formasyonu)
Fiyatın dirence iki kez çarpıp geçememesi. Düşüş habercisidir.
- **Hedef:** Boyun çizgisi kırıldığında, tepe ile boyun arasındaki mesafe kadar düşüş beklenir.

# İkili Dip (W Formasyonu)
Fiyatın desteğe iki kez çarpıp kıramaması. Yükseliş habercisidir.
- **Hedef:** Boyun çizgisi kırıldığında, dip ile boyun arasındaki mesafe kadar yükseliş beklenir.
''',
    ),
    EducationTopic(
      id: 'triangle-patterns',
      title: 'Üçgen Formasyonları',
      description:
          'Fiyatın sıkıştığı ve patlamaya hazırlandığı anları yakalayın.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Grafik Formasyonları',
      icon: Icons.change_history_rounded,
      content: '''
# Simetrik Üçgen
Alıcı ve satıcıların kararsız olduğu sıkışma alanı. Kırılım ne tarafa olursa o yöne sert hareket gelir.

# Yükselen Üçgen
Dipler yükselirken tepeler sabittir. Genellikle yukarı kırılım (Boğa) beklenir.

# Alçalan Üçgen
Tepeler düşerken dipler sabittir. Genellikle aşağı kırılım (Ayı) beklenir.

## Strateji
Üçgenin içindeyken değil, kırılım gerçekleşip hacimle onaylandığında işleme girin.
''',
    ),
    EducationTopic(
      id: 'flag-pennant-patterns',
      title: 'Bayrak ve Flama (Flags)',
      description: 'Sert hareketler sonrası oluşan trend devam formasyonları.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Grafik Formasyonları',
      icon: Icons.flag_rounded,
      content: '''
# Boğa Bayrağı (Bull Flag)
Direk gibi sert bir yükseliş sonrası, fiyatın hafifçe aşağı eğimli bir kanalda dinlenmesi.
- **Sonuç:** Bayrak yukarı kırıldığında, direk boyu kadar daha yükseliş beklenir.

# Ayı Bayrağı (Bear Flag)
Sert düşüş sonrası fiyatın hafifçe yukarı eğimli bir kanalda dinlenmesi.
- **Sonuç:** Bayrak aşağı kırıldığında düşüş devam eder.
''',
    ),
    EducationTopic(
      id: 'candlestick-patterns-101',
      title: 'Mum Formasyonları (Candlesticks)',
      description: 'Tek bir mumun şeklinden piyasanın yönünü okuma sanatı.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Grafik Formasyonları',
      icon: Icons.candlestick_chart_rounded,
      content: '''
# Doji (Kararsızlık)
Gövdesi çok ince veya hiç olmayan artı (+) şeklindeki mum. Piyasanın yön konusunda kararsız olduğunu, bir dönüşün yakın olabileceğini gösterir.

# Hammer (Çekiç)
Düşüş trendi sonunda oluşan, alt gölgesi uzun, gövdesi yukarıda küçük mum. "Alıcılar geldi, düşüş bitti" sinyalidir.

# Shooting Star (Kayan Yıldız)
Yükseliş trendi tepesinde oluşan, üst gölgesi uzun ters çekiç. "Satıcılar baskın, düşüş başlayabilir" sinyalidir.

# Engulfing (Yutan Mum)
Kendinden önceki mumu tamamen içine alan büyük gövdeli mum. Çok güçlü bir trend dönüş sinyalidir.
''',
    ),
    EducationTopic(
      id: 'defi-yield-farming',
      title: 'DeFi ve Yield Farming',
      description: 'Merkeziyetsiz finansta pasif gelir elde etme yöntemleri.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'DeFi & Web3',
      icon: Icons.agriculture_rounded,
      content: '''
# DeFi Nedir?
Bankasız finans. Aracılar yerine akıllı kontratlar vardır.

# Yield Farming
Likidite sağlayarak (coinlerinizi havuza koyarak) faiz ve ödül token kazanma işlemidir.
- **Risk:** Impermanent Loss ve hack riski.
- **Ödül:** Geleneksel banka faizlerinden çok daha yüksek getiri (APY).

# Staking
Coinlerinizi ağın güvenliğini sağlamak için kilitleyip ödül kazanmaktır (Örn: ETH 2.0 Staking).
''',
    ),
    EducationTopic(
      id: 'nft-metaverse-concepts',
      title: 'NFT ve Metaverse',
      description: 'Dijital mülkiyet ve sanal evrenlerin ekonomisi.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'DeFi & Web3',
      icon: Icons.vrpano_rounded,
      content: '''
# NFT (Non-Fungible Token)
Değiştirilemez dijital varlık. Bir sanat eserinin, oyun eşyasının veya tapunun dijital sahiplik sertifikasıdır.

# Metaverse
Sanal gerçeklik ile fiziksel dünyanın birleştiği, kendi ekonomisi olan dijital evrenlerdir (Örn: Decentraland, Sandbox).

## Yatırım Açısı
Metaverse arsaları veya popüler NFT koleksiyonları, spekülatif ama yüksek getirili yatırım araçları olabilir.
''',
    ),
    EducationTopic(
      id: 'layer1-vs-layer2',
      title: 'Layer 1 vs Layer 2',
      description: 'Blockchain ölçeklenebilirlik savaşları ve farkları.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Teknoloji',
      icon: Icons.layers_rounded,
      content: '''
# Layer 1 (Ana Ağ)
Bitcoin, Ethereum, Solana gibi ana blokzincirlerdir. Güvenliği sağlarlar ancak yoğunlukta yavaşlayıp pahalanabilirler.

# Layer 2 (Ölçekleme Çözümü)
Ana ağın üzerine inşa edilen, işlemleri hızlandıran ve ucuzlatan katmanlardır.
- **Örnekler:** Arbitrum, Optimism, Polygon.
- **Mantık:** İşlemleri dışarıda yapıp sonucu ana ağa toplu şekilde yazar (Rollup).

## Kullanıcı İçin Önemi
Düşük işlem ücreti ödemek için transferlerinizi Layer 2 ağları üzerinden yapmayı tercih edin.
''',
    ),
    EducationTopic(
      id: 'revenge-trading-psychology',
      title: 'İntikam Trade\'i (Revenge Trading)',
      description:
          'Kaybettikten sonra parayı hemen geri kazanma hırsının tehlikesi.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Psikoloji',
      icon: Icons.psychology_alt_rounded,
      content: '''
# En Büyük Düşman: Hırs
Büyük bir kayıp yaşadıktan sonra beynimiz rasyonel düşünmeyi bırakır ve "haksızlığa uğramış" hissederek hemen parayı geri kazanmak ister.

## Belirtileri
- Strateji dışına çıkmak.
- Normalden çok daha büyük kaldıraç veya bakiye kullanmak.
- Hatalı işlemde ısrar etmek (Stop olmamak).

## Çözüm
Büyük bir kayıp sonrası **masadan kalkın**. Yürüyüşe çıkın, ekranı kapatın. Piyasadan intikam alamazsınız, piyasa her zaman haklıdır.
''',
    ),
    EducationTopic(
      id: 'gamblers-fallacy',
      title: 'Kumarbaz Yanılgısı',
      description: 'Olasılıkları yanlış hesaplamanın getirdiği batış.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Psikoloji',
      icon: Icons.casino_rounded,
      content: '''
# Kumarbaz Yanılgısı Nedir?
"5 kere üst üste yazı geldi, kesin tura gelecek" düşüncesidir. Oysa her atış bağımsızdır, ihtimal her seferinde %50'dir.

## Trading'de Karşılığı
"Bu coin çok düştü, artık yükselmek zorunda" düşüncesi yanlıştır. Bir coin %90 düştükten sonra %90 daha düşebilir.

## Korunma
Hissiyatla değil, trend ve indikatör sinyalleriyle hareket edin. "Buradan dönmeli" diye bir kural yoktur.
''',
    ),
    EducationTopic(
      id: 'wedge-patterns',
      title: 'Kama (Wedge) Formasyonları',
      description:
          'Trendin yorulduğunu ve dönüşün yakın olduğunu gösteren yapılar.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Grafik Formasyonları',
      icon: Icons.signal_cellular_alt_rounded,
      content: '''
# Yükselen Kama (Rising Wedge)
Fiyat yükseliyor ama tepeler arası mesafe daralıyor. Alıcıların gücü tükeniyor.
- **Sonuç:** Aşağı kırılım beklenir (Ayı sinyali).

# Alçalan Kama (Falling Wedge)
Fiyat düşüyor ama dipler arası mesafe daralıyor. Satıcıların gücü tükeniyor.
- **Sonuç:** Yukarı kırılım beklenir (Boğa sinyali).
''',
    ),
    EducationTopic(
      id: 'cup-and-handle',
      title: 'Fincan Kulp Formasyonu',
      description: 'Uzun süreli birikim ve sert yükseliş habercisi.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Grafik Formasyonları',
      icon: Icons.coffee_rounded,
      content: '''
# Fincan Kulp (Cup & Handle)
Fiyat önce "U" şeklinde bir çanak yapar (Fincan), sonra küçük bir düşüşle düzeltme yapar (Kulp).
- **Psikoloji:** Uzun süreli toparlanma sonrası son silkeleme yapılır.
- **Hedef:** Kulp kırıldığında, fincanın derinliği kadar yükseliş beklenir.
''',
    ),
    EducationTopic(
      id: 'grid-strategy',
      title: 'Grid (Izgara) Stratejisi',
      description:
          'Yatay piyasalarda düzenli aralıklarla al-sat yaparak kâr elde etme.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Otomatik Botlar',
      icon: Icons.grid_view_rounded,
      content: '''
# Grid Bot Stratejisi
Grid stratejisi, belirlenen bir fiyat aralığında düzenli "ızgaralar" oluşturarak çalışır.

## Nasıl Çalışır?
- Fiyat düştükçe her ızgara seviyesinden alım yapılır.
- Fiyat yükseldikçe alınan miktarlar bir üst seviyeden satılır.
- Özellikle yatay giden (zigzag çizen) piyasalarda çok etkilidir.

## Avantajları
- Fiyatın yönünden bağımsız kâr elde edebilir.
- Duygulardan arınmış, sistematik bir süreçtir.
''',
    ),
    EducationTopic(
      id: 'dca-strategy',
      title: 'DCA (Maliyet Azaltma)',
      description:
          'Düşen piyasada ortalama maliyeti aşağı çekerek başarılı çıkış planlama.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Otomatik Botlar',
      icon: Icons.trending_down,
      content: '''
# DCA Nedir?
Dollar Cost Averaging (DCA), varlığın fiyatı düştükçe belirli oranlarda ek alım yaparak giriş maliyetini aşağı çekme sanatıdır.

## Kripteks DCA Botu
Kripteks botları, siz uyurken bile fiyat düşüşlerinde stratejik eklemeler yaparak pozisyonu kara geçirmeyi hedefler.

## İpucu
DCA yaparken kasanızın tamamını değil, kademeli bir bütçe yönetimi kullanmanız kritiktir.
''',
    ),
    EducationTopic(
      id: 'swing-trading',
      title: 'Swing Trading',
      description:
          'Orta vadeli dalgalanmalardan kâr elde etmeyi hedefleyen strateji.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Manuel Stratejiler',
      icon: Icons.waves_rounded,
      content: '''
# Swing Trading Nedir?
Birkaç günden birkaç haftaya kadar süren fiyat "salınımlarını" yakalamayı amaçlar.

## Özellikleri
- Günlük ekrana bakma zorunluluğunu azaltır.
- Trend değişimlerini ve dip/tepe noktalarını hedef alır.
- Sabır gerektiren bir yaklaşımdır.

## Kripteks Uygulaması
Kripteks'teki 4 saatlik ve Günlük sinyal tarayıcılar, swing traderlar için en güçlü yardımcıdır.
''',
    ),
    EducationTopic(
      id: 'scalping-strategy',
      title: 'Scalping (Kısa Vadeli İşlem)',
      description:
          'Dakikalar içinde küçük fiyat hareketlerinden kâr elde etme sanatı.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Manuel Stratejiler',
      icon: Icons.flash_on_rounded,
      content: '''
# Scalping Nedir?
Çok kısa zaman dilimlerinde (1-15 dakika) küçük fiyat değişimlerinden (%0.5-2) kâr elde etmeyi hedefler.

## Gereksinimler
- **Hız:** Milisaniyeler önemlidir, düşük gecikme (latency) şarttır.
- **Likidite:** Sadece yüksek hacimli paritelerde yapılmalıdır.
- **Disiplin:** Küçük kayıpları hemen kesmek kritiktir.

## Avantajları
- Piyasada uzun süre risk taşımazsınız.
- Günde onlarca işlemle küçük kârlar birikir.

## Dezavantajları
- Komisyonlar kârınızı eritebilir.
- Yüksek stres ve sürekli ekran başında olma gerektirir.

## Kripteks İpucu
Scalping için Kripteks Sinyal Botunu 1 dakikalık veya 5 dakikalık periyotlarda kullanabilirsiniz.
''',
    ),
    EducationTopic(
      id: 'mean-reversion',
      title: 'Mean Reversion (Ortalamaya Dönüş)',
      description: 'Aşırı sapan fiyatların ortalamaya geri döneceği varsayımı.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Otomatik Botlar',
      icon: Icons.restore_rounded,
      content: '''
# Mean Reversion Stratejisi
Fiyatın istatistiksel ortalamasından çok uzaklaştığında, er ya da geç oraya geri döneceği prensibine dayanır.

## Nasıl Çalışır?
- Bollinger Bantlarının alt bandına değen bir varlık "ucuz" kabul edilir, AL sinyali.
- Üst banda değen varlık "pahalı" kabul edilir, SAT sinyali.

## En İyi Piyasa Koşulu
Yatay (sideways) piyasalarda çok etkilidir. Güçlü trendlerde tehlikelidir.

## Kripteks Grid Botu
Grid botları aslında bir mean reversion stratejisidir. Fiyat ortalamanın altına düştükçe alır, üstüne çıktıkça satar.
''',
    ),
    EducationTopic(
      id: 'breakout-strategy',
      title: 'Breakout (Kırılım) Stratejisi',
      description:
          'Fiyatın önemli bir seviyeyi kırmasıyla birlikte harekete geçme.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Manuel Stratejiler',
      icon: Icons.rocket_launch_rounded,
      content: '''
# Breakout Nedir?
Fiyatın uzun süredir test ettiği bir direnç veya destek seviyesini kırarak yeni bir trend başlatmasıdır.

## Doğru Breakout Tespiti
- **Hacim Onayı:** Kırılım yüksek hacimle gerçekleşmelidir.
- **Kapanış Onayı:** Mum, seviyenin üstünde/altında kapanmalıdır (gölge değil).
- **Retest:** Bazen fiyat kırdığı seviyeye geri dönerek test eder, sonra devam eder.

## Sahte Kırılım (Fakeout)
Fiyat seviyeyi kırar gibi yapar ama hemen geri döner. Bu yüzden hacim ve kapanış onayı şarttır.

## Kripteks Tarayıcı
"Direnç Kırılımı" filtresini aktif ederek gerçek zamanlı breakout fırsatlarını yakalayabilirsiniz.
''',
    ),
    EducationTopic(
      id: 'arbitrage-strategy',
      title: 'Arbitraj (Borsa Farkı)',
      description:
          'Aynı varlığın farklı borsalardaki fiyat farkından kâr etme.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Manuel Stratejiler',
      icon: Icons.swap_horiz_rounded,
      content: '''
# Arbitraj Nedir?
Bir varlığı ucuz olan borsadan alıp, pahalı olan borsada satarak risksiz kâr elde etme yöntemidir.

## Türleri
- **Basit Arbitraj:** BTC Binance'de 50,000 USD, Coinbase'de 50,200 USD ise, Binance'den al Coinbase'de sat.
- **Üçgen Arbitraj:** Aynı borsa içinde 3 farklı parite arasındaki dengesizlikten faydalanma.

## Zorluklar
- **Transfer Süresi:** Kripto transferi dakikalar alabilir, bu sürede fiyat eşitlenebilir.
- **Komisyonlar:** Transfer ve işlem ücretleri kârı eritebilir.
- **KYC Limitleri:** Borsalar arası büyük transferler sınırlamalara takılabilir.

## Kripteks Notu
Arbitraj fırsatları genellikle saniyeler içinde kapanır, bu yüzden profesyonel botlar gerektirir.
''',
    ),
    EducationTopic(
      id: 'hodl-strategy',
      title: 'HODL Stratejisi (Al ve Tut)',
      description:
          'Uzun vadeli değer artışına inanarak varlığı satmadan tutma.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Manuel Stratejiler',
      icon: Icons.lock_clock_rounded,
      content: '''
# HODL Felsefesi
Kısa vadeli fiyat dalgalanmalarını görmezden gelerek, varlığı yıllarca tutma stratejisidir.

## Kimler İçin Uygun?
- Günlük ekrana bakma stresi yaşamak istemeyenler.
- Projenin uzun vadeli potansiyeline inananlar.
- Vergi avantajından faydalanmak isteyenler (birçok ülkede uzun vadeli tutma daha az vergilendirilir).

## Riskler
- Proje başarısız olursa tüm sermayenizi kaybedebilirsiniz.
- Fırsatları kaçırabilirsiniz (örn: %300 yükseliş sonrası düzeltme).

## Hibrit Yaklaşım
Kripteks ile botlardan elde ettiğiniz kârların bir kısmını HODL cüzdanınıza aktararak dengeli bir portföy oluşturabilirsiniz.
''',
    ),
    EducationTopic(
      id: 'martingale-strategy',
      title: 'Martingale (Katlama) Stratejisi',
      description:
          'Her kayıptan sonra pozisyon büyüklüğünü artırarak telafi etme.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Otomatik Botlar',
      icon: Icons.trending_down_rounded,
      content: '''
# Martingale Nedir?
Kumar masalarından gelen bu strateji, her kayıptan sonra bahsi ikiye katlayarak bir kazançta tüm kayıpları telafi etmeyi hedefler.

## Kripto Uygulaması
DCA botlarında kullanılır: Fiyat düştükçe her ekleme bir öncekinden daha büyük yapılır.

## Tehlikesi
- **Sermaye Tükenmesi:** Arka arkaya düşüşlerde bakiyeniz hızla biter.
- **Sınırsız Risk:** Teoride sonsuz sermaye gerektirir, pratikte iflas ettirir.

## Güvenli Kullanım
- Maksimum ekleme sayısını sınırlayın (Örn: 5 adım).
- Sadece toplam sermayenizin küçük bir kısmını (<%10) kullanın.
- Volatilitesi düşük, güçlü projelerde uygulayın.

## Kripteks Uyarısı
Martingale çok agresif bir stratejidir. Risk yönetimi olmadan kullanmayın.
''',
    ),
    EducationTopic(
      id: 'range-trading',
      title: 'Range Trading (Aralık Ticareti)',
      description:
          'Belirli destek ve direnç arasında gidip gelen fiyattan kâr etme.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Otomatik Botlar',
      icon: Icons.horizontal_rule_rounded,
      content: '''
# Range Trading Nedir?
Fiyatın belirli bir aralıkta (range) hareket ettiği dönemlerde, destekten AL, dirençten SAT mantığıyla çalışır.

## Tespit Yöntemi
- Fiyat grafiğinde yatay bir kanal çizin.
- Alt sınır: Destek (alım bölgesi).
- Üst sınır: Direnç (satım bölgesi).

## Sinyal Üretme
- Fiyat desteğe yaklaştığında AL.
- Fiyat dirence yaklaştığında SAT.
- Aralık kırılırsa stratejiyi durdur.

## Kripteks Grid Botu
Grid botları aslında otomatik range trading yapar. Siz aralığı belirlersiniz, bot geri kalanını halleder.

## Uyarı
Güçlü bir trend başladığında range stratejisi zarara yol açar. ADX gibi trend filtreleri kullanın.
''',
    ),
    EducationTopic(
      id: 'momentum-trading',
      title: 'Momentum Trading',
      description:
          'Güçlü hareket eden varlıklara atlayarak trendle birlikte kâr etme.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Manuel Stratejiler',
      icon: Icons.speed_rounded,
      content: '''
# Momentum Nedir?
Hızla yükselen veya düşen varlıklara "trendin arkasına takılarak" kısa sürede kâr elde etme stratejisidir.

## Nasıl Tespit Edilir?
- **Hacim Patlaması:** Normalin 3-5 katı hacim artışı.
- **Güçlü Mumlar:** Büyük gövdeli, gölgesiz yeşil (veya kırmızı) mumlar.
- **RSI > 70:** Aşırı alım ama momentum devam edebilir.

## Giriş ve Çıkış
- **Giriş:** İlk kırılımdan sonra, ilk pullback (geri çekilme) sonrası.
- **Çıkış:** Hacim azalmaya başladığında veya ters yönlü büyük mum geldiğinde.

## Risk
Momentum biter bitmez fiyat sert düzeltme yapabilir. Trailing stop kullanmak şarttır.

## Kripteks Tarayıcı
"Hacim Artışı" ve "Fiyat Değişimi %" filtrelerini birleştirerek momentum fırsatlarını bulabilirsiniz.
''',
    ),
    EducationTopic(
      id: 'position-sizing',
      title: 'Pozisyon Büyüklüğü Hesaplama',
      description:
          'Her işlemde ne kadar sermaye riske atmanız gerektiğini belirleme.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Risk Yönetimi',
      icon: Icons.calculate_rounded,
      content: '''
# Position Sizing Nedir?
Bir işlemde kullanacağınız sermaye miktarını, risk toleransınıza göre hesaplama yöntemidir.

## Formül
Pozisyon Büyüklüğü = (Toplam Sermaye × Risk Yüzdesi) / (Giriş Fiyatı - Stop Loss Fiyatı)

## Örnek
- Toplam Sermaye: 10,000 USDT
- Risk Yüzdesi: %2 (200 USDT)
- Giriş: 100 USDT
- Stop Loss: 95 USDT
- Pozisyon Büyüklüğü = 200 / (100-95) = 40 adet

## Altın Kural
Tek bir işlemde toplam sermayenizin %1-2'sinden fazlasını riske atmayın.

## Kripteks Hesaplayıcı
Kripteks uygulamasındaki "Pozisyon Hesaplayıcı" aracı bu hesabı sizin için otomatik yapar.
''',
    ),
    EducationTopic(
      id: 'risk-reward-ratio',
      title: 'Risk/Ödül Oranı (R:R)',
      description: 'Bir işlemin potansiyel kârının, potansiyel zararına oranı.',
      category: EducationTopicCategory.strategies,
      subCategory: 'Risk Yönetimi',
      icon: Icons.balance_rounded,
      content: '''
# Risk/Reward Ratio Nedir?
Bir işlemde kazanabileceğiniz tutarın, kaybedebileceğiniz tutara oranıdır.

## Hesaplama
R:R = (Take Profit - Giriş) / (Giriş - Stop Loss)

## Örnek
- Giriş: 100 USDT
- Stop Loss: 95 USDT (5 USDT risk)
- Take Profit: 110 USDT (10 USDT kâr)
- R:R = 10/5 = 2:1 (İki birim kâr, bir birim risk)

## Minimum Oran
Profesyonel traderlar minimum 1:2 R:R oranında işlem yaparlar. Yani her 1 dolar risk için 2 dolar kâr hedeflerler.

## Başarı Formülü
%50 başarı oranıyla bile 1:2 R:R ile uzun vadede kârlı olursunuz.

## Kripteks Botu
Bot kurarken Take Profit ve Stop Loss'u R:R'ye göre ayarlayarak matematiksel avantaj elde edersiniz.
''',
    ),

    // Temel Kavramlar
    EducationTopic(
      id: 'bull-bear',
      title: 'Boğa ve Ayı Piyasası',
      description: 'Piyasa trendlerini ifade eden temel terimler.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Piyasa Bilgisi',
      icon: Icons.compare_arrows_rounded,
      content: '''
# Trendleri Anlamak
Kripto para piyasasında yön genellikle iki sembolle ifade edilir:

## Boğa (Bull) Piyasası
Fiyatların genel olarak yükseldiği, yatırımcıların iyimser olduğu dönemlerdir. Adını, boğanın boynuzlarını aşağıdan yukarıya vurmasından alır.

## Ayı (Bear) Piyasası
Fiyatların genel olarak düştüğü, kötümserliğin hakim olduğu dönemlerdir. Adını, ayının pençesini yukarıdan aşağıya vurmasından alır.
''',
    ),
    EducationTopic(
      id: 'fomo-fud',
      title: 'FOMO ve FUD',
      description:
          'Piyasa psikolojisini yönetmek için bilmeniz gereken iki kavram.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Psikoloji',
      icon: Icons.psychology_alt_rounded,
      content: '''
# Yatırımcı Psikolojisi
Kripto paralar, psikolojinin en yoğun yaşandığı piyasalarlar.

## FOMO (Fear Of Missing Out)
"Fırsatı kaçırma korkusu" anlamına gelir. Fiyat hızla yükselirken en tepeden alım yapma hatasına düşmektir.

## FUD (Fear, Uncertainty, Doubt)
"Korku, Belirsizlik ve Şüphe" demektir. Kötü haberlerle piyasada panik yaratarak varlıkları en dip fiyattan sattırma çabasıdır.

## Altın Kural
Başkaları açgözlü olduğunda kork, başkaları korktuğunda açgözlü ol.
''',
    ),
    EducationTopic(
      id: 'liquidity',
      title: 'Likidite Nedir?',
      description: 'Bir varlığın nakde dönüştürülme hızı ve kolaylığı.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Piyasa Bilgisi',
      icon: Icons.water_drop_rounded,
      content: '''
# Likidite Kavramı
Likidite, bir varlığı fiyatını çok fazla etkilemeden hızlıca alıp satabilme kapasitesidir.

## Neden Önemli?
- **Yüksek Likidite:** Bitcoin gibi varlıklarda alım-satım farkı azdır, işlem kolaydır.
- **Düşük Likidite:** Küçük altcoinlerde büyük bir satış yapmaya kalktığınızda fiyat hızla çökebilir (Slippage).

## Kripteks Tavsiyesi
Botlarınızı her zaman likiditesi yüksek (yüksek hacimli) paritelerde çalıştırmanız, ani fiyat kaymalarından korunmanızı sağlar.
''',
    ),
    EducationTopic(
      id: 'blockchain-basics',
      title: 'Blockchain Nedir?',
      description:
          'Kripto paraların temelini oluşturan blokzincir teknolojisi.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Teknoloji',
      icon: Icons.link_rounded,
      content: '''
# Blockchain (Blokzincir) Teknolojisi
Blockchain, verilerin şifrelenmiş bir şekilde, birbirine bağlı bloklar halinde saklandığı dağıtık bir kayıt sistemidir.

## Temel Özellikler:
- **Merkeziyetsizlik:** Veriler tek bir sunucuda değil, binlerce bilgisayarda (node) aynı anda tutulur.
- **Şeffaflık:** Yapılan tüm işlemler herkes tarafından görülebilir ancak değiştirilemez.
- **Güvenlik:** Bir bloğu değiştirmek için ağdaki diğer tüm blokları da değiştirmek gerekir, bu da hacklenmeyi imkansız hale getirir.

## Neden Önemli?
Aracıları (bankalar vb.) aradan kaldırarak doğrudan kişiden kişiye (P2P) güvenli transfer sağlar.
''',
    ),
    EducationTopic(
      id: 'market-cap-vs-supply',
      title: 'Market Cap ve Arz İlişkisi',
      description: 'Bir projenin değerini sadece fiyata bakarak ölçmeyin.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Ekonomi',
      icon: Icons.analytics_rounded,
      content: '''
# Piyasa Değeri (Market Cap)
Market Cap = Mevcut Fiyat × Dolaşımdaki Arz

## Kavramlar:
- **Circulating Supply:** Şu an piyasada alınıp satılabilen miktar.
- **Total Supply:** Üretilmiş toplam miktar.
- **Max Supply:** Gelecekte üretilebilecek maksimum miktar (Örn: BTC için 21 Milyon).

## Hata:
"Bu coin 1 dolar, Bitcoin 50 bin dolar, o zaman bu çok ucuz" demek yanlıştır. Önemli olan piyasa değeridir. Arzı trilyonlarca olan bir coinin 1 dolar olması imkansız olabilir.
''',
    ),
    EducationTopic(
      id: 'bitcoin-halving-logic',
      title: 'Bitcoin Halving (Yarılanma)',
      description: '4 yılda bir gerçekleşen bu olay neden fiyatı etkiler?',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Ekonomi',
      icon: Icons.hourglass_empty_rounded,
      content: '''
# Bitcoin Halving Nedir?
Madencilere verilen ödüllerin her 210.000 blokta bir (yaklaşık 4 yıl) yarı yarıya düşürülmesidir.

## Neden Yapılır?
- **Enflasyon Kontrolü:** Yeni BTC arzını azaltarak kıtlık yaratır.
- **Değer Koruma:** Arz azalıp talep sabit kalırsa veya artarsa fiyat yükselme eğilimine girer.

## Tarihsel Etki:
Geçmişteki tüm halving olaylarından sonraki 12-18 ay içinde Bitcoin genellikle yeni bir tarihi zirve (ATH) yapmıştır.
''',
    ),
    EducationTopic(
      id: 'stablecoin-types',
      title: 'Stablecoin Nedir ve Türleri',
      description: 'Fiyatı sabit varlıklara endeksli kripto paralar.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Ekonomi',
      icon: Icons.monetization_on_rounded,
      content: '''
# Stablecoin (Stabil Coin)
Fiyatı genellikle Amerikan Doları (USDT, USDC) gibi bir varlığa sabitlenmiş kripto paralardır.

## Türleri:
1. **İtibari Para Destekli:** Kasasında her 1 coin için 1 dolar tutanlar (Örn: USDT, USDC). En güvenli kabul edilenlerdir.
2. **Kripto Destekli:** Başka bir kripto parayı teminat gösterenler (Örn: DAI).
3. **Algoritmik:** Yazılımsal olarak arz-talep dengesiyle fiyatı sabitlemeye çalışanlar. Riskleri daha yüksektir.

## Kullanım Amacı:
Piyasadaki sert düşüşlerden korunmak (nakde geçmek) ve borsalar arası hızlı transfer yapmak.
''',
    ),
    EducationTopic(
      id: 'cex-vs-dex-guide',
      title: 'CEX vs DEX: Hangi Borsa?',
      description: 'Merkezi ve merkeziyetsiz borsalar arasındaki farklar.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Piyasa Bilgisi',
      icon: Icons.account_balance_rounded,
      content: '''
# Borsa Türleri
Kripto para ticareti yaptığınız platformlar iki ana gruba ayrılır.

## CEX (Merkezi Borsalar):
- **Örnekler:** Binance, Coinbase.
- **Artıları:** Kullanımı kolaydır, müşteri desteği vardır, hızlıdır.
- **Eksileri:** Varlıklarınız borsanın kontrolündedir.

## DEX (Merkeziyetsiz Borsalar):
- **Örnekler:** Uniswap, PancakeSwap.
- **Artıları:** Varlıklar kendi cüzdanınızdadır, kimlik doğrulama (KYC) gerektirmez.
- **Eksileri:** Kullanımı daha zordur, hata yaparsanız telafisi yoktur.
''',
    ),
    EducationTopic(
      id: 'altseason-concept',
      title: 'Altcoin Sezonu (Altseason)',
      description: 'Paranın Bitcoin\'den altcoinlere geçtiği o büyülü dönem.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Piyasa Bilgisi',
      icon: Icons.auto_awesome_motion_rounded,
      content: '''
# Altseason Nedir?
Bitcoin fiyatının yatay seyrettiği veya hafif yükseldiği dönemde, yatırımcıların daha büyük kârlar için altcoinlere yönelmesiyle oluşan rallidir.

## Nasıl Anlaşılır?
- **Bitcoin Dominance (Süreç):** BTC'nin toplam piyasa değerindeki payının düşmesi.
- **ETH Yükselişi:** Genellikle Ethereum'un Bitcoin'den daha iyi performans göstermesi altseason habercisidir.
- **Hacim Artışı:** Altcoin paritelerinde işlem hacminin aniden yükselmesi.

## Dikkat:
Altcoinler çok hızlı yükseldiği gibi çok sert de düşebilirler. Botlarınızı kurarken bu volatiliteyi hesaba katın.
''',
    ),
    EducationTopic(
      id: 'smart-contracts',
      title: 'Akıllı Kontratlar (Smart Contracts)',
      description: 'Programlanabilir paranın arkasındaki mantık.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Teknoloji',
      icon: Icons.terminal_rounded,
      content: '''
# Akıllı Kontratlar
Belirli koşullar yerine getirildiğinde otomatik olarak çalışan dijital sözleşmelerdir.

## Nasıl Çalışır?
"Eğer A olursa, B'yi yap" mantığıyla çalışırlar. Aracısız (avukat, noter vb.) güven inşa ederler.

## Kullanım Alanları:
- **DeFi:** Otomatik borç alma ve verme.
- **NFT:** Dijital sanat eserlerinin sahiplik onayı.
- **DAO:** Toplulukların oylama ile yönetilmesi.

Ethereum, akıllı kontratları dünyaya tanıtan ilk blockchain'dir.
''',
    ),
    EducationTopic(
      id: 'whitepaper-reading',
      title: 'Whitepaper Nasıl Okunur?',
      description:
          'Bir projeye yatırım yapmadan önce incelemeniz gereken anayasa.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Piyasa Bilgisi',
      icon: Icons.description_outlined,
      content: '''
# Whitepaper Nedir?
Bir projenin amacını, teknolojisini ve ekonomisini (tokenomics) anlatan resmi dökümandır.

## Kritik Sorular:
- Bu proje hangi sorunu çözüyor?
- Token ne işe yarıyor? (Utility)
- Ekip kimlerden oluşuyor ve geçmişleri ne?
- Yol haritası (Roadmap) gerçekçi mi?

Eğer bir projenin whitepaper'ı kopyalanmışsa veya sadece fiyat odaklıysa, bu bir risk sinyali (Red Flag) olabilir.
''',
    ),
    EducationTopic(
      id: 'bull-trap-bear-trap',
      title: 'Boğa ve Ayı Tuzakları',
      description: 'Fiyatın ters yöne dönecekmiş gibi yapıp sizi yanıltması.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Psikoloji',
      icon: Icons.warning_amber_rounded,
      content: '''
# Piyasa Tuzakları
Profesyonel oyuncuların deneyimsiz yatırımcıları ters köşe yapmak için oluşturduğu hareketlerdir.

## Boğa Tuzağı (Bull Trap):
Fiyat direnci kırıyormuş gibi yükselir, herkes "yükseliş başlıyor" diye alım yapınca sertçe düşer.

## Ayı Tuzağı (Bear Trap):
Fiyat destek altına düşüp "çöküş başlıyor" algısı yaratır, herkes panikle satınca fiyat hızla yukarı döner.

## Korunma:
İşleme girmeden önce mutlaka hacim onayı ve bir sonraki mum kapanışını bekleyin.
''',
    ),
    EducationTopic(
      id: 'hodl-mentality',
      title: 'HODL Mantığı ve Uzun Vade',
      description: 'Kısa vadeli dalgalanmaları görmezden gelme sanatı.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Psikoloji',
      icon: Icons.volunteer_activism_rounded,
      content: '''
# HODL Nedir?
Bir Bitcoin forumunda yanlışlıkla yazılan "HOLD" (Tut) kelimesinden doğmuştur. Fiyata bakmaksızın uzun vadeli varlık saklamayı ifade eder.

## Neden HODL?
- **Duygusal Azlık:** Her gün ekrana bakıp panik yapmanızı engeller.
- **Zaman Tasarrufu:** Sürekli trade yapma yorgunluğunu ortadan kaldırır.
- **Vergi Avantajı:** Birçok ülkede uzun vadeli tutulan varlıklar daha az vergiye tabidir.

Kripteks ile kâr alıp, ana sermayenizin bir kısmını HODL cüzdanınıza aktararak dengeli bir portföy oluşturabilirsiniz.
''',
    ),
    EducationTopic(
      id: 'fa-vs-ta-guide',
      title: 'Temel vs Teknik Analiz',
      description:
          'Hangi analiz yöntemi size daha uygun? İkisinin farklarını öğrenin.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Piyasa Bilgisi',
      icon: Icons.fact_check_rounded,
      content: '''
# Analiz Yöntemleri
Başarılı bir yatırımcı her iki yöntemi de harmanlayarak kullanır.

## Teknik Analiz (TA):
- **Odak:** "Ne zaman almalıyım?" sorusuna yanıt arar.
- **Araçlar:** Grafikler, indikatörler, hacim ve fiyat hareketleri.
- **Mantık:** "Geçmişte olan gelecekte de olur."

## Temel Analiz (FA):
- **Odak:** "Neyi almalıyım?" sorusuna yanıt arar.
- **Araçlar:** Haberler, ekip kadrosu, ortaklıklar, token ekonomisi ve kullanım alanı.
- **Mantık:** "Değeri düşük kalmış (undervalued) varlıkları bul."

## Kripteks İpucu:
FA ile potansiyel coinleri bulun, Kripteks Tarayıcı (TA) ile doğru giriş zamanını yakalayın.
''',
    ),
    EducationTopic(
      id: 'order-book-depth-logic',
      title: 'Emir Defteri ve Derinlik',
      description:
          'Fiyatın nasıl oluştuğunu ve "Buy/Sell Wall" kavramlarını anlayın.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Piyasa Bilgisi',
      icon: Icons.reorder_rounded,
      content: '''
# Marketin Arka Planı
Emir defteri, alıcı ve satıcıların bekleyen emirlerinin listesidir.

## Kavramlar:
- **Bid (Alış):** Alıcıların almak istediği fiyatlar.
- **Ask (Satış):** Satıcıların satmak istediği fiyatlar.
- **Depth (Derinlik):** Belirli fiyattaki emirlerin toplam miktarı.

## Buy/Sell Wall (Duvarlar):
Eğer bir fiyat seviyesinde çok büyük miktarda alım veya satım emri varsa buna "duvar" denir. Fiyatın bu seviyeyi aşması için o büyük miktarın tamamen tüketilmesi gerekir.
''',
    ),
    EducationTopic(
      id: 'slippage-and-spread',
      title: 'Slippage (Kayma) ve Spread',
      description: 'Gördüğünüz fiyattan neden farklı alım yaptığınızı öğrenin.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Piyasa Bilgisi',
      icon: Icons.sync_problem_rounded,
      content: '''
# Gizli İşlem Maliyetleri
İşlem yaparken sadece komisyon ödemezsiniz, bazen spread ve slippage da kârınızı etkiler.

## Spread (Fark):
En yüksek alış emri ile en düşük satış emri arasındaki farktır. Hacimsiz tahtalarda bu fark çok açılabilir.

## Slippage (Kayma):
Siz "Market" emri verdiğinizde, tahtadaki emirlerin yetersiz kalması sonucu işleminizin daha üst (veya alt) fiyatlardan gerçekleşmesidir.

## Korunma:
Hacimsiz coinlerde yüksek tutarlı market emirleri vermekten kaçının. Kripteks ile limit emirleri kullanarak alım fiyatınızı sabitleyebilirsiniz.
''',
    ),
    EducationTopic(
      id: 'tokenomics-concepts',
      title: 'Token Ekonomisi (Tokenomics)',
      description: 'Enflasyonist ve deflasyonist modellerin fiyata etkisi.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Ekonomi',
      icon: Icons.savings_rounded,
      content: '''
# Tokenomics Nedir?
Bir kripto paranın arz miktarını, dağıtımını ve kullanımını belirleyen kurallar bütünüdür.

## Kritik Parametreler:
- **Burn (Yakım):** Arzı azaltıp değeri artırmak için sistemden coin çıkarılması.
- **Staking Rewards:** Arzın artmasına (enflasyon) neden olan yeni coin basımları.
- **Vesting:** Kurucu ekibin coinlerini hemen satamaması için kilitli tutulması.

## Neden Bakılmalı?
Arzı sürekli ve kontrolsüz artan bir projenin fiyatının uzun vadede yükselmesi matematiksel olarak zordur.
''',
    ),
    EducationTopic(
      id: 'wallet-types-security',
      title: 'Sıcak ve Soğuk Cüzdanlar',
      description: 'Varlıklarınızı nerede saklamalısınız? Güvenlik dereceleri.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Güvenlik',
      icon: Icons.admin_panel_settings_rounded,
      content: '''
# Cüzdan Rehberi
Kriptoda bir söz vardır: "Not your keys, not your coins." (Anahtarlar senin değilse, paralar senin değildir.)

## Sıcak Cüzdan (Hot Wallet):
İnternete bağlı yazılımlardır (Örn: Trust Wallet, MetaMask).
- **Artı:** Hızlı ve kolay erişim.
- **Eksi:** Online oldukları için hacklenme riski taşırlar.

## Soğuk Cüzdan (Cold Wallet):
Donanımsal, internete kapalı cihazlardır (Örn: Ledger, Trezor).
- **Artı:** En üst düzey güvenlik. Offline oldukları için hacklenemezler.
- **Eksi:** Kullanımı daha hantaldır.

## Tavsiye:
Günlük bot işlemleriniz için borsada (CEX) para bulundururken, uzun vadeli birikimlerinizi mutlaka bir soğuk cüzdana çekin.
''',
    ),
    EducationTopic(
      id: 'gas-fees-and-traffic',
      title: 'Gas Ücretleri ve Ağ Trafiği',
      description: 'Transfer yaparken neden yüksek ücret ödersiniz?',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Teknoloji',
      icon: Icons.gas_meter_rounded,
      content: '''
# Gas Nedir?
Blockchain üzerinde bir işlem yapmak için ağdaki madencilere veya onaylayıcılara ödenen işlem ücretidir.

## Neden Değişir?
Ağdaki trafik ne kadar yoğunsa (Örn: Popüler bir NFT satışı varsa), işlemlerinizin sıraya girmesi için ödemeniz gereken ücret o kadar artar.

## Tasarruf İpuçları:
- İşlemlerinizi ağın sakin olduğu saatlerde (Genellikle hafta sonu gece saatleri) yapın.
- Katman 2 (Layer 2) ağlarını (Arbitrum, Optimism vb.) kullanarak çok daha düşük ücretler ödeyin.
''',
    ),
    EducationTopic(
      id: 'scams-rug-pull-warning',
      title: 'Dolandırıcılık Türleri ve Rug Pull',
      description: 'Varlıklarınızı kaybetmemek için bu tuzaklara dikkat edin.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Güvenlik',
      icon: Icons.gpp_bad_rounded,
      content: '''
# Karanlık Taraf
Maalesef kripto dünyasında dolandırıcılar çok aktiftir.

## Rug Pull (Halı Çekme):
Geliştiricilerin projenin likiditesini aniden çekip kaçmasıdır. Sosyal medyada çok parlatılan ama teknik altyapısı olmayan coinlere dikkat edin.

## Phishing (Oltalama):
Size "bedava token" vereceğini vaat eden sahte sitelere cüzdanınızı bağlamayın. Kelime listenizi (Seed phrase) ASLA kimseyle paylaşmayın.

## Altın Kural:
Bir şey gerçek olamayacak kadar iyi görünüyorsa (%100 günlük kazanç vaadi vb.), muhtemelen bir dolandırıcılıktır.
''',
    ),
    EducationTopic(
      id: 'funding-rate-importance',
      title: 'Funding Rate (Fonlama Oranı)',
      description: 'Vadeli işlemlerin spot fiyatına etkisini öğrenin.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Ekonomi',
      icon: Icons.currency_lira_rounded,
      content: '''
# Funding Rate Nedir?
Sürekli vadeli işlemler (Perpetual Futures) ile spot fiyat arasındaki farkı minimize eden periyodik ödemelerdir.

## Neden İzlemeliyiz?
- **Pozitif Funding:** Long açanların sayısı çok fazla demektir. Piyasa aşırı ısınmış olabilir ve bir düzeltme (long liquidation) gelebilir.
- **Negatif Funding:** Short açanlar çoğunluktadır. "Short Squeeze" denilen ani bir yükseliş dalgasını tetikleyebilir.

## Kripteks Notu:
Fonlama oranlarını takip etmek, piyasanın genel psikolojisini ölçmenin en teknik yollarından biridir.
''',
    ),
    EducationTopic(
      id: 'market-cycles-wyckoff',
      title: 'Piyasa Döngüleri ve Wyckoff',
      description: 'Piyasanın 4 ana evresini tanıyarak yönü tayin edin.',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Psikoloji',
      icon: Icons.cyclone_rounded,
      content: '''
# Wyckoff Metodu
Market her zaman şu 4 evrede hareket eder:

1. **Birikim (Accumulation):** Büyük oyuncuların sessizce alım yaptığı, fiyatın yatay gittiği evre.
2. **Yükseliş (Markup):** Fiyatın dirençleri kırıp hızla yükseldiği, medyanın konuşmaya başladığı evre.
3. **Dağıtım (Distribution):** Büyük oyuncuların kâr realize edip malı devrettiği tepe evresi.
4. **Düşüş (Markdown):** Herkesin panikle sattığı, ayı piyasası evresi.

## Strateji:
En büyük kârlar "Birikim" evresinin sonunda, yükseliş başlamadan hemen önce girildiğinde elde edilir.
''',
    ),
    EducationTopic(
      id: 'impermanent-loss-defi',
      title: 'Geçici Kayıp (Impermanent Loss)',
      description: 'Likidite sağlayıcılar için en büyük risk nedir?',
      category: EducationTopicCategory.fundamentals,
      subCategory: 'Ekonomi',
      icon: Icons.trending_down_rounded,
      content: '''
# Impermanent Loss (IL)
Merkeziyetsiz borsalarda (DEX) likidite sağlarken, coinlerin fiyatı arasındaki dengenin bozulması sonucu yaşanan kâr kaybıdır.

## Nasıl Oluşur?
Likidite havuzuna koyduğunuz iki varlıktan biri aşırı yükselirse, havuz kendini dengelemek için o coini satar. Eğer coini sadece cüzdanınızda tutsaydınız (HODL), havuzda durmasından daha kârlı olabilirdiniz.

## Not:
Eğer fiyatlar tekrar havuzu kurduğunuz seviyeye dönerse bu kayıp sıfırlanır, bu yüzden adı "Geçici Kayıp"tır.
''',
    ),

    // Kripteks Uygulama Eğitimleri
    EducationTopic(
      id: 'how-to-create-bot',
      title: 'Nasıl Bot Oluşturulur?',
      description: 'İlk ticaret botunuzu 1 dakika içinde kurun ve çalıştırın.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Kurulum',
      icon: Icons.add_to_photos_rounded,
      content: '''
# Kripteks Bot Kurulumu
Kripteks'te bot oluşturmak oldukça basittir. İşte adım adım süreç:

## 1. Sihirbazı Başlatın
Ana ekrandaki "+" butonuna veya "Botlarım" sekmesindeki "Yeni Bot" seçeneğine tıklayın.

## 2. Strateji Seçimi
İstediğiniz stratejiyi seçin (DCA, Grid veya Sinyal Botu). Her stratejinin altında kısa bir açıklaması bulunur.

## 3. Parametreleri Belirleyin
Botun hangi paritede çalışacağını (örneğin BTC/USDT), yatırım miktarını ve kâr hedefinizi girin. 

## 4. Test ve Başlat
Botunuzu başlatmadan önce "Geriye Dönük Test" (Backtest) yaparak geçmişte nasıl performans göstereceğini görebilirsiniz. Her şey hazırsa "Başlat" butonuna basın.

## İpucu
Düşük bakiye ile başlayıp botun performansını gözlemlemek, stratejinizi geliştirmek için en iyi yoldur.
''',
    ),
    EducationTopic(
      id: 'market-scanner-guide',
      title: 'Piyasa Tarayıcı Kullanımı',
      description:
          'Binance üzerindeki binlerce pariteyi saniyeler içinde analiz edin.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Analiz Araçları',
      icon: Icons.radar_rounded,
      content: '''
# Piyasa Tarayıcı (Scanner) Nedir?
Piyasa tarayıcı, belirlediğiniz teknik kriterlere uyan kripto paraları anlık olarak bulmanızı sağlar.

## Kriter Belirleme
Hangi zaman diliminde (1s, 4s, Günlük) ve hangi indikatör kesişimlerinde (RSI < 30, Golden Cross vb.) tarama yapmak istediğinizi seçin.

## Filtreleri Kullanın
Yalnızca yüksek hacimli veya belirli bir fiyat aralığındaki pariteleri görmek için filtreleri kullanabilirsiniz.

## Hızlı Bot Kurulumu
Tarayıcıda beğendiğiniz bir fırsat bulduğunuzda, üzerine tıklayarak o parite için saniyeler içinde bot kurabilirsiniz.
''',
    ),
    EducationTopic(
      id: 'binance-api-setup',
      title: 'Binance API Ayarları',
      description: 'Hesabınızı güvenli bir şekilde Kripteks\'e bağlayın.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Kurulum',
      icon: Icons.api_rounded,
      content: '''
# API Bağlantısı Rehberi
Botlarınızın Binance üzerinde işlem yapabilmesi için API anahtarlarına ihtiyacı vardır.

## Güvenlik Önceliğimiz
Kripteks, API anahtarlarınızı cihazınızda şifreli olarak saklar. **Asla "Para Çekme" (Withdrawal) yetkisi vermeyin.** Sadece "Spot Trading" yetkisi yeterlidir.

## Adımlar:
1. Binance hesabınıza girin ve **API Yönetimi**'ne gidin.
2. Yeni bir API anahtarı oluşturun ve isimlendirin.
3. **API Key** ve **Secret Key** bilgilerini not edin.
4. Kripteks Ayarlar menüsünden "Binance API" kısmına bu bilgileri girin.

## Önemli Not
API anahtarınızın "Enable Spot & Margin Trading" seçeneğinin işaretli olduğundan emin olun.
''',
    ),
    EducationTopic(
      id: 'portfolio-tracking',
      title: 'Varlık ve Cüzdan Takibi',
      description: 'Toplam bakiyenizi ve botlarınızın performansını izleyin.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Bot Yönetimi',
      icon: Icons.account_balance_wallet_rounded,
      content: '''
# Cüzdan Yönetimi
Kripteks üzerinden tüm varlıklarınızı tek bir yerden görebilirsiniz.

## Varlık Dağılımı
Cüzdan sekmesinde hangi coin'den ne kadar olduğunu ve toplam dolar karşılığını görebilirsiniz.

## İşlem Geçmişi
Botlarınızın yaptığı tüm alım-satım işlemlerini "Geçmiş" sekmesinden detaylıca inceleyebilirsiniz.

## Performans Analizi
Hangi stratejinin daha kârlı olduğunu görmek için günlük ve haftalık PNL (Kâr/Zarar) grafiklerini takip edin.
''',
    ),
    EducationTopic(
      id: 'backtest-guide',
      title: 'Strateji Test Etme (Backtest)',
      description: 'Botunuzu yayına almadan önce geçmiş verilerle test edin.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Bot Yönetimi',
      icon: Icons.history_rounded,
      content: '''
# Backtest Nasıl Yapılır?
Paranızı riske atmadan önce stratejinizi geçmiş fiyat hareketleri üzerinde deneyin.

## Test Adımları:
- **Parite ve Zaman:** Test etmek istediğiniz işlem çiftini ve tarih aralığını seçin.
- **Başlangıç Bakiyesi:** Testin ne kadarlık bir bütçe ile simüle edileceğini belirleyin.
- **Strateji Ayarları:** Botun kullanacağı indikatör ve kâr hedeflerini girin.
- **Analiz:** "Testi Çalıştır" butonuna basın ve sonuçları bekleyin.

## Sonuçları Okuma:
- **Net Kâr:** Stratejinin toplam kazancı.
- **Başarı Oranı (Win Rate):** Kârlı biten işlemlerin yüzdesi.
- **Max Drawdown:** Başlangıçtan itibaren yaşanan en büyük düşüş oranı (Risk ölçüsü).
- **Monte Carlo:** Gelecekteki olası senaryoları görmek için "Monte Carlo" simülasyonunu kullanın.
''',
    ),
    EducationTopic(
      id: 'bot-management-tips',
      title: 'Bot Yönetimi ve Müdahale',
      description:
          'Aktif botlarınızın kontrol altında tutulmasının püf noktaları.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Bot Yönetimi',
      icon: Icons.settings_suggest_rounded,
      content: '''
# Bot Kontrol Paneli
Aktif botlarınızı yönetmek, kârınızı korumak için kritiktir.

## İzleme Seçenekleri:
- **Canlı Takip:** Botunuzun şu anki durumunu (Alış Bekliyor, Satış Bekliyor) anlık görün.
- **Gerçek Zamanlı Kar/Zarar:** Pozisyonun mevcut durumunu yüzde ve dolar cinsinden takip edin.
- **Sinyal Logları:** Botun neden işleme girdiğini teknik loglardan inceleyin.

## Müdahale Yöntemleri:
- **Durdur (Pause):** Botu geçici olarak durdurur, mevcut pozisyonu kapatmaz.
- **Kapat ve Sat (Close & Sell):** Botu tamamen kapatır ve eldeki varlığı piyasa fiyatından hemen satar.
- **Parametre Değişimi:** Bot çalışırken kâr alma hedefini veya durdurma seviyesini güncelleyebilirsiniz.
''',
    ),
    EducationTopic(
      id: 'market-intel',
      title: 'Market Intelligence Kullanımı',
      description:
          'Trendleri piyasadan önce yakalamak için AI araçlarını kullanın.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Analiz Araçları',
      icon: Icons.auto_awesome_rounded,
      content: '''
# Piyasa İstihbarat Araçları
Fiyat hareketlerinin arkasındaki temel nedenleri anlamak için bu araçları kullanın.

## Önemli Özellikler:
- **Duygu Analizi (Sentiment):** Haberlerin ve sosyal medyanın piyasa üzerindeki etkisini yapay zeka ile analiz edin (Pozitif, Negatif, Nötr).
- **Haber Akışı:** CryptoPanic entegrasyonu ile tüm önemli gelişmeleri filtrelenmiş şekilde takip edin.
- **Fear & Greed Index:** Piyasanın genel "Korku" veya "Açgözlülük" seviyesini görerek ters işlem yapma hatasından kaçının.
- **Balina Takibi:** Büyük cüzdan hareketlerini izleyerek market yapıcıların yönünü tayin edin.
''',
    ),
    EducationTopic(
      id: 'risk-management',
      title: 'Risk ve Kasa Yönetimi',
      description:
          'Sermayenizi korumak için uygulamanız gereken altın kurallar.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Güvenlik & Destek',
      icon: Icons.security_rounded,
      content: '''
# Güvenli Ticaret İlkeleri
Kripteks ile işlem yaparken sermayenizi korumak, kâr etmekten daha önemlidir.

## Temel Kurallar:
- **Yüzde Kuralı:** Tek bir bota asla kasanızın tamamını bağlamayın. İdeal olan %10-%20 arasıdır.
- **Stop-Loss Kullanımı:** Beklenmedik düşüşlerde kaybınızı sınırlamak için mutlaka Stop-Loss seviyesi belirleyin.
- **Kademeli Giriş (DCA):** Fiyat düşerken maliyeti düşürmek için bakiyenizi bölerek kullanın.
- **Duyguları Yönetin:** Botlar sizin yerinize stratejiye sadık kalır; sabırlı olun ve botun işini yapmasına izin verin.
''',
    ),
    EducationTopic(
      id: 'strategy-comparison',
      title: 'Grid mi, DCA mi? Strateji Seçimi',
      description: 'Piyasa koşullarına göre en doğru bot tipini seçme rehberi.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Kurulum',
      icon: Icons.compare_rounded,
      content: '''
# Strateji Karşılaştırması
Hangi botun ne zaman daha kârlı olduğunu anlamak, başarının anahtarıdır.

## Grid (Izgara) Botu:
- **Ne Zaman Kullanılır?** Piyasa yatay (sideways) seyrediyorsa ve belirli bir aralıkta gidip geliyorsa.
- **Nasıl Kâr Eder?** Her küçük düşüşte alır, her küçük yükselişte satar. Sık işlem yapar.
- **Risk:** Fiyat işlem aralığının dışına sert çıkarsa bot beklemeye geçer.

## DCA (Maliyet Azaltma) Botu:
- **Ne Zaman Kullanılır?** Net bir trend varsa (yükseliş beklenen piyasalar) veya sert düşüşlerde maliyet düşürmek için.
- **Nasıl Kâr Eder?** Fiyat düştükçe alım yapar, ortalamayı düşürür ve ilk tepki yükselişinde tüm pozisyonu kârla kapatır.
- **Risk:** Piyasa durmaksızın düşerse kasa limitsiz değildir, dikkatli bütçe yönetimi gerektirir.

## Sinyal Botu:
- **Ne Zaman Kullanılır?** Teknik indikatörler (RSI, MACD vb.) belirli bir sinyal verdiğinde tek seferlik veya trend takipli işlemler için.
''',
    ),
    EducationTopic(
      id: 'notifications-guide',
      title: 'Bildirimler ve Anlık Uyarılar',
      description:
          'Botlarınız işlem yaptığında veya önemli bir sinyal geldiğinde haberdar olun.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Güvenlik & Destek',
      icon: Icons.notifications_active_rounded,
      content: '''
# Bildirim Yönetimi
Piyasayı 7/24 takip edemeyebilirsiniz, ancak Kripteks sizin için bunu yapar.

## Bildirim Türleri:
- **İşlem Bildirimleri:** Bot bir alım veya satım yaptığında anında telefonunuza düşer.
- **Fiyat Uyarıları:** Belirlediğiniz bir coin belirlediğiniz fiyata ulaştığında uyarı alırsınız.
- **Strateji Sinyalleri:** Taramada kriterlerinize uygun bir coin bulunduğunda "Yeni Fırsat" bildirimi gelir.

## Ayarlar:
- Uygulama içindeki **Ayarlar > Bildirimler** kısmından hangi tür uyarıları almak istediğinizi özelleştirebilirsiniz.
- Önemli bot işlemlerini kaçırmamak için bildirim izinlerinin açık olduğundan emin olun.
''',
    ),
    EducationTopic(
      id: 'troubleshooting',
      title: 'Sık Karşılaşılan Sorunlar',
      description: 'Botunuz neden çalışmıyor? Hızlı çözüm rehberi.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Güvenlik & Destek',
      icon: Icons.help_outline_rounded,
      content: '''
# Sorun Giderme (Troubleshooting)
Eğer bir şeyler ters giderse, genellikle nedeni şunlardan biridir:

## 1. Yetersiz Bakiye (Insufficient Balance)
- En sık rastlanan hatadır. Spot cüzdanınızda botun alım yapması için yeterli **USDT** (veya ilgili parite) olduğundan emin olun.

## 2. API Yetki Hataları
- Binance API anahtarınızda "Enable Spot & Margin Trading" seçeneğinin işaretli olduğundan emin olun.
- IP kısıtlaması yaptıysanız, Kripteks'in güncel IP adreslerini eklemeniz gerekir.

## 3. Minimum İşlem Tutarı
- Binance, genellikle her bir alım satım için minimum 10 USDT kısıtlaması uygular. Botunuzun adım tutarlarının bu limitin üzerinde olduğundan emin olun.

## 4. Senkronizasyon Sorunları
- Eğer bakiye yanlış görünüyorsa, cüzdan sayfasındaki "Yenile" butonuna basarak verileri güncelleyin.
''',
    ),
    EducationTopic(
      id: 'security-safety',
      title: 'Güvenlik ve Hesap Koruması',
      description: 'Varlıklarınızı en üst düzeyde nasıl korursunuz?',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Güvenlik & Destek',
      icon: Icons.lock_person_rounded,
      content: '''
# Güvenliğiniz Bizim İçin Önemli
Kripto dünyasında güvenlik, kazançtan önce gelir.

## Uygulama İçi Güvenlik:
- **Biometrik Giriş:** Ayarlar menüsünden FaceID veya Parmak İzi özelliğini aktif ederek uygulamayı kilitleyin.
- **Şifreli Depolama:** API anahtarlarınız telefonunuzun güvenli alanında (Keychain/Secure Storage) şifrelenmiş olarak saklanır.

## API Güvenliği Tavsiyeleri:
- **Para Çekme Yetkisi VERMEYİN:** API oluştururken "Enable Withdrawals" kutusunun ASLA işaretli olmadığından emin olun. Kripteks'in paralarınıza dokunma yetkisi olmamalıdır.
- **Düzenli Yenileme:** Güvenlik için 90 günde bir API anahtarlarınızı yenilemek iyi bir uygulamadır.
''',
    ),
    EducationTopic(
      id: 'advanced-signals-deep-dive',
      title: 'Sinyal Botu ve Teknik Onaylar',
      description:
          'Botunuzun işleme girmesi için gereken teknik koşulları özelleştirin.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Analiz Araçları',
      icon: Icons.psychology_rounded,
      content: '''
# Sinyal Botu Nasıl Çalışır?
Sinyal botları, belirli bir fiyat beklentisi yerine teknik indikatörlerin "AL" sinyali üretmesini bekler.

## Onay Mekanizmaları:
- **Tekli Sinyal:** Sadece bir indikatör (örneğin RSI) istediğiniz seviyeye geldiğinde işlem açılır.
- **Çoklu Onay (Kombinasyon):** Hem RSI aşırı satım bölgesinde olmalı hem de MACD yukarı kesişim yapmalı gibi kurallar koyabilirsiniz.
- **Zaman Dilimi Uyumu:** 1 saatlik grafikte gelen sinyali, 4 saatlik trend ile teyit ederek hata payını düşürebilirsiniz.

## Neden Sinyal Botu?
Sinyal botları "her zaman" işlemde kalmak yerine sadece piyasa koşulları uygun olduğunda pozisyon açar, bu da sermaye verimliliğini artırır.
''',
    ),
    EducationTopic(
      id: 'tradingview-integration',
      title: 'Yazılım İçinde Grafik Analizi',
      description:
          'TradingView entegrasyonu ile grafiklerinizi Kripteks dışına çıkmadan analiz edin.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Analiz Araçları',
      icon: Icons.bar_chart_rounded,
      content: '''
# Entegre Analiz Araçları
Kripteks, her botun ve her tarayıcı sonucunun yanında güçlü bir grafik arayüzü sunar.

## Kullanım İpuçları:
- **Tam Ekran Görünümü:** Grafiğin sağ üstündeki ikonla TradingView derinliklerine dalın.
- **Hazır İndikatörler:** Uygulama, botunuzun kullandığı RSI, Bollinger gibi indikatörleri grafik üzerine otomatik olarak ekler.
- **Trend Çizimleri:** Mobil öncelikli tasarım ile parmağınızla destek ve direnç çizgilerini kolayca çizebilirsiniz.

## İşlemden Grafiğe:
Aktif botunuzun içinden "Grafiği Gör" diyerek, botun hangi noktada alım yaptığını ve kâr alma hedefine ne kadar kaldığını görsel olarak takip edebilirsiniz.
''',
    ),
    EducationTopic(
      id: 'compound-interest-strategy',
      title: 'Bileşik Getiri (Compound) Mantığı',
      description:
          'Elde ettiğiniz kârları otomatik olarak yeni işlemlere dahil edin.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Bot Yönetimi',
      icon: Icons.trending_up_rounded,
      content: '''
# Kartopu Etkisi Yaratın
Bileşik getiri, kazandığınız kârın da size kâr getirmesi prensibidir.

## Nasıl Uygulanır?
- **Kâr Re-Yatırımı:** Bot ayarlarından "Kârı Bakiyeye Ekle" seçeneğini aktif ettiğinizde, bir sonraki işlemin bütçesi (Base Order) kâr oranında artırılır.
- **DCA ile Bileşik Getiri:** DCA botlarında kârla kapanan her pozisyon sonrası, bir sonraki turda daha büyük bir pozisyon açarak kümülatif büyümeyi hızlandırabilirsiniz.

## Dikkat Edilmesi Gerekenler:
Bileşik getiri kârı artırdığı gibi, risk miktarını (pozisyon büyüklüğünü) da artırır. Belirli aralıklarla ana sermayenizi çekip kârla devam etmek en güvenli yöntemdir.
''',
    ),
    EducationTopic(
      id: 'performance-reporting',
      title: 'Veri Analitiği ve Raporlama',
      description:
          'Haftalık ve aylık performansınızı ölçerek stratejinizi optimize edin.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Analiz Araçları',
      icon: Icons.analytics_outlined,
      content: '''
# Rakamlarla Başarıyı Ölçün
Duygularla ticaret yapmak yerine verilerle hareket edin.

## İzlenmesi Gereken Metrikler:
- **Ortalama İşlem Süresi:** Botlarınızın pozisyonları ne kadar sürede kapattığını görün (Verimlilik ölçüsü).
- **Parite Performansı:** Hangi coin paritesinde en çok kâr ettiğinizi, hangisinde stop-loss olduğunuzu analiz edin.
- **Kümülatif PNL:** Toplam bakiyenizin zaman içindeki değişim grafiğini inceleyerek genel gidişatı görün.

## Strateji Güncelleme:
Eğer bir botunuz sürekli "Waiting" (Bekliyor) durumunda kalıyorsa, tarama kriterleriniz piyasa için çok katı olabilir. Raporlardaki verilere dayanarak kriterleri esnetebilirsiniz.
''',
    ),
    EducationTopic(
      id: 'trailing-stop-loss',
      title: 'Trailing Stop (Takip Eden Zarar Kes)',
      description:
          'Kârınızı koruyarak fiyat yükselişinden maksimum fayda sağlayın.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Bot Yönetimi',
      icon: Icons.trending_up,
      content: '''
# Trailing Stop Nedir?
Fiyat yükseldikçe stop-loss seviyesini de yukarı çeken dinamik bir mekanizmadır.

## Nasıl Çalışır?
- **Aktivasyon:** Belirlediğiniz bir kâr oranına ulaşıldığında devreye girer.
- **Takip Mesafesi:** Fiyat en tepe noktadan yüzde kaç düşerse satılacağını belirlersiniz (Örn: %1).
- **Sonuç:** Fiyat yükselmeye devam ettiği sürece bot satmaz, geri dönüş başladığında kârı realize eder.

## Kripteks'te Kullanım:
Bot ayarlarında "Trailing Stop" özelliğini aktif ederek, sert yükselişlerde pozisyondan erken çıkma riskini minimize edebilirsiniz.
''',
    ),
    EducationTopic(
      id: 'whale-tracking-strategy',
      title: 'Balina Takibi ve Büyük İşlemler',
      description:
          'Market yapıcıların ayak izlerini takip ederek avantaj sağlayın.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Analiz Araçları',
      icon: Icons.waves_rounded,
      content: '''
# Balina Hareketlerini Okuma
Büyük miktardaki transferler genellikle fiyat hareketlerinin öncü sinyalidir.

## İzleme Kriterleri:
- **Borsaya Girişler:** Genellikle satış baskısı (fiyat düşüşü) beklentisi yaratır.
- **Borsadan Çıkışlar:** Yatırımcıların coinlerini uzun vadeli saklayacağını (fiyat yükselişi) gösterir.
- **Anlık Alımlar:** Tahtadaki büyük "Buy Wall"lar direnç kırılım habercisi olabilir.

## Stratejiye Entegrasyon:
Kripteks Tarayıcıda balina hareketlerinin yoğunlaştığı pariteleri bularak, hacimle desteklenmiş trendlere dahil olabilirsiniz.
''',
    ),
    EducationTopic(
      id: 'ip-whitelisting',
      title: 'IP Beyaz Liste (Güvenlik)',
      description:
          'API anahtarınızı sadece Kripteks üzerinden kullanıma kısıtlayın.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Kurulum',
      icon: Icons.vpn_lock_rounded,
      content: '''
# Maksimum API Güvenliği
API anahtarınızın çalınması durumunda bile işlem yapılmasını engellemek için IP kısıtlaması en etkili yöntemdir.

## Neden Zorunlu Değil ama Tavsiye Edilir?
IP kısıtlaması sayesinde, o API anahtarı sadece Kripteks sunucuları tarafından kullanıldığında aktif olur.

## Nasıl Yapılır?
1. Binance API ayarlarında "Restrict access to trusted IPs only" seçeneğini seçin.
2. Kripteks Ayarlar > API sekmesindeki güncel IP adreslerini kopyalayın.
3. Binance ekranına yapıştırın ve kaydedin.

## Önemli:
API anahtarınızın süresinin (genellikle 90 gün) IP kısıtlaması varken de geçerli olduğunu unutmayın.
''',
    ),
    EducationTopic(
      id: 'grid-range-optimization',
      title: 'Grid Aralığı Optimizasyonu',
      description:
          'Değişen piyasa volatilitesine göre ızgara aralıklarını güncelleyin.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Bot Yönetimi',
      icon: Icons.settings_input_component_rounded,
      content: '''
# Verimli Grid Kurulumu
Grid botları için en kritik unsur, fiyatın ızgara aralığında kalmasıdır.

## Aralık Belirleme İpuçları:
- **Destek/Direnç:** Alt sınırı güçlü bir destek seviyesine, üst sınırı ise dirence yakın belirleyin.
- **ATR Kullanımı:** Ortalama Gerçek Menzil (ATR) indikatörüne bakarak ızgara sıklığını volatilitenize göre ayarlayın.
- **Genişlik Oranı:** Çok dar aralıklar kârı artırır ama aralık dışına çıkma riskini yükseltir.

## Güncelleme Zamanı:
Eğer fiyat belirlenen aralığın üzerine çıkarsa bot işlemleri durdurur. Bu durumda kârı alıp yeni bir aralıkla botu yeniden başlatmak en mantıklısıdır.
''',
    ),
    EducationTopic(
      id: 'sentiment-trading-guide',
      title: 'Haber ve Duygu Trade Rehberi',
      description:
          'Kripto haberlerinin fiyat üzerindeki etkisini kâr fırsatına dönüştürün.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Analiz Araçları',
      icon: Icons.newspaper_rounded,
      content: '''
# Haberleri Fiyata Çevirme
Kripto piyasası haberlere karşı en duyarlı piyasalardan biridir.

## Sentiment Araçları:
- **AI Sentiment Skoru:** Haberin içeriğini (boğa/ayı) saniyeler içinde analiz eder.
- **Haber Hızı:** Belirli bir coin hakkında haber trafiği aniden artarsa, büyük bir hareket gelmek üzeredir.

## Uygulama Stratejisi:
Çok pozitif bir haber düştüğünde, Sinyal Botu ile hızlı bir giriş yaparak ve kısa bir kâr hedefi koyarak "scalp" işlemler gerçekleştirebilirsiniz.
''',
    ),
    EducationTopic(
      id: 'community-support',
      title: 'Destek ve Topluluk Kanalları',
      description: 'Sorularınız ve strateji paylaşımları için bize ulaşın.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Güvenlik & Destek',
      icon: Icons.groups_rounded,
      content: '''
# Asla Yalnız Değilsiniz
Kripteks ailesi olarak her adımda yanınızdayız.

## Ulaşabileceğimiz Kanallar:
- **Teknik Destek:** Uygulama içindeki "Destek" butonundan canlı sohbet başlatabilirsiniz.
- **Telegram Grubu:** Diğer kullanıcılarla strateji paylaşmak ve güncelsig sinyalleri takip etmek için topluluğumuza katılın.
- **Eğitim Videoları:** YouTube kanalımızdaki "Kripteks 101" serisini izleyerek görsel rehberlere ulaşabilirsiniz.

## Önemli Hatırlatma:
Hiçbir Kripteks yetkilisi sizden özel API Secret Key veya şifre talep etmez. Güvenliğiniz için bu bilgileri kimseyle paylaşmayın.
''',
    ),
    EducationTopic(
      id: 'profit-management-rules',
      title: 'Kâr Alım ve Büyüme Kuralları',
      description:
          'Zararda beklemeyi bildiğiniz kadar kârda durmayı da öğrenin.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Bot Yönetimi',
      icon: Icons.savings_rounded,
      content: '''
# Disiplinli Kâr Yönetimi
Finansal piyasalarda kalıcı olmanın yolu kârı cebine koymaktan geçer.

## 3 Ana Kural:
1. **Hedef Odaklılık:** Botunuzu kurarken gerçekçi bir kâr hedefi (%1-%5 arası) belirleyin. Çok hırslı hedefler dönüş riskini artırır.
2. **Kâr Çekme:** Ana paranın kârını belirli periyotlarla stabil coin (USDT) cüzdanınıza aktarın.
3. **Kademeli Kâr:** Tek seferde çıkmak yerine, yükseliş devam ederse kademeli olarak bot kârını artırabilirsiniz.

## Başarının Sırrı:
Kripteks botları duygusuzdur. Siz kâr hedefini koyun, o saniyesinde satsın. Duygularınızı bota devredin.
''',
    ),
    EducationTopic(
      id: 'api-error-codes-meaning',
      title: 'Binance API Hata Sözlüğü',
      description:
          'Karşılaştığınız hata kodlarının ne anlama geldiğini hızlıca öğrenin.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Güvenlik & Destek',
      icon: Icons.code_rounded,
      content: '''
# Hata Kodları Rehberi
Bot loglarında gördüğünüz sayılar aslında size ne yapmanız gerektiğini söyler.

## Sık Rastlanan Kodlar:
- **-2015:** Yanlış API Key veya geçersiz imza. Genellikle anahtarın yanlış kopyalanmasından olur.
- **-1013:** Minimum işlem tutarının (10 USDT) altında alım yapılmaya çalışılıyor.
- **-2010:** Yetersiz bakiye. Emir vermek için cüzdanda yeterli tutar yok.
- **-1021 (Timestamp for this request is outside of the recvWindow):** Telefonunuzun saati ile borsa saati senkronize değil. Saat ayarlarınızı "Otomatik" yapın.

## Nasıl Çözülür?
Log detayındaki hata kodunu bu rehberle eşleştirerek problemin kaynağını saniyeler içinde bulabilirsiniz.
''',
    ),
    EducationTopic(
      id: 'dca-safety-orders-deep-dive',
      title: 'DCA Güvenlik Emirleri (Safety)',
      description:
          'Düşüşlerde botunuzun ne sıklıkla ve ne kadar ekleme yapacağını belirleyin.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Bot Yönetimi',
      icon: Icons.shield_moon_rounded,
      content: '''
# DCA Güvenlik Ayarları
DCA botunun en güçlü yanı, fiyat düştükçe maliyet düşürmesidir. Bunu "Güvenlik Emirleri" ile yapar.

## Temel Parametreler:
- **Price Deviation (%):** Fiyat ana girişten ne kadar düşerse ilk ekleme yapılacak? (Örn: %2).
- **Safety Order Size:** Her eklemede ne kadarlık alım yapılacak? (Örn: 20 USDT).
- **Max Safety Orders:** Bot toplamda en fazla kaç kez ekleme yapabilir?

## Stratejik İpucu:
"Martingale" çarpanı kullanarak, her düşüşte bir öncekinden daha büyük alım yapabilir ve kâr hedefinize çok daha hızlı ulaşabilirsiniz. Ancak dikkatli olun; bu yöntem bakiyenizi hızlı tüketir.
''',
    ),
    EducationTopic(
      id: 'rsi-divergence-concepts',
      title: 'Scanner ile RSI Uyumsuzluğu',
      description:
          'Trend dönüşlerini yakalamak için RSI ve Fiyat arasındaki farkları bulun.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Analiz Araçları',
      icon: Icons.insights_rounded,
      content: '''
# Uyumsuzluk (Divergence) Nedir?
Fiyat yeni bir dip yaparken RSI'ın daha yüksek bir dip yapması durumudur. Bu genellikle düşüş trendinin bittiğinin sinyalidir.

## Scanner'da Tespit:
Kripteks tarayıcısında "RSI Pozitif Uyumsuzluk" filtresini aktif ederek, piyasada dönmek üzere olan pariteleri otomatik listeleyebilirsiniz.

## Kullanım Şekli:
- 4 saatlik grafiklerdeki uyumsuzluklar daha güvenilirdir.
- Uyumsuzluk yakalandığında Sinyal Botu ile işleme girmek başarı oranını artırır.
''',
    ),
    EducationTopic(
      id: 'binance-sub-accounts-usage',
      title: 'Binance Alt Hesap Kullanımı',
      description:
          'Farklı stratejiler için ana hesabınızı bölerek riskinizi yönetin.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Kurulum',
      icon: Icons.switch_account_rounded,
      content: '''
# Çoklu Hesap Yönetimi
Eğer Binance ana hesabınızda farklı botlar çalıştırmak istiyorsanız, "Sub-Account" özelliği hayat kurtarıcıdır.

## Avantajları:
- Botların bakiyeleri birbirine karışmaz.
- Her alt hesap için ayrı API anahtarı oluşturarak güvenliği artırırsınız.
- Bir bota ayırdığınız sermayenin diğer bot tarafından kullanılmasını engellersiniz.

## Kripteks'e Ekleme:
Kripteks birden fazla API anahtarını destekler. Her bir alt hesabınızı farklı bir "Cüzdan" olarak tanımlayıp yönetebilirsiniz.
''',
    ),
    EducationTopic(
      id: 'market-vs-limit-orders',
      title: 'Piyasa (Market) vs Limit Emirler',
      description:
          'Botunuzun işlemleri hangi hızda ve hangi fiyattan açacağını seçin.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Kurulum',
      icon: Icons.shutter_speed_rounded,
      content: '''
# Emir Türleri Arasındaki Fark
Botunuzun işleme girme saniyeleri kârlılığınızı etkileyebilir.

## Piyasa (Market) Emri:
- **Hız:** Anında gerçekleşir.
- **Risk:** "Slippage" (Kayma) riski vardır; fiyat çok hareketliyse beklenenden biraz farklı bir fiyattan alınabilir.
- **Kullanım:** Fırsatı kaçırmak istemediğiniz sinyal botlarında idealdir.

## Limit Emri:
- **Hız:** Belirlediğiniz fiyata gelene kadar bekler.
- **Risk:** Fiyat o seviyeye gelmezse işlem açılmaz.
- **Kullanım:** Grid botlarında ve belirli bir fiyattan alım yapmak istediğinizde kullanılır.
''',
    ),
    EducationTopic(
      id: 'bot-status-deep-meaning',
      title: 'Bot Durumlarının Anlamları',
      description:
          'Bot ekranındaki "Sinyal Bekleniyor" veya "İşlemde" gibi ifadelerin detayları.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Bot Yönetimi',
      icon: Icons.info_outline_rounded,
      content: '''
# Botunuz Ne Yapıyor?
Ekrandaki her durum ifadesi botun o anki teknik sürecini gösterir.

## Durumlar:
- **Waiting for Entry (Giriş Bekliyor):** Bot aktif ancak henüz belirlediğiniz giriş fiyatına veya sinyal koşuluna ulaşılmadı.
- **Signal Pending (Sinyal Bekleniyor):** Teknik onaylar (RSI, MACD vb.) oluşmak üzere, bot tetikte bekliyor.
- **Active / Trading (İşlemde):** Alım yapıldı, şu an kâr alma (TP) veya zarar kesme (SL) hedeflerinden biri bekleniyor.
- **Cooling Down (Soğuma Süreci):** Başarılı bir işlem sonrası botun aynı paritede hemen tekrar girmemesi için beklediği süre.
''',
    ),
    EducationTopic(
      id: 'stablecoin-pair-management',
      title: 'Stabil Coin Parite Yönetimi',
      description:
          'Sadece USDT değil, FDUSD, EUR veya BTC paritelerinde bot çalıştırma.',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Kurulum',
      icon: Icons.currency_exchange_rounded,
      content: '''
# Parite Seçimi
Kripteks botları Binance üzerindeki tüm işlem çiftlerini destekler.

## Dikkat Edilmesi Gerekenler:
- **Likidite:** Her zaman işlem hacmi en yüksek olan (Genellikle USDT) pariteleri tercih edin.
- **Komisyon Avantajları:** Bazı dönemlerde Binance'in stabil pariteler (FDUSD vb.) için uyguladığı 0 komisyon fırsatlarını değerlendirin.
- **Bakiye Kontrolü:** Botu hangi paritede çalıştıracaksanız cüzdanınızda o birimden (Örn: ETH paritesi ise cüzdanınızda ETH olmalı) bakiye olmalıdır.
''',
    ),
    EducationTopic(
      id: 'backtest-optimization-cycles',
      title: 'Backtest Optimizasyon Döngüsü',
      description:
          'En kârlı ayarları bulmak için testleri nasıl yorumlamalısınız?',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Analiz Araçları',
      icon: Icons.published_with_changes_rounded,
      content: '''
# Profesyonel Test Süreci
Tek bir test sonucuyla bot başlatmak yerine verileri iterate edin.

## Adımlar:
1. **Baz Test:** Standart ayarlarla bir test çalıştırın.
2. **Parametre Değişimi:** Sadece tek bir ayarı (Örn: Sadece kâr alma oranını) değiştirip tekrar test edin.
3. **Kıyaslama:** Hangi ayar "Drawdown" oranını düşürürken kârı artırdı?
4. **Zaman Analizi:** Stratejinin hem boğa hem de ayı piyasası dönemlerindeki performansını ayrı ayrı görün.

## Altın Kural:
Geçmiş performans geleceğin garantisi değildir ancak olasılıkları sizin lehine çevirmenin tek yoludur.
''',
    ),
    EducationTopic(
      id: 'updating-expiring-api-keys',
      title: 'API Anahtarı Güncelleme',
      description:
          'Zaman aşımına uğrayan veya güvenliğiniz için yenilediğiniz anahtarları nasıl değiştirirsiniz?',
      category: EducationTopicCategory.appTraining,
      subCategory: 'Güvenlik & Destek',
      icon: Icons.update_rounded,
      content: '''
# Kesintisiz Bot Deneyimi
Binance, güvenlik nedeniyle bazen 90 gün sonra API anahtarlarını pasife alabilir.

## Güncelleme Adımları:
1. Binance üzerinde yeni bir API anahtarı oluşturun.
2. Kripteks'te **Ayarlar > Binance API** sayfasına gidin.
3. Mevcut anahtarları silin veya "Güncelle" butonuna basın.
4. Yeni API Key ve Secret Key'i yapıştırın ve Test edin.

## Önemli:
Güncelleme sırasında aktif botlarınız varsa, işlemlerin aksamaması için yeni anahtarın aynı yetkilere (Spot Trading) sahip olduğundan emin olun.
''',
    ),
  ];
}
