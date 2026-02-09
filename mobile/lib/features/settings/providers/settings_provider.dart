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

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );

class NotificationSettingsNotifier extends AsyncNotifier<NotificationSettings> {
  @override
  Future<NotificationSettings> build() async {
    final service = ref.watch(settingsServiceProvider);
    return service.getNotificationSettings();
  }

  Future<void> updateSettings(NotificationSettings newSettings) async {
    final service = ref.read(settingsServiceProvider);
    state = const AsyncValue.loading();
    try {
      await service.updateNotificationSettings(newSettings);
      state = AsyncValue.data(newSettings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleSetting(String field, bool value) async {
    final current = state.value;
    if (current == null) return;

    NotificationSettings updated;
    switch (field) {
      case 'notifyBuySignals':
        updated = current.copyWith(notifyBuySignals: value);
        break;
      case 'notifySellSignals':
        updated = current.copyWith(notifySellSignals: value);
        break;
      case 'notifyStopLoss':
        updated = current.copyWith(notifyStopLoss: value);
        break;
      case 'notifyTakeProfit':
        updated = current.copyWith(notifyTakeProfit: value);
        break;
      case 'notifyGeneral':
        updated = current.copyWith(notifyGeneral: value);
        break;
      case 'notifyErrors':
        updated = current.copyWith(notifyErrors: value);
        break;
      case 'enablePushNotifications':
        updated = current.copyWith(enablePushNotifications: value);
        break;
      default:
        return;
    }

    await updateSettings(updated);
  }
}
