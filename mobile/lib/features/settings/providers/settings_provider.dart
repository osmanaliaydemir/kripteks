import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/auth/biometric_service.dart';
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

final biometricStateProvider = FutureProvider.autoDispose<BiometricState>((
  ref,
) async {
  final service = ref.read(biometricServiceProvider);
  final isSupported = await service.isDeviceSupported();
  // Only check enabled if supported to avoid unnecessary reads
  final isEnabled = isSupported ? await service.isBiometricEnabled() : false;
  return BiometricState(isSupported: isSupported, isEnabled: isEnabled);
});
