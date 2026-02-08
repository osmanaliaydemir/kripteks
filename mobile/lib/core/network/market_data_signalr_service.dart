import 'dart:async';
import 'package:logging/logging.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/features/market_analysis/models/market_data.dart';

/// Singleton service managing SignalR connection for real-time market data
class MarketDataSignalRService {
  static final MarketDataSignalRService _instance =
      MarketDataSignalRService._internal();
  factory MarketDataSignalRService() => _instance;
  MarketDataSignalRService._internal();

  static const String _hubUrl = AppConstants.marketHubUrl;

  HubConnection? _hubConnection;
  final _log = Logger('MarketDataSignalR');
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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

  /// Initialize and start SignalR connection
  Future<void> connect() async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      _log.info('Already connected to market data hub');
      return;
    }

    try {
      _connectionStateController.add(HubConnectionState.Connecting);

      final token = await _storage.read(key: 'auth_token');

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            _hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token ?? '',
              requestTimeout: 30000,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _setupEventHandlers();
      _setupConnectionLifecycle();

      await _hubConnection?.start();
      _log.info('✅ Connected to market data hub');
      _connectionStateController.add(HubConnectionState.Connected);

      // Subscribe to market data updates
      await _hubConnection?.invoke('SubscribeToMarketData');
    } catch (e) {
      _log.severe('❌ Market data hub connection error: $e');
      _connectionStateController.add(HubConnectionState.Disconnected);
      rethrow;
    }
  }

  /// Setup SignalR event handlers for incoming data
  void _setupEventHandlers() {
    // Market overview updates
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

    // Top gainers updates
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

    // Top losers updates
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

    // Volume data updates
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
    });

    _hubConnection?.onreconnecting(({Exception? error}) {
      _log.info('Market data reconnecting...', error);
      _connectionStateController.add(HubConnectionState.Reconnecting);
    });

    _hubConnection?.onreconnected(({String? connectionId}) {
      _log.info('Market data reconnected: $connectionId');
      _connectionStateController.add(HubConnectionState.Connected);
      // Re-subscribe after reconnection
      _hubConnection?.invoke('SubscribeToMarketData');
    });
  }

  /// Disconnect from market data hub
  Future<void> disconnect() async {
    try {
      await _hubConnection?.invoke('UnsubscribeFromMarketData');
      await _hubConnection?.stop();
      _log.info('Disconnected from market data hub');
      _connectionStateController.add(HubConnectionState.Disconnected);
    } catch (e) {
      _log.warning('Error disconnecting: $e');
    }
  }

  /// Dispose all resources
  void dispose() {
    _marketOverviewController.close();
    _topGainersController.close();
    _topLosersController.close();
    _volumeDataController.close();
    _connectionStateController.close();
    _hubConnection?.stop();
  }
}
