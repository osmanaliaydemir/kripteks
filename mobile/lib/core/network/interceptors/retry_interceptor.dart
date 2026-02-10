import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Ağ hataları ve sunucu hataları için otomatik yeniden deneme interceptor'ı.
///
/// - Sadece idempotent istekler (GET, PUT, DELETE, HEAD, OPTIONS) için retry yapar.
/// - POST istekleri retry **yapmaz** (yan etki riski).
/// - Exponential backoff stratejisi: 1s, 2s, 4s (varsayılan).
/// - Maksimum 3 deneme (varsayılan).
/// - Sadece retry yapılabilir hata tipleri için çalışır:
///   - Connection timeout/error
///   - 408, 429, 502, 503, 504 geçici sunucu hataları
///   - Send/Receive timeout
///   - 500 (Internal Server Error) retry **yapılmaz** (deterministik hata)
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration initialDelay;

  /// İsteğin kaçıncı denemede olduğunu takip etmek için
  /// extra map'e yazılan key.
  static const _retryCountKey = '_retryCount';

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    // POST istekleri retry yapma (idempotent değil)
    if (!_isIdempotent(requestOptions.method)) {
      return handler.next(err);
    }

    // İstek iptal edildiyse retry yapma
    if (err.type == DioExceptionType.cancel) {
      return handler.next(err);
    }

    // Bu hata retry yapılabilir mi?
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    // Mevcut deneme sayısı
    final retryCount = (requestOptions.extra[_retryCountKey] as int?) ?? 0;

    if (retryCount >= maxRetries) {
      if (kDebugMode) {
        debugPrint(
          '🔄 [RetryInterceptor] Max retries ($maxRetries) reached for '
          '${requestOptions.method} ${requestOptions.uri}',
        );
      }
      return handler.next(err);
    }

    // Exponential backoff: delay * 2^retryCount
    final delay = initialDelay * (1 << retryCount);

    if (kDebugMode) {
      debugPrint(
        '🔄 [RetryInterceptor] Retry ${retryCount + 1}/$maxRetries for '
        '${requestOptions.method} ${requestOptions.uri} '
        'after ${delay.inMilliseconds}ms',
      );
    }

    await Future.delayed(delay);

    // CancelToken kontrol - delay sırasında iptal edilmiş olabilir
    if (requestOptions.cancelToken?.isCancelled ?? false) {
      return handler.next(err);
    }

    // Retry sayacını artır
    requestOptions.extra[_retryCountKey] = retryCount + 1;

    try {
      final response = await dio.fetch(requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Sadece idempotent HTTP metotları retry edilir.
  bool _isIdempotent(String method) {
    return const {
      'GET',
      'PUT',
      'DELETE',
      'HEAD',
      'OPTIONS',
    }.contains(method.toUpperCase());
  }

  /// Hatanın retry yapılabilir olup olmadığını belirler.
  bool _shouldRetry(DioException err) {
    switch (err.type) {
      // Ağ ve timeout hataları -> retry
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;

      // Sunucu hataları -> retry (geçici olabilir)
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        return statusCode != null && _isRetryableStatusCode(statusCode);

      // Unknown hata (SocketException vb.) -> retry
      case DioExceptionType.unknown:
        return true;

      // İptal ve sertifika -> retry yapma
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return false;
    }
  }

  /// Retry yapılabilir HTTP durum kodları.
  ///
  /// 500 (Internal Server Error) retry listesinden **çıkarıldı** çünkü
  /// deterministik bir hata olup retry ile düzelmez. Sadece geçici hatalar:
  /// - 408: Request Timeout
  /// - 429: Too Many Requests (rate limit)
  /// - 502: Bad Gateway (proxy/load balancer geçici hatası)
  /// - 503: Service Unavailable (sunucu geçici olarak meşgul)
  /// - 504: Gateway Timeout
  bool _isRetryableStatusCode(int statusCode) {
    return const {408, 429, 502, 503, 504}.contains(statusCode);
  }
}
