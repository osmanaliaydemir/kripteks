import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../services/portfolio_service.dart';
import '../models/portfolio_model.dart';

final portfolioServiceProvider = Provider<PortfolioService>((ref) {
  final dio = ref.watch(dioProvider);
  return PortfolioService(dio);
});

/// Portföy özet bilgisi provider'ı.
/// Her 15 saniyede otomatik güncellenir (fiyat değişimleri için).
final portfolioSummaryProvider = StreamProvider.autoDispose<PortfolioSummary>((
  ref,
) async* {
  final service = ref.watch(portfolioServiceProvider);
  yield await service.getPortfolioSummary();
  await for (final _ in Stream.periodic(const Duration(seconds: 15))) {
    yield await service.getPortfolioSummary();
  }
});
