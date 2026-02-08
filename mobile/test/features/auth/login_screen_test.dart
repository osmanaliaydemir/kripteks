import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/auth/biometric_service.dart';
import 'package:mobile/features/auth/login_screen.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:async';

// Mock Services
class MockBiometricService implements BiometricService {
  bool isSupported = false;
  bool isEnabled = false;
  Map<String, String>? credentials;
  bool authenticateResult = false;

  @override
  Future<bool> isDeviceSupported() async => isSupported;

  @override
  Future<bool> isBiometricEnabled() async => isEnabled;

  @override
  Future<Map<String, String>?> getCredentials() async => credentials;

  @override
  Future<void> saveCredentials(String email, String password) async {}

  @override
  Future<void> setBiometricEnabled(bool enabled) async {}

  @override
  Future<bool> authenticate() async => authenticateResult;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [];

  @override
  Future<void> clearCredentials() async {}
}

class MockAuthController extends AuthController {
  @override
  FutureOr<void> build() {
    return null;
  }

  @override
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    await Future.delayed(const Duration(milliseconds: 10));

    if (password == 'wrong') {
      state = AsyncError(Exception('Invalid credentials'), StackTrace.current);
    } else {
      state = const AsyncData(null);
    }
  }
}

void main() {
  late MockBiometricService mockBiometricService;

  setUp(() {
    mockBiometricService = MockBiometricService();
  });

  Widget createLoginScreen() {
    return ProviderScope(
      overrides: [
        biometricServiceProvider.overrideWithValue(mockBiometricService),
        authControllerProvider.overrideWith(() => MockAuthController()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('tr')],
        home: LoginScreen(),
      ),
    );
  }

  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Check input fields exist
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Biometric button visible when supported and enabled', (
    WidgetTester tester,
  ) async {
    mockBiometricService.isSupported = true;
    mockBiometricService.isEnabled = true;
    mockBiometricService.credentials = {
      'email': 'test@test.com',
      'password': 'password',
    };

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    expect(find.text('Biyometrik Giriş'), findsOneWidget);
  });

  testWidgets('Biometric button hidden when not supported', (
    WidgetTester tester,
  ) async {
    mockBiometricService.isSupported = false;

    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.fingerprint), findsNothing);
  });

  testWidgets('Login with invalid credentials shows error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Enter text
    await tester.enterText(find.byType(TextFormField).first, 'test@test.com');
    await tester.enterText(find.byType(TextFormField).last, 'wrong');
    await tester.pump();

    // Tap login button (using find by Type since text might be localized)
    await tester.tap(find.byType(ElevatedButton));

    // Wait for async operation and snackbar animation
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 100)); // Advance timer
    await tester.pumpAndSettle(); // Finish animation

    // Check for error snackbar
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Invalid credentials'), findsOneWidget);
  });
}
