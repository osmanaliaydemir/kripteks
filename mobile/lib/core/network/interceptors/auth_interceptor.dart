import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/network/auth_state_provider.dart';

/// JWT kimlik doğrulama interceptor'ı.
///
/// Sorumlulukları:
/// 1. Her isteğe Bearer token ekler.
/// 2. 401 alındığında refresh token dener (backend desteklediğinde).
/// 3. Concurrent 401'lerde tek bir refresh isteği gönderir (queue pattern).
/// 4. Refresh başarısızsa oturumu temizler ve login'e yönlendirir.
class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final FlutterSecureStorage storage;
  final Ref ref;

  /// Refresh işlemi devam ederken true.
  bool _isRefreshing = false;

  /// Refresh sırasında bekleyen isteklerin completer'ları.
  final List<_PendingRequest> _pendingRequests = [];

  /// Login endpoint'i refresh denenmemeli (sonsuz döngü riski).
  static const _noRetryPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/verify-reset-code',
    '/auth/reset-password',
  ];

  AuthInterceptor({
    required this.dio,
    required this.storage,
    required this.ref,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.read(key: 'auth_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Sadece 401 Unauthorized hatalarında refresh dene
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Auth endpoint'lerinde retry yapma (sonsuz döngü riski)
    final path = err.requestOptions.path;
    if (_noRetryPaths.any((p) => path.contains(p))) {
      return handler.next(err);
    }

    // Refresh token var mı kontrol et
    final refreshToken = await storage.read(key: 'refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      // Refresh token yok -> oturumu kapat
      if (kDebugMode) {
        debugPrint(
          '🔐 [AuthInterceptor] 401 received, no refresh token. Logging out.',
        );
      }
      await _handleSessionExpired();
      return handler.next(err);
    }

    // Zaten bir refresh işlemi devam ediyorsa kuyruğa ekle
    if (_isRefreshing) {
      if (kDebugMode) {
        debugPrint(
          '🔐 [AuthInterceptor] Queuing request: ${err.requestOptions.uri}',
        );
      }
      return _enqueueRequest(err, handler);
    }

    // Refresh token dene
    _isRefreshing = true;

    try {
      final success = await _refreshAccessToken(refreshToken);

      if (success) {
        if (kDebugMode) {
          debugPrint('🔐 [AuthInterceptor] Token refreshed successfully.');
        }

        // Orijinal isteği yeni token ile tekrarla
        final response = await _retryRequest(err.requestOptions);
        handler.resolve(response);

        // Kuyruktaki istekleri de tekrarla
        _resolvePendingRequests();
      } else {
        // Refresh başarısız -> oturumu kapat
        await _handleSessionExpired();
        handler.next(err);
        _rejectPendingRequests(err);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔐 [AuthInterceptor] Refresh failed: $e');
      }
      await _handleSessionExpired();
      handler.next(err);
      _rejectPendingRequests(err);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Refresh token ile yeni access token al.
  ///
  /// NOT: Backend'de henüz refresh token endpoint'i yok.
  /// Bu metot, backend'e `/auth/refresh-token` eklendiğinde
  /// otomatik olarak çalışacak şekilde hazırlanmıştır.
  ///
  /// Beklenen endpoint:
  /// ```
  /// POST /auth/refresh-token
  /// Body: { "refreshToken": "..." }
  /// Response: { "token": "...", "refreshToken": "..." }
  /// ```
  Future<bool> _refreshAccessToken(String refreshToken) async {
    try {
      // Yeni bir Dio instance kullan (interceptor loop'u önlemek için)
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newToken = data['token'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newToken != null) {
          await storage.write(key: 'auth_token', value: newToken);

          if (newRefreshToken != null) {
            await storage.write(key: 'refresh_token', value: newRefreshToken);
          }

          return true;
        }
      }

      return false;
    } on DioException {
      return false;
    }
  }

  /// 401 alınan isteği yeni token ile tekrar gönderir.
  Future<Response<dynamic>> _retryRequest(RequestOptions options) async {
    final token = await storage.read(key: 'auth_token');
    options.headers['Authorization'] = 'Bearer $token';
    return dio.fetch(options);
  }

  /// Refresh beklerken gelen isteği kuyruğa ekler.
  void _enqueueRequest(DioException err, ErrorInterceptorHandler handler) {
    _pendingRequests.add(
      _PendingRequest(
        requestOptions: err.requestOptions,
        handler: handler,
        originalError: err,
      ),
    );
  }

  /// Kuyruktaki tüm istekleri yeni token ile tekrar gönderir.
  void _resolvePendingRequests() {
    final requests = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    for (final pending in requests) {
      _retryRequest(pending.requestOptions).then(
        (response) => pending.handler.resolve(response),
        onError: (e) {
          if (e is DioException) {
            pending.handler.next(e);
          } else {
            pending.handler.next(pending.originalError);
          }
        },
      );
    }
  }

  /// Kuyruktaki tüm istekleri reddeder.
  void _rejectPendingRequests(DioException error) {
    final requests = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    for (final pending in requests) {
      pending.handler.next(error);
    }
  }

  /// Oturumu temizle ve login'e yönlendir.
  Future<void> _handleSessionExpired() async {
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'refresh_token');
    ref.read(authStateProvider.notifier).setAuthenticated(false);

    if (kDebugMode) {
      debugPrint('🔐 [AuthInterceptor] Session expired. Redirecting to login.');
    }
  }
}

/// Refresh beklerken kuyruğa eklenen istek.
class _PendingRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;
  final DioException originalError;

  _PendingRequest({
    required this.requestOptions,
    required this.handler,
    required this.originalError,
  });
}
