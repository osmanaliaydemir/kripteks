import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../providers/heatmap_provider.dart';

class PnLHeatmapCalendar extends ConsumerStatefulWidget {
  const PnLHeatmapCalendar({super.key});

  @override
  ConsumerState<PnLHeatmapCalendar> createState() => _PnLHeatmapCalendarState();
}

class _PnLHeatmapCalendarState extends ConsumerState<PnLHeatmapCalendar> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + increment,
      );
    });
  }

  DailyPnlMap? _pnlData;

  @override
  Widget build(BuildContext context) {
    final heatmapAsync = ref.watch(heatmapDataProvider);

    return Container(
      decoration: BoxDecoration(
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
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          heatmapAsync.when(
            data: (pnlMap) {
              _pnlData = pnlMap;
              return _buildCalendarGrid(_selectedMonth, pnlMap);
            },
            error: (err, stack) => Center(
              child: Text(
                'Veri hatası',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
            loading: () {
              if (_pnlData != null) {
                return _buildCalendarGrid(_selectedMonth, _pnlData!);
              }
              return const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final monthName = DateFormat('MMMM yyyy', 'tr_TR').format(_selectedMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.date_range,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'GÜNLÜK PNL TAKVİMİ',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _changeMonth(-1),
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.textPrimary,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Text(
              monthName,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _changeMonth(1),
              icon: const Icon(
                Icons.chevron_right,
                color: AppColors.textPrimary,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(DateTime month, DailyPnlMap pnlMap) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    // Ayın ilk gününün haftanın hangi günü olduğunu bul (Monday=1, Sunday=7)
    // Calendar grid genellikle Pzt veya Paz başlar. Burada Pzt (1) baz alalım.
    int startingWeekday = firstDay.weekday; // 1 (Mon) - 7 (Sun)

    // Grid için toplam hücre sayısı (boşluklar + günler)
    // 7 sütun x 5 veya 6 satır

    List<Widget> dayCells = [];

    // Header Row (M T W T F S S)
    final daysOfWeek = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    for (var day in daysOfWeek) {
      dayCells.add(
        Center(
          child: Text(
            day,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Empty cells for previous month days
    for (int i = 1; i < startingWeekday; i++) {
      dayCells.add(Container());
    }

    // Days of current month
    for (int i = 1; i <= lastDay.day; i++) {
      final currentDay = DateTime(month.year, month.month, i);
      final pnl = pnlMap[currentDay] ?? 0.0;
      final hasTrade = pnlMap.containsKey(currentDay);

      dayCells.add(_buildDayCell(i, pnl, hasTrade));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.0,
      children: dayCells,
    );
  }

  Widget _buildDayCell(int day, double pnl, bool hasTrade) {
    Color bgColor;
    Color textColor = Colors.white;

    if (!hasTrade) {
      bgColor = Colors.white.withValues(alpha: 0.05);
      textColor = Colors.white24;
    } else if (pnl > 0) {
      // Positive (Green intensity)
      // Simple logic: >0 -> base green, >10 -> brighter, >50 -> max
      if (pnl > 50) {
        bgColor = const Color(0xFF10B981);
      } else if (pnl > 10) {
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.7);
      } else {
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.4);
      }
    } else if (pnl < 0) {
      // Negative (Red intensity)
      if (pnl < -50) {
        bgColor = const Color(0xFFEF4444);
      } else if (pnl < -10) {
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.7);
      } else {
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.4);
      }
    } else {
      // 0 PnL but hasTrade (Breakeven)
      bgColor = Colors.white.withValues(alpha: 0.2);
    }

    return Tooltip(
      message: hasTrade
          ? '$day: ${pnl > 0 ? '+' : ''}${pnl.toStringAsFixed(2)}\$'
          : '$day: İşlem yok',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$day',
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _legendItem(const Color(0xFFEF4444), 'Zarar'),
        const SizedBox(width: 8),
        _legendItem(Colors.white.withValues(alpha: 0.05), 'Boş'),
        const SizedBox(width: 8),
        _legendItem(const Color(0xFF10B981), 'Kâr'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}
