import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'providers/scanner_provider.dart';
import 'models/scanner_model.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  String _selectedStrategy = 'SMA_111';
  String _selectedInterval = '1h';
  bool _useFavorites = false;

  final List<String> _strategies = ['SMA_111', 'RSI_Strategy', 'MACD_Strategy'];
  final List<String> _intervals = ['15m', '1h', '4h', '1d'];

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(scannerResultsProvider);
    final favoritesAsync = ref.watch(favoriteListsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppHeader(
        title: 'Strateji Tarayıcı',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => _triggerScan(favoritesAsync.asData?.value),
          ),
        ],
      ),
      body: Column(
        children: [
          // Configuration Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
              border: const Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Strategy & Interval
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildDropdown(
                        value: _selectedStrategy,
                        items: _strategies,
                        onChanged: (val) {
                          setState(() => _selectedStrategy = val!);
                          _triggerScan(favoritesAsync.asData?.value);
                        },
                        label: 'Strateji',
                        icon: Icons.candlestick_chart,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _buildDropdown(
                        value: _selectedInterval,
                        items: _intervals,
                        onChanged: (val) {
                          setState(() => _selectedInterval = val!);
                          _triggerScan(favoritesAsync.asData?.value);
                        },
                        label: 'Periyot',
                        icon: Icons.timer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Helpers (Favorites Toggle)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: _useFavorites,
                          onChanged: (val) {
                            setState(() => _useFavorites = val);
                            _triggerScan(favoritesAsync.asData?.value);
                          },
                          activeTrackColor: const Color(0xFFF59E0B),
                        ),
                        const Text(
                          'Sadece Favoriler',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _triggerScan(favoritesAsync.asData?.value),
                      icon: const Icon(Icons.search),
                      label: const Text('Tara'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results List
          Expanded(
            child: resultsAsync.when(
              data: (result) {
                if (result == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.radar,
                          size: 64,
                          color: Colors.white10,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Taramayı başlatmak için "Tara" butonuna basın',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ],
                    ),
                  );
                }

                if (result.results.isEmpty) {
                  return const Center(
                    child: Text(
                      'Sonuç bulunamadı',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                // Sort by score descending
                final items = List<ScannerResultItem>.from(result.results);
                items.sort((a, b) => b.signalScore.compareTo(a.signalScore));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _buildResultItem(items[index])
                          .animate()
                          .fadeIn(delay: (50 * index).ms)
                          .slideX(begin: 0.1, end: 0),
                );
              },
              loading: () => _buildShimmerList(),
              error: (err, stack) => Center(
                child: Text(
                  'Hata: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerScan(List<ScannerFavoriteList>? favoriteLists) {
    List<String> symbols = [];
    if (_useFavorites && favoriteLists != null) {
      for (var list in favoriteLists) {
        symbols.addAll(list.symbols);
      }
      symbols = symbols.toSet().toList(); // Remove duplicates
    }

    ref
        .read(scannerResultsProvider.notifier)
        .scan(
          strategyId: _selectedStrategy,
          interval: _selectedInterval,
          symbols: symbols,
        );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1E293B),
          icon: Icon(icon, color: const Color(0xFFF59E0B), size: 20),
          isExpanded: true,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
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
        actionColor = const Color(0xFF10B981);
        actionText = 'AL';
        actionIcon = Icons.arrow_upward;
        break;
      case 1: // Sell
        actionColor = const Color(0xFFEF4444);
        actionText = 'SAT';
        actionIcon = Icons.arrow_downward;
        break;
      default:
        actionColor = Colors.grey;
        actionText = 'BEKLE';
        actionIcon = Icons.remove;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Symbol & Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '\$${item.lastPrice}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Score
              Column(
                children: [
                  const Text(
                    'Skor',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  Text(
                    '${item.signalScore.toInt()}',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFFF59E0B),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),

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
                    Icon(actionIcon, size: 14, color: actionColor),
                    const SizedBox(width: 6),
                    Text(
                      actionText,
                      style: TextStyle(
                        color: actionColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.comment,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.white10,
            highlightColor: Colors.white12,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 80, height: 20, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 60, height: 16, color: Colors.white),
                      ],
                    ),
                  ),
                  Container(width: 40, height: 24, color: Colors.white),
                  const SizedBox(width: 24),
                  Container(
                    width: 70,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
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
