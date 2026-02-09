import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'providers/scanner_provider.dart';
import 'models/scanner_model.dart';
import 'widgets/scanner_symbol_selection_sheet.dart';
import '../../core/providers/market_data_provider.dart';
import '../backtest/providers/backtest_provider.dart';
import '../backtest/models/strategy_model.dart';
import 'dart:async';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  String _selectedStrategy = '';
  String _selectedInterval = '1h';
  double _minSignalScore = 70;
  int? _autoScanInterval; // in minutes, null means off
  Timer? _autoScanTimer;
  List<String> _selectedSymbols = [];

  final List<String> _intervals = ['15m', '1h', '4h', '1d'];
  final List<int> _autoScanOptions = [1, 5, 15, 30, 60];

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    super.dispose();
  }

  String _getStrategyName() {
    if (_selectedStrategy.isEmpty) return 'Strateji Seçiniz';
    final strategiesAsync = ref.read(strategiesProvider);
    return strategiesAsync.when(
      data: (strategies) {
        final strategy = strategies.firstWhere(
          (s) => s.id == _selectedStrategy,
          orElse: () => Strategy(
            id: _selectedStrategy,
            name: _selectedStrategy,
            description: '',
            category: 'scanner',
          ),
        );
        return strategy.name;
      },
      loading: () => _selectedStrategy,
      error: (_, _) => _selectedStrategy,
    );
  }

  void _autoSelectFirstStrategy() {
    if (_selectedStrategy.isNotEmpty) return;
    final strategiesAsync = ref.read(strategiesProvider);
    strategiesAsync.whenData((strategies) {
      final scannerStrategies = strategies
          .where((s) => s.category == 'scanner' || s.category == 'both')
          .toList();
      if (scannerStrategies.isNotEmpty && mounted) {
        setState(() => _selectedStrategy = scannerStrategies.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(scannerResultsProvider);
    final availablePairsAsync = ref.watch(availablePairsProvider);
    final favoriteListsAsync = ref.watch(favoriteListsProvider);

    // İlk scanner stratejisini otomatik seç
    _autoSelectFirstStrategy();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Strateji Tarayıcı'),
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            height: 400,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.8,
                  colors: [AppColors.primaryTransparent, AppColors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          Column(
            children: [
              // Configuration Panel
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filter Selection Card
                    _buildSelectionCard(
                      availablePairsAsync.value ?? [],
                      favoriteListsAsync.value ?? [],
                    ),
                    const SizedBox(height: 16),

                    // Strategy & Interval
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildSelector(
                            label: 'STRATEJİ',
                            value: _getStrategyName(),
                            icon: Icons.psychology_rounded,
                            onTap: () => _showStrategySelector(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildSelector(
                            label: 'ZAMAN',
                            value: _selectedInterval,
                            icon: Icons.timer_outlined,
                            onTap: () => _showIntervalSelector(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Min Score Slider
                    _buildMinScoreSlider(),
                    const SizedBox(height: 16),

                    // Auto Scan
                    _buildAutoScanSelector(),
                    const SizedBox(height: 16),

                    // Start Button
                    _buildStartButton(),
                  ],
                ),
              ),

              // Results List
              Expanded(
                child: resultsAsync.when(
                  data: (result) {
                    if (result == null) {
                      return _buildEmptyState(
                        'Yeni bir tarama başlatın',
                        Icons.radar_rounded,
                      );
                    }

                    // Filter by Min Score locally
                    final items = result.results
                        .where((item) => item.signalScore >= _minSignalScore)
                        .toList();

                    if (items.isEmpty) {
                      return _buildEmptyState(
                        'Kriterlere uygun sonuç bulunamadı',
                        Icons.filter_list_off_rounded,
                      );
                    }

                    // Sort by score descending
                    items.sort(
                      (a, b) => b.signalScore.compareTo(a.signalScore),
                    );

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _buildResultItem(items[index])
                              .animate()
                              .fadeIn(delay: (50 * index).ms)
                              .slideY(begin: 0.1, end: 0),
                    );
                  },
                  loading: () => _buildShimmerList(),
                  error: (err, stack) => _buildErrorState(err.toString()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard(
    List<String> allSymbols,
    List<ScannerFavoriteList> favoriteLists,
  ) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ScannerSymbolSelectionSheet(
            favoriteLists: favoriteLists,
            allSymbols: allSymbols,
            scriptSelectedSymbols: _selectedSymbols,
            onSelectionChanged: (selected) {
              setState(() => _selectedSymbols = selected);
            },
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.list_alt_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parite ve Liste Seçimi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedSymbols.isEmpty
                        ? 'Tüm Pariteler'
                        : '${_selectedSymbols.length} parite seçili',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelector({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white24,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinScoreSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MİN. SİNYAL SKORU',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _minSignalScore.toInt().toString(),
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white10,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: _minSignalScore,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (val) {
                setState(() => _minSignalScore = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoScanSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'OTO. TARAMA',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        InkWell(
          onTap: _showAutoScanSelectionSheet,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _autoScanInterval == null
                        ? 'Kapalı'
                        : '$_autoScanInterval Dakika',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white24,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _triggerScan,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radar_rounded, size: 20)
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scaleXY(end: 1.2, duration: 800.ms, curve: Curves.easeInOut),
            const SizedBox(width: 12),
            Text(
              'TARAMAYI BAŞLAT',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.white10),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hata: $error',
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerScan() {
    ref
        .read(scannerResultsProvider.notifier)
        .scan(
          strategyId: _selectedStrategy,
          interval: _selectedInterval,
          symbols: _selectedSymbols,
        );
  }

  void _setupAutoScan() {
    _autoScanTimer?.cancel();
    if (_autoScanInterval != null) {
      _autoScanTimer = Timer.periodic(
        Duration(minutes: _autoScanInterval!),
        (_) => _triggerScan(),
      );
    }
  }

  void _showStrategySelector() {
    final strategiesAsync = ref.read(strategiesProvider);

    strategiesAsync.when(
      data: (strategies) {
        final scannerStrategies = strategies
            .where((s) => s.category == 'scanner' || s.category == 'both')
            .toList();

        if (scannerStrategies.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarayıcı stratejisi bulunamadı')),
          );
        } else {
          _showStrategySelectionSheet(scannerStrategies);
        }
      },
      loading: () {},
      error: (_, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stratejiler yüklenemedi')),
        );
      },
    );
  }

  void _showIntervalSelector() {
    _showSelectionSheet(
      title: 'Zaman Dilimi',
      items: _intervals,
      currentValue: _selectedInterval,
      onSelect: (val) {
        setState(() => _selectedInterval = val);
      },
    );
  }

  void _showSelectionSheet({
    required String title,
    required List<String> items,
    required String currentValue,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: Wrap(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item == currentValue;

                return InkWell(
                  onTap: () {
                    onSelect(item);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          item,
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoScanSelectionSheet() {
    final options = [null, ..._autoScanOptions];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: Wrap(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Otomatik Tarama',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == _autoScanInterval;
                final displayText = option == null
                    ? 'Kapalı'
                    : '$option Dakika';

                return InkWell(
                  onTap: () {
                    setState(() {
                      _autoScanInterval = option;
                      _setupAutoScan();
                    });
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          displayText,
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStrategySelectionSheet(List<Strategy> strategies) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'Strateji Seçiniz',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: strategies.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final strategy = strategies[index];
                      final isSelected = strategy.id == _selectedStrategy;

                      return InkWell(
                        onTap: () {
                          setState(() => _selectedStrategy = strategy.id);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.06)
                                : const Color(0xFF1A1D2E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.04),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 4,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      strategy.name,
                                      style: GoogleFonts.inter(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (strategy.description.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        strategy.description,
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 12),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultItem(ScannerResultItem item) {
    Color actionColor;
    String actionText;
    IconData actionIcon;

    switch (item.suggestedAction) {
      case 0: // Buy
        actionColor = AppColors.success;
        actionText = 'AL';
        actionIcon = Icons.arrow_upward_rounded;
        break;
      case 1: // Sell
        actionColor = AppColors.error;
        actionText = 'SAT';
        actionIcon = Icons.arrow_downward_rounded;
        break;
      case 2: // Close Buy
        actionColor = AppColors.error;
        actionText = 'AL KAPAT';
        actionIcon = Icons.close_rounded;
        break;
      case 3: // Close Sell
        actionColor = AppColors.success;
        actionText = 'SAT KAPAT';
        actionIcon = Icons.close_rounded;
        break;
      default:
        actionColor = Colors.grey;
        actionText = 'BEKLE';
        actionIcon = Icons.remove_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Symbol Icon Placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  item.symbol.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Symbol & Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.symbol,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '\$${item.lastPrice}',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: actionColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(actionIcon, size: 16, color: actionColor),
                    const SizedBox(width: 6),
                    Text(
                      actionText,
                      style: GoogleFonts.inter(
                        color: actionColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (item.comment.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.white38,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.comment,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          // Footer: Score and Timestamp or Extra info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Sinyal Gücü: ',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  Text(
                    '${item.signalScore.toInt()}/100',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                'Taranan: ${item.symbol}', // Placeholder for timestamp if available
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.white10,
            highlightColor: Colors.white12,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 60,
                              height: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      Container(width: 60, height: 28, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 30,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
