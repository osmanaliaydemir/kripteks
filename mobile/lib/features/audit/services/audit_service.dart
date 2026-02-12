import 'package:dio/dio.dart';
import '../models/audit_model.dart';

class AuditService {
  final Dio _dio;

  AuditService(this._dio);

  Future<AuditQueryResult> getLogs({
    int page = 1,
    int pageSize = 50,
    String? category,
    String? severity,
    String? searchTerm,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (category != null) params['category'] = category;
    if (severity != null) params['severity'] = severity;
    if (searchTerm != null) params['searchTerm'] = searchTerm;
    if (startDate != null) {
      params['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) params['endDate'] = endDate.toIso8601String();

    final response = await _dio.get('/auditlog', queryParameters: params);
    return AuditQueryResult.fromJson(response.data);
  }

  Future<AuditStats> getStats({DateTime? startDate, DateTime? endDate}) async {
    final params = <String, dynamic>{};
    if (startDate != null) {
      params['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) params['endDate'] = endDate.toIso8601String();

    final response = await _dio.get('/auditlog/stats', queryParameters: params);
    return AuditStats.fromJson(response.data);
  }
}
