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
  String? _lastError;

  SignalRService({String? baseUrl}) : _baseUrl = baseUrl ?? AppConstants.hubUrl;

  Stream<SignalRConnectionStatus> get statusStream => _statusController.stream;
  String? get lastError => _lastError;

  Future<void> initConnection() async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    _updateStatus(SignalRConnectionStatus.connecting);

    try {
      final token = await _storage.read(key: 'auth_token');

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            _baseUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                return token ?? '';
              },
              // Fiziksel cihazlarda ağ gecikmesi nedeniyle bağlantının kopmasını engellemek için timeout süresini artırdık.
              requestTimeout: 30000,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _hubConnection?.onclose(({Exception? error}) {
        _log.warning('SignalR Connection Closed', error);
        _updateStatus(SignalRConnectionStatus.disconnected, error?.toString());
      });

      _hubConnection?.onreconnecting(({Exception? error}) {
        _updateStatus(SignalRConnectionStatus.reconnecting, error?.toString());
      });

      _hubConnection?.onreconnected(({String? connectionId}) {
        _updateStatus(SignalRConnectionStatus.connected);
      });

      await _hubConnection?.start();
      _log.info('SignalR Connected');
      _updateStatus(SignalRConnectionStatus.connected);
    } catch (e) {
      _log.severe('SignalR Connection Error', e);
      _updateStatus(SignalRConnectionStatus.error, e.toString());
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

  void _updateStatus(SignalRConnectionStatus status, [String? error]) {
    if (error != null) {
      _lastError = error;
    } else if (status == SignalRConnectionStatus.connected) {
      _lastError = null;
    }
    _statusController.add(status);
  }
}
