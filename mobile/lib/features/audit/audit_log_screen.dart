import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'models/audit_model.dart';
import 'providers/audit_provider.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String? _selectedCategory;
  String? _selectedSeverity;
  int _currentPage = 1;

  static const _categories = [
    null,
    'Auth',
    'Trade',
    'Wallet',
    'Settings',
    'Bot',
    'System',
  ];

  static const _categoryLabels = {
    null: 'Tümü',
    'Auth': 'Kimlik',
    'Trade': 'İşlem',
    'Wallet': 'Cüzdan',
    'Settings': 'Ayarlar',
    'Bot': 'Bot',
    'System': 'Sistem',
  };

  static const _categoryIcons = {
    'Auth': Icons.login,
    'Trade': Icons.swap_horiz,
    'Wallet': Icons.account_balance_wallet,
    'Settings': Icons.settings,
    'Bot': Icons.smart_toy,
    'System': Icons.computer,
  };

  static const _categoryColors = {
    'Auth': Color(0xFF3B82F6),
    'Trade': Color(0xFFF59E0B),
    'Wallet': Color(0xFF10B981),
    'Settings': Color(0xFF8B5CF6),
    'Bot': Color(0xFFEC4899),
    'System': Color(0xFF6B7280),
  };

  static const _severityColors = {
    'Info': Color(0xFF3B82F6),
    'Warning': Color(0xFFF59E0B),
    'Critical': Color(0xFFEF4444),
  };

  AuditQueryParams get _currentParams => AuditQueryParams(
    page: _currentPage,
    pageSize: 30,
    category: _selectedCategory,
    severity: _selectedSeverity,
  );

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditLogsProvider(_currentParams));
    final statsAsync = ref.watch(auditStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Denetim Kayıtları'),
            // İstatistik kartları
            statsAsync.when(
              data: (stats) => _buildStatsBar(stats),
              loading: () => const SizedBox(height: 80),
              error: (_, _) => const SizedBox(height: 8),
            ),
            // Filtreler
            _buildFilters(),
            const SizedBox(height: 8),
            // Log listesi
            Expanded(
              child: logsAsync.when(
                data: (result) => _buildLogList(result),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                ),
                error: (err, _) => _buildError(err.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(AuditStats stats) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: stats.categories.length,
        itemBuilder: (context, index) {
          final cat = stats.categories[index];
          final color =
              _categoryColors[cat.category] ?? const Color(0xFF6B7280);
          final icon = _categoryIcons[cat.category] ?? Icons.circle;
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _categoryLabels[cat.category] ?? cat.category,
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  cat.count.toString(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.2, end: 0);
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Kategori filtresi
          Expanded(
            child: SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  final color = cat != null
                      ? (_categoryColors[cat] ?? const Color(0xFF6B7280))
                      : const Color(0xFFF59E0B);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                        _currentPage = 1;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? color : Colors.white12,
                        ),
                      ),
                      child: Text(
                        _categoryLabels[cat] ?? 'Tümü',
                        style: GoogleFonts.inter(
                          color: isSelected ? color : Colors.white54,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Severity dropdown
          _buildSeverityDropdown(),
        ],
      ),
    );
  }

  Widget _buildSeverityDropdown() {
    return PopupMenuButton<String?>(
      onSelected: (value) {
        setState(() {
          _selectedSeverity = value;
          _currentPage = 1;
        });
      },
      offset: const Offset(0, 40),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        _buildSeverityMenuItem(null, 'Tümü'),
        _buildSeverityMenuItem('Info', 'Bilgi'),
        _buildSeverityMenuItem('Warning', 'Uyarı'),
        _buildSeverityMenuItem('Critical', 'Kritik'),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _selectedSeverity != null
              ? (_severityColors[_selectedSeverity!] ?? const Color(0xFF3B82F6))
                    .withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedSeverity != null
                ? (_severityColors[_selectedSeverity!] ??
                      const Color(0xFF3B82F6))
                : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _selectedSeverity == 'Critical'
                  ? Icons.error
                  : _selectedSeverity == 'Warning'
                  ? Icons.warning
                  : Icons.info,
              size: 14,
              color: _selectedSeverity != null
                  ? _severityColors[_selectedSeverity!]
                  : Colors.white54,
            ),
            const SizedBox(width: 4),
            Text(
              _selectedSeverity == 'Critical'
                  ? 'Kritik'
                  : _selectedSeverity == 'Warning'
                  ? 'Uyarı'
                  : _selectedSeverity == 'Info'
                  ? 'Bilgi'
                  : 'Önem',
              style: GoogleFonts.inter(
                color: _selectedSeverity != null
                    ? _severityColors[_selectedSeverity!]
                    : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String?> _buildSeverityMenuItem(String? value, String label) {
    final isSelected = _selectedSeverity == value;
    final color = value != null
        ? (_severityColors[value] ?? const Color(0xFF3B82F6))
        : Colors.white54;
    return PopupMenuItem<String?>(
      value: value,
      child: Row(
        children: [
          Icon(
            value == 'Critical'
                ? Icons.error
                : value == 'Warning'
                ? Icons.warning
                : Icons.info,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? color : Colors.white70,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(AuditQueryResult result) {
    if (result.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            Text(
              'Kayıt bulunamadı',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final totalPages = (result.totalCount / result.pageSize).ceil();

    return Column(
      children: [
        // Toplam sonuç ve sayfa bilgisi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${result.totalCount} kayıt',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
              const Spacer(),
              Text(
                'Sayfa $_currentPage / $totalPages',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        // Log listesi
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(auditLogsProvider(_currentParams));
              ref.invalidate(auditStatsProvider);
            },
            color: const Color(0xFFF59E0B),
            backgroundColor: const Color(0xFF1E293B),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: result.items.length,
              itemBuilder: (context, index) {
                return _buildLogItem(result.items[index], index);
              },
            ),
          ),
        ),
        // Sayfalama
        if (totalPages > 1) _buildPagination(totalPages),
      ],
    );
  }

  Widget _buildLogItem(AuditLogItem log, int index) {
    final catColor = _categoryColors[log.category] ?? const Color(0xFF6B7280);
    final sevColor = _severityColors[log.severity] ?? const Color(0xFF3B82F6);
    final catIcon = _categoryIcons[log.category] ?? Icons.circle;
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: log.severity == 'Critical'
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır: Kategori + Severity + Tarih
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(catIcon, color: catColor, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      _categoryLabels[log.category] ?? log.category,
                      style: GoogleFonts.inter(
                        color: catColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (log.severity != 'Info')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: sevColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log.severity == 'Warning' ? 'Uyarı' : 'Kritik',
                    style: GoogleFonts.inter(
                      color: sevColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                dateFormat.format(log.timestamp.toLocal()),
                style: GoogleFonts.inter(color: Colors.white30, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Eylem
          Text(
            log.action,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // Kullanıcı & IP
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.white24, size: 12),
              const SizedBox(width: 3),
              Text(
                log.userEmail,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
              if (log.ipAddress != null) ...[
                const SizedBox(width: 10),
                Icon(Icons.language, color: Colors.white24, size: 12),
                const SizedBox(width: 3),
                Text(
                  log.ipAddress!,
                  style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
                ),
              ],
            ],
          ),
          // Eski → Yeni değer
          if (log.oldValue != null && log.newValue != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eski',
                          style: GoogleFonts.inter(
                            color: Colors.white24,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          log.oldValue!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white24,
                    size: 14,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Yeni',
                          style: GoogleFonts.inter(
                            color: Colors.white24,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          log.newValue!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: (index * 30).ms);
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageButton(
            icon: Icons.chevron_left,
            onTap: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
          ),
          const SizedBox(width: 16),
          ...List.generate(totalPages > 5 ? 5 : totalPages, (i) {
            int pageNum;
            if (totalPages <= 5) {
              pageNum = i + 1;
            } else if (_currentPage <= 3) {
              pageNum = i + 1;
            } else if (_currentPage >= totalPages - 2) {
              pageNum = totalPages - 4 + i;
            } else {
              pageNum = _currentPage - 2 + i;
            }
            return _buildPageNumber(pageNum);
          }),
          const SizedBox(width: 16),
          _buildPageButton(
            icon: Icons.chevron_right,
            onTap: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.white70 : Colors.white24,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildPageNumber(int pageNum) {
    final isSelected = pageNum == _currentPage;
    return GestureDetector(
      onTap: () => setState(() => _currentPage = pageNum),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            '$pageNum',
            style: GoogleFonts.inter(
              color: isSelected ? const Color(0xFFF59E0B) : Colors.white54,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: const Color(0xFFEF4444), size: 40),
          const SizedBox(height: 12),
          Text(
            'Veriler yüklenemedi',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
