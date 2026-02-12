import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/paged_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/paginated_provider.dart';
import '../services/wallet_service.dart';
import '../models/wallet_model.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  final dio = ref.watch(dioProvider);
  return WalletService(dio);
});

/// Cüzdan detay bilgisi (pagination gereksiz - tek obje).
final walletDetailsProvider = StreamProvider.autoDispose<WalletDetails>((
  ref,
) async* {
  final service = ref.watch(walletServiceProvider);
  yield await service.getWalletDetails();
  await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
    yield await service.getWalletDetails();
  }
});

/// Sayfalanmış işlem geçmişi provider'ı.
final paginatedTransactionsProvider =
    AsyncNotifierProvider<
      PaginatedTransactionsNotifier,
      PaginatedState<WalletTransaction>
    >(PaginatedTransactionsNotifier.new);

class PaginatedTransactionsNotifier
    extends PaginatedAsyncNotifier<WalletTransaction> {
  @override
  int get pageSize => 20;

  @override
  Future<PagedResult<WalletTransaction>> fetchPage(int page, int pageSize) {
    final service = ref.read(walletServiceProvider);
    return service.getTransactions(page: page, pageSize: pageSize);
  }
}
