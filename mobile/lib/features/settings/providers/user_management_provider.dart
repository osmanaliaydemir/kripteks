import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/models/paged_result.dart';
import 'package:mobile/core/providers/paginated_provider.dart';

// Service
class UserManagementService {
  final Dio _dio;

  UserManagementService(this._dio);

  Future<List<UserManagementDto>> getUsers() async {
    final response = await _dio.get('/users');
    return (response.data as List)
        .map((e) => UserManagementDto.fromJson(e))
        .toList();
  }

  Future<void> updateUser(String id, UserManagementDto user) async {
    await _dio.put('/users/$id', data: user.toJson());
  }

  Future<void> deleteUser(String id) async {
    await _dio.delete('/users/$id');
  }

  Future<void> sendPasswordResetLink(String id) async {
    await _dio.post('/users/$id/send-password-reset');
  }

  Future<PagedResult<AuditLogDto>> getAuditLogs(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/users/$userId/audit-logs',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return PagedResult.fromJson(
      response.data,
      (json) => AuditLogDto.fromJson(json),
    );
  }
}

class AuditLogDto {
  final String id;
  final String action;
  final String category;
  final String severity;
  final DateTime timestamp;
  final String? ipAddress;

  AuditLogDto({
    required this.id,
    required this.action,
    required this.category,
    required this.severity,
    required this.timestamp,
    this.ipAddress,
  });

  factory AuditLogDto.fromJson(Map<String, dynamic> json) {
    return AuditLogDto(
      id: json['id'],
      action: json['action'],
      category: json['category'],
      severity: json['severity'],
      timestamp: DateTime.parse(json['timestamp']),
      ipAddress: json['ipAddress'],
    );
  }
}

// Models
// ... (UserManagementDto)
class UserManagementDto {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final bool isActive;

  UserManagementDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory UserManagementDto.fromJson(Map<String, dynamic> json) {
    return UserManagementDto(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'User',
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'isActive': isActive,
    };
  }

  UserManagementDto copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    bool? isActive,
  }) {
    return UserManagementDto(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}

// Providers
final userManagementServiceProvider = Provider<UserManagementService>((ref) {
  return UserManagementService(ref.watch(dioProvider));
});

final usersProvider =
    AsyncNotifierProvider<UsersNotifier, List<UserManagementDto>>(
      UsersNotifier.new,
    );

class UsersNotifier extends AsyncNotifier<List<UserManagementDto>> {
  @override
  FutureOr<List<UserManagementDto>> build() {
    return _fetchUsers();
  }

  Future<List<UserManagementDto>> _fetchUsers() async {
    final service = ref.read(userManagementServiceProvider);
    return service.getUsers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchUsers());
  }

  Future<void> updateUser(UserManagementDto user) async {
    final service = ref.read(userManagementServiceProvider);

    // Optimistic update
    final previousState = state;
    // ... existing ...
    try {
      await service.updateUser(user.id, user);
    } catch (e) {
      // Revert on error
      state = previousState;
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    final service = ref.read(userManagementServiceProvider);

    // Optimistic update
    final previousState = state;
    if (previousState.hasValue) {
      final updatedList = previousState.value!
          .where((u) => u.id != id)
          .toList();
      state = AsyncData(updatedList);
    }

    try {
      await service.deleteUser(id);
    } catch (e) {
      // Revert on error
      state = previousState;
      rethrow;
    }
  }

  Future<void> sendPasswordResetLink(String id) async {
    final service = ref.read(userManagementServiceProvider);
    await service.sendPasswordResetLink(id);
  }
}

final paginatedAuditLogsProvider =
    AsyncNotifierProvider<
      PaginatedAuditLogsNotifier,
      PaginatedState<AuditLogDto>
    >(PaginatedAuditLogsNotifier.new);

class PaginatedAuditLogsNotifier extends PaginatedAsyncNotifier<AuditLogDto> {
  String? _userId;

  void init(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    refresh();
  }

  @override
  Future<PagedResult<AuditLogDto>> fetchPage(int page, int pageSize) {
    if (_userId == null) return Future.value(PagedResult.empty());
    final service = ref.read(userManagementServiceProvider);
    return service.getAuditLogs(_userId!, page: page, pageSize: pageSize);
  }
}
