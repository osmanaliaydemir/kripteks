import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/theme/app_colors.dart';

class TradingViewChart extends ConsumerStatefulWidget {
  final String symbol;
  final String interval;
  final String? botId;
  final double height;

  const TradingViewChart({
    super.key,
    required this.symbol,
    required this.interval,
    this.botId,
    this.height = 400,
  });

  @override
  ConsumerState<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends ConsumerState<TradingViewChart> {
  late final WebViewController _controller;
  bool _isReady = false;
  String _currentInterval = '';

  @override
  void initState() {
    super.initState();
    _currentInterval = widget.interval;
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final data = jsonDecode(message.message);
          if (data['type'] == 'ready') {
            setState(() => _isReady = true);
            _sendInitialData();
            _fetchAndSendData();
          } else if (data['type'] == 'intervalChange') {
            setState(() => _currentInterval = data['interval']);
            _fetchAndSendData();
          }
        },
      )
      ..loadFlutterAsset('assets/html/tradingview_chart.html');
  }

  Future<void> _sendInitialData() async {
    await _controller.runJavaScript(
      "setSymbolInfo('${widget.symbol}', '$_currentInterval')",
    );
  }

  Future<void> _fetchAndSendData() async {
    try {
      final dio = ref.read(dioProvider);

      // 1. Klines and Indicators
      final chartDataResponse = await dio.get(
        '/chart/klines-with-indicators/${widget.symbol}',
        queryParameters: {'interval': _currentInterval, 'limit': 500},
      );

      var chartData = Map<String, dynamic>.from(chartDataResponse.data);

      // 2. Bot Markers (if applicable)
      if (widget.botId != null) {
        final markersResponse = await dio.get(
          '/chart/bot-markers/${widget.botId}',
        );
        chartData['markers'] = markersResponse.data;
      }

      // 3. Send to JS
      final jsonStr = jsonEncode(chartData);
      await _controller.runJavaScript("setChartData('$jsonStr')");
    } catch (e) {
      debugPrint('Chart data fetch error: $e');
    }
  }

  @override
  void didUpdateWidget(TradingViewChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol || oldWidget.botId != widget.botId) {
      _fetchAndSendData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white05),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (!_isReady)
            Container(
              color: AppColors.background,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
