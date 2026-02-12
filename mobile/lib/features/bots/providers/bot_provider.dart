import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/auth_state_provider.dart';
import '../../../core/models/paged_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/paginated_provider.dart';
import '../services/bot_service.dart';
import '../models/bot_model.dart';

final botServiceProvider = Provider<BotService>((ref) {
  final dio = ref.watch(dioProvider);
  return BotService(dio);
});

/// Sayfalanmış bot listesi provider'ı.
final paginatedBotListProvider =
    AsyncNotifierProvider<PaginatedBotListNotifier, PaginatedState<Bot>>(
      PaginatedBotListNotifier.new,
    );

class PaginatedBotListNotifier extends PaginatedAsyncNotifier<Bot> {
  Timer? _refreshTimer;

  @override
  int get pageSize => 20;

  @override
  Future<PaginatedState<Bot>> build() async {
    _refreshTimer?.cancel();

    final authState = ref.watch(authStateProvider);
    if (authState.asData?.value != true) {
      return PaginatedState<Bot>();
    }

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      silentRefresh();
    });

    ref.onDispose(() => _refreshTimer?.cancel());

    return super.build();
  }

  /// Listeyi ekranı loading yapmadan arka planda günceller.
  Future<void> silentRefresh() async {
    try {
      final result = await fetchPage(1, pageSize);
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncData(
          currentState.copyWith(
            items: result.items,
            totalCount: result.totalCount,
            hasMore: result.hasMore,
          ),
        );
      }
    } catch (e) {
      // Sessiz hata
    }
  }

  @override
  Future<PagedResult<Bot>> fetchPage(int page, int pageSize) {
    final botService = ref.read(botServiceProvider);
    return botService.getBots(page: page, pageSize: pageSize);
  }
}

/// Tek bot detayı provider'ı (Real-time).
final botDetailProvider = StreamProvider.family.autoDispose<Bot, String>((
  ref,
  id,
) {
  final authState = ref.watch(authStateProvider);
  if (authState.asData?.value != true) {
    return const Stream.empty();
  }

  final botService = ref.watch(botServiceProvider);
  return Stream.periodic(
    const Duration(seconds: 5),
  ).asyncMap((_) => botService.getBot(id));
});

final botLogsProvider = FutureProvider.family
    .autoDispose<PagedResult<BotLog>, ({String botId, int page, int pageSize})>(
      (ref, arg) async {
        final botService = ref.watch(botServiceProvider);
        return botService.getBotLogs(
          arg.botId,
          page: arg.page,
          pageSize: arg.pageSize,
        );
      },
    );
