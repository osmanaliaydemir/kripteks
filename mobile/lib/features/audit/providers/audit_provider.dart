import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import '../models/audit_model.dart';
import '../services/audit_service.dart';

final auditServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AuditService(dio);
});

final auditStatsProvider = FutureProvider.autoDispose<AuditStats>((ref) async {
  final service = ref.watch(auditServiceProvider);
  return service.getStats(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
  );
});

/// Audit loglarını sayfalı çekmek için family provider.
final auditLogsProvider = FutureProvider.autoDispose
    .family<AuditQueryResult, AuditQueryParams>((ref, params) async {
      final service = ref.watch(auditServiceProvider);
      return service.getLogs(
        page: params.page,
        pageSize: params.pageSize,
        category: params.category,
        severity: params.severity,
        searchTerm: params.searchTerm,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

class AuditQueryParams {
  final int page;
  final int pageSize;
  final String? category;
  final String? severity;
  final String? searchTerm;
  final DateTime? startDate;
  final DateTime? endDate;

  const AuditQueryParams({
    this.page = 1,
    this.pageSize = 50,
    this.category,
    this.severity,
    this.searchTerm,
    this.startDate,
    this.endDate,
  });

  AuditQueryParams copyWith({
    int? page,
    int? pageSize,
    String? category,
    String? severity,
    String? searchTerm,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return AuditQueryParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      searchTerm: searchTerm ?? this.searchTerm,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditQueryParams &&
          page == other.page &&
          pageSize == other.pageSize &&
          category == other.category &&
          severity == other.severity &&
          searchTerm == other.searchTerm &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(
    page,
    pageSize,
    category,
    severity,
    searchTerm,
    startDate,
    endDate,
  );
}
