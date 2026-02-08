import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../../scanner/models/scanner_model.dart';

class ScannerSymbolSelectionSheet extends ConsumerStatefulWidget {
  final List<ScannerFavoriteList>? favoriteLists;
  final List<String> allSymbols;
  final List<String> scriptSelectedSymbols;
  final Function(List<String>) onSelectionChanged;

  const ScannerSymbolSelectionSheet({
    super.key,
    required this.favoriteLists,
    required this.allSymbols,
    required this.scriptSelectedSymbols,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<ScannerSymbolSelectionSheet> createState() =>
      _ScannerSymbolSelectionSheetState();
}

class _ScannerSymbolSelectionSheetState
    extends ConsumerState<ScannerSymbolSelectionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _selectedSymbols;
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedSymbols = List.from(widget.scriptSelectedSymbols);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSymbol(String symbol) {
    setState(() {
      if (_selectedSymbols.contains(symbol)) {
        _selectedSymbols.remove(symbol);
      } else {
        _selectedSymbols.add(symbol);
      }
    });
  }

  void _applySelection() {
    widget.onSelectionChanged(_selectedSymbols);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Parite ve Liste Seçimi',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
              padding: EdgeInsets.zero,
              tabs: const [
                Tab(text: 'Favori Listelerim'),
                Tab(text: 'Manuel Seçim'),
              ],
            ),
          ),

          // Search Bar (Only for Manual Selection)
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              return _tabController.index == 1
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Sembol Ara (örn. BTC)',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toUpperCase();
                          });
                        },
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildFavoritesTab(), _buildManualSelectionTab()],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedSymbols.length} Sembol Seçildi',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _applySelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Uygula'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final lists = widget.favoriteLists ?? [];
    if (lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.list_alt_rounded, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Henüz favori listeniz yok',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: lists.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final list = lists[index];
        // Check if all symbols in this list are selected
        final isFullySelected = list.symbols.every(
          (s) => _selectedSymbols.contains(s),
        );

        return InkWell(
          onTap: () {
            setState(() {
              if (isFullySelected) {
                // Deselect all
                for (final s in list.symbols) {
                  _selectedSymbols.remove(s);
                }
              } else {
                // Select all
                for (final s in list.symbols) {
                  if (!_selectedSymbols.contains(s)) {
                    _selectedSymbols.add(s);
                  }
                }
              }
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isFullySelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFullySelected ? AppColors.primary : Colors.white10,
                width: isFullySelected ? 1.5 : 1.0,
              ),
              boxShadow: isFullySelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isFullySelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isFullySelected ? AppColors.primary : Colors.white24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${list.symbols.length} Sembol',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManualSelectionTab() {
    final filteredSymbols = widget.allSymbols
        .where((s) => s.contains(_searchQuery))
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredSymbols.length,
      itemBuilder: (context, index) {
        final symbol = filteredSymbols[index];
        final isSelected = _selectedSymbols.contains(symbol);

        return InkWell(
          onTap: () => _toggleSymbol(symbol),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              symbol,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }
}
