import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:mobile/core/error/error_service.dart';
import 'package:mobile/core/theme/app_colors.dart';

class GlobalErrorHandler {
  final ErrorService _errorService;

  GlobalErrorHandler(this._errorService);

  /// Initializes the error handler and runs the app within a guarded zone
  void handle(void Function() appRunner) {
    runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        await _errorService.initialize();

        // Catch Flutter Framework Errors
        FlutterError.onError = (FlutterErrorDetails details) {
          if (kDebugMode) {
            FlutterError.dumpErrorToConsole(details);
          } else {
            FirebaseCrashlytics.instance.recordFlutterError(details);
          }
        };

        appRunner();
      },
      (error, stackTrace) {
        _errorService.recordError(
          error,
          stackTrace,
          reason: 'Uncaught Global Exception',
        );
      },
    );
  }

  /// Custom Error Widget Builder for Release Mode
  static WidgetBuilder errorWidgetBuilder(FlutterErrorDetails details) {
    return (context) => Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Beklenmedik bir hata oluştu',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                kDebugMode
                    ? details.summary.toString()
                    : 'Uygulamada beklenmedik bir sorun oluştu. Lütfen tekrar deneyiniz.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      details.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Basic attempt to recover - might need more sophisticated navigation reset
                  // For now, in release, this acts as a visual cue or could restart the app logically
                  // Depending on routing strategy, we might want to go home
                  // Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  // Since we don't have context here easily for navigation without context,
                  // we just provide a visual reset for now or basic pop if possible.
                  // Ideally, we would use a global key for navigation or restart the app.
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
