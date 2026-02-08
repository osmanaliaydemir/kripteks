import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:mobile/features/reports/models/reports_model.dart';

final equityCurveProvider = FutureProvider<List<EquityPoint>>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  final data = await service.getEquityCurve();
  return data
      .map((e) => EquityPoint.fromJson(e as Map<String, dynamic>))
      .toList();
});

final strategyPerformanceProvider = FutureProvider<List<StrategyPerformance>>((
  ref,
) async {
  final service = ref.watch(analyticsServiceProvider);
  final data = await service.getStrategyPerformance();
  return data
      .map((e) => StrategyPerformance.fromJson(e as Map<String, dynamic>))
      .toList();
});
