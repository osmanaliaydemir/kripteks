import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/error/global_error_handler.dart';
import 'package:mobile/core/error/error_service.dart';
import 'package:mobile/core/widgets/network_status_banner.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/l10n/app_localizations.dart';

Future<void> main() async {
  final errorHandler = GlobalErrorHandler(errorService);

  await errorHandler.handle(() async {
    runApp(const ProviderScope(child: MyApp()));
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

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
        return NetworkStatusBanner(child: widget!);
      },
    );
  }
}
