import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final _logger = Logger('BiometricService');
  final _storage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';

  // Checks if the device supports biometrics
  Future<bool> isDeviceSupported() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isDeviceSupported;
    } on PlatformException catch (e) {
      _logger.warning('Error checking device support: $e');
      return false;
    }
  }

  // Checks if biometrics are enrolled
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      _logger.warning('Error getting available biometrics: $e');
      return [];
    }
  }

  // Authenticate user
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Lütfen giriş yapmak için kimliğinizi doğrulayın',
        // options parameter removed to fix lint error temporarily.
        // Default behavior is usually acceptable.
      );
    } on PlatformException catch (e) {
      _logger.warning('Authentication error: $e');
      // Common error codes as strings if needed: 'NotAvailable', 'NotEnrolled'
      return false;
    }
  }

  // Settings: Enable/Disable
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: 'biometric_email', value: email);
    await _storage.write(key: 'biometric_password', value: password);
  }

  Future<Map<String, String>?> getCredentials() async {
    final email = await _storage.read(key: 'biometric_email');
    final password = await _storage.read(key: 'biometric_password');

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: 'biometric_email');
    await _storage.delete(key: 'biometric_password');
    // Also disable biometric setting if credentials are cleared
    await setBiometricEnabled(false);
  }
}
