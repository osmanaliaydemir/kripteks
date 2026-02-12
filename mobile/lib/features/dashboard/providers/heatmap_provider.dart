import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bots/providers/bot_provider.dart';

// Günlük PnL verisi için model (Tarih -> PnL)
typedef DailyPnlMap = Map<DateTime, double>;

final heatmapDataProvider = FutureProvider.autoDispose<DailyPnlMap>((
  ref,
) async {
  // Bot servisini al
  final botService = ref.watch(botServiceProvider);

  // Son 200 botu çek (Yeterli bir geçmiş için)
  // İdeal dünyada backend'de /analytics/daily-pnl gibi bir endpoint olmalıydı.
  // Frontend simülasyonu olarak geçmiş botlardan hesaplıyoruz.
  final result = await botService.getBots(page: 1, pageSize: 200);

  final bots = result.items;
  final dailyPnl = <DateTime, double>{};

  for (final bot in bots) {
    // Sadece tamamlanmış veya durdurulmuş (kar/zarar realize edilmiş) botları al
    if (bot.status != 'Completed' && bot.status != 'Stopped') continue;

    // Tarih belirle (Çıkış tarihi yoksa oluşturulma tarihini kullan - fallback)
    final date = bot.exitDate ?? bot.createdAt;

    // Saat bilgisini sıfırla (Sadece gün bazlı gruplama)
    final dayKey = DateTime(date.year, date.month, date.day);

    // O güne ait PnL'i ekle
    dailyPnl[dayKey] = (dailyPnl[dayKey] ?? 0) + bot.pnl;
  }

  return dailyPnl;
});
