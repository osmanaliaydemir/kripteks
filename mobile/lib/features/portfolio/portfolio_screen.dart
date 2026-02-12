import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/sensitive_text.dart';
import 'package:mobile/core/providers/privacy_provider.dart';
import 'providers/portfolio_provider.dart';
import 'models/portfolio_model.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  int? _touchedPieIndex;
  late TabController _tabController;

  // Coin'lere özgü renkler
  static const Map<String, Color> _coinColors = {
    'BTC': Color(0xFFF7931A),
    'ETH': Color(0xFF627EEA),
    'BNB': Color(0xFFF3BA2F),
    'SOL': Color(0xFF9945FF),
    'XRP': Color(0xFF00AAE4),
    'ADA': Color(0xFF0033AD),
    'DOT': Color(0xFFE6007A),
    'AVAX': Color(0xFFE84142),
    'MATIC': Color(0xFF8247E5),
    'LINK': Color(0xFF2A5ADA),
    'DOGE': Color(0xFFC3A634),
    'UNI': Color(0xFFFF007A),
    'ATOM': Color(0xFF2E3148),
    'LTC': Color(0xFF345D9D),
    'FTM': Color(0xFF1969FF),
  };

  static const List<Color> _fallbackColors = [
    Color(0xFF06B6D4),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF6366F1),
    Color(0xFF84CC16),
    Color(0xFFEAB308),
  ];

  Color _getAssetColor(String baseAsset, int index) {
    return _coinColors[baseAsset] ??
        _fallbackColors[index % _fallbackColors.length];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portfolioAsync = ref.watch(portfolioSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppHeader(
        title: 'Portföy Yönetimi',
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final isHidden = ref.watch(
                privacyProvider.select((s) => s.isBalanceHidden),
              );
              return IconButton(
                icon: Icon(
                  isHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  ref.read(privacyProvider.notifier).toggleBalanceVisibility();
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
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
                  colors: [
                    Color(0x408B5CF6), // Purple glow
                    Colors.transparent,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: portfolioAsync.when(
              data: (summary) => _buildContent(summary),
              loading: () => _buildLoadingState(),
              error: (err, _) => _buildErrorState(err.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PortfolioSummary summary) {
    if (summary.assetCount == 0) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(portfolioSummaryProvider);
      },
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portföy Değer Kartı
            _buildValueCard(
              summary,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),

            // Tab Bar
            _buildTabBar(),
            const SizedBox(height: 16),

            // Tab Content
            SizedBox(
              height: _getTabContentHeight(summary),
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildDistributionTab(summary),
                  _buildRiskMetricsTab(summary.riskMetrics),
                  _buildRebalancingTab(summary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getTabContentHeight(PortfolioSummary summary) {
    // Dynamic height based on content
    final assetListHeight = summary.assets.length * 88.0 + 280;
    final riskHeight = 650.0;
    final rebalanceHeight = max(
      summary.rebalanceSuggestions.length * 160.0 + 100,
      300.0,
    );
    return max(max(assetListHeight, riskHeight), rebalanceHeight);
  }

  // ═══════════════════════════════════════════════════════════════
  // ██ PORTFÖY DEĞER KARTI
  // ═══════════════════════════════════════════════════════════════

  Widget _buildValueCard(PortfolioSummary summary) {
    final isPnlPositive = summary.totalPnl >= 0;
    final isDailyPositive = summary.dailyPnl >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Toplam Değer
          Text(
            'Toplam Portföy Değeri',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 6),
          SensitiveText(
            '\$${summary.totalValue.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Toplam P&L ve Günlük Değişim
          Row(
            children: [
              Expanded(
                child: _buildMiniMetric(
                  'Toplam K/Z',
                  '${isPnlPositive ? "+" : ""}\$${summary.totalPnl.toStringAsFixed(2)}',
                  '${isPnlPositive ? "+" : ""}${summary.totalPnlPercent.toStringAsFixed(2)}%',
                  isPnlPositive ? AppColors.success : AppColors.error,
                ),
              ),
              Container(width: 1, height: 48, color: Colors.white10),
              Expanded(
                child: _buildMiniMetric(
                  '24s Değişim',
                  '${isDailyPositive ? "+" : ""}\$${summary.dailyPnl.toStringAsFixed(2)}',
                  '${isDailyPositive ? "+" : ""}${summary.dailyPnlPercent.toStringAsFixed(2)}%',
                  isDailyPositive ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Yatırılan ve Varlık Sayısı
          Row(
            children: [
              Expanded(
                child: _buildMiniMetric(
                  'Yatırılan',
                  '\$${summary.totalInvested.toStringAsFixed(2)}',
                  null,
                  Colors.white70,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white10),
              Expanded(
                child: _buildMiniMetric(
                  'Varlık Sayısı',
                  '${summary.assetCount}',
                  null,
                  AppColors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(
    String label,
    String value,
    String? badge,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 4),
        SensitiveText(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        if (badge != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ██ TAB BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.purple,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Dağılım', height: 36),
          Tab(text: 'Risk', height: 36),
          Tab(text: 'Dengeleme', height: 36),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ██ TAB 1: DAĞILIM (Pie Chart + Asset List)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDistributionTab(PortfolioSummary summary) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pie Chart
          _buildPieChart(summary.assets),
          const SizedBox(height: 20),

          // Legend
          _buildChartLegend(summary.assets),
          const SizedBox(height: 20),

          // Asset List
          _buildSectionTitle('Varlıklar', Icons.account_balance_wallet),
          const SizedBox(height: 12),
          ...summary.assets.asMap().entries.map(
            (entry) => _buildAssetItem(entry.value, entry.key)
                .animate()
                .fadeIn(delay: (80 * entry.key).ms)
                .slideX(begin: 0.15, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<PortfolioAsset> assets) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedPieIndex = null;
                    return;
                  }
                  _touchedPieIndex =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            startDegreeOffset: -90,
            borderData: FlBorderData(show: false),
            sectionsSpace: 2,
            centerSpaceRadius: 50,
            sections: assets.asMap().entries.map((entry) {
              final i = entry.key;
              final asset = entry.value;
              final isTouched = i == _touchedPieIndex;
              final color = _getAssetColor(asset.baseAsset, i);

              return PieChartSectionData(
                color: color,
                value: asset.allocationPercent,
                title: isTouched
                    ? '${asset.baseAsset}\n%${asset.allocationPercent.toStringAsFixed(1)}'
                    : '%${asset.allocationPercent.toStringAsFixed(0)}',
                radius: isTouched ? 55 : 45,
                titleStyle: GoogleFonts.inter(
                  fontSize: isTouched ? 11 : 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
                badgePositionPercentageOffset: 0.98,
              );
            }).toList(),
          ),
        ),
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildChartLegend(List<PortfolioAsset> assets) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: assets.asMap().entries.map((entry) {
        final color = _getAssetColor(entry.value.baseAsset, entry.key);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${entry.value.baseAsset} ${entry.value.allocationPercent.toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAssetItem(PortfolioAsset asset, int index) {
    final color = _getAssetColor(asset.baseAsset, index);
    final isPnlPositive = asset.pnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Coin Badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                asset.baseAsset.length > 3
                    ? asset.baseAsset.substring(0, 3)
                    : asset.baseAsset,
                style: GoogleFonts.jetBrainsMono(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      asset.baseAsset,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SensitiveText(
                      '\$${asset.currentValue.toStringAsFixed(2)}',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${asset.quantity.toStringAsFixed(6)} adet • Ort: \$${asset.averageCost.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isPnlPositive
                                    ? AppColors.success
                                    : AppColors.error)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${isPnlPositive ? "+" : ""}${asset.pnlPercent.toStringAsFixed(2)}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: isPnlPositive
                              ? AppColors.success
                              : AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ██ TAB 2: RİSK METRİKLERİ
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRiskMetricsTab(PortfolioRiskMetrics metrics) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk Seviyesi Kartı
          _buildRiskLevelCard(metrics),
          const SizedBox(height: 20),

          // Metrik Kartları
          _buildSectionTitle('Detaylı Metrikler', Icons.analytics),
          const SizedBox(height: 12),

          // Row 1
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Sharpe Ratio',
                  metrics.sharpeRatio.toStringAsFixed(2),
                  'Risk başına getiri',
                  Icons.trending_up,
                  _getSharpeColor(metrics.sharpeRatio),
                  _getSharpeLabel(metrics.sharpeRatio),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  'Sortino Ratio',
                  metrics.sortinoRatio.toStringAsFixed(2),
                  'Düşüş riskine göre getiri',
                  Icons.shield,
                  _getSortinoColor(metrics.sortinoRatio),
                  _getSortinoLabel(metrics.sortinoRatio),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 10),

          // Row 2
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Beta (BTC)',
                  metrics.beta.toStringAsFixed(2),
                  'BTC korelasyonu',
                  Icons.compare_arrows,
                  _getBetaColor(metrics.beta),
                  _getBetaLabel(metrics.beta),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  'Max Drawdown',
                  '%${metrics.maxDrawdown.toStringAsFixed(1)}',
                  'En büyük düşüş',
                  Icons.trending_down,
                  _getDrawdownColor(metrics.maxDrawdown),
                  _getDrawdownLabel(metrics.maxDrawdown),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 10),

          // Row 3
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Volatilite',
                  '${(metrics.volatility * 100).toStringAsFixed(1)}%',
                  'Yıllık dalgalanma',
                  Icons.waves,
                  _getVolatilityColor(metrics.volatility),
                  _getVolatilityLabel(metrics.volatility),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  'Yoğunlaşma',
                  (metrics.concentrationRisk * 100).toStringAsFixed(0),
                  'HHI endeksi',
                  Icons.pie_chart,
                  _getConcentrationColor(metrics.concentrationRisk),
                  _getConcentrationLabel(metrics.concentrationRisk),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildRiskLevelCard(PortfolioRiskMetrics metrics) {
    final riskColor = _getRiskLevelColor(metrics.riskLevel);
    final riskIcon = _getRiskLevelIcon(metrics.riskLevel);

    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [riskColor.withValues(alpha: 0.15), AppColors.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: riskColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: riskColor.withValues(alpha: 0.4)),
                ),
                child: Icon(riskIcon, color: riskColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Genel Risk Seviyesi',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metrics.riskLevel,
                      style: GoogleFonts.inter(
                        color: riskColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Risk gauge
              SizedBox(
                width: 60,
                height: 60,
                child: CustomPaint(
                  painter: _RiskGaugePainter(
                    riskLevel: metrics.riskLevel,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    String badge,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ██ TAB 3: REBALANCING ÖNERİLERİ
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRebalancingTab(PortfolioSummary summary) {
    final suggestions = summary.rebalanceSuggestions;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Dengeleme Önerileri', Icons.balance),
          const SizedBox(height: 8),
          Text(
            'Portföyünüzü optimize etmek için aşağıdaki öneriler değerlendirilebilir.',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),

          if (suggestions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Portföy Dengede',
                          style: GoogleFonts.inter(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Portföy dağılımınız hedef ağırlıklara yakın. Şimdilik herhangi bir dengeleme gerekmiyor.',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms)
          else
            ...suggestions.asMap().entries.map(
              (entry) => _buildRebalanceItem(entry.value)
                  .animate()
                  .fadeIn(delay: (100 * entry.key).ms)
                  .slideY(begin: 0.1, end: 0),
            ),
        ],
      ),
    );
  }

  Widget _buildRebalanceItem(RebalanceSuggestion suggestion) {
    final isBuy = suggestion.action == 'BUY';
    final actionColor = isBuy ? AppColors.success : AppColors.error;
    final actionIcon = isBuy ? Icons.add_circle : Icons.remove_circle;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: actionColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(actionIcon, color: actionColor, size: 20),
              const SizedBox(width: 8),
              Text(
                suggestion.baseAsset,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: actionColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  isBuy ? 'AL' : 'SAT',
                  style: GoogleFonts.inter(
                    color: actionColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar: Current vs Target
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mevcut: %${suggestion.currentPercent.toStringAsFixed(1)}',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Hedef: %${suggestion.targetPercent.toStringAsFixed(1)}',
                          style: GoogleFonts.inter(
                            color: AppColors.purple,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        // Background
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        // Filled
                        FractionallySizedBox(
                          widthFactor: (suggestion.currentPercent / 100).clamp(
                            0,
                            1,
                          ),
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: actionColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        // Target marker
                        Positioned(
                          left:
                              (suggestion.targetPercent / 100).clamp(0, 1) *
                                  (MediaQuery.of(context).size.width - 96) -
                              1,
                          child: Container(
                            width: 2,
                            height: 6,
                            color: AppColors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Suggested amount + reason
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white24, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '≈ \$${suggestion.suggestedAmountUsdt.toStringAsFixed(2)} ${isBuy ? "alım" : "satım"} öneriliyor',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            suggestion.reason,
            style: GoogleFonts.inter(
              color: Colors.white30,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ██ YARDIMCI FONKSİYONLAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.purple, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 72,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 20),
            Text(
              'Portföy Boş',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aktif botlarınız alım yaptığında portföyünüz burada görünecektir.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.purple),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Portföy yüklenemedi',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              icon: const Icon(Icons.refresh, color: AppColors.purple),
              label: Text(
                'Tekrar Dene',
                style: GoogleFonts.inter(color: AppColors.purple),
              ),
              onPressed: () => ref.invalidate(portfolioSummaryProvider),
            ),
          ],
        ),
      ),
    );
  }

  // ── Color / Label Helpers ──

  Color _getRiskLevelColor(String level) => switch (level) {
    'Çok Düşük' => AppColors.success,
    'Düşük' => const Color(0xFF10B981),
    'Orta' => AppColors.primary,
    'Yüksek' => const Color(0xFFF97316),
    'Çok Yüksek' => AppColors.error,
    _ => Colors.white38,
  };

  IconData _getRiskLevelIcon(String level) => switch (level) {
    'Çok Düşük' || 'Düşük' => Icons.shield,
    'Orta' => Icons.warning_amber,
    'Yüksek' || 'Çok Yüksek' => Icons.dangerous,
    _ => Icons.help_outline,
  };

  Color _getSharpeColor(double v) =>
      v > 1 ? AppColors.success : (v > 0 ? AppColors.primary : AppColors.error);
  String _getSharpeLabel(double v) =>
      v > 2 ? 'Mükemmel' : (v > 1 ? 'İyi' : (v > 0 ? 'Zayıf' : 'Kötü'));

  Color _getSortinoColor(double v) => v > 1.5
      ? AppColors.success
      : (v > 0 ? AppColors.primary : AppColors.error);
  String _getSortinoLabel(double v) =>
      v > 2 ? 'Mükemmel' : (v > 1 ? 'İyi' : (v > 0 ? 'Zayıf' : 'Kötü'));

  Color _getBetaColor(double v) => v > 1.5
      ? AppColors.error
      : (v > 1 ? AppColors.primary : AppColors.success);
  String _getBetaLabel(double v) =>
      v > 1.5 ? 'Yüksek Risk' : (v > 1 ? 'Normal' : 'Düşük Risk');

  Color _getDrawdownColor(double v) => v > 20
      ? AppColors.error
      : (v > 10 ? AppColors.primary : AppColors.success);
  String _getDrawdownLabel(double v) =>
      v > 30 ? 'Tehlike' : (v > 15 ? 'Dikkat' : (v > 5 ? 'Normal' : 'Güvenli'));

  Color _getVolatilityColor(double v) => v > 0.8
      ? AppColors.error
      : (v > 0.4 ? AppColors.primary : AppColors.success);
  String _getVolatilityLabel(double v) => v > 0.8
      ? 'Çok Yüksek'
      : (v > 0.4 ? 'Yüksek' : (v > 0.2 ? 'Normal' : 'Düşük'));

  Color _getConcentrationColor(double v) => v > 0.5
      ? AppColors.error
      : (v > 0.25 ? AppColors.primary : AppColors.success);
  String _getConcentrationLabel(double v) => v > 0.5
      ? 'Çok Yoğun'
      : (v > 0.25 ? 'Yoğun' : (v > 0.15 ? 'Normal' : 'Dağınık'));
}

// ═══════════════════════════════════════════════════════════════
// ██ RİSK GAUGE PAINTER
// ═══════════════════════════════════════════════════════════════

class _RiskGaugePainter extends CustomPainter {
  final String riskLevel;
  final Color color;

  _RiskGaugePainter({required this.riskLevel, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.65);
    final radius = size.width * 0.42;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.8,
      pi * 1.4,
      false,
      bgPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final progress = switch (riskLevel) {
      'Çok Düşük' => 0.15,
      'Düşük' => 0.3,
      'Orta' => 0.5,
      'Yüksek' => 0.75,
      'Çok Yüksek' => 0.95,
      _ => 0.0,
    };

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.8,
      pi * 1.4 * progress,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RiskGaugePainter oldDelegate) =>
      riskLevel != oldDelegate.riskLevel || color != oldDelegate.color;
}
