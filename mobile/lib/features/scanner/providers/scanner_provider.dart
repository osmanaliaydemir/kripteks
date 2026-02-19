import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../services/scanner_service.dart';
import '../models/scanner_model.dart';

final scannerServiceProvider = Provider<ScannerService>((ref) {
  final dio = ref.watch(dioProvider);
  return ScannerService(dio);
});

final favoriteListsProvider = FutureProvider<List<ScannerFavoriteList>>((
  ref,
) async {
  final service = ref.watch(scannerServiceProvider);
  return service.getFavoriteLists();
});

final scannerResultsProvider =
    AsyncNotifierProvider<ScannerResultsNotifier, ScannerResult?>(
      ScannerResultsNotifier.new,
    );

class ScannerResultsNotifier extends AsyncNotifier<ScannerResult?> {
  late final ScannerService _service;

  @override
  FutureOr<ScannerResult?> build() {
    _service = ref.watch(scannerServiceProvider);
    return null;
  }

  Future<void> scan({
    required String strategyId,
    required String interval,
    List<String> symbols = const [],
    String market = 'crypto',
    Map<String, String>? strategyParameters,
  }) async {
    state = const AsyncValue.loading();
    try {
      final request = ScannerRequest(
        symbols: symbols.isNotEmpty
            ? symbols
            : (market == 'bist'
                  ? ['THYAO.IS', 'ASELS.IS', 'EREGL.IS']
                  : [
                      'BTCUSDT',
                      'ETHUSDT',
                      'BNBUSDT',
                      'SOLUSDT',
                      'XRPUSDT',
                      'ADAUSDT',
                      'AVAXUSDT',
                      'DOGEUSDT',
                    ]),
        strategyId: strategyId,
        interval: interval,
        market: market,
        strategyParameters: strategyParameters,
      );
      final result = await _service.scan(request);
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
