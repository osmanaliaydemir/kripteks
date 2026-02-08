import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/settings/models/user_profile.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileService(dio);
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final service = ref.watch(profileServiceProvider);
  return service.getProfile();
});

class ProfileService {
  final Dio _dio;

  ProfileService(this._dio);

  Future<UserProfile> getProfile() async {
    final response = await _dio.get('/profile');
    return UserProfile.fromJson(response.data);
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    await _dio.put(
      '/profile',
      data: {'firstName': firstName, 'lastName': lastName},
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '/profile/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
