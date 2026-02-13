import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/error/error_handler.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/core/auth/biometric_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _canUseBiometric = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final biometricService = ref.read(biometricServiceProvider);
    final isSupported = await biometricService.isDeviceSupported();
    final credentials = await biometricService.getCredentials();

    // Only show biometric button if device supports it AND we have stored credentials
    // AND biometric is enabled in settings (default true if credentials exist usually)
    final isEnabled = await biometricService.isBiometricEnabled();

    if (mounted && isSupported && credentials != null && isEnabled) {
      setState(() {
        _canUseBiometric = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      await ref.read(authControllerProvider.notifier).login(email, password);

      // Only save if "Remember Me" is checked
      if (_rememberMe) {
        final biometricService = ref.read(biometricServiceProvider);
        await biometricService.saveCredentials(email, password);
        await biometricService.setBiometricEnabled(true);
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final biometricService = ref.read(biometricServiceProvider);
    final authenticated = await biometricService.authenticate();

    if (authenticated) {
      final credentials = await biometricService.getCredentials();
      if (credentials != null) {
        if (mounted) {
          // Auto-fill and submit
          _emailController.text = credentials['email']!;
          _passwordController.text = credentials['password']!;
          _handleLogin();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes
    ref.listen(authControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (!next.isLoading && !next.hasError) {
            context.go('/dashboard');
          }
        },
        error: (err, stack) {
          ErrorHandler.showError(context, err);
        },
        loading: () {},
      );
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    Container(
                      margin: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        children: [
                          Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryDark,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.candlestick_chart_rounded,
                                  size: 40,
                                  color: AppColors.textPrimary,
                                ),
                              )
                              .animate()
                              .scale(
                                duration: 600.ms,
                                curve: Curves.easeOutBack,
                              )
                              .shimmer(delay: 1000.ms, duration: 1500.ms),

                          const SizedBox(height: 24),

                          Text(
                                AppLocalizations.of(context)!.loginTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.2, end: 0),
                        ],
                      ),
                    ),

                    // Form Section
                    Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLabel(AppLocalizations.of(context)!.email),
                          const SizedBox(height: 8),
                          TextFormField(
                                controller: _emailController,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: _buildInputDecoration(
                                  hint: AppLocalizations.of(context)!.emailHint,
                                  prefixIcon: Icons.mail_outline,
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(
                                      context,
                                    )!.emailRequired;
                                  }
                                  if (!_isValidEmail(value.trim())) {
                                    return AppLocalizations.of(
                                      context,
                                    )!.emailInvalid;
                                  }
                                  return null;
                                },
                              )
                              .animate()
                              .fadeIn(delay: 300.ms)
                              .slideX(begin: 0.1, end: 0),
                          const SizedBox(height: 16),

                          _buildLabel(AppLocalizations.of(context)!.password),
                          const SizedBox(height: 8),
                          TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: _buildInputDecoration(
                                  hint: '••••••••',
                                  prefixIcon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(
                                      context,
                                    )!.passwordRequired;
                                  }
                                  return null;
                                },
                              )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideX(begin: 0.1, end: 0),

                          const SizedBox(height: 16),

                          // Remember Me & Forgot Password Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Remember Me
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.primary,
                                      checkColor: Colors.white,
                                      side: const BorderSide(
                                        color: AppColors.textSecondary,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    child: const Text(
                                      'Beni Hatırla',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Forgot Password link
                              TextButton(
                                onPressed: () =>
                                    context.push('/forgot-password'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.forgotPassword,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 500.ms),

                          const SizedBox(height: 32),

                          // Login Button
                          Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryDark,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          AppLocalizations.of(context)!.login,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 600.ms)
                              .scale(begin: const Offset(0.9, 0.9)),

                          const SizedBox(height: 24),

                          // Biometric Login Button
                          if (_canUseBiometric)
                            Container(
                              width: double.infinity,
                              height: 56,
                              margin: const EdgeInsets.only(bottom: 24),
                              child: OutlinedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : _handleBiometricLogin,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  foregroundColor: AppColors.primary,
                                ),
                                icon: const Icon(Icons.fingerprint, size: 28),
                                label: Text(
                                  AppLocalizations.of(context)!.biometricLogin,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 800.ms),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${AppLocalizations.of(context)!.dontHaveAccount} ',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/signup'),
                                child: Text(
                                  AppLocalizations.of(context)!.signup,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 900.ms),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textDisabled),
      prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
    );
  }

  static bool _isValidEmail(String value) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(value);
  }
}
