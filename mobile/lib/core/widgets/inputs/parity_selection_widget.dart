import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/providers/market_data_provider.dart';

class ParitySelectionWidget extends ConsumerStatefulWidget {
  final String? selectedSymbol;
  final Function(String) onChanged;
  final String label;

  const ParitySelectionWidget({
    super.key,
    required this.selectedSymbol,
    required this.onChanged,
    this.label = 'Parite Seçiniz',
  });

  @override
  ConsumerState<ParitySelectionWidget> createState() =>
      _ParitySelectionWidgetState();
}

class _ParitySelectionWidgetState extends ConsumerState<ParitySelectionWidget> {
  void _showSymbolSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            String searchQuery = '';

            return StatefulBuilder(
              builder: (context, setStateSheet) {
                return Consumer(
                  builder: (context, ref, child) {
                    final pairsAsync = ref.watch(liveMarketDataProvider);
                    return pairsAsync.when(
                      data: (pairs) {
                        final filteredPairs = pairs
                            .where(
                              (pair) => pair.symbol.toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();

                        return Column(
                          children: [
                            // Handle Bar
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Header & Close
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    widget.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Search Input
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: TextField(
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Ara...',
                                  hintStyle: const TextStyle(
                                    color: Colors.white38,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.white38,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.05,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  setStateSheet(() => searchQuery = value);
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // List
                            Expanded(
                              child: ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filteredPairs.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final pair = filteredPairs[index];
                                  final isSelected =
                                      pair.symbol == widget.selectedSymbol;

                                  return InkWell(
                                    onTap: () {
                                      widget.onChanged(pair.symbol);
                                      Navigator.pop(context);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.05,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Checkmark (Left)
                                          if (isSelected)
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                right: 12,
                                              ),
                                              child: Icon(
                                                Icons.check_circle,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),

                                          // Symbol Name
                                          Text(
                                            pair.symbol,
                                            style: GoogleFonts.inter(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),

                                          const Spacer(),

                                          // Price (Right)
                                          Text(
                                            () {
                                              final price = pair.price;
                                              if (price == 0) return '\$0.00';
                                              if (price < 0.00001) {
                                                return '\$${price.toStringAsFixed(8)}';
                                              }
                                              if (price < 0.01) {
                                                return '\$${price.toStringAsFixed(6)}';
                                              }
                                              if (price < 1) {
                                                return '\$${price.toStringAsFixed(4)}';
                                              }
                                              return '\$${price.toStringAsFixed(2)}';
                                            }(),
                                            style: GoogleFonts.inter(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.white70,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      error: (err, stack) => Center(
                        child: Text(
                          'Hata: $err',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showSymbolSelectionSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.currency_bitcoin_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parite',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.selectedSymbol ?? widget.label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}
