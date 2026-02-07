import 'dart:async';
import 'package:logging/logging.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:mobile/core/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SignalRConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class SignalRService {
  final String _baseUrl;
  HubConnection? _hubConnection;
  final _statusController =
      StreamController<SignalRConnectionStatus>.broadcast();
  final _log = Logger('SignalRService');
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SignalRService({String? baseUrl}) : _baseUrl = baseUrl ?? AppConstants.hubUrl;

  Stream<SignalRConnectionStatus> get statusStream => _statusController.stream;

  Future<void> initConnection() async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    _updateStatus(SignalRConnectionStatus.connecting);

    try {
      final token = await _storage.read(key: 'auth_token');

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            _baseUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token ?? '',
            ),
          )
          .withAutomaticReconnect()
          .build();

      _hubConnection?.onclose(({Exception? error}) {
        _log.warning('SignalR Connection Closed', error);
        _updateStatus(SignalRConnectionStatus.disconnected);
      });

      _hubConnection?.onreconnecting(({Exception? error}) {
        _log.info('SignalR Reconnecting...', error);
        _updateStatus(SignalRConnectionStatus.reconnecting);
      });

      _hubConnection?.onreconnected(({String? connectionId}) {
        _log.info('SignalR Reconnected: $connectionId');
        _updateStatus(SignalRConnectionStatus.connected);
      });

      await _hubConnection?.start();
      _log.info('SignalR Connected');
      _updateStatus(SignalRConnectionStatus.connected);
    } catch (e) {
      _log.severe('SignalR Connection Error', e);
      _updateStatus(SignalRConnectionStatus.error);
    }
  }

  void onBotUpdate(void Function(Object?) handler) {
    _hubConnection?.on('ReceiveBotUpdate', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        handler(arguments.first);
      }
    });
  }

  Future<void> stopConnection() async {
    await _hubConnection?.stop();
    _updateStatus(SignalRConnectionStatus.disconnected);
  }

  void _updateStatus(SignalRConnectionStatus status) {
    _statusController.add(status);
  }
}
