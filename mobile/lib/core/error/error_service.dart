import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Abstract class for error reporting services (e.g. Crashlytics, Sentry)
abstract class ErrorService {
  Future<void> initialize();
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
  });
  Future<void> log(String message);
}

/// A simple implementation that logs to console/observability
class ConsoleErrorService implements ErrorService {
  final _logger = Logger('ErrorService');

  @override
  Future<void> initialize() async {
    // Initialize logging configuration if needed
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        print('${record.level.name}: ${record.time}: ${record.message}');
      }
    });
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
  }) async {
    _logger.severe('Exception detected: $reason', exception, stack);
  }

  @override
  Future<void> log(String message) async {
    _logger.info(message);
  }
}

/// Implementation that sends errors to Firebase Crashlytics
class FirebaseErrorService implements ErrorService {
  final _logger = Logger('FirebaseErrorService');

  @override
  Future<void> initialize() async {
    try {
      // Initialize Firebase App
      await Firebase.initializeApp();

      // Pass all uncaught fatal errors from the framework to Crashlytics
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Only enable collection in release mode or if specifically requested
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );

      _logger.info('Firebase Crashlytics initialized');
    } catch (e) {
      _logger.warning('Failed to initialize Firebase Crashlytics: $e');
      // Fallback: If Firebase fails (e.g. no config file), we continue without crashing
    }
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
  }) async {
    if (kDebugMode) {
      _logger.severe(
        'Exception (Relayed to Firebase): $reason',
        exception,
        stack,
      );
      // In debug, we don't want to actually send unless force enabled, usually we just log
      return;
    }
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: reason,
        fatal: false,
      );
    } catch (e) {
      _logger.warning('Failed to record error to Firebase: $e');
    }
  }

  @override
  Future<void> log(String message) async {
    if (kDebugMode) {
      _logger.info(message);
      return;
    }
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (e) {
      // Ignore
    }
  }
}

// Global accessor
// We decide here which one to use.
// TODO: Firebase'i yapılandırdığında (GoogleService-Info.plist + firebase_options.dart)
// FirebaseErrorService()'e geri dön.
final ErrorService errorService = ConsoleErrorService();
