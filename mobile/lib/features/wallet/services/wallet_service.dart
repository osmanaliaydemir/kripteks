import 'package:dio/dio.dart';
import '../../wallet/models/wallet_model.dart';

class WalletService {
  final Dio _dio;

  WalletService(this._dio);

  Future<WalletDetails> getWalletDetails() async {
    try {
      final response = await _dio.get('/wallet');
      return WalletDetails.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch wallet details: $e');
    }
  }

  Future<List<WalletTransaction>> getTransactions() async {
    try {
      final response = await _dio.get('/wallet/transactions');
      final List<dynamic> data = response.data;
      return data.map((json) => WalletTransaction.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }
}
