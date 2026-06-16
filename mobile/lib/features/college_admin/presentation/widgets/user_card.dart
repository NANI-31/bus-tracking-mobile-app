import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/college_admin/application/college_admin_provider.dart';
import 'package:collegebus/core/constants/constants.dart';

class UserCard extends ConsumerWidget {
  final UserModel user;

  const UserCard({super.key, required this.user});

  void _confirmDeleteUser(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete User?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${user.fullName}? This action cannot be undone.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final caNotifier = ref.read(collegeAdminServiceProvider.notifier);
                await caNotifier.deleteUser(user.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete user: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserApproval(BuildContext context, WidgetRef ref, bool newStatus) async {
    try {
      final caNotifier = ref.read(collegeAdminServiceProvider.notifier);
      await caNotifier.updateUserStatus(user.id, approved: newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'User approved successfully' : 'User suspended successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Operation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return const Color(0xFF1E90FF); // Dodger Blue
      case UserRole.driver:
        return const Color(0xFF00B5B5); // Turquoise / Teal
      case UserRole.busCoordinator:
        return const Color(0xFF9370DB); // Medium Purple
      case UserRole.collegeAdmin:
        return const Color(0xFFFF8C00); // Dark Orange
      default:
        return Colors.blueGrey;
    }
  }

  LinearGradient _getAvatarGradient(UserRole role) {
    switch (role) {
      case UserRole.student:
        return const LinearGradient(
          colors: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case UserRole.driver:
        return const LinearGradient(
          colors: [Color(0xFF4DB6AC), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case UserRole.busCoordinator:
        return const LinearGradient(
          colors: [Color(0xFFBA68C8), Color(0xFF8E24AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case UserRole.collegeAdmin:
        return const LinearGradient(
          colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Colors.grey, Colors.blueGrey],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isApproved = user.approved;
    final roleColor = _getRoleColor(user.role);
    final initial = user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row (Avatar, Name, Role Badge, Menu)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with Status Badge
                  Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _getAvatarGradient(user.role),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isApproved ? Colors.green : Colors.amber,
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Name and badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (user.isPremium)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.workspace_premium, size: 10, color: Colors.amber),
                                    SizedBox(width: 2),
                                    Text(
                                      'PRO',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Role and Approval status tags
                        Row(
                          children: [
                            // Role tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: roleColor.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                user.role.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: roleColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Approval tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isApproved
                                    ? Colors.green.withValues(alpha: 0.08)
                                    : Colors.amber.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isApproved
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.amber.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                isApproved ? 'Approved' : 'Pending',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isApproved ? Colors.green : Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions Popup Menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDeleteUser(context, ref);
                      } else if (value == 'toggle_approve') {
                        _toggleUserApproval(context, ref, !isApproved);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle_approve',
                        child: Row(
                          children: [
                            Icon(
                              isApproved ? Icons.block : Icons.check_circle_outline,
                              size: 18,
                              color: isApproved ? Colors.amber : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(isApproved ? 'Suspend' : 'Approve'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Delete User', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              // Metadata rows (Email, Phone, RollNumber)
              _buildMetadataRow(Icons.mail_outline_rounded, user.email, isDark),
              if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildMetadataRow(Icons.phone_outlined, user.phoneNumber!, isDark),
              ],
              if (user.rollNumber != null && user.rollNumber!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildMetadataRow(Icons.badge_outlined, user.rollNumber!, isDark),
              ],
              
              // Approve Button at bottom if user is pending
              if (!isApproved) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleUserApproval(context, ref, true),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve Registration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? Colors.white38 : Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
