import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/auth_state_provider.dart';
import 'package:mobile/features/auth/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  const storage = FlutterSecureStorage();
  return AuthService(dio, storage);
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).login(email, password),
    );
    if (!state.hasError) {
      ref.read(authStateProvider.notifier).setAuthenticated(true);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).logout(),
    );
    ref.read(authStateProvider.notifier).setAuthenticated(false);
  }

  void setUnauthenticated() {
    ref.read(authStateProvider.notifier).setAuthenticated(false);
  }
}
