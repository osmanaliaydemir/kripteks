import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/settings/providers/user_management_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class UserEditScreen extends ConsumerStatefulWidget {
  final UserManagementDto user;

  const UserEditScreen({super.key, required this.user});

  @override
  ConsumerState<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends ConsumerState<UserEditScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late String _role;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _role = widget.user.role;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      final updatedUser = widget.user.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        role: _role,
        isActive: _isActive,
      );

      await ref.read(usersProvider.notifier).updateUser(updatedUser);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı güncellendi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordResetLink() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(usersProvider.notifier)
          .sendPasswordResetLink(widget.user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre sıfırlama bağlantısı gönderildi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Kullanıcı Düzenle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildTextField(
              controller: _firstNameController,
              label: 'Ad',
              hint: 'Ad giriniz',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _lastNameController,
              label: 'Soyad',
              hint: 'Soyad giriniz',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 24),

            // Role Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.white10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _role,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.primary,
                  ),
                  items: ['User', 'Trader', 'Admin'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _role = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // IsActive Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Hesap Aktif',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                _isActive ? 'Kullanıcı giriş yapabilir' : 'Kullanıcı engelli',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              value: _isActive,
              activeThumbColor: AppColors.success,
              onChanged: (bool value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
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
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'Kaydet',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _sendPasswordResetLink,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.lock_reset),
                label: Text(
                  'Şifre Sıfırlama Bağlantısı Gönder',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildAuditLogs(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLogs() {
    final auditLogsAsync = ref.watch(auditLogsProvider(widget.user.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İşlem Geçmişi (Audit Logs)',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        auditLogsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return const Text(
                'Kayıt bulunamadı.',
                style: TextStyle(color: Colors.grey),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      _getIconForCategory(log.category),
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    log.action,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${log.timestamp.toString().substring(0, 16)} • ${log.ipAddress ?? "IP Yok"}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text(
            'Hata: $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Auth':
        return Icons.security;
      case 'Trade':
        return Icons.candlestick_chart;
      case 'Wallet':
        return Icons.account_balance_wallet;
      case 'Settings':
        return Icons.settings;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
