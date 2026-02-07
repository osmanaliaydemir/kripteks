import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiStatusAsync = ref.watch(apiKeyStatusProvider);
    // User info could be fetched from a dedicated UserProvider if available
    // For now we use a placeholder or decoded token if we implemented it
    const String userEmail = 'Trader';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Ayarlar',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSectionHeader('Profil'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF3B82F6),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userEmail,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Trader',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // API Keys Section
            _buildSectionHeader('Borsa Bağlantısı'),
            apiStatusAsync.when(
              data: (status) => _buildApiKeyCard(context, ref, status),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Text('Hata: $err', style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 24),

            // App Settings
            _buildSectionHeader('Uygulama'),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.notifications,
                    title: 'Bildirimler',
                    subtitle: 'Açık',
                    onTap: () {},
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildListTile(
                    icon: Icons.language,
                    title: 'Dil',
                    subtitle: 'Türkçe',
                    onTap: () {},
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildListTile(
                    icon: Icons.logout,
                    title: 'Çıkış Yap',
                    color: Colors.redAccent,
                    onTap: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildApiKeyCard(BuildContext context, WidgetRef ref, dynamic status) {
    final bool isConnected = status.hasKeys;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3BA2F).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/1/12/Binance_logo.svg', // Placeholder or use Asset
                  height: 24,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.currency_bitcoin,
                    color: Color(0xFFF3BA2F),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Binance',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isConnected ? 'Bağlı (${status.apiKey})' : 'Bağlı Değil',
                      style: TextStyle(
                        color: isConnected
                            ? const Color(0xFF10B981)
                            : Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70),
                onPressed: () => _showApiKeyDialog(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.white38))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }

  void _showApiKeyDialog(BuildContext context, WidgetRef ref) {
    final apiKeyController = TextEditingController();
    final secretKeyController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'API Anahtarlarını Güncelle',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: apiKeyController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: secretKeyController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Secret Key',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            if (isLoading)
              const CircularProgressIndicator()
            else
              TextButton(
                onPressed: () async {
                  setState(() => isLoading = true);
                  try {
                    await ref
                        .read(settingsServiceProvider)
                        .saveApiKeys(
                          apiKeyController.text.trim(),
                          secretKeyController.text.trim(),
                        );
                    ref.invalidate(apiKeyStatusProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('API anahtarları güncellendi'),
                        ),
                      );
                    }
                  } catch (e) {
                    setState(() => isLoading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Kaydet',
                  style: TextStyle(color: Color(0xFFF59E0B)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
