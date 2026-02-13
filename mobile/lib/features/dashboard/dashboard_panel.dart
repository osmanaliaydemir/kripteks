import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/sensitive_text.dart';
import 'models/dashboard_stats.dart';
import 'providers/dashboard_provider.dart';
import 'providers/dashboard_layout_provider.dart';
import '../wallet/providers/wallet_provider.dart';
import '../wallet/wallet_screen.dart';
import '../bots/bot_list_screen.dart';
import '../bots/providers/bot_provider.dart';
import '../bots/models/bot_model.dart';
import 'package:mobile/l10n/app_localizations.dart';

class DashboardPanel extends ConsumerWidget {
  const DashboardPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final layoutState = ref.watch(dashboardLayoutProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // ignore: unused_result
        ref.refresh(dashboardStatsProvider);
      },
      child: statsAsync.when(
        data: (stats) => _buildLayout(context, ref, stats, layoutState),
        error: (err, stack) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Text(
                'Hata: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
        ),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
    DashboardLayoutState layoutState,
  ) {
    if (layoutState.isEditing) {
      // --- EDIT MODE ---
      // Edit modunda tüm widgetları ALT ALTA listeliyoruz (tek sütun).
      // Bu sayede sürükleyip bırakmak çok daha kolay ve tutarlı oluyor.
      // ReorderableListView doğal olarak bunu destekler.

      final items = <Widget>[];

      for (final id in layoutState.order) {
        // Edit modunda gizli olsa bile gösteriyoruz (opacity ile)
        items.add(_buildEditItem(context, ref, stats, id, layoutState));
      }

      return ReorderableListView(
        padding: const EdgeInsets.all(16),
        onReorder: (oldIndex, newIndex) {
          ref
              .read(dashboardLayoutProvider.notifier)
              .reorder(oldIndex, newIndex);
        },
        physics: const AlwaysScrollableScrollPhysics(),
        children: items,
      );
    } else {
      // --- VIEW MODE ---
      // Normal modda "Masonry" benzeri basit bir grid mantığı kuruyoruz.
      // Widgetları sırasıyla alıyoruz:
      // - Eğer widget LARGE ise -> Tek satırda tam genişlikte çiziyoruz.
      // - Eğer widget SMALL ise -> Bir sonrakine bakıyoruz.
      //   - Sonraki de SMALL'sa -> Yan yana çiziyoruz (Row).
      //   - Sonraki LARGE veya yoksa -> Tek başına çiziyoruz (ama yine de dengeli dursun diye).

      final viewItems = <Widget>[];
      final visibleIds = layoutState.order
          .where((id) => !layoutState.hiddenIds.contains(id))
          .toList();

      for (int i = 0; i < visibleIds.length; i++) {
        final id = visibleIds[i];
        final isLarge = DashboardWidgets.isLarge(id);

        if (isLarge) {
          // Large widget: Tam genişlik
          viewItems.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildWidgetById(context, ref, stats, id),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          );
        } else {
          // Small widget
          // Bir sonraki eleman var mı ve o da small mu?
          if (i + 1 < visibleIds.length) {
            final nextId = visibleIds[i + 1];
            if (!DashboardWidgets.isLarge(nextId)) {
              // İkisini yan yana koy
              viewItems.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildWidgetById(context, ref, stats, id),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildWidgetById(context, ref, stats, nextId),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              );
              i++; // Sonraki elemanı da işledik, atla
              continue;
            }
          }

          // Yanına koyacak small bulamadık, tek başına koy (Expanded içinde değil, Row içinde Expanded olarak duralım ki structure bozulmasın, veya direkt tam genişlik mi?)
          // Genelde tek kalan small widget tam genişlikte (Large gibi) görünse daha şık olur.
          viewItems.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildWidgetById(context, ref, stats, id),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          );
        }
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: viewItems,
      );
    }
  }

  Widget _buildEditItem(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
    String id,
    DashboardLayoutState layoutState,
  ) {
    final isHidden = layoutState.hiddenIds.contains(id);
    final widget = _buildWidgetById(context, ref, stats, id);

    return Container(
      key: ValueKey(id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Sol Taraf: Widget Önizlemesi (Küçültülmüş ve Orantılı)
          Expanded(
            child: Opacity(
              opacity: isHidden ? 0.4 : 1.0,
              child: IgnorePointer(
                ignoring: true, // İçeriğe tıklanamasın
                child: SizedBox(
                  height: 60, // Sabit yükseklik ile hizala
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      // Orijinal genişliğe yakın bir değer veriyoruz ki
                      // FittedBox onu sığdırmak için orantılı küçültsün.
                      width: MediaQuery.of(context).size.width - 40,
                      child: widget,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Dikey Ayırıcı Çizgi
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Sağ Taraf: Kontrol Butonları

          // Göz İkonu
          IconButton(
            icon: Icon(
              isHidden ? Icons.visibility_off : Icons.visibility,
              color: isHidden ? AppColors.textSecondary : AppColors.primary,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              ref.read(dashboardLayoutProvider.notifier).toggleVisibility(id);
            },
          ),

          const SizedBox(width: 16),

          // Sürükleme Tutamacı
          ReorderableDragStartListener(
            index: layoutState.order.indexOf(id),
            child: const Icon(
              Icons.drag_handle,
              color: Colors.white70,
              size: 26,
            ),
          ),

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildWidgetById(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
    String id,
  ) {
    switch (id) {
      case DashboardWidgets.totalPnl:
        return _buildTotalPnlCard(context, ref, stats);
      case DashboardWidgets.avgTradePnl:
        return _buildStatCard(
          title: 'Ort. İşlem Kârı',
          value: '\$${stats.avgTradePnL.toStringAsFixed(2)}',
          icon: Icons.show_chart,
          color: stats.avgTradePnL >= 0
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          isSensitive: true,
        );
      case DashboardWidgets.botBalance:
        return Consumer(
          builder: (context, ref, child) {
            final walletAsync = ref.watch(walletDetailsProvider);
            final walletDetails = walletAsync.asData?.value;
            final lockedBalance = walletDetails?.lockedBalance ?? 0.0;
            return _buildStatCard(
              title: 'Mevcut Bot Bakiyesi',
              value: '\$${lockedBalance.toStringAsFixed(2)}',
              icon: Icons.savings,
              color: const Color(0xFFF59E0B),
              isSensitive: true,
            );
          },
        );
      case DashboardWidgets.activeBots:
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BotListScreen()),
          ),
          child: Consumer(
            builder: (context, ref, child) {
              final botListAsync = ref.watch(paginatedBotListProvider);
              final activeBotCount =
                  botListAsync.asData?.value.items
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
        );
      case DashboardWidgets.bestPair:
        return _buildStatCard(
          title: 'En İyi Parite',
          value: stats.bestPair.isEmpty ? '-' : stats.bestPair,
          icon: Icons.star,
          color: AppColors.primary,
        );
      case DashboardWidgets.dailyProfit:
        return _buildStatCard(
          title: 'Bugünkü Kazanç',
          value: '+\$0.00', // Placeholder
          icon: Icons.calendar_today,
          color: const Color(0xFF10B981),
          isSensitive: true,
        );
      case DashboardWidgets.totalInvest:
        return Consumer(
          builder: (context, ref, child) {
            final botListAsync = ref.watch(paginatedBotListProvider);
            final totalInvested =
                botListAsync.asData?.value.items
                    .map((b) => b.amount)
                    .fold(0.0, (sum, amount) => sum + amount) ??
                0.0;

            return _buildStatCard(
              title: 'Toplam Yatırım',
              value: '\$${totalInvested.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFF3B82F6),
              isSensitive: true,
            );
          },
        );
      case DashboardWidgets.bestBot:
        return _buildBestBotCard(context, ref, stats);
      default:
        // Eğer tanınmayan bir ID varsa (versiyon uyumsuzluğu vs) boş dön
        return const SizedBox.shrink();
    }
  }

  // --- Widget Builders (Complex Ones) ---

  Widget _buildTotalPnlCard(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final walletAsync = ref.watch(walletDetailsProvider);
        final walletDetails = walletAsync.asData?.value;

        final unrealizedPnl = walletDetails?.totalPnl ?? 0.0;
        final netPnl = stats.totalPnl + unrealizedPnl;
        final isNetPnlPositive = netPnl >= 0;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WalletScreen()),
          ),
          child: _buildStatCard(
            title: 'Toplam Kâr/Zarar',
            value: '\$${netPnl.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: isNetPnlPositive
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            isLarge: true,
            isSensitive: true,
          ),
        );
      },
    );
  }

  Widget _buildBestBotCard(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final botListAsync = ref.watch(paginatedBotListProvider);
        final bots = botListAsync.asData?.value.items ?? [];

        Bot? bestBot;
        if (bots.isNotEmpty) {
          bestBot = bots.reduce(
            (curr, next) => curr.pnl > next.pnl ? curr : next,
          );
        }

        final bestVal = (bestBot != null && bestBot.pnl > 0)
            ? '+\$${bestBot.pnl.toStringAsFixed(2)} (${bestBot.symbol})'
            : '-';

        return _buildStatCard(
          title: 'En Çok Kazandıran Bot',
          value: bestVal,
          icon: Icons.emoji_events,
          color: const Color(0xFFF59E0B),
          isSensitive: true,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLarge = false,
    bool isSensitive = false,
  }) {
    final isPnlCard = title == 'Toplam Kâr/Zarar';
    BoxDecoration decoration;

    if (isPnlCard) {
      final isPositive = !value.contains('-');
      final gradientColors = isPositive
          ? [
              AppColors.successDark.withValues(alpha: 0.9),
              AppColors.successDark.withValues(alpha: 0.3),
              AppColors.surface,
            ]
          : [
              AppColors.errorDark.withValues(alpha: 0.9),
              AppColors.errorDark.withValues(alpha: 0.3),
              AppColors.surface,
            ];

      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      );
    } else {
      decoration = BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 20),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: isPnlCard ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: color, size: isLarge ? 20 : 16),
              ),
            ],
          ),
          SizedBox(height: isLarge ? 20 : 14),
          isSensitive
              ? SensitiveText(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isLarge ? 36 : (value.contains('adet') ? 14 : 22),
                    fontWeight: FontWeight.w800,
                    color: isPnlCard ? Colors.white : AppColors.textPrimary,
                    height: 1.1,
                  ),
                )
              : Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isLarge ? 36 : (value.contains('adet') ? 14 : 22),
                    fontWeight: FontWeight.w800,
                    color: isPnlCard ? Colors.white : AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
          if (isPnlCard) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Toplam bakiye değişimi',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
