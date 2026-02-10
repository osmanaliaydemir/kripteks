import 'package:dio/dio.dart';
import 'package:mobile/core/error/error_handler.dart';
import 'package:mobile/core/models/paged_result.dart';
import '../../wallet/models/wallet_model.dart';

class WalletService {
  final Dio _dio;

  WalletService(this._dio);

  Future<WalletDetails> getWalletDetails() async {
    try {
      final response = await _dio.get('/wallet');
      return WalletDetails.fromJson(response.data);
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<PagedResult<WalletTransaction>> getTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/wallet/transactions',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(
        response.data as Map<String, dynamic>,
        (json) => WalletTransaction.fromJson(json),
      );
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }
}
