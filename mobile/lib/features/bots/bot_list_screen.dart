import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'providers/bot_provider.dart';
import 'models/bot_model.dart';

class BotListScreen extends ConsumerStatefulWidget {
  const BotListScreen({super.key});

  @override
  ConsumerState<BotListScreen> createState() => _BotListScreenState();
}

class _BotListScreenState extends ConsumerState<BotListScreen> {
  String _selectedTab = 'Aktif Botlar'; // Aktif Botlar, Geçmiş
  String _activeFilter = 'Hepsi'; // Hepsi, Pozisyonda, Sinyal Bekleniyor

  @override
  Widget build(BuildContext context) {
    final botListAsync = ref.watch(botListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate-950
      appBar: AppBar(
        title: Text(
          'Botlar',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
      ),
      body: botListAsync.when(
        data: (bots) {
          // Calculate counts
          final activeBots = bots
              .where(
                (b) => b.status == 'Running' || b.status == 'WaitingForEntry',
              )
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

          // Filter logic
          List<Bot> displayedBots = [];
          if (_selectedTab == 'Aktif Botlar') {
            if (_activeFilter == 'Hepsi') {
              displayedBots = activeBots;
            } else if (_activeFilter == 'Pozisyonda') {
              displayedBots = activeBots
                  .where((b) => b.status == 'Running')
                  .toList();
            } else if (_activeFilter == 'Sinyal Bekleniyor') {
              displayedBots = activeBots
                  .where((b) => b.status == 'WaitingForEntry')
                  .toList();
            }
          } else {
            displayedBots = historyBots;
          }

          return Column(
            children: [
              // 1. Level Tabs (Active vs History)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Slate-800
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        'Aktif Botlar',
                        activeBots.length,
                        _selectedTab == 'Aktif Botlar',
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        'Geçmiş',
                        historyBots.length,
                        _selectedTab == 'Geçmiş',
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Level Filters (Only for Active Bots)
              if (_selectedTab == 'Aktif Botlar')
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterButton(
                        'Hepsi',
                        activeBots.length,
                        const Color(0xFFF59E0B),
                      ), // Amber
                      const SizedBox(width: 12),
                      _buildFilterButton(
                        'Pozisyonda',
                        inPositionCount,
                        const Color(0xFF10B981),
                      ), // Emerald
                      const SizedBox(width: 12),
                      _buildFilterButton(
                        'Sinyal Bekleniyor',
                        waitingCount,
                        const Color(0xFF3B82F6),
                      ), // Blue
                    ],
                  ),
                ),

              if (_selectedTab == 'Aktif Botlar') const SizedBox(height: 16),

              // Bot List
              Expanded(
                child: displayedBots.isEmpty
                    ? Center(
                        child: Text(
                          'Bot bulunamadı',
                          style: GoogleFonts.inter(color: Colors.white54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          // ignore: unused_result
                          ref.refresh(botListProvider);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: displayedBots.length,
                          itemBuilder: (context, index) {
                            final bot = displayedBots[index];
                            return _buildBotCard(bot)
                                .animate()
                                .fadeIn(delay: (50 * index).ms)
                                .slideX(begin: 0.1, end: 0);
                          },
                        ),
                      ),
              ),
            ],
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
    );
  }

  Widget _buildTabButton(String label, int count, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTab = label;
        // Reset sub-filter when switching tabs? Or keep it?
        // Usually safer to reset or keep assuming logical defaults.
        if (label == 'Aktif Botlar') _activeFilter = 'Hepsi';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF334155) // Slate-700 (Lighter for active)
              : const Color(0xFF1E293B), // Transparent/Base
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon based on label?
            Icon(
              label == 'Aktif Botlar' ? Icons.monitor_heart : Icons.history,
              size: 18,
              color: isSelected ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF475569)
                    : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, int count, Color color) {
    final isSelected = _activeFilter == label;
    // final baseColor = isSelected ? color : const Color(0xFF1E293B);
    // final textColor = isSelected ? Colors.black : Colors.white54;
    // For 'Hepsi', simplify color logic or use specific design
    // The image shows 'Hepsi' as brown/orange button, others as dark with colored dot.

    // Let's implement specific styling per type based on the screenshot description
    // "Hepsi": Solid brownish button (if selected) or outline?
    // "Pozisyonda": Dark bg, Green dot, Green text (or white if simple)
    // Actually, let's follow a cleaner "pill" design where:
    // Selected = Filled with Color (low opacity) + Border
    // Unselected = Dark bg + Border

    // For "Hepsi" specifically it looked like a full button.
    // For others it looked like "Dot + Text + Badge".

    // Let's go with a consistent look first:
    // Filled for selected, Outlined for unselected.

    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white10,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != 'Hepsi') ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? color : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotCard(Bot bot) {
    final isPositive = bot.pnl >= 0;
    final pnlColor = isPositive
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push('/bots/${bot.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.smart_toy,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bot.symbol,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              bot.strategyName,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildStatusBadge(bot.status),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PNL (USDT)',
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${bot.pnl.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: pnlColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'ROI',
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '%${bot.pnlPercent.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: pnlColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'Running':
        color = const Color(0xFF10B981);
        text = 'Çalışıyor';
        break;
      case 'WaitingForEntry':
        color = const Color(0xFF3B82F6);
        text = 'Bekliyor';
        break;
      case 'Stopped':
        color = const Color(0xFF94A3B8);
        text = 'Durdu';
        break;
      case 'Completed':
        color = const Color(0xFF8B5CF6);
        text = 'Tamamlandı';
        break;
      default:
        color = const Color(0xFF94A3B8);
        text = status;
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (status == 'Running') {
      return badge
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(duration: 2000.ms, color: color.withValues(alpha: 0.5));
    }

    return badge;
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 140,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 100, height: 20, color: Colors.white),
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 80, height: 40, color: Colors.white),
                      Container(width: 80, height: 40, color: Colors.white),
                    ],
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
