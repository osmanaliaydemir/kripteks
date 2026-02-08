import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Bildirim Ayarları',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bot işlemleriniz ve önemli güncellemeler hakkında bildirim alın.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notification Settings
          _buildSection('Bot Bildirimleri', [
            _buildSwitchTile(
              context,
              icon: Icons.trending_up,
              title: 'Alış Sinyalleri',
              subtitle: 'Bot alış işlemi yaptığında bildirim al',
              value: true,
              onChanged: (value) {},
            ),
            _buildSwitchTile(
              context,
              icon: Icons.trending_down,
              title: 'Satış Sinyalleri',
              subtitle: 'Bot satış işlemi yaptığında bildirim al',
              value: true,
              onChanged: (value) {},
            ),
            _buildSwitchTile(
              context,
              icon: Icons.warning_amber,
              title: 'Stop Loss',
              subtitle: 'Stop loss tetiklendiğinde bildirim al',
              value: true,
              onChanged: (value) {},
            ),
            _buildSwitchTile(
              context,
              icon: Icons.check_circle_outline,
              title: 'Take Profit',
              subtitle: 'Take profit hedefine ulaşıldığında bildirim al',
              value: true,
              onChanged: (value) {},
            ),
          ]),
          const SizedBox(height: 24),

          _buildSection('Sistem Bildirimleri', [
            _buildSwitchTile(
              context,
              icon: Icons.notifications_active,
              title: 'Genel Bildirimler',
              subtitle: 'Sistem güncellemeleri ve duyurular',
              value: true,
              onChanged: (value) {},
            ),
            _buildSwitchTile(
              context,
              icon: Icons.error_outline,
              title: 'Hata Bildirimleri',
              subtitle: 'Kritik hatalar hakkında bildirim al',
              value: true,
              onChanged: (value) {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF10B981),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white10,
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
      ],
    );
  }
}
