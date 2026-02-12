import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/signalr_service.dart';

import 'package:mobile/core/network/auth_state_provider.dart';

final signalRServiceProvider = Provider<SignalRService>((ref) {
  final service = SignalRService();
  ref.onDispose(() => service.dispose());

  // Auth durumunu dinle
  ref.listen(authStateProvider, (previous, next) {
    final isAuthenticated = next.asData?.value == true;
    if (isAuthenticated) {
      service.initConnection();
    } else {
      service.stopConnection();
    }
  });

  return service;
});

final signalRStatusProvider = StreamProvider<SignalRConnectionStatus>((ref) {
  final service = ref.watch(signalRServiceProvider);
  return service.statusStream;
});
