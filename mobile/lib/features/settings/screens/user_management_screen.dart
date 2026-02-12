import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/settings/providers/user_management_provider.dart';
import 'package:mobile/features/settings/screens/user_edit_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter =
      'Tümü'; // 'Tümü', 'Aktif', 'Pasif', 'User', 'Trader', 'Admin'

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final usersNotifier = ref.read(usersProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Kullanıcı Ara...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Tümü', Colors.white),
                const SizedBox(width: 8),
                _buildFilterChip('Aktif', AppColors.success),
                const SizedBox(width: 8),
                _buildFilterChip('Pasif', AppColors.error),
                const SizedBox(width: 8),
                _buildFilterChip('User', Colors.blue),
                const SizedBox(width: 8),
                _buildFilterChip('Trader', Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip('Admin', Colors.purple),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // User List
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filteredUsers = users.where((user) {
                  // Search Filter
                  final query = _searchController.text.toLowerCase();
                  final matchesSearch =
                      user.firstName.toLowerCase().contains(query) ||
                      user.lastName.toLowerCase().contains(query) ||
                      user.email.toLowerCase().contains(query);

                  if (!matchesSearch) return false;

                  // Category Filter
                  switch (_selectedFilter) {
                    case 'Aktif':
                      return user.isActive;
                    case 'Pasif':
                      return !user.isActive;
                    case 'User':
                      return user.role == 'User';
                    case 'Trader':
                      return user.role == 'Trader';
                    case 'Admin':
                      return user.role == 'Admin';
                    default:
                      return true;
                  }
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text(
                      'Kullanıcı bulunamadı',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.isActive
                            ? AppColors.success.withOpacity(0.2)
                            : AppColors.error.withOpacity(0.2),
                        child: Text(
                          user.firstName.isNotEmpty
                              ? user.firstName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: user.isActive
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        '${user.firstName} ${user.lastName}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        user.email,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getRoleColor(
                                  user.role,
                                ).withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              user.role,
                              style: TextStyle(
                                color: _getRoleColor(user.role),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserEditScreen(user: user),
                              ),
                            )
                            .then((_) {
                              usersNotifier.refresh();
                            });
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Hata: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, Color color) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : AppColors.surfaceLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? color : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.purple;
      case 'Trader':
        return Colors.orange;
      case 'User':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
