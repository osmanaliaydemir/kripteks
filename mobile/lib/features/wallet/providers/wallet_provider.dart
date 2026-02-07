import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../services/wallet_service.dart';
import '../models/wallet_model.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  final dio = ref.watch(dioProvider);
  return WalletService(dio);
});

final walletDetailsProvider = FutureProvider<WalletDetails>((ref) async {
  final service = ref.watch(walletServiceProvider);
  return service.getWalletDetails();
});

final walletTransactionsProvider = FutureProvider<List<WalletTransaction>>((
  ref,
) async {
  final service = ref.watch(walletServiceProvider);
  return service.getTransactions();
});
