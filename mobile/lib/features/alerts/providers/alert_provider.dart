import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';

final alertServiceProvider = Provider<AlertService>((ref) {
  final dio = ref.watch(dioProvider);
  return AlertService(dio);
});

final alertsProvider = AsyncNotifierProvider<AlertsNotifier, List<Alert>>(
  AlertsNotifier.new,
);

class AlertsNotifier extends AsyncNotifier<List<Alert>> {
  @override
  Future<List<Alert>> build() async {
    return _fetchAlerts();
  }

  Future<List<Alert>> _fetchAlerts() {
    final service = ref.read(alertServiceProvider);
    return service.getAlerts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAlerts());
  }

  Future<void> createAlert(CreateAlertDto request) async {
    final service = ref.read(alertServiceProvider);
    await service.createAlert(request);
    ref.invalidateSelf(); // Refresh list
  }

  Future<void> deleteAlert(String id) async {
    final service = ref.read(alertServiceProvider);
    await service.deleteAlert(id);
    ref.invalidateSelf(); // Refresh list
  }
}
