import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/error/error_service.dart';
import 'package:mobile/core/theme/app_colors.dart';

/// Merkezi hata yönetimi sınıfı.
///
/// Tüm catch bloklarından buraya yönlendirme yapılarak:
/// - Hatanın AppException'a dönüştürülmesi
/// - Crashlytics'e raporlanması
/// - Kullanıcıya tutarlı mesaj gösterilmesi
/// sağlanır.
class ErrorHandler {
  ErrorHandler._();

  /// Herhangi bir hatayı [AppException]'a dönüştürür.
  ///
  /// Bu metot, servis katmanlarında kullanılır:
  /// ```dart
  /// try {
  ///   await dio.get('/endpoint');
  /// } on DioException catch (e) {
  ///   throw ErrorHandler.handle(e);
  /// }
  /// ```
  static AppException handle(dynamic error, [StackTrace? stackTrace]) {
    final appException = _toAppException(error, stackTrace);

    // Crashlytics'e raporla (CancelledException ve AuthException hariç)
    if (appException is! CancelledException && appException is! AuthException) {
      errorService.recordError(
        appException.originalError ?? appException,
        appException.stackTrace ?? stackTrace,
        reason: appException.debugMessage ?? appException.message,
      );
    }

    if (kDebugMode) {
      debugPrint('🔴 [ErrorHandler] $appException');
    }

    return appException;
  }

  /// Kullanıcıya SnackBar ile hata mesajı gösterir.
  static void showError(BuildContext context, dynamic error) {
    final appException = error is AppException
        ? error
        : _toAppException(error, null);

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _iconForException(appException),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                appException.message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: _colorForException(appException),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: _durationForException(appException),
        action: appException is! CancelledException
            ? SnackBarAction(
                label: 'Tamam',
                textColor: Colors.white,
                onPressed: () => messenger.hideCurrentSnackBar(),
              )
            : null,
      ),
    );
  }

  /// Kullanıcıya Dialog ile hata mesajı gösterir (kritik hatalar için).
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
  }) async {
    final appException = error is AppException
        ? error
        : _toAppException(error, null);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _iconForException(appException),
              color: _colorForException(appException),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title ?? _titleForException(appException),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          appException.message,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Tekrar Dene'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // ─── Internal helpers ───────────────────────────────────────────

  static AppException _toAppException(dynamic error, StackTrace? stackTrace) {
    if (error is AppException) return error;

    // DioException -> interceptor'dan zaten AppException gelmiş olabilir
    if (error is DioException) {
      if (error.error is AppException) {
        return error.error as AppException;
      }
      // Interceptor'dan geçmemiş bir DioException (nadir durum)
      return UnknownException(
        message: error.message ?? 'Beklenmedik bir ağ hatası oluştu.',
        debugMessage: 'Unhandled DioException: ${error.type}',
        originalError: error,
        stackTrace: stackTrace ?? error.stackTrace,
      );
    }

    // Dart'ın kendi TimeoutException'ı
    if (error is TimeoutException) {
      return TimeoutException(
        debugMessage: 'Dart TimeoutException: $error',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Eski Exception('message') formatı - geriye dönük uyumluluk
    if (error is Exception) {
      return UnknownException(
        message: error.toString().replaceFirst('Exception: ', ''),
        debugMessage: 'Legacy Exception: $error',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return UnknownException(
      message: 'Beklenmedik bir hata oluştu.',
      debugMessage: 'Raw error: $error',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static IconData _iconForException(AppException exception) {
    return switch (exception) {
      NetworkException() => Icons.wifi_off_rounded,
      AuthException() => Icons.lock_outline_rounded,
      ValidationException() => Icons.info_outline_rounded,
      ServerException() => Icons.cloud_off_rounded,
      TimeoutException() => Icons.timer_off_rounded,
      CancelledException() => Icons.cancel_outlined,
      UnknownException() => Icons.error_outline_rounded,
    };
  }

  static Color _colorForException(AppException exception) {
    return switch (exception) {
      NetworkException() => const Color(0xFFEF4444), // red
      AuthException() => const Color(0xFFF59E0B), // amber
      ValidationException() => const Color(0xFFF97316), // orange
      ServerException() => const Color(0xFFEF4444), // red
      TimeoutException() => const Color(0xFFF97316), // orange
      CancelledException() => const Color(0xFF6B7280), // gray
      UnknownException() => const Color(0xFFEF4444), // red
    };
  }

  static String _titleForException(AppException exception) {
    return switch (exception) {
      NetworkException() => 'Bağlantı Hatası',
      AuthException() => 'Oturum Hatası',
      ValidationException() => 'Doğrulama Hatası',
      ServerException() => 'Sunucu Hatası',
      TimeoutException() => 'Zaman Aşımı',
      CancelledException() => 'İptal Edildi',
      UnknownException() => 'Hata',
    };
  }

  static Duration _durationForException(AppException exception) {
    return switch (exception) {
      CancelledException() => const Duration(seconds: 2),
      NetworkException() => const Duration(seconds: 5),
      AuthException() => const Duration(seconds: 4),
      _ => const Duration(seconds: 3),
    };
  }
}
