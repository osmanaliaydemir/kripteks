import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../services/backtest_service.dart';
import '../models/strategy_model.dart';
import '../models/backtest_model.dart';

final backtestServiceProvider = Provider<BacktestService>((ref) {
  final dio = ref.watch(dioProvider);
  return BacktestService(dio);
});

final strategiesProvider = FutureProvider<List<Strategy>>((ref) async {
  final service = ref.watch(backtestServiceProvider);
  return service.getStrategies();
});

// Using AsyncNotifier for backtest run state
final backtestRunProvider =
    AsyncNotifierProvider<BacktestRunNotifier, BacktestResult?>(
      BacktestRunNotifier.new,
    );

class BacktestRunNotifier extends AsyncNotifier<BacktestResult?> {
  @override
  FutureOr<BacktestResult?> build() {
    return null;
  }

  Future<void> runBacktest(BacktestRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(backtestServiceProvider);
      return service.runBacktest(request);
    });
  }
}
