import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/features/market_analysis/models/market_data.dart';

/// Singleton service managing SignalR connection for real-time market data.
///
/// Reconnection stratejisi:
/// - Exponential backoff: 1s, 2s, 4s, 8s, 16s, 32s, 60s (max)
/// - Maksimum 10 deneme sonrası durur
/// - Jitter ile thundering herd önlenir
/// - Manuel reconnect butonu desteği
class MarketDataSignalRService {
  static final MarketDataSignalRService _instance =
      MarketDataSignalRService._internal();
  factory MarketDataSignalRService() => _instance;
  MarketDataSignalRService._internal();

  static const String _hubUrl = AppConstants.marketHubUrl;

  HubConnection? _hubConnection;
  final _log = Logger('MarketDataSignalR');
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ─── Reconnection ayarları ────────────────────────────────────
  static const int _maxReconnectAttempts = 10;
  static const Duration _minReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 60);

  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  bool _isManuallyDisconnected = false;

  // Stream controllers for market data events
  final _marketOverviewController =
      StreamController<MarketOverview>.broadcast();
  final _topGainersController = StreamController<List<TopMover>>.broadcast();
  final _topLosersController = StreamController<List<TopMover>>.broadcast();
  final _volumeDataController = StreamController<VolumeData>.broadcast();
  final _connectionStateController =
      StreamController<HubConnectionState>.broadcast();

  // Public streams
  Stream<MarketOverview> get marketOverviewStream =>
      _marketOverviewController.stream;
  Stream<List<TopMover>> get topGainersStream => _topGainersController.stream;
  Stream<List<TopMover>> get topLosersStream => _topLosersController.stream;
  Stream<VolumeData> get volumeDataStream => _volumeDataController.stream;
  Stream<HubConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  HubConnectionState get connectionState =>
      _hubConnection?.state ?? HubConnectionState.Disconnected;
  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;
  int get reconnectAttempt => _reconnectAttempt;
  int get maxReconnectAttempts => _maxReconnectAttempts;

  /// Initialize and start SignalR connection
  Future<void> connect() async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      _log.info('Already connected to market data hub');
      return;
    }

    _isManuallyDisconnected = false;
    _reconnectAttempt = 0;

    try {
      _connectionStateController.add(HubConnectionState.Connecting);

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            _hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                final token = await _storage.read(key: 'auth_token');
                return token ?? '';
              },
              requestTimeout: 30000,
            ),
          )
          .build();

      _setupEventHandlers();
      _setupConnectionLifecycle();

      await _hubConnection?.start();
      _log.info('Connected to market data hub');
      _reconnectAttempt = 0;
      _connectionStateController.add(HubConnectionState.Connected);

      // Subscribe to market data updates
      await _hubConnection?.invoke('SubscribeToMarketData');
    } catch (e) {
      _log.severe('Market data hub connection error: $e');
      _connectionStateController.add(HubConnectionState.Disconnected);

      if (!_isManuallyDisconnected) {
        _scheduleReconnect();
      }
    }
  }

  /// Setup SignalR event handlers for incoming data
  void _setupEventHandlers() {
    _hubConnection?.on('ReceiveMarketOverview', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final data = arguments.first as Map<String, dynamic>;
          final overview = MarketOverview.fromJson(data);
          _marketOverviewController.add(overview);
        } catch (e) {
          _log.warning('Error parsing market overview: $e');
        }
      }
    });

    _hubConnection?.on('ReceiveTopGainers', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final data = arguments.first as List<dynamic>;
          final gainers = data
              .map((item) => TopMover.fromJson(item as Map<String, dynamic>))
              .toList();
          _topGainersController.add(gainers);
        } catch (e) {
          _log.warning('Error parsing top gainers: $e');
        }
      }
    });

    _hubConnection?.on('ReceiveTopLosers', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final data = arguments.first as List<dynamic>;
          final losers = data
              .map((item) => TopMover.fromJson(item as Map<String, dynamic>))
              .toList();
          _topLosersController.add(losers);
        } catch (e) {
          _log.warning('Error parsing top losers: $e');
        }
      }
    });

    _hubConnection?.on('ReceiveVolumeUpdate', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final data = arguments.first as Map<String, dynamic>;
          final volumeData = VolumeData.fromJson(data);
          _volumeDataController.add(volumeData);
        } catch (e) {
          _log.warning('Error parsing volume data: $e');
        }
      }
    });
  }

  /// Setup connection lifecycle handlers
  void _setupConnectionLifecycle() {
    _hubConnection?.onclose(({Exception? error}) {
      _log.warning('Market data connection closed', error);
      _connectionStateController.add(HubConnectionState.Disconnected);

      if (!_isManuallyDisconnected) {
        _scheduleReconnect();
      }
    });

    _hubConnection?.onreconnecting(({Exception? error}) {
      _log.info('Market data reconnecting...', error);
      _connectionStateController.add(HubConnectionState.Reconnecting);
    });

    _hubConnection?.onreconnected(({String? connectionId}) {
      _log.info('Market data reconnected: $connectionId');
      _reconnectAttempt = 0;
      _connectionStateController.add(HubConnectionState.Connected);
      // Re-subscribe after reconnection
      _hubConnection?.invoke('SubscribeToMarketData');
    });
  }

  /// Exponential backoff ile yeniden bağlanma planlar.
  void _scheduleReconnect() {
    if (_isManuallyDisconnected) return;
    if (_reconnectAttempt >= _maxReconnectAttempts) {
      _log.severe(
        'MarketData SignalR: Max reconnect attempts ($_maxReconnectAttempts) reached.',
      );
      return;
    }

    _reconnectTimer?.cancel();

    final exponentialMs =
        _minReconnectDelay.inMilliseconds * (1 << _reconnectAttempt);
    final cappedMs = min(exponentialMs, _maxReconnectDelay.inMilliseconds);
    final jitterMs = Random().nextInt(1000);
    final delay = Duration(milliseconds: cappedMs + jitterMs);

    _reconnectAttempt++;

    if (kDebugMode) {
      debugPrint(
        '🔄 [MarketDataSignalR] Reconnect attempt '
        '$_reconnectAttempt/$_maxReconnectAttempts in ${delay.inMilliseconds}ms',
      );
    }

    _reconnectTimer = Timer(delay, () async {
      if (_isManuallyDisconnected) return;

      try {
        try {
          await _hubConnection?.stop();
        } catch (_) {}

        _hubConnection = null;
        await connect();
      } catch (e) {
        _log.warning(
          'Market data reconnect attempt $_reconnectAttempt failed: $e',
        );
      }
    });
  }

  /// Manuel reconnect (kullanıcı tetikler)
  Future<void> manualReconnect() async {
    _reconnectAttempt = 0;
    _isManuallyDisconnected = false;
    _reconnectTimer?.cancel();
    await connect();
  }

  /// Disconnect from market data hub
  Future<void> disconnect() async {
    _isManuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;

    try {
      await _hubConnection?.invoke('UnsubscribeFromMarketData');
      await _hubConnection?.stop();
      _log.info('Disconnected from market data hub');
    } catch (e) {
      _log.warning('Error disconnecting: $e');
    }

    _connectionStateController.add(HubConnectionState.Disconnected);
  }

  /// Dispose all resources
  void dispose() {
    _isManuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _marketOverviewController.close();
    _topGainersController.close();
    _topLosersController.close();
    _volumeDataController.close();
    _connectionStateController.close();
    _hubConnection?.stop();
  }
}
