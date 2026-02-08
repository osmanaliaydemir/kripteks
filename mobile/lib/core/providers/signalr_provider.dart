import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/signalr_service.dart';

final signalRServiceProvider = Provider<SignalRService>((ref) {
  return SignalRService();
});

final signalRStatusProvider = StreamProvider<SignalRConnectionStatus>((ref) {
  final service = ref.watch(signalRServiceProvider);
  return service.statusStream;
});
