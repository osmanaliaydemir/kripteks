/// Backend'den dönen sayfalanmış sonuç modeli.
/// Tüm liste endpoint'leri bu formatta döner.
class PagedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;
  final int totalPages;

  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
    required this.totalPages,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResult<T>(
      items: (json['items'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      totalCount: json['totalCount'] as int? ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  /// Boş bir PagedResult oluşturur.
  factory PagedResult.empty() {
    return const PagedResult(
      items: [],
      page: 1,
      pageSize: 20,
      totalCount: 0,
      hasMore: false,
      totalPages: 0,
    );
  }
}
