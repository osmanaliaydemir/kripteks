import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../services/settings_service.dart';
import '../models/settings_model.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final dio = ref.watch(dioProvider);
  return SettingsService(dio);
});

final apiKeyStatusProvider = FutureProvider.autoDispose<ApiKeyStatus>((
  ref,
) async {
  final service = ref.watch(settingsServiceProvider);
  return service.getApiKeys();
});

final systemSettingsProvider = FutureProvider.autoDispose<SystemSetting>((
  ref,
) async {
  final service = ref.watch(settingsServiceProvider);
  return service.getSystemSettings();
});
