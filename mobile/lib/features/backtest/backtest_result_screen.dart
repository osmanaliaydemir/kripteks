import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models/backtest_model.dart';

class BacktestResultScreen extends StatelessWidget {
  final BacktestResult result;

  const BacktestResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Sonuçlar',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Net Kâr',
                    '\$${result.totalPnl.toStringAsFixed(2)}',
                    result.totalPnl >= 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Başarı %',
                    '%${result.winRate.toStringAsFixed(1)}',
                    Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Equity Curve Chart
            const Text(
              'Bakiye Grafiği',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildEquityChart(),
            ),
            const SizedBox(height: 24),

            // Trade List
            const Text(
              'İşlem Geçmişi',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...result.trades.map((trade) => _buildTradeItem(trade)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeItem(BacktestTrade trade) {
    final isWin = (trade.pnl ?? 0) >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trade.type,
                style: TextStyle(
                  color: trade.type == 'BUY'
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('dd MMM HH:mm').format(trade.entryTime),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          Text(
            '\$${trade.entryPrice.toStringAsFixed(2)} -> \$${(trade.exitPrice ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            trade.pnl != null
                ? '${isWin ? "+" : ""}${trade.pnl!.toStringAsFixed(2)}\$'
                : 'Açık',
            style: TextStyle(
              color: isWin ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquityChart() {
    // Generate simple spots from equity curve or trades if curve not available
    // Assuming equityCurve is list of {time, balance}
    // If not, we simulate from trades for visual demo
    List<FlSpot> spots = [];

    if (result.equityCurve.isNotEmpty) {
      // Parse equity curve
      for (int i = 0; i < result.equityCurve.length; i++) {
        // Simple mapping index to value
        // dynamic val = result.equityCurve[i]['balance'];
        // spots.add(FlSpot(i.toDouble(), (val as num).toDouble()));
        // Note: simplified for demo as actual parsing depends on specific json structure
      }
    }

    // Fallback: build from trades for visual check
    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 0));
      double cumPnl = 0;
      for (int i = 0; i < result.trades.length; i++) {
        cumPnl += (result.trades[i].pnl ?? 0);
        spots.add(FlSpot((i + 1).toDouble(), cumPnl));
      }
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFF59E0B),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
