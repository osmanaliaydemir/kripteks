import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  int get pageSize => 20;

  @override
  Future<PagedResult<Bot>> fetchPage(int page, int pageSize) {
    final botService = ref.read(botServiceProvider);
    return botService.getBots(page: page, pageSize: pageSize);
  }
}

/// Tek bot detayı provider'ı (pagination gereksiz).
final botDetailProvider = FutureProvider.family.autoDispose<Bot, String>((
  ref,
  id,
) async {
  final botService = ref.watch(botServiceProvider);
  return botService.getBot(id);
});
