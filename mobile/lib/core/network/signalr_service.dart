import 'dart:async';
import 'dart:math';
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

  // ─── Reconnection ayarları ────────────────────────────────────
  static const int _maxReconnectAttempts = 10;
  static const Duration _minReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 60);

  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  bool _isManuallyDisconnected = false;

  SignalRService({String? baseUrl}) : _baseUrl = baseUrl ?? AppConstants.hubUrl;

  Stream<SignalRConnectionStatus> get statusStream => _statusController.stream;
  String? get lastError => _lastError;
  int get reconnectAttempt => _reconnectAttempt;
  int get maxReconnectAttempts => _maxReconnectAttempts;
  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Future<void> initConnection() async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    _isManuallyDisconnected = false;
    _reconnectAttempt = 0;

    final token = await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      _log.warning('No access token found, skipping SignalR connection');
      return;
    }

    _updateStatus(SignalRConnectionStatus.connecting);

    try {
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            _baseUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                // Her bağlantıda güncel token'ı oku
                final freshToken = await _storage.read(key: 'auth_token');
                return freshToken ?? '';
              },
              requestTimeout: 30000,
            ),
          )
          // Kendi reconnection mekanizmamızı kullanacağız
          .build();

      _hubConnection?.onclose(({Exception? error}) {
        _log.warning('SignalR Connection Closed', error);
        _updateStatus(SignalRConnectionStatus.disconnected, error?.toString());

        // Manuel kapatma değilse otomatik reconnect başlat
        if (!_isManuallyDisconnected) {
          _scheduleReconnect();
        }
      });

      _hubConnection?.onreconnecting(({Exception? error}) {
        _updateStatus(SignalRConnectionStatus.reconnecting, error?.toString());
      });

      _hubConnection?.onreconnected(({String? connectionId}) {
        _reconnectAttempt = 0;
        _updateStatus(SignalRConnectionStatus.connected);
      });

      await _hubConnection?.start();
      _log.info('SignalR Connected');
      _reconnectAttempt = 0;
      _updateStatus(SignalRConnectionStatus.connected);
    } catch (e) {
      _log.severe('SignalR Connection Error', e);
      _updateStatus(SignalRConnectionStatus.error, e.toString());

      // İlk bağlantı başarısız -> reconnect dene
      if (!_isManuallyDisconnected) {
        _scheduleReconnect();
      }
    }
  }

  /// Exponential backoff ile yeniden bağlanma planlar.
  ///
  /// Gecikme: min(maxDelay, minDelay * 2^attempt) + jitter
  /// Örnek: 1s, 2s, 4s, 8s, 16s, 32s, 60s, 60s, 60s, 60s
  void _scheduleReconnect() {
    if (_isManuallyDisconnected) return;
    if (_reconnectAttempt >= _maxReconnectAttempts) {
      _log.severe(
        'SignalR: Max reconnect attempts ($_maxReconnectAttempts) reached.',
      );
      _updateStatus(
        SignalRConnectionStatus.error,
        'Bağlantı kurulamadı. Maksimum deneme sayısına ulaşıldı.',
      );
      return;
    }

    _reconnectTimer?.cancel();

    // Exponential backoff + jitter
    final exponentialMs =
        _minReconnectDelay.inMilliseconds * (1 << _reconnectAttempt);
    final cappedMs = min(exponentialMs, _maxReconnectDelay.inMilliseconds);
    final jitterMs = Random().nextInt(1000); // 0-1s arası jitter
    final delay = Duration(milliseconds: cappedMs + jitterMs);

    _reconnectAttempt++;

    // if (kDebugMode) {
    //   debugPrint(
    //     '🔄 [SignalR] Reconnect attempt $_reconnectAttempt/$_maxReconnectAttempts '
    //     'in ${delay.inMilliseconds}ms',
    //   );
    // }

    _updateStatus(SignalRConnectionStatus.reconnecting);

    _reconnectTimer = Timer(delay, () async {
      if (_isManuallyDisconnected) return;

      try {
        // Önceki bağlantıyı temizle
        try {
          await _hubConnection?.stop();
        } catch (_) {}

        _hubConnection = null;
        await initConnection();
      } catch (e) {
        _log.warning('Reconnect attempt $_reconnectAttempt failed: $e');
        // initConnection zaten _scheduleReconnect'i çağıracak
      }
    });
  }

  /// Manuel olarak yeniden bağlanmayı tetikler (kullanıcı butona bastığında).
  Future<void> manualReconnect() async {
    _reconnectAttempt = 0;
    _isManuallyDisconnected = false;
    _reconnectTimer?.cancel();
    await initConnection();
  }

  void onBotUpdate(void Function(Object?) handler) {
    _hubConnection?.on('ReceiveBotUpdate', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        handler(arguments.first);
      }
    });
  }

  void onNotification(void Function(Object?) handler) {
    _hubConnection?.on('ReceiveNotification', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        handler(arguments.first);
      }
    });
  }

  Future<void> stopConnection() async {
    _isManuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;

    try {
      await _hubConnection?.stop();
    } catch (_) {}

    _updateStatus(SignalRConnectionStatus.disconnected);
  }

  void dispose() {
    _isManuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _statusController.close();
    _hubConnection?.stop();
  }

  void _updateStatus(SignalRConnectionStatus status, [String? error]) {
    if (error != null) {
      _lastError = error;
    } else if (status == SignalRConnectionStatus.connected) {
      _lastError = null;
    }

    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
