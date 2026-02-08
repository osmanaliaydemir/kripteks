import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/features/market_analysis/providers/market_analysis_provider.dart';
import 'package:mobile/features/market_analysis/models/market_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MarketAnalysisScreen extends ConsumerWidget {
  const MarketAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gainersAsync = ref.watch(topGainersProvider);
    final losersAsync = ref.watch(topLosersProvider);
    final volumeAsync = ref.watch(volumeHistoryProvider);
    final metricsAsync = ref.watch(marketMetricsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: const AppHeader(title: 'Piyasa Analizi'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(marketOverviewProvider);
          ref.invalidate(topGainersProvider);
          ref.invalidate(topLosersProvider);
          ref.invalidate(volumeHistoryProvider);
          ref.invalidate(marketMetricsProvider);
        },
        color: const Color(0xFF10B981),
        backgroundColor: const Color(0xFF1E293B),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Market Overview Cards
              metricsAsync
                  .when(
                    data: (metrics) => _buildMetricsGrid(context, metrics),
                    loading: () => _buildLoadingCards(),
                    error: (e, _) => _buildErrorCard(e.toString()),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // Volume Chart
              _buildSectionHeader(
                'Hacim Trendi',
                '24 saatlik toplam işlem hacmi',
                Icons.bar_chart,
                const Color(0xFF10B981),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 12),
              volumeAsync
                  .when(
                    data: (data) => _buildVolumeChart(data),
                    loading: () => _buildLoadingChart(),
                    error: (e, _) => _buildErrorCard(e.toString()),
                  )
                  .animate()
                  .fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // Top Gainers
              _buildSectionHeader(
                'En Çok Kazananlar',
                '24 saatte en yüksek artış gösteren coinler',
                Icons.trending_up,
                const Color(0xFF10B981),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              gainersAsync
                  .when(
                    data: (data) => _buildMoversList(data, true),
                    loading: () => _buildLoadingList(),
                    error: (e, _) => _buildErrorCard(e.toString()),
                  )
                  .animate()
                  .fadeIn(delay: 250.ms),

              const SizedBox(height: 24),

              // Top Losers
              _buildSectionHeader(
                'En Çok Kaybedenler',
                '24 saatte en düşük performans gösteren coinler',
                Icons.trending_down,
                const Color(0xFFF43F5E),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              losersAsync
                  .when(
                    data: (data) => _buildMoversList(data, false),
                    loading: () => _buildLoadingList(),
                    error: (e, _) => _buildErrorCard(e.toString()),
                  )
                  .animate()
                  .fadeIn(delay: 350.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, MarketMetrics metrics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'BTC Fiyat',
                '\$${metrics.btcPrice.toStringAsFixed(2)}',
                Icons.currency_bitcoin,
                const Color(0xFFF59E0B),
                true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'ETH Fiyat',
                '\$${metrics.ethPrice.toStringAsFixed(2)}',
                Icons.diamond_outlined,
                const Color(0xFF6366F1),
                true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                '24h Hacim',
                '\$${_formatLargeNumber(metrics.totalVolume24h)}',
                Icons.swap_horiz,
                const Color(0xFF10B981),
                true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Pariteleri',
                metrics.tradingPairs.toString(),
                Icons.show_chart,
                const Color(0xFF8B5CF6),
                true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildFearGreedCard(metrics),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isPositive,
  ) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isPositive ? Colors.white : const Color(0xFFF43F5E),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFearGreedCard(MarketMetrics metrics) {
    final index = metrics.fearGreedIndex;
    Color getColor() {
      if (index < 25) return const Color(0xFFF43F5E); // Extreme Fear
      if (index < 45) return const Color(0xFFF59E0B); // Fear
      if (index < 55) return const Color(0xFF6366F1); // Neutral
      if (index < 75) return const Color(0xFF10B981); // Greed
      return const Color(0xFF059669); // Extreme Greed
    }

    return Container(
      width: double.infinity,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fear & Greed Index',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Icon(Icons.psychology_outlined, color: getColor(), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                index.toStringAsFixed(0),
                style: TextStyle(
                  color: getColor(),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                metrics.fearGreedLabel,
                style: TextStyle(
                  color: getColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: index / 100,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(getColor()),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeChart(List<VolumeData> data) {
    if (data.isEmpty) {
      return _buildErrorCard('Hacim verisi bulunamadı');
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.volume,
                  color: const Color(0xFF10B981),
                  width: 4,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMoversList(List<TopMover> movers, bool isGainers) {
    return Column(
      children: movers.asMap().entries.map((entry) {
        final index = entry.key;
        final mover = entry.value;
        return _buildMoverItem(mover, isGainers, index + 1)
            .animate()
            .fadeIn(delay: Duration(milliseconds: 50 * index))
            .slideX(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  Widget _buildMoverItem(TopMover mover, bool isGainer, int rank) {
    final color = isGainer ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Symbol & Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mover.symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  mover.name,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          // Price & Change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${mover.price.toStringAsFixed(4)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGainer ? Icons.arrow_upward : Icons.arrow_downward,
                      color: color,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${mover.changePercent24h.abs().toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLargeNumber(double number) {
    if (number >= 1e12) {
      return '${(number / 1e12).toStringAsFixed(2)}T';
    } else if (number >= 1e9) {
      return '${(number / 1e9).toStringAsFixed(2)}B';
    } else if (number >= 1e6) {
      return '${(number / 1e6).toStringAsFixed(2)}M';
    }
    return number.toStringAsFixed(2);
  }

  Widget _buildLoadingCards() {
    return const SizedBox(
      height: 200,
      child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
    );
  }

  Widget _buildLoadingChart() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );
  }

  Widget _buildLoadingList() {
    return const SizedBox(
      height: 100,
      child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
