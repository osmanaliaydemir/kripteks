import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/error/global_error_handler.dart';
import 'package:mobile/core/error/error_service.dart';
import 'package:mobile/core/widgets/network_status_banner.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mobile/core/services/firebase_notification_service.dart';
import 'package:mobile/core/providers/firebase_notification_provider.dart';
import 'package:mobile/core/widgets/privacy_blur_guard.dart';
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:mobile/core/providers/privacy_provider.dart';

void main() {
  final errorHandler = GlobalErrorHandler(errorService);

  errorHandler.handle(() {
    // Register background message handler
    // Note: Firebase is initialized inside errorHandler.handle via errorService.initialize()
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    runApp(const ProviderScope(child: MyApp()));
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription? _shakeSubscription;
  DateTime _lastShakeTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _initShakeDetector();
  }

  void _initShakeDetector() {
    _shakeSubscription = userAccelerometerEventStream().listen((event) {
      final double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      const double shakeThreshold = 15.0; // m/s^2

      if (acceleration > shakeThreshold) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime) >
            const Duration(milliseconds: 1500)) {
          _lastShakeTime = now;
          if (mounted) {
            ref.read(privacyProvider.notifier).toggleBalanceVisibility();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _shakeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    // Initialize notification service
    ref.watch(firebaseNotificationServiceProvider);

    return MaterialApp.router(
      title: 'Kripteks Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF59E0B), // Amber from web theme
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A), // Slate-900 from web theme
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('tr')],
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return GlobalErrorHandler.errorWidgetBuilder(details)(context);
        };
        return PrivacyBlurGuard(child: NetworkStatusBanner(child: widget!));
      },
    );
  }
}
