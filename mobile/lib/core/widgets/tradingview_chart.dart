import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  late WebViewController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A));

    _loadChart();

    // Fallback: 12 saniye sonra hala hazır değilse zorla göster
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && !_isReady) {
        setState(() => _isReady = true);
        debugPrint('🌐 [TradingView] Fallback triggered');
      }
    });
  }

  void _loadChart() {
    final tvInterval = _mapIntervalToTV(widget.interval);
    final tvSymbol = 'BINANCE:${_sanitizedSymbol}';

    // HTML String for the official TradingView Widget
    final html =
        '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
        body, html { margin: 0; padding: 0; width: 100%; height: 100%; background-color: #0F172A; overflow: hidden; }
        .tradingview-widget-container { width: 100%; height: 100%; }
    </style>
</head>
<body>
    <div class="tradingview-widget-container">
        <div id="tradingview_widget"></div>
        <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
        <script type="text/javascript">
        new TradingView.widget({
            "autosize": true,
            "symbol": "$tvSymbol",
            "interval": "$tvInterval",
            "timezone": "Etc/UTC",
            "theme": "dark",
            "style": "1",
            "locale": "tr",
            "toolbar_bg": "#f1f3f6",
            "enable_publishing": false,
            "allow_symbol_change": true,
            "container_id": "tradingview_widget"
        });
        </script>
    </div>
</body>
</html>
''';

    debugPrint('🌐 [TradingView] Loading HTML content for $tvSymbol');

    _controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (progress > 80 && !_isReady) {
              if (mounted) setState(() => _isReady = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isReady = true);
          },
          onWebResourceError: (error) {
            debugPrint('🌐 [TradingView Error] ${error.description}');
          },
        ),
      )
      ..loadHtmlString(html);
  }

  String get _sanitizedSymbol => widget.symbol.replaceAll('/', '');

  String _mapIntervalToTV(String interval) {
    switch (interval) {
      case '1m':
        return '1';
      case '3m':
        return '3';
      case '5m':
        return '5';
      case '15m':
        return '15';
      case '30m':
        return '30';
      case '1h':
        return '60';
      case '2h':
        return '120';
      case '4h':
        return '240';
      case '6h':
        return '360';
      case '8h':
        return '480';
      case '12h':
        return '720';
      case '1d':
        return 'D';
      case '3d':
        return '3D';
      case '1w':
        return 'W';
      case '1M':
        return 'M';
      default:
        return '60';
    }
  }

  @override
  void didUpdateWidget(TradingViewChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol ||
        oldWidget.interval != widget.interval) {
      _loadChart();
    }
  }

  void _reload() {
    setState(() => _isReady = false);
    _loadChart();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white05),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (!_isReady)
            Container(
              color: const Color(0xFF0F172A),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Grafik hazırlanıyor...',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _reload,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'Yeniden Dene',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
