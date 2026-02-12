import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';

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
}

// Models
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
    if (previousState.hasValue) {
      final updatedList = previousState.value!.map((u) {
        return u.id == user.id ? user : u;
      }).toList();
      state = AsyncData(updatedList);
    }

    try {
      await service.updateUser(user.id, user);
    } catch (e) {
      // Revert on error
      state = previousState;
      rethrow;
    }
  }
}
