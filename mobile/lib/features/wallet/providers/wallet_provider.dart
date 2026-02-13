import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/paged_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/paginated_provider.dart';
import '../services/wallet_service.dart';
import '../models/wallet_model.dart';

import '../../../core/network/auth_state_provider.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  final dio = ref.watch(dioProvider);
  return WalletService(dio);
});

final walletDetailsProvider = StreamProvider.autoDispose<WalletDetails>((
  ref,
) async* {
  // Auth kontrolü
  final authState = ref.watch(authStateProvider);
  if (authState.asData?.value != true) return;

  final service = ref.watch(walletServiceProvider);

  try {
    yield await service.getWalletDetails();

    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      // Stream sırasında oturum sonlanırsa durdur
      if (ref.read(authStateProvider).value != true) break;
      yield await service.getWalletDetails();
    }
  } catch (e) {
    if (e.toString().contains('StatusCode: 401') ||
        e.toString().contains('AuthException')) {
      return;
    }
    rethrow;
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
