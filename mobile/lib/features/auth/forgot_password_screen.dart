import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 1; // 1: Email, 2: Code, 3: New Password
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .forgotPassword(_emailController.text.trim());
      setState(() {
        _currentStep = 2;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doğrulama kodu e-posta adresinize gönderildi.'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleVerifyCode() async {
    if (_codeController.text.length != 6) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .verifyResetCode(
            _emailController.text.trim(),
            _codeController.text.trim(),
          );
      setState(() {
        _currentStep = 3;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .resetPassword(
            _emailController.text.trim(),
            _codeController.text.trim(),
            _passwordController.text,
          );
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Şifreniz başarıyla sıfırlandı. Giriş yapabilirsiniz.',
            ),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            height: 400,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.8,
                  colors: [Color(0x40F59E0B), Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo / Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      _currentStep == 1
                          ? Icons.lock_reset_rounded
                          : _currentStep == 2
                          ? Icons.mark_email_read_rounded
                          : Icons.verified_user_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ).animate().scale(curve: Curves.easeOutBack),

                  const SizedBox(height: 32),

                  Text(
                    _currentStep == 1
                        ? 'Şifremi Unuttum'
                        : _currentStep == 2
                        ? 'Kodu Doğrula'
                        : 'Yeni Şifre Belirle',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 12),

                  Text(
                    _currentStep == 1
                        ? 'E-posta adresinizi girin, size bir kod gönderelim.'
                        : _currentStep == 2
                        ? '${_emailController.text} adresine gönderilen 6 haneli kodu giriniz.'
                        : 'Güçlü ve güvenli yeni bir şifre oluşturun.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 40),

                  Form(key: _formKey, child: _buildStepContent()),

                  const SizedBox(height: 32),

                  // Back to login
                  if (_currentStep == 1)
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Giriş Ekranına Dön',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabel('Email Adresiniz'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration(
                hint: 'ornek@mail.com',
                prefixIcon: Icons.mail_outline,
              ),
              validator: (val) => val == null || !val.contains('@')
                  ? 'Geçerli bir email girin'
                  : null,
            ),
            const SizedBox(height: 24),
            _buildButton('Kod Gönder', _handleSendCode),
          ],
        ).animate().fadeIn().slideX(begin: 0.1, end: 0);
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabel('Doğrulama Kodu'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 12,
              ),
              decoration: _buildInputDecoration(
                hint: '000000',
                prefixIcon: Icons.security_rounded,
              ).copyWith(counterText: ""),
              onChanged: (val) {
                if (val.length == 6) _handleVerifyCode();
              },
            ),
            const SizedBox(height: 24),
            _buildButton('Doğrula', _handleVerifyCode),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading ? null : _handleSendCode,
              child: const Text(
                'Kodu Tekrar Gönder',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ).animate().fadeIn().slideX(begin: 0.1, end: 0);
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabel('Yeni Şifre'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration(
                hint: '••••••••',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white38,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (val) =>
                  val != null && val.length < 6 ? 'En az 6 karakter' : null,
            ),
            const SizedBox(height: 24),
            _buildButton('Şifreyi Sıfırla', _handleResetPassword),
          ],
        ).animate().fadeIn().slideX(begin: 0.1, end: 0);
      default:
        return const SizedBox();
    }
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
      fillColor: const Color(0xFF1E293B).withValues(alpha: 0.5),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      prefixIcon: Icon(prefixIcon, color: Colors.white38, size: 20),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
