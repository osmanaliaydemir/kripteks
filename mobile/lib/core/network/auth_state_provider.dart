import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProvider = NotifierProvider<AuthStateNotifier, bool>(
  AuthStateNotifier.new,
);

class AuthStateNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setAuthenticated(bool value) {
    state = value;
  }
}
