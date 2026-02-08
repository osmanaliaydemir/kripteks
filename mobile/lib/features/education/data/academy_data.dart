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
  ];

  static final List<EducationTopic> topics = [
    // İndikatörler
    EducationTopic(
      id: 'rsi',
      title: 'RSI (Göreceli Güç Endeksi)',
      description:
          'Aşırı alım ve aşırı satım bölgelerini belirlemek için kullanılır.',
      category: EducationTopicCategory.indicators,
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
      id: 'macd',
      title: 'MACD',
      description:
          'Trend yönünü ve gücünü takip etmek için kullanılan indikatör.',
      category: EducationTopicCategory.indicators,
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
      id: 'grid-strategy',
      title: 'Grid (Izgara) Stratejisi',
      description:
          'Yatay piyasalarda düzenli aralıklarla al-sat yaparak kâr elde etme.',
      category: EducationTopicCategory.strategies,
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

    // Temel Kavramlar
    EducationTopic(
      id: 'bull-bear',
      title: 'Boğa ve Ayı Piyasası',
      description: 'Piyasa trendlerini ifade eden temel terimler.',
      category: EducationTopicCategory.fundamentals,
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
  ];
}
