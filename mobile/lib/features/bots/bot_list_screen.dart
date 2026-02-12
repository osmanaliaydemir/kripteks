import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/core/error/error_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/bot_provider.dart';
import 'models/bot_model.dart';

class BotListScreen extends ConsumerStatefulWidget {
  const BotListScreen({super.key});

  @override
  ConsumerState<BotListScreen> createState() => _BotListScreenState();
}

class _BotListScreenState extends ConsumerState<BotListScreen> {
  String _selectedTab = 'Aktif Botlar';
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

    // Aktif bot kontrolü
    bool hasActiveBots = false;
    if (botListAsync.value != null) {
      hasActiveBots = botListAsync.value!.items.any(
        (b) => b.status == 'Running' || b.status == 'WaitingForEntry',
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppHeader(
        title: 'Botlarım',
        showBackButton: false,
        actions: hasActiveBots
            ? [
                IconButton(
                  onPressed: () => _showPanicModeDialog(),
                  icon: const Icon(
                    Icons.gpp_bad_rounded,
                    color: AppColors.error,
                    size: 24,
                  ),
                  tooltip: 'Acil Durdurma',
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      floatingActionButton: Container(
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
              child: Icon(Icons.add_rounded, color: Colors.black, size: 22),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: botListAsync.when(
        data: (paginatedState) {
          final bots = paginatedState.items;
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
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
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

              // Filters
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
                        onRefresh: () => ref
                            .read(paginatedBotListProvider.notifier)
                            .refresh(),
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.1)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
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
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
