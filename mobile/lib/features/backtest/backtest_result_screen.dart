import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models/backtest_model.dart';
import 'package:mobile/core/theme/app_colors.dart';

class BacktestResultScreen extends StatelessWidget {
  final BacktestResult result;

  const BacktestResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Simülasyon Sonuçları',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Net Kar/Zarar',
                        '${result.totalPnl >= 0 ? "+" : ""}\$${result.totalPnl.toStringAsFixed(2)}',
                        result.totalPnl >= 0
                            ? AppColors.success
                            : AppColors.error,
                        '${result.totalPnlPercent.toStringAsFixed(2)}%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Başarı Oranı',
                        '%${result.winRate.toStringAsFixed(1)}',
                        AppColors.primary,
                        '${result.winningTrades}/${result.totalTrades} İşlem',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Chart Section
                _buildSectionHeader('Sermaye Eğrisi', Icons.show_chart_rounded),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: _buildEquityChart(),
                ),
                const SizedBox(height: 24),

                // Trade History
                _buildSectionHeader('İşlem Geçmişi', Icons.history_rounded),
                const SizedBox(height: 12),
                if (result.trades.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'İşlem kaydı bulunamadı',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  )
                else
                  ...result.trades.reversed.map(
                    (trade) => _buildTradeItem(trade),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white54),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeItem(BacktestTrade trade) {
    final isWin = trade.pnl >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (trade.type == 'BUY' ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              trade.type == 'BUY'
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: trade.type == 'BUY' ? AppColors.success : AppColors.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trade.type} @ \$${trade.entryPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM, HH:mm').format(trade.entryDate),
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isWin ? "+" : ""}${trade.pnl.toStringAsFixed(2)}\$',
                style: GoogleFonts.inter(
                  color: isWin ? AppColors.success : AppColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Exit: \$${trade.exitPrice.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquityChart() {
    List<FlSpot> spots = [];

    if (result.candles.isNotEmpty) {
      for (int i = 0; i < result.candles.length; i++) {
        spots.add(FlSpot(i.toDouble(), result.candles[i].close));
      }
    }

    if (spots.isEmpty) {
      double currentBalance = 1000;
      spots.add(FlSpot(0, currentBalance));
      for (int i = 0; i < result.trades.length; i++) {
        currentBalance += result.trades[i].pnl;
        spots.add(FlSpot((i + 1).toDouble(), currentBalance));
      }
    }

    if (spots.isEmpty) spots = [const FlSpot(0, 0), const FlSpot(1, 0)];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.03),
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
