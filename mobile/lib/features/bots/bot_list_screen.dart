import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/core/theme/app_colors.dart';

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
      backgroundColor: Colors.transparent,
      appBar: const AppHeader(title: 'Botlarım', showBackButton: false),
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
              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        'Aktif Botlar',
                        _selectedTab == 'Aktif Botlar',
                        count: activeBots.length,
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        'Geçmiş',
                        _selectedTab == 'Geçmiş',
                        count: historyBots.length,
                      ),
                    ),
                  ],
                ),
              ),

              // Filters (Only for Active Bots)
              if (_selectedTab == 'Aktif Botlar')
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
                        onRefresh: () async => ref.refresh(botListProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayedBots.length,
                          itemBuilder: (context, index) {
                            return _BotCardItem(
                              bot: displayedBots[index],
                              onStop: () =>
                                  _showStopConfirmation(displayedBots[index]),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
        ),
        error: (err, stack) => Center(
          child: Text('Hata: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected, {int? count}) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTab = title;
        _activeFilter = 'Hepsi';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white60,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black26 : Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : Colors.white10,
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
                    ? const Color(0xFF10B981)
                    : label == 'Sinyal Bekleniyor'
                    ? const Color(0xFFF59E0B)
                    : Colors.white38,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color:
                          (label == 'Pozisyonda'
                                  ? AppColors.success
                                  : label == 'Sinyal Bekleniyor'
                                  ? AppColors.primary
                                  : AppColors.textSecondary)
                              .withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                ],
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
            const SizedBox(width: 4),
            Text(
              '($count)',
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.7)
                    : AppColors.white10,
                fontSize: 11,
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Botu Durdur',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '${bot.symbol} botunu durdurmak istediğinize emin misiniz? Açık pozisyonlar piyasa fiyatından kapatılacaktır.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(botServiceProvider).stopBot(bot.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
}

class _BotCardItem extends StatefulWidget {
  final Bot bot;
  final VoidCallback onStop;

  const _BotCardItem({required this.bot, required this.onStop});

  @override
  State<_BotCardItem> createState() => _BotCardItemState();
}

class _BotCardItemState extends State<_BotCardItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bot = widget.bot;
    final isPositive = bot.pnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Info Row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon Stack
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          bot.symbol.isNotEmpty
                              ? bot.symbol.substring(0, 1)
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _getStatusColor(bot.status),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0F172A),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Middle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              bot.symbol,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildMiniStatusBadge(bot.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.attach_money_rounded,
                              size: 14,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${bot.amount.toInt()} Bakiye',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Right Info (PnL & ROI)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isPositive ? '+' : ''}${bot.pnl.toStringAsFixed(2)}\$',
                      style: TextStyle(
                        color: isPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF43F5E),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isPositive
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF43F5E))
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${bot.pnlPercent < 0 ? '-' : ''}%${bot.pnlPercent.abs().toStringAsFixed(2)} ROI',
                        style: TextStyle(
                          color: isPositive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF43F5E),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                // Strategy & Interval Buttons
                Expanded(
                  child: Row(
                    children: [
                      // Strategy
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            bot.strategyName.toUpperCase().contains('STRATEGY-')
                                ? bot.strategyName.toUpperCase().replaceAll(
                                    'STRATEGY-',
                                    '',
                                  )
                                : bot.strategyName.toUpperCase(),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Interval
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          bot.interval.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Action Icons
                Row(
                  children: [
                    _buildIconAction(
                      icon: Icons.show_chart_rounded,
                      onTap: () => _openTradingView(bot.symbol),
                    ),
                    const SizedBox(width: 8),
                    _buildIconAction(
                      icon: Icons.stop_rounded,
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      iconColor: Colors.redAccent,
                      onTap: widget.onStop,
                    ),
                    const SizedBox(width: 8),
                    _buildIconAction(
                      icon: Icons.open_in_new_rounded,
                      onTap: () => context.push('/bots/${bot.id}'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Logs Accordion
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                onExpansionChanged: (value) {
                  setState(() {
                    _isExpanded = value;
                  });
                },
                title: Row(
                  children: [
                    const Icon(Icons.code, size: 16, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'İŞLEM KAYITLARI',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white24,
                ),
                children: [
                  if (bot.logs != null && bot.logs!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        children: bot.logs!.take(5).map((log) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Text(
                                  _formatTime(log.timestamp),
                                  style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    log.message,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
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
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'LOG KAYDI BULUNAMADI',
                        style: TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color ?? Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
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

  Future<void> _openTradingView(String symbol) async {
    try {
      final url = Uri.parse(
        'https://tr.tradingview.com/chart/RbphTzbt/?symbol=BINANCE:$symbol',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('TradingView açılamadı')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }
}
