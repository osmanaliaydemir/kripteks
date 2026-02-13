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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Modern Background Glow
          Positioned(
            top: -100,
            left: -100,
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
                AppHeader(title: 'Denetim Kayıtları'),
                // İstatistik kartları
                statsAsync.when(
                  data: (stats) => _buildStatsBar(stats),
                  loading: () => const SizedBox(height: 80),
                  error: (_, _) => const SizedBox(height: 8),
                ),
                // Filtreler
                _buildFilters(),
                const SizedBox(height: 16),
                // Log listesi
                Expanded(
                  child: logsAsync.when(
                    data: (result) => _buildLogList(result),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (err, _) => _buildError(err.toString()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(AuditStats stats) {
    return SizedBox(
      height: 100,
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
            width: 110,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _categoryLabels[cat.category] ?? cat.category,
                        style: GoogleFonts.plusJakartaSans(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  cat.count.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 20,
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
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  final color = cat != null
                      ? (_categoryColors[cat] ?? const Color(0xFF6B7280))
                      : AppColors.primary;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                        _currentPage = 1;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        _categoryLabels[cat] ?? 'Tümü',
                        style: GoogleFonts.plusJakartaSans(
                          color: isSelected ? color : Colors.white54,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
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
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: _selectedSeverity != null
            ? (_severityColors[_selectedSeverity!] ?? const Color(0xFF3B82F6))
                  .withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedSeverity != null
              ? (_severityColors[_selectedSeverity!] ?? const Color(0xFF3B82F6))
              : Colors.white12,
        ),
      ),
      child: PopupMenuButton<String?>(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _selectedSeverity == 'Critical'
                    ? Icons.error_outline
                    : _selectedSeverity == 'Warning'
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: _selectedSeverity != null
                    ? _severityColors[_selectedSeverity!]
                    : Colors.white54,
              ),
              const SizedBox(width: 6),
              Text(
                _selectedSeverity == 'Critical'
                    ? 'Kritik'
                    : _selectedSeverity == 'Warning'
                    ? 'Uyarı'
                    : _selectedSeverity == 'Info'
                    ? 'Bilgi'
                    : 'Önem',
                style: GoogleFonts.plusJakartaSans(
                  color: _selectedSeverity != null
                      ? _severityColors[_selectedSeverity!]
                      : Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Colors.white38,
              ),
            ],
          ),
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
                ? Icons.error_outline
                : value == 'Warning'
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: isSelected ? color : Colors.white70,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 14,
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${result.totalCount} kayıt bulundu',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Sayfa $_currentPage / $totalPages',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
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
            color: AppColors.primary,
            backgroundColor: const Color(0xFF1E293B),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: result.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: log.severity == 'Critical'
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır: Kategori + Severity + Tarih
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(catIcon, color: catColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _categoryLabels[log.category] ?? log.category,
                      style: GoogleFonts.plusJakartaSans(
                        color: catColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (log.severity != 'Info')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sevColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    log.severity == 'Warning' ? 'Uyarı' : 'Kritik',
                    style: GoogleFonts.plusJakartaSans(
                      color: sevColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                dateFormat.format(log.timestamp.toLocal()),
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Eylem
          Text(
            log.action,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Kullanıcı & IP
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: Colors.white38,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                log.userEmail,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
              if (log.ipAddress != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.language, color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(
                  log.ipAddress!,
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                ),
              ],
            ],
          ),
          // Eski → Yeni değer
          if (log.oldValue != null && log.newValue != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESKİ DEĞER',
                          style: GoogleFonts.inter(
                            color: Colors.white24,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log.oldValue!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFEF4444),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white38,
                      size: 14,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'YENİ DEĞER',
                          style: GoogleFonts.inter(
                            color: Colors.white24,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log.newValue!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF10B981),
                            fontSize: 13,
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
    ).animate().fadeIn(delay: (index * 30).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageButton(
            icon: Icons.chevron_left_rounded,
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
            icon: Icons.chevron_right_rounded,
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: onTap != null
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.02),
          ),
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.white : Colors.white24,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPageNumber(int pageNum) {
    final isSelected = pageNum == _currentPage;
    return GestureDetector(
      onTap: () => setState(() => _currentPage = pageNum),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$pageNum',
            style: GoogleFonts.plusJakartaSans(
              color: isSelected ? Colors.black : Colors.white54,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            'Veriler yüklenemedi',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
