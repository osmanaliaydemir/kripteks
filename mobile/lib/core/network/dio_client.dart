import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:mobile/core/network/interceptors/retry_interceptor.dart';
import 'package:mobile/core/constants.dart';

// ─── Dio Provider ─────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final storage = const FlutterSecureStorage();

  // 1. Auth interceptor (token ekleme + 401 refresh + queue pattern)
  //    QueuedInterceptor olduğu için ilk sıraya eklenmeli.
  dio.interceptors.add(AuthInterceptor(dio: dio, storage: storage, ref: ref));

  // 2. Error mapping interceptor (DioException -> AppException)
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException e, handler) async {
        final appException = _mapDioException(e);
        return handler.next(
          DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: appException,
            stackTrace: e.stackTrace,
            message: appException.message,
          ),
        );
      },
    ),
  );

  // 3. Retry interceptor (ağ hataları ve 5xx için otomatik retry)
  //    Error mapping'den sonra olmalı ki retry sırasında
  //    mapping tekrar çalışsın.
  dio.interceptors.add(RetryInterceptor(dio: dio));

  // 4. Debug modda request/response logla
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  return dio;
});

// ─── CancelToken Provider ─────────────────────────────────────────

/// Sayfa bazlı CancelToken yönetimi.
///
/// Her ekran `ref.watch(cancelTokenProvider)` ile kendi token'ını alır.
/// `autoDispose` sayesinde sayfa dispose olduğunda token otomatik iptal edilir.
///
/// Kullanım (serviste):
/// ```dart
/// final cancelToken = ref.watch(cancelTokenProvider);
/// await dio.get('/endpoint', cancelToken: cancelToken);
/// ```
///
/// Kullanım (provider'da):
/// ```dart
/// final myDataProvider = FutureProvider.autoDispose<Data>((ref) async {
///   final dio = ref.watch(dioProvider);
///   final cancelToken = ref.watch(cancelTokenProvider);
///   final response = await dio.get('/data', cancelToken: cancelToken);
///   return Data.fromJson(response.data);
/// });
/// ```
final cancelTokenProvider = Provider.autoDispose<CancelToken>((ref) {
  final cancelToken = CancelToken();

  ref.onDispose(() {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('Provider disposed - page navigation');
    }
  });

  return cancelToken;
});

/// Aile bazlı CancelToken - aynı sayfada farklı istekler için.
///
/// Kullanım:
/// ```dart
/// final token = ref.watch(cancelTokenFamilyProvider('bot_detail'));
/// ```
final cancelTokenFamilyProvider = Provider.autoDispose
    .family<CancelToken, String>((ref, key) {
      final cancelToken = CancelToken();

      ref.onDispose(() {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('Provider disposed - $key');
        }
      });

      return cancelToken;
    });

// ─── Exception Mapping ────────────────────────────────────────────

/// DioException'ı uygun AppException tipine dönüştürür.
AppException _mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return TimeoutException(
        debugMessage: 'Timeout: ${e.requestOptions.uri} - ${e.message}',
        originalError: e,
        stackTrace: e.stackTrace,
      );

    case DioExceptionType.connectionError:
      return NetworkException(
        debugMessage: 'Connection error: ${e.message}',
        originalError: e,
        stackTrace: e.stackTrace,
      );

    case DioExceptionType.cancel:
      return CancelledException(
        debugMessage: 'Request cancelled: ${e.requestOptions.uri}',
        originalError: e,
        stackTrace: e.stackTrace,
      );

    case DioExceptionType.badResponse:
      return _mapHttpStatusCode(e);

    case DioExceptionType.badCertificate:
      return const NetworkException(
        message: 'Güvenli bağlantı kurulamadı.',
        debugMessage: 'Bad certificate',
      );

    case DioExceptionType.unknown:
      if (e.error != null && e.error.toString().contains('SocketException')) {
        return NetworkException(
          debugMessage: 'Socket error: ${e.error}',
          originalError: e,
          stackTrace: e.stackTrace,
        );
      }
      return UnknownException(
        debugMessage: 'Unknown error: ${e.message}',
        originalError: e,
        stackTrace: e.stackTrace,
      );
  }
}

/// HTTP durum koduna göre AppException tipi belirler.
AppException _mapHttpStatusCode(DioException e) {
  final statusCode = e.response?.statusCode;
  final responseData = e.response?.data;

  final serverMessage = _extractServerMessage(responseData);

  switch (statusCode) {
    case 400:
      final fieldErrors = _extractFieldErrors(responseData);
      return ValidationException(
        message: serverMessage ?? 'Girdiğiniz bilgileri kontrol edin.',
        debugMessage: 'Bad Request: ${e.requestOptions.uri}',
        statusCode: statusCode,
        originalError: e,
        stackTrace: e.stackTrace,
        fieldErrors: fieldErrors,
      );

    case 401:
      final isLoginEndpoint = e.requestOptions.uri.path.contains('auth/login');
      return AuthException(
        message: isLoginEndpoint
            ? 'E-posta adresi veya şifre hatalı. Lütfen bilgilerinizi kontrol edin.'
            : (serverMessage ?? 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.'),
        debugMessage: 'Unauthorized: ${e.requestOptions.uri}',
        statusCode: statusCode,
        originalError: e,
        stackTrace: e.stackTrace,
      );

    case 403:
      return AuthException(
        message: serverMessage ?? 'Bu işlem için yetkiniz yok.',
        debugMessage: 'Forbidden: ${e.requestOptions.uri}',
        statusCode: statusCode,
        originalError: e,
        stackTrace: e.stackTrace,
      );

    case 404:
      return ValidationException(
        message: serverMessage ?? 'İstenen kaynak bulunamadı.',
        debugMessage: 'Not Found: ${e.requestOptions.uri}',
        statusCode: statusCode,
        originalError: e,
        stackTrace: e.stackTrace,
      );

    case 409:
      return ValidationException(
        message: serverMessage ?? 'Bu işlem bir çakışmaya neden oldu.',
        debugMessage: 'Conflict: ${e.requestOptions.uri}',
        statusCode: statusCode,
        originalError: e,
        stackTrace: e.stackTrace,
      );

    case 422:
      final fieldErrors = _extractFieldErrors(responseData);
      return ValidationException(
        message: serverMessage ?? 'Gönderilen veriler geçersiz.',
        debugMessage: 'Unprocessable Entity: ${e.requestOptions.uri}',
        statusCode: statusCode,
        originalError: e,
        stackTrace: e.stackTrace,
        fieldErrors: fieldErrors,
      );

    case 429:
      return const ServerException(
        message: 'Çok fazla istek gönderdiniz. Lütfen biraz bekleyin.',
        debugMessage: 'Too Many Requests',
        statusCode: 429,
      );

    case 500:
    case 502:
    case 503:
    case 504:
      return ServerException(
        message:
            serverMessage ??
            'Sunucuda bir sorun oluştu. Lütfen daha sonra tekrar deneyin.',
        debugMessage: 'Server Error ($statusCode): ${e.requestOptions.uri}',
        statusCode: statusCode,
        originalError: e,
        stackTrace: e.stackTrace,
      );

    default:
      return UnknownException(
        message:
            serverMessage ?? 'Beklenmedik bir hata oluştu (Kod: $statusCode).',
        debugMessage: 'HTTP $statusCode: ${e.requestOptions.uri}',
        originalError: e,
        stackTrace: e.stackTrace,
      );
  }
}

/// Backend response'undan kullanıcıya gösterilecek mesajı çıkarır.
String? _extractServerMessage(dynamic data) {
  if (data == null) return null;

  if (data is String && data.isNotEmpty) return data;

  if (data is Map<String, dynamic>) {
    if (data.containsKey('message')) return data['message']?.toString();
    if (data.containsKey('title')) return data['title']?.toString();
    if (data.containsKey('error')) return data['error']?.toString();
    if (data.containsKey('detail')) return data['detail']?.toString();
  }

  return null;
}

/// ASP.NET Core ValidationProblemDetails formatından field error'ları çıkarır.
Map<String, List<String>>? _extractFieldErrors(dynamic data) {
  if (data is! Map<String, dynamic>) return null;

  final errors = data['errors'];
  if (errors is! Map<String, dynamic>) return null;

  final result = <String, List<String>>{};
  for (final entry in errors.entries) {
    if (entry.value is List) {
      result[entry.key] = (entry.value as List)
          .map((e) => e.toString())
          .toList();
    }
  }

  return result.isEmpty ? null : result;
}
