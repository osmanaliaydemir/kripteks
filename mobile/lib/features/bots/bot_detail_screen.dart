import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/features/bots/providers/bot_provider.dart';
import 'package:mobile/features/bots/models/bot_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BotDetailScreen extends ConsumerWidget {
  final String botId;

  const BotDetailScreen({super.key, required this.botId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final botAsync = ref.watch(botDetailProvider(botId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'İşlem Detayları',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: botAsync.when(
        data: (bot) => _buildContent(context, ref, bot),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Hata: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Bot bot) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bot.symbol,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          bot.strategyName,
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusChip(bot.status),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Tutar', '\$${bot.amount}'),
                    _buildStatItem(
                      'Giriş',
                      bot.entryPrice > 0 ? '\$${bot.entryPrice}' : '-',
                    ),
                    _buildStatItem(
                      'PNL',
                      '\$${bot.pnl.toStringAsFixed(2)}',
                      color: bot.pnl >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Actions
          if (bot.status == 'Running' || bot.status == 'WaitingForEntry') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _stopBot(ref, context),
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Durdur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 32),
          ],

          Text(
            'İşlem Kayıtları', // Changed from 'Geçmiş İşlemler'
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 16),

          if (bot.logs != null && bot.logs!.isNotEmpty) ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bot.logs!.length,
              itemBuilder: (context, index) {
                final log = bot.logs![index];
                final isInfo = log.logLevel == 'INFO';
                final isError = log.logLevel == 'ERROR';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isInfo
                                  ? const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.2)
                                  : isError
                                  ? const Color(
                                      0xFFEF4444,
                                    ).withValues(alpha: 0.2)
                                  : const Color(
                                      0xFF3B82F6,
                                    ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.logLevel,
                              style: TextStyle(
                                color: isInfo
                                    ? const Color(0xFF10B981)
                                    : isError
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF3B82F6),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(log.timestamp),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        log.message,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (50 * index).ms).slideX();
              },
            ),
          ] else ...[
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.terminal_rounded, size: 48, color: Colors.white10),
                  const SizedBox(height: 16),
                  const Text(
                    "Henüz log kaydı yok",
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: color ?? Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
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
      default:
        color = const Color(0xFF94A3B8);
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _stopBot(WidgetRef ref, BuildContext context) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Botu Durdur',
      'Botu durdurmak istediğinize emin misiniz? Açık pozisyonlar manuel yönetilmelidir.',
    );

    if (confirmed != true) return;

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bot durduruluyor...')));
      }

      await ref.read(botServiceProvider).stopBot(botId);

      // Refresh bot details
      ref.invalidate(botDetailProvider(botId));
      ref.invalidate(botListProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bot durduruldu')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Evet',
              style: TextStyle(color: Color(0xFFF59E0B)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}
