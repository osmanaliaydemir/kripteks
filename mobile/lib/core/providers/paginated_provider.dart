import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/paged_result.dart';

/// Sayfalanmış liste durumunu tutan state model.
class PaginatedState<T> {
  final List<T> items;
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? error;

  const PaginatedState({
    this.items = const [],
    this.currentPage = 0,
    this.pageSize = 20,
    this.totalCount = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.error,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// Generic paginated async notifier.
/// Alt sınıflar sadece [fetchPage]'i implement eder.
abstract class PaginatedAsyncNotifier<T>
    extends AsyncNotifier<PaginatedState<T>> {
  int get pageSize => 20;

  /// Backend'den sayfa verisi çeker. Alt sınıflar implement eder.
  Future<PagedResult<T>> fetchPage(int page, int pageSize);

  @override
  Future<PaginatedState<T>> build() async {
    final result = await fetchPage(1, pageSize);
    return PaginatedState<T>(
      items: result.items,
      currentPage: 1,
      pageSize: pageSize,
      totalCount: result.totalCount,
      hasMore: result.hasMore,
    );
  }

  /// Sonraki sayfayı yükler. ListView sonuna yaklaşınca çağrılır.
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncData(
      currentState.copyWith(isLoadingMore: true, clearError: true),
    );

    try {
      final nextPage = currentState.currentPage + 1;
      final result = await fetchPage(nextPage, pageSize);

      final updatedItems = [...currentState.items, ...result.items];
      state = AsyncData(
        currentState.copyWith(
          items: updatedItems,
          currentPage: nextPage,
          totalCount: result.totalCount,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncData(currentState.copyWith(isLoadingMore: false, error: e));
    }
  }

  /// Listeyi sıfırdan yeniler (pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final result = await fetchPage(1, pageSize);
      state = AsyncData(
        PaginatedState<T>(
          items: result.items,
          currentPage: 1,
          pageSize: pageSize,
          totalCount: result.totalCount,
          hasMore: result.hasMore,
        ),
      );
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}
