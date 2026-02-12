class AuditLogItem {
  final String id;
  final String? userId;
  final String userEmail;
  final String action;
  final String category;
  final String severity;
  final String? entityId;
  final String? entityType;
  final String? oldValue;
  final String? newValue;
  final String? metadata;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;

  AuditLogItem({
    required this.id,
    this.userId,
    required this.userEmail,
    required this.action,
    required this.category,
    required this.severity,
    this.entityId,
    this.entityType,
    this.oldValue,
    this.newValue,
    this.metadata,
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    return AuditLogItem(
      id: json['id'] ?? '',
      userId: json['userId'],
      userEmail: json['userEmail'] ?? '',
      action: json['action'] ?? '',
      category: json['category'] ?? 'System',
      severity: json['severity'] ?? 'Info',
      entityId: json['entityId'],
      entityType: json['entityType'],
      oldValue: json['oldValue'],
      newValue: json['newValue'],
      metadata: json['metadata'],
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class AuditQueryResult {
  final List<AuditLogItem> items;
  final int totalCount;
  final int page;
  final int pageSize;

  AuditQueryResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory AuditQueryResult.fromJson(Map<String, dynamic> json) {
    return AuditQueryResult(
      items:
          (json['items'] as List?)
              ?.map((e) => AuditLogItem.fromJson(e))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 50,
    );
  }
}

class AuditStats {
  final DateTime startDate;
  final DateTime endDate;
  final List<CategoryStat> categories;

  AuditStats({
    required this.startDate,
    required this.endDate,
    required this.categories,
  });

  factory AuditStats.fromJson(Map<String, dynamic> json) {
    return AuditStats(
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      categories:
          (json['categories'] as List?)
              ?.map((e) => CategoryStat.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CategoryStat {
  final String category;
  final int count;

  CategoryStat({required this.category, required this.count});

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      category: json['category'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
