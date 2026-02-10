/// Tüm uygulama hatalarının temel sınıfı.
///
/// Her exception tipi, kullanıcıya gösterilecek mesajı ve
/// opsiyonel olarak orijinal hatayı ve stack trace'i taşır.
sealed class AppException implements Exception {
  final String message;
  final String? debugMessage;
  final int? statusCode;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.debugMessage,
    this.statusCode,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() =>
      '$runtimeType(message: $message, statusCode: $statusCode, debugMessage: $debugMessage)';
}

/// Ağ bağlantısı hataları (internet yok, DNS çözümlenemedi vb.)
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'İnternet bağlantınızı kontrol edin.',
    super.debugMessage,
    super.originalError,
    super.stackTrace,
  });
}

/// Kimlik doğrulama hataları (401 Unauthorized, 403 Forbidden)
class AuthException extends AppException {
  const AuthException({
    super.message = 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.',
    super.debugMessage,
    super.statusCode,
    super.originalError,
    super.stackTrace,
  });
}

/// Geçersiz veri / doğrulama hataları (400 Bad Request, 422)
class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException({
    super.message = 'Girdiğiniz bilgileri kontrol edin.',
    super.debugMessage,
    super.statusCode,
    super.originalError,
    super.stackTrace,
    this.fieldErrors,
  });
}

/// Sunucu hataları (500, 502, 503 vb.)
class ServerException extends AppException {
  const ServerException({
    super.message =
        'Sunucuda bir sorun oluştu. Lütfen daha sonra tekrar deneyin.',
    super.debugMessage,
    super.statusCode,
    super.originalError,
    super.stackTrace,
  });
}

/// Zaman aşımı hataları
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.',
    super.debugMessage,
    super.originalError,
    super.stackTrace,
  });
}

/// Sınıflandırılamamış / bilinmeyen hatalar
class UnknownException extends AppException {
  const UnknownException({
    super.message = 'Beklenmedik bir hata oluştu.',
    super.debugMessage,
    super.originalError,
    super.stackTrace,
  });
}

/// İstek iptal edildi
class CancelledException extends AppException {
  const CancelledException({
    super.message = 'İstek iptal edildi.',
    super.debugMessage,
    super.originalError,
    super.stackTrace,
  });
}
