import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/paginated_provider.dart';

/// Sayfalanmış listeyi gösteren generic widget.
/// Infinite scroll, pull-to-refresh ve loading/empty/error durumlarını yönetir.
class PaginatedListView<T> extends ConsumerStatefulWidget {
  /// Riverpod provider - PaginatedAsyncNotifier kullanan bir AsyncNotifierProvider.
  final AsyncNotifierProvider<PaginatedAsyncNotifier<T>, PaginatedState<T>>
  provider;

  /// Her item için widget builder.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Liste boşken gösterilecek widget.
  final Widget? emptyWidget;

  /// İlk yükleme sırasında gösterilecek widget.
  final Widget? loadingWidget;

  /// Hata durumunda gösterilecek widget builder.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// İtem arası separator widget.
  final Widget? separatorWidget;

  /// Liste üstüne eklenecek widget (header).
  final Widget? header;

  /// Listenin padding'i.
  final EdgeInsetsGeometry? padding;

  /// ScrollController (dışarıdan yönetim için).
  final ScrollController? scrollController;

  /// Pull-to-refresh aktif mi?
  final bool enableRefresh;

  /// Sonraki sayfayı tetiklemek için listenin sonuna kalan mesafe (piksel).
  final double loadMoreThreshold;

  /// ListView.builder'a ek physics.
  final ScrollPhysics? physics;

  const PaginatedListView({
    super.key,
    required this.provider,
    required this.itemBuilder,
    this.emptyWidget,
    this.loadingWidget,
    this.errorBuilder,
    this.separatorWidget,
    this.header,
    this.padding,
    this.scrollController,
    this.enableRefresh = true,
    this.loadMoreThreshold = 200,
    this.physics,
  });

  @override
  ConsumerState<PaginatedListView<T>> createState() =>
      _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends ConsumerState<PaginatedListView<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= widget.loadMoreThreshold) {
      ref.read(widget.provider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(widget.provider);

    return asyncState.when(
      loading: () =>
          widget.loadingWidget ??
          const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        if (widget.errorBuilder != null) {
          return widget.errorBuilder!(context, error);
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Bir hata oluştu',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.read(widget.provider.notifier).refresh(),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        );
      },
      data: (paginatedState) {
        if (paginatedState.items.isEmpty) {
          return widget.emptyWidget ??
              const Center(child: Text('Henüz veri yok'));
        }

        final itemCount =
            paginatedState.items.length +
            (widget.header != null ? 1 : 0) +
            (paginatedState.isLoadingMore || !paginatedState.hasMore ? 1 : 0);

        Widget listView = ListView.builder(
          controller: _scrollController,
          physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
          padding: widget.padding,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // Header
            if (widget.header != null && index == 0) {
              return widget.header!;
            }

            final itemIndex = index - (widget.header != null ? 1 : 0);

            // Footer: loading more veya "daha fazla yok"
            if (itemIndex >= paginatedState.items.length) {
              if (paginatedState.isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              if (!paginatedState.hasMore) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Tüm veriler yüklendi',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }

            final item = paginatedState.items[itemIndex];

            if (widget.separatorWidget != null && itemIndex > 0) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.separatorWidget!,
                  widget.itemBuilder(context, item, itemIndex),
                ],
              );
            }

            return widget.itemBuilder(context, item, itemIndex);
          },
        );

        if (widget.enableRefresh) {
          listView = RefreshIndicator(
            onRefresh: () => ref.read(widget.provider.notifier).refresh(),
            child: listView,
          );
        }

        return listView;
      },
    );
  }
}
