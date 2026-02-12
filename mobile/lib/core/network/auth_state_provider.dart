import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authStateProvider = AsyncNotifierProvider<AuthStateNotifier, bool>(
  AuthStateNotifier.new,
);

class AuthStateNotifier extends AsyncNotifier<bool> {
  final _storage = const FlutterSecureStorage();

  @override
  Future<bool> build() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_token');
    state = const AsyncData(false);
  }

  void setAuthenticated(bool value) {
    state = AsyncData(value);
  }
}
