import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/error/error_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/bot_provider.dart';
import 'models/bot_model.dart';
import 'package:mobile/core/providers/paginated_provider.dart';
import '../wallet/providers/wallet_provider.dart'; // Add wallet provider import

class BotListScreen extends ConsumerStatefulWidget {
  const BotListScreen({super.key});

  @override
  ConsumerState<BotListScreen> createState() => _BotListScreenState();
}

class _BotListScreenState extends ConsumerState<BotListScreen> {
  String _mainTab = 'Botlarım';
  String _subTab = 'Aktif Botlar';
  String _activeFilter = 'Hepsi';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      ref.read(paginatedBotListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final botListAsync = ref.watch(paginatedBotListProvider);

    // Bot listelerini ve sayaçları hesapla
    final bots = botListAsync.value?.items ?? [];
    final activeBots = bots
        .where((b) => b.status == 'Running' || b.status == 'WaitingForEntry')
        .toList();
    final historyBots = bots
        .where((b) => b.status == 'Stopped' || b.status == 'Completed')
        .toList();

    final inPositionCount = activeBots
        .where((b) => b.status == 'Running')
        .length;
    final waitingCount = activeBots
        .where((b) => b.status == 'WaitingForEntry')
        .length;

    // Aktif bot kontrolü (Header için)
    bool hasActiveBots = activeBots.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                                'Botlarım',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: 4),
                          Text(
                                'Otomatik strateji yönetimi',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white54,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 200.ms)
                              .slideY(begin: 0.2, end: 0),
                        ],
                      ),
                      if (hasActiveBots)
                        IconButton(
                          onPressed: () => _showPanicModeDialog(),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.error.withValues(
                              alpha: 0.1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.gpp_bad_rounded,
                            color: AppColors.error,
                            size: 24,
                          ),
                          tooltip: 'Acil Durdurma',
                        ),
                    ],
                  ),
                ),

                // Main Tabs (Botlarım / Keşfet)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMainTabButton(
                          'Botlarım',
                          Icons.smart_toy_rounded,
                          _mainTab == 'Botlarım',
                        ),
                      ),
                      Expanded(
                        child: _buildMainTabButton(
                          'Keşfet',
                          Icons.explore_rounded,
                          _mainTab == 'Keşfet',
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _mainTab == 'Keşfet'
                      ? _buildDiscoveryTab()
                      : _buildMyBotsTab(
                          botListAsync,
                          activeBots,
                          historyBots,
                          botListAsync.value,
                          inPositionCount,
                          waitingCount,
                        ),
                ),
              ],
            ),
          ),

          if (_mainTab == 'Botlarım')
            Positioned(
              right: 16,
              bottom: 110,
              child:
                  Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFFE6C200)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push('/bots/create'),
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.black,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(begin: const Offset(0.8, 0.8)),
            ),
        ],
      ),
    );
  }

  Widget _buildMainTabButton(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        setState(() {
          _mainTab = title;
        });
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : Colors.white60,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.black : Colors.white60,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (title == 'Keşfet') ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'BETA',
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.black54 : AppColors.primary,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryTab() {
    return CustomScrollView(
      slivers: [
        // 1. Spotlight Section Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Günün Fırsatları',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Spotlight Carousel
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSpotlightCard(
                  title: 'MoonWalker 🚀',
                  subtitle: 'Yüksek volatilite avcısı',
                  apy: '%120',
                  risk: 'YÜKSEK RİSK',
                  color1: const Color(0xFF8B5CF6),
                  color2: const Color(0xFFEC4899),
                  onTap: () => _showQuickCreateDialog('MoonWalker'),
                ),
                const SizedBox(width: 12),
                _buildSpotlightCard(
                  title: 'AI Trend Master',
                  subtitle: 'Yapay zeka destekli trend takibi',
                  apy: '%65',
                  risk: 'ORTA RİSK',
                  color1: const Color(0xFF3B82F6),
                  color2: const Color(0xFF06B6D4),
                  onTap: () => _showQuickCreateDialog('AI Trend Master'),
                ),
                const SizedBox(width: 12),
                _buildSpotlightCard(
                  title: 'Stable Growth',
                  subtitle: 'Düşük risk, sürekli kazanç',
                  apy: '%25',
                  risk: 'DÜŞÜK RİSK',
                  color1: const Color(0xFF10B981),
                  color2: const Color(0xFF34D399),
                  onTap: () => _showQuickCreateDialog('Stable Growth'),
                ),
              ],
            ),
          ),
        ),

        // 3. Categories / Grid Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tüm Stratejiler',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Filtrele',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. Strategy Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75, // Taller cards
            ),
            delegate: SliverChildListDelegate([
              _buildStrategyGridCard(
                    title: 'Dengeli Sepet',
                    risk: 'Orta',
                    apy: '%42',
                    users: '1.2k',
                    icon: Icons.balance_rounded,
                    color: const Color(0xFF3B82F6),
                    onTap: () => _showQuickCreateDialog('Dengeli Sepet'),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
              _buildStrategyGridCard(
                    title: 'Scalp King',
                    risk: 'Yüksek',
                    apy: '%180',
                    users: '850',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () => _showQuickCreateDialog('Scalp King'),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
              _buildStrategyGridCard(
                    title: 'Altcoin Gem',
                    risk: 'Yüksek',
                    apy: '%95',
                    users: '2.4k',
                    icon: Icons.diamond_rounded,
                    color: const Color(0xFFA855F7),
                    onTap: () => _showQuickCreateDialog('Altcoin Gem'),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
              _buildStrategyGridCard(
                    title: 'BTC Accumulator',
                    risk: 'Düşük',
                    apy: '%18',
                    users: '5k+',
                    icon: Icons.currency_bitcoin_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () => _showQuickCreateDialog('BTC Accumulator'),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
              _buildStrategyGridCard(
                    title: 'ETH Killer',
                    risk: 'Orta',
                    apy: '%55',
                    users: '1.8k',
                    icon: Icons.layers_rounded,
                    color: const Color(0xFF6366F1),
                    onTap: () => _showQuickCreateDialog('ETH Killer'),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
              _buildStrategyGridCard(
                    title: 'DeFi Farmer',
                    risk: 'Düşük',
                    apy: '%22',
                    users: '920',
                    icon: Icons.local_florist_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => _showQuickCreateDialog('DeFi Farmer'),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 500.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
            ]),
          ),
        ),

        // Bottom Padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildSpotlightCard({
    required String title,
    required String subtitle,
    required String apy,
    required String risk,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    // Risk rengini belirle
    final riskColor = risk.contains('YÜKSEK')
        ? AppColors.error
        : risk.contains('DÜŞÜK')
        ? AppColors.success
        : const Color(0xFFF59E0B);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: color1.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background Glow
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: color1.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color1.withValues(alpha: 0.15),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: riskColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: riskColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            risk,
                            style: GoogleFonts.inter(
                              color: riskColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yıllık Getiri',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              apy,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.success,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: color1,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrategyGridCard({
    required String title,
    required String risk,
    required String apy,
    required String users,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final riskColor = risk.contains('Yüksek')
        ? AppColors.error
        : risk.contains('Düşük')
        ? AppColors.success
        : const Color(0xFFF59E0B);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Glow
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: riskColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: riskColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            risk,
                            style: GoogleFonts.inter(
                              color: riskColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 14,
                          color: Colors.white38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$users kullanım',
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'APY',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            apy,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickCreateDialog(String strategyName) {
    // Mock strateji detayları
    final details = _getStrategyDetails(strategyName);
    final amountController = TextEditingController(text: '100');
    double sliderValue = 100;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Consumer(
            builder: (context, ref, child) {
              final walletAsync = ref.watch(walletDetailsProvider);
              final availableBalance =
                  walletAsync.value?.availableBalance ?? 0.0;
              final maxInvest = availableBalance > 100
                  ? availableBalance
                  : 100.0;
              final isBalanceSufficient = sliderValue <= availableBalance;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header & Close Button
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Handle Bar
                              Container(
                                width: 48,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                              // Close Button
                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white70,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: details['color'].withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                details['icon'],
                                color: details['color'],
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strategyName,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: details['color'].withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      details['risk'],
                                      style: GoogleFonts.inter(
                                        color: details['color'],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description
                        Text(
                          details['description'],
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Stats Grid
                        Row(
                          children: [
                            _buildDetailStat(
                              'Beklenen APY',
                              details['apy'],
                              const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 16),
                            _buildDetailStat(
                              'Win Rate',
                              details['winRate'],
                              const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 16),
                            _buildDetailStat(
                              'Aktif Bot',
                              details['activeUsers'],
                              Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Supported Pairs
                        Text(
                          'Önerilen Pariteler',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Wrap(
                            spacing: 8,
                            children: (details['pairs'] as List<String>)
                                .map(
                                  (pair) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      pair,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                        // Investment Input
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Yatırım Tutarı (USDT)',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            walletAsync.when(
                              data: (wallet) => Text(
                                'Kullanılabilir: \$${wallet.availableBalance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              loading: () => const SizedBox(
                                height: 12,
                                width: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white54,
                                ),
                              ),
                              error: (_, _) => const Text(
                                'Bakiye Hatası',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isBalanceSufficient
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : AppColors.error,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '\$',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isBalanceSufficient
                                          ? AppColors.primary
                                          : AppColors.error,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 150,
                                    child: TextField(
                                      controller: amountController,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (value) {
                                        final val = double.tryParse(value);
                                        if (val != null) {
                                          setModalState(() {
                                            sliderValue = val.clamp(
                                              100,
                                              maxInvest,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: isBalanceSufficient
                                      ? AppColors.primary
                                      : AppColors.error,
                                  inactiveTrackColor: Colors.white10,
                                  thumbColor: Colors.white,
                                  overlayColor:
                                      (isBalanceSufficient
                                              ? AppColors.primary
                                              : AppColors.error)
                                          .withValues(alpha: 0.2),
                                ),
                                child: Slider(
                                  value: sliderValue,
                                  min: 100,
                                  max: maxInvest,
                                  divisions: (maxInvest / 10).round() > 0
                                      ? (maxInvest / 10).round()
                                      : 1,
                                  onChanged: (value) {
                                    setModalState(() {
                                      sliderValue = value;
                                      amountController.text = value
                                          .toInt()
                                          .toString();
                                    });
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Min: \$100',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        sliderValue = maxInvest;
                                        amountController.text = maxInvest
                                            .toInt()
                                            .toString();
                                      });
                                    },
                                    child: Text(
                                      'Max: \$${maxInvest.toInt()}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Profit Simulator
                        if (isBalanceSufficient) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_graph_rounded,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tahmini Getiri Simülasyonu',
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildProfitBox(
                                        'Aylık Ortalama',
                                        '\$${(sliderValue * (double.tryParse(details['apy'].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0) / 100 / 12).toStringAsFixed(1)}',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildProfitBox(
                                        'Yıllık Toplam',
                                        '\$${(sliderValue * (double.tryParse(details['apy'].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0) / 100).toStringAsFixed(1)}',
                                        isHighlight: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (!isBalanceSufficient)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Yetersiz bakiye. Lütfen bakiyeyi kontrol edin.',
                                  style: GoogleFonts.inter(
                                    color: AppColors.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        SizedBox(
                          width: double.infinity,
                          child: Row(
                            children: [
                              // Cancel Button (25%)
                              Expanded(
                                flex: 1,
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.05,
                                    ),
                                    foregroundColor: Colors.white70,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Start Button (75%)
                              Expanded(
                                flex: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: isBalanceSufficient
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: isBalanceSufficient
                                        ? () {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '$strategyName botu \$${amountController.text} ile kuruldu!',
                                                ),
                                                backgroundColor:
                                                    AppColors.success,
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      disabledBackgroundColor: Colors.white10,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: Icon(
                                      Icons.rocket_launch_rounded,
                                      color: isBalanceSufficient
                                          ? Colors.black
                                          : Colors.white38,
                                      size: 20,
                                    ),
                                    label: Text(
                                      'Botu Başlat',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isBalanceSufficient
                                            ? Colors.black
                                            : Colors.white38,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitBox(
    String title,
    String value, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: isHighlight
            ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: isHighlight ? const Color(0xFF10B981) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStrategyDetails(String name) {
    // Varsayılan değerler
    Map<String, dynamic> details = {
      'description':
          'Optimize edilmiş algoritma ile piyasa fırsatlarını değerlendirir.',
      'apy': '%45',
      'winRate': '%68',
      'activeUsers': '1.2k',
      'risk': 'ORTA RİSK',
      'color': const Color(0xFF3B82F6),
      'icon': Icons.smart_toy_rounded,
      'pairs': ['BTC/USDT', 'ETH/USDT'],
    };

    if (name.contains('MoonWalker')) {
      details = {
        'description':
            'Yüksek volatilite dönemlerinde agresif alım-satım yaparak kısa vadeli fiyat hareketlerinden maksimum kar elde etmeyi hedefler.',
        'apy': '%120',
        'winRate': '%45',
        'activeUsers': '342',
        'risk': 'YÜKSEK RİSK',
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.rocket_launch_rounded,
        'pairs': ['PEPE/USDT', 'DOGE/USDT', 'SOL/USDT'],
      };
    } else if (name.contains('Stable') || name.contains('Accumulator')) {
      details = {
        'description':
            'Düşük riskli, sermaye koruma odaklı strateji. Ani düşüşlerde alım yapmaz, sadece onaylanmış trendlerde işlem açar.',
        'apy': '%25',
        'winRate': '%85',
        'activeUsers': '5.4k',
        'risk': 'DÜŞÜK RİSK',
        'color': const Color(0xFF10B981),
        'icon': Icons.shield_rounded,
        'pairs': ['BTC/USDT', 'ETH/USDT', 'BNB/USDT'],
      };
    } else if (name.contains('Scalp')) {
      details = {
        'description':
            'Dakikalık grafiklerde küçük fiyat değişimlerinden kar eden hiper-aktif bot. Günde 50+ işlem açabilir.',
        'apy': '%180',
        'winRate': '%52',
        'activeUsers': '850',
        'risk': 'ÇOK YÜKSEK',
        'color': const Color(0xFFEF4444),
        'icon': Icons.bolt_rounded,
        'pairs': ['XRP/USDT', 'MATIC/USDT'],
      };
    }

    return details;
  }

  Widget _buildMyBotsTab(
    AsyncValue<PaginatedState<Bot>> botListAsync,
    List<Bot> activeBots,
    List<Bot> historyBots,
    PaginatedState<Bot>? paginatedState,
    int inPositionCount,
    int waitingCount,
  ) {
    List<Bot> displayedBots = [];

    if (_subTab == 'Aktif Botlar') {
      if (_activeFilter == 'Hepsi') {
        displayedBots = activeBots;
      } else if (_activeFilter == 'Pozisyonda') {
        displayedBots = activeBots.where((b) => b.status == 'Running').toList();
      } else if (_activeFilter == 'Sinyal Bekleniyor') {
        displayedBots = activeBots
            .where((b) => b.status == 'WaitingForEntry')
            .toList();
      }
    } else {
      displayedBots = historyBots;
    }

    return botListAsync.when(
      data: (paginatedState) {
        return Column(
          children: [
            // Sub Tabs - Minimalist Style
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  _buildMinimalSubTab(
                    'Aktif Botlar',
                    _subTab == 'Aktif Botlar',
                    count: activeBots.length,
                  ),
                  const SizedBox(width: 24),
                  _buildMinimalSubTab(
                    'Geçmiş',
                    _subTab == 'Geçmiş',
                    count: historyBots.length,
                  ),
                ],
              ),
            ),

            // Filters
            if (_subTab == 'Aktif Botlar')
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildFilterChip('Hepsi', activeBots.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pozisyonda', inPositionCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Sinyal Bekleniyor', waitingCount),
                  ],
                ),
              ),

            // List
            Expanded(
              child: displayedBots.isEmpty
                  ? Center(
                      child: Text(
                        'Bot bulunamadı',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(paginatedBotListProvider.notifier).refresh(),
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        itemCount:
                            displayedBots.length +
                            (paginatedState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= displayedBots.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            );
                          }
                          return _BotCardItem(
                            bot: displayedBots[index],
                            onStop: () =>
                                _showStopConfirmation(displayedBots[index]),
                            onTap: () => context.push(
                              '/bots/${displayedBots[index].id}',
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Hata: $err',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildMinimalSubTab(String title, bool isSelected, {int? count}) {
    return GestureDetector(
      onTap: () => setState(() {
        _subTab = title;
        _activeFilter = 'Hepsi';
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: GoogleFonts.inter(
                      color: isSelected
                          ? Colors.black
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // Animated Indicator
          AnimatedContainer(
            duration: 200.ms,
            height: 3,
            width: isSelected ? 24 : 0,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white10,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: label == 'Pozisyonda'
                    ? AppColors.success
                    : label == 'Sinyal Bekleniyor'
                    ? AppColors.primary
                    : Colors.white38,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.3),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStopConfirmation(Bot bot) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Botu Durdur',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${bot.symbol} botunu durdurmak istediğinize emin misiniz? Açık pozisyonlar piyasa fiyatından kapatılacaktır.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(botServiceProvider).stopBot(bot.id);
                ref.invalidate(paginatedBotListProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${bot.symbol} botu durduruldu'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ErrorHandler.showError(context, e);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Durdur',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showPanicModeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E0F0F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.error, width: 2),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              'ACİL DURDURMA!',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu işlem şunları yapacaktır:',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildPanicItem('Tüm aktif botlar durdurulacak.'),
            _buildPanicItem('Açık pozisyonlar piyasa fiyatından satılacak.'),
            _buildPanicItem('Bekleyen tüm emirler iptal edilecek.'),
            const SizedBox(height: 16),
            Text(
              'Bu işlem geri alınamaz. Devam etmek istediğinize emin misiniz?',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Vazgeç',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executePanicProtocol();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'EVET, DURDUR',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanicItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executePanicProtocol() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: AppColors.surface,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.error),
                SizedBox(height: 16),
                Text(
                  'Acil Durdurma Protokolü İşleniyor...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final botService = ref.read(botServiceProvider);

      final result = await botService.getBots(page: 1, pageSize: 1000);

      final activeBots = result.items
          .where((b) => b.status == 'Running' || b.status == 'WaitingForEntry')
          .toList();

      if (activeBots.isEmpty) {
        if (mounted) Navigator.pop(context);
        _showResultDialog(
          success: true,
          message: 'Durdurulacak aktif bot bulunamadı.',
        );
        return;
      }

      final futures = activeBots.map((bot) => botService.stopBot(bot.id));
      await Future.wait(futures);

      ref.invalidate(paginatedBotListProvider);

      if (mounted) Navigator.pop(context);
      _showResultDialog(
        success: true,
        message:
            '${activeBots.length} adet bot ve ilişkili pozisyonlar başarıyla durduruldu.',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showResultDialog(
        success: false,
        message:
            'Bazı işlemler başarısız oldu: $e\nLütfen bakiyenizi borsadan manuel kontrol edin.',
      );
    }
  }

  void _showResultDialog({required bool success, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.error_outline,
              color: success ? AppColors.success : AppColors.error,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              success ? 'İşlem Tamamlandı' : 'Hata Oluştu',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: success ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

class _BotCardItem extends StatefulWidget {
  final Bot bot;
  final VoidCallback onStop;
  final VoidCallback onTap;

  const _BotCardItem({
    required this.bot,
    required this.onStop,
    required this.onTap,
  });

  @override
  State<_BotCardItem> createState() => _BotCardItemState();
}

class _BotCardItemState extends State<_BotCardItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bot = widget.bot;
    final isPositive = bot.pnl >= 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Center(
                      child: Text(
                        bot.symbol.isNotEmpty
                            ? bot.symbol.substring(0, 1)
                            : '?',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bot.symbol,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _getStatusColor(bot.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStatusLabel(bot.status),
                              style: GoogleFonts.inter(
                                color: _getStatusColor(
                                  bot.status,
                                ).withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (bot.status != 'WaitingForEntry')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isPositive ? '+' : ''}${bot.pnl.toStringAsFixed(2)}\$',
                          style: GoogleFonts.inter(
                            color: isPositive
                                ? AppColors.success
                                : AppColors.error,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${bot.pnlPercent < 0 ? '-' : ''}%${bot.pnlPercent.abs().toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                color: isPositive
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Action Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: _buildSmallChip(
                            bot.strategyName.toUpperCase().contains('STRATEGY-')
                                ? bot.strategyName.toUpperCase().replaceFirst(
                                    'STRATEGY-',
                                    '',
                                  )
                                : bot.strategyName.toUpperCase(),
                            color: Colors.white.withValues(alpha: 0.05),
                            textColor: Colors.white38,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildSmallChip(
                          bot.interval.toUpperCase(),
                          color: AppColors.primary.withValues(alpha: 0.1),
                          textColor: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        _buildSmallChip(
                          '${bot.amount.toInt()}\$',
                          color: Colors.white.withValues(alpha: 0.03),
                          textColor: Colors.white38,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      _buildMinimalAction(
                        icon: Icons.show_chart_rounded,
                        onTap: () => _openTradingView(bot.symbol, bot.interval),
                      ),
                      const SizedBox(width: 6),
                      _buildMinimalAction(
                        icon: Icons.stop_rounded,
                        color: AppColors.error.withValues(alpha: 0.1),
                        iconColor: AppColors.error,
                        onTap: widget.onStop,
                      ),
                      const SizedBox(width: 6),
                      _buildMinimalAction(
                        icon: Icons.keyboard_arrow_right_rounded,
                        onTap: () => context.push('/bots/${bot.id}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Logs
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white10, width: 0.5),
                ),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  onExpansionChanged: (value) =>
                      setState(() => _isExpanded = value),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'İŞLEM KAYITLARI',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  trailing: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white12,
                    size: 20,
                  ),
                  children: [
                    if (bot.logs != null && bot.logs!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          children: bot.logs!.take(3).map((log) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Text(
                                    _formatTime(log.timestamp),
                                    style: const TextStyle(
                                      color: Colors.white24,
                                      fontSize: 9,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      log.message,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallChip(
    String label, {
    required Color color,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalAction({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color ?? Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor ?? Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Future<void> _openTradingView(String symbol, String interval) async {
    try {
      final tvInterval = _mapIntervalToTradingView(interval);
      // 1. Try to open directly in the TradingView App using custom scheme with path-based symbol
      // Format: tradingview://chart/EXCHANGE:SYMBOL?interval=INTERVAL
      final appUrl = Uri.parse(
        'tradingview://chart/BINANCE:$symbol?interval=$tvInterval',
      );

      // Attempt to launch the app scheme
      final bool launchedApp = await launchUrl(
        appUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launchedApp) {
        // 2. Fallback to Browser if app is not installed or doesn't support the scheme
        final webUrl = Uri.parse(
          'https://tr.tradingview.com/chart/RbphTzbt/?symbol=BINANCE:$symbol&interval=$tvInterval',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // 3. Last fallback: try browser directly if first attempt threw error
      try {
        final tvInterval = _mapIntervalToTradingView(interval);
        final webUrl = Uri.parse(
          'https://tr.tradingview.com/chart/RbphTzbt/?symbol=BINANCE:$symbol&interval=$tvInterval',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalNonBrowserApplication);
      } catch (innerError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('TradingView açılamadı')),
          );
        }
      }
    }
  }

  String _mapIntervalToTradingView(String interval) {
    // interval formats like "1m", "15m", "1h", "4h", "1d"
    final clean = interval.toLowerCase().trim();
    if (clean.endsWith('m')) {
      // "15m" -> "15"
      return clean.replaceAll('m', '');
    } else if (clean.endsWith('h')) {
      // "1h" -> "60", "4h" -> "240"
      final hours = int.tryParse(clean.replaceAll('h', '')) ?? 1;
      return (hours * 60).toString();
    } else if (clean.endsWith('d')) {
      // "1d" -> "1D" or just "D"
      // TradingView often uses "1D", "1W", "1M" for daily/weekly/monthly
      return clean.toUpperCase();
    } else if (clean.endsWith('w')) {
      return clean.toUpperCase(); // "1w" -> "1W"
    } else if (clean.endsWith('M')) {
      return clean.toUpperCase(); // "1M" -> "1M"
    }
    return '60'; // default to 1h
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Running':
        return 'POZİSYONDA';
      case 'WaitingForEntry':
        return 'BEKLİYOR';
      case 'Stopped':
        return 'DURDU';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Running':
        return const Color(0xFF10B981);
      case 'WaitingForEntry':
        return const Color(0xFFF59E0B);
      case 'Stopped':
        return const Color(0xFFF43F5E);
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
  }
}
