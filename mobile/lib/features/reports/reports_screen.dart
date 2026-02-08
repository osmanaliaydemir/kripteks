import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:mobile/features/reports/providers/reports_provider.dart';
import 'package:mobile/features/reports/models/reports_model.dart';
import 'package:mobile/features/dashboard/models/dashboard_stats.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/core/theme/app_colors.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final equityAsync = ref.watch(equityCurveProvider);
    final performanceAsync = ref.watch(strategyPerformanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Analiz ve Raporlar'),
      body: Stack(
        children: [
          // Background Gradient (Consistent with other screens)
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
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(equityCurveProvider);
              ref.invalidate(strategyPerformanceProvider);
            },
            color: const Color(0xFFF59E0B),
            backgroundColor: const Color(0xFF1E293B),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Grid
                  statsAsync.when(
                    data: (stats) => _buildStatsGrid(stats),
                    loading: () => _buildShimmerStats(),
                    error: (e, _) => _buildErrorCard(e.toString()),
                  ),
                  const SizedBox(height: 24),

                  // Equity Curve Chart
                  _buildSectionHeader(
                    'Sermaye Büyümesi',
                    'Zaman içindeki toplam bakiye değişimi',
                    Icons.trending_up,
                    const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 12),
                  equityAsync.when(
                    data: (data) => _buildEquityChart(data),
                    loading: () => _buildLoadingChart(),
                    error: (e, _) => _buildErrorCard(e.toString()),
                  ),
                  const SizedBox(height: 24),

                  // Strategy Performance
                  _buildSectionHeader(
                    'Strateji Analizi',
                    'Kullanılan stratejilerin performans verileri',
                    Icons.analytics_outlined,
                    const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 12),
                  performanceAsync.when(
                    data: (data) => _buildPerformanceList(data),
                    loading: () => _buildLoadingList(),
                    error: (e, _) => _buildErrorCard(e.toString()),
                  ),
                  const SizedBox(height: 24),

                  // Comparative Performance (Bar Chart)
                  _buildSectionHeader(
                    'Karşılaştırmalı Performans',
                    'Strateji bazlı kazanç ve verimlilik',
                    Icons.bar_chart_rounded,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  performanceAsync.when(
                    data: (data) => _buildPerformanceBarChart(data),
                    loading: () => _buildLoadingChart(),
                    error: (e, _) => _buildErrorCard(e.toString()),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildStatsGrid(DashboardStats stats) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              'Toplam P/L',
              '+%${stats.totalPnl.toStringAsFixed(2)}',
              Icons.trending_up,
              const Color(0xFF10B981),
              stats.totalPnl >= 0,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Başarı Oranı',
              '%${stats.winRate.toStringAsFixed(1)}',
              Icons.check_circle_outline,
              const Color(0xFFF59E0B),
              true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              'İşlem Sayısı',
              stats.totalTrades.toString(),
              Icons.swap_horiz,
              const Color(0xFF6366F1),
              true,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Max Drawdown',
              '-%${stats.maxDrawdown.toStringAsFixed(2)}',
              Icons.warning_amber_rounded,
              const Color(0xFFF43F5E),
              false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isPositive,
  ) {
    return Expanded(
      child: Container(
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
                color: isPositive
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF43F5E),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquityChart(List<EquityPoint> data) {
    if (data.isEmpty) {
      return _buildErrorCard('Görüntülemek için veri yok');
    }
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: LineChart(
        LineChartData(
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
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.balance))
                  .toList(),
              isCurved: true,
              color: const Color(0xFFF59E0B),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    const Color(0xFFF59E0B).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceList(List<StrategyPerformance> data) {
    if (data.isEmpty) {
      return _buildErrorCard('Strateji verisi bulunamadı');
    }
    return Column(
      children: data.map((item) => _buildPerformanceItem(item)).toList(),
    );
  }

  Widget _buildPerformanceItem(StrategyPerformance item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.strategyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '+%${item.totalPnl.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.winRate / 100,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                item.winRate >= 50
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF43F5E),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Basarı Oranı: %${item.winRate.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                'Profit Factor: ${item.profitFactor.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBarChart(List<StrategyPerformance> data) {
    if (data.isEmpty) {
      return _buildErrorCard('Görüntülemek için veri yok');
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
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.totalPnl,
                  color: const Color(0xFF10B981),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildShimmerStats() {
    return const SizedBox(
      height: 160,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildLoadingChart() {
    return const SizedBox(
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildLoadingList() {
    return const SizedBox(
      height: 100,
      child: Center(child: CircularProgressIndicator()),
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
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }
}
