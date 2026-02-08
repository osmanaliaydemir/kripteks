import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectionStatus { online, offline }

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  return ref.watch(connectivityServiceProvider).statusStream;
});

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectionStatus> _controller =
      StreamController<ConnectionStatus>.broadcast();

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _checkStatus(results);
    });
    // Check initial status
    _connectivity.checkConnectivity().then((results) => _checkStatus(results));
  }

  Stream<ConnectionStatus> get statusStream => _controller.stream;

  void _checkStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      _controller.add(ConnectionStatus.offline);
    } else {
      _controller.add(ConnectionStatus.online);
    }
  }
}
