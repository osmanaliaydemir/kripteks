import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'models/dashboard_stats.dart';
import 'providers/dashboard_provider.dart';
import '../wallet/providers/wallet_provider.dart';
import '../wallet/wallet_screen.dart';
import '../bots/bot_list_screen.dart';
import '../bots/providers/bot_provider.dart';
import '../bots/models/bot_model.dart';

class DashboardPanel extends ConsumerWidget {
  const DashboardPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    // Scaffold and AppBar removed to use parent DashboardScreen's AppBar
    return RefreshIndicator(
      onRefresh: () async {
        // ignore: unused_result
        ref.refresh(dashboardStatsProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statsAsync.when(
              data: (stats) => _buildStatsGrid(context, stats),
              error: (err, stack) => Center(
                child: Text(
                  'Hata: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
              ),
            ),
            const SizedBox(height: 24),
            // Placeholder for future charts or lists
            // New Stats Row 1
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Bugünkü Kazanç',
                    value:
                        '+\$0.00', // Placeholder as per instructions (needs backend filter)
                    icon: Icons.calendar_today,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      // Calculate approximate total invested from bot list amount sum
                      // This is 'Total Invested' in ACTIVE/HISTORY bots known to client
                      final botListAsync = ref.watch(botListProvider);
                      final totalInvested =
                          botListAsync.asData?.value
                              .map((b) => b.amount)
                              .fold(0.0, (sum, amount) => sum + amount) ??
                          0.0;

                      return _buildStatCard(
                        title: 'Toplam Yatırım',
                        value: '\$${totalInvested.toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet,
                        color: const Color(0xFF3B82F6), // Blue
                      );
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 12),

            // New Stats Row 2 (En Çok Kazandıran Bot moved here or duplicated?)
            // The user request implies adding these, possibly keeping or moving existing ones.
            // Existing 'En Çok Kazandıran Bot' is in the grid above (Best Pair).
            // Actually 'En Çok Kazandıran Bot' (Specific Bot) is different from 'Best Pair'.
            // Let's add 'En Çok Kazandıran Bot' as a full width or half width card here.
            Consumer(
              builder: (context, ref, child) {
                final botListAsync = ref.watch(botListProvider);
                final bots = botListAsync.asData?.value ?? [];

                // Find bot with max PnL
                Bot? bestBot;
                if (bots.isNotEmpty) {
                  bestBot = bots.reduce(
                    (curr, next) => curr.pnl > next.pnl ? curr : next,
                  );
                }

                // If best bot PnL is negative, maybe don't show "Best"? Or show lease worst?
                // Usually 'Best' implies high positive.
                final bestVal = (bestBot != null && bestBot.pnl > 0)
                    ? '+\$${bestBot.pnl.toStringAsFixed(2)} (${bestBot.symbol})'
                    : '-';

                return _buildStatCard(
                  title: 'En Çok Kazandıran Bot',
                  value: bestVal,
                  icon: Icons.emoji_events,
                  color: const Color(0xFFF59E0B), // Amber
                );
              },
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardStats stats) {
    return Column(
      children: [
        // Total PnL Card (Big)
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WalletScreen()),
          ),
          child: _buildStatCard(
            title: 'Toplam Kâr/Zarar',
            value: '\$${stats.totalPnl.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: stats.totalPnl >= 0
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            isLarge: true,
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Ort. İşlem Kârı',
                value: '\$${stats.avgTradePnL.toStringAsFixed(2)}',
                icon: Icons.show_chart,
                color: stats.avgTradePnL >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final walletDetailsAsync = ref.watch(walletDetailsProvider);
                  final lockedBalance =
                      walletDetailsAsync.asData?.value.lockedBalance ?? 0.0;

                  return _buildStatCard(
                    title: 'Mevcut Bot Bakiyesi',
                    value: '\$${lockedBalance.toStringAsFixed(2)}',
                    icon: Icons.savings,
                    color: const Color(0xFFF59E0B),
                  );
                },
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BotListScreen(),
                  ),
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    final botListAsync = ref.watch(botListProvider);
                    final activeBotCount =
                        botListAsync.asData?.value
                            .where(
                              (b) =>
                                  b.status == 'Running' ||
                                  b.status == 'WaitingForEntry',
                            )
                            .length ??
                        0;

                    return _buildStatCard(
                      title: 'Aktif İşlemler',
                      value: '$activeBotCount adet bot aktif işlemde',
                      icon: Icons.smart_toy,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'En İyi Parite',
                value: stats.bestPair.isEmpty ? '-' : stats.bestPair,
                icon: Icons.star,
                color: const Color(0xFFF59E0B), // Amber
              ),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLarge = false,
  }) {
    // Determine background decoration based on card type to add visual hierarchy
    final isPnlCard = title == 'Toplam Kâr/Zarar';

    BoxDecoration decoration;

    if (isPnlCard) {
      // Different gradient for positive/negative PnL
      final isPositive = !value.contains('-');
      final gradientColors = isPositive
          ? [
              const Color(0xFF064E3B), // Dark Emerald
              const Color(0xFF1E293B), // Slate-800
            ]
          : [
              const Color(0xFF7F1D1D), // Dark Red
              const Color(0xFF1E293B), // Slate-800
            ];

      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else {
      decoration = BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          SizedBox(height: isLarge ? 16 : 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isLarge ? 32 : (value.contains('adet') ? 14 : 20),
              fontWeight: FontWeight.bold,
              color: isPnlCard ? Colors.white : Colors.white,
            ),
          ),
          if (isPnlCard) ...[
            const SizedBox(height: 4),
            Text(
              'Toplam bakiye değişimi',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
