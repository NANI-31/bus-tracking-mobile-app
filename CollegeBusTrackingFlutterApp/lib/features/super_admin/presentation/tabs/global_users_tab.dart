import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/admin/application/admin_provider.dart';
import 'package:collegebus/core/constants/constants.dart';

class GlobalUsersTab extends ConsumerStatefulWidget {
  const GlobalUsersTab({super.key});

  @override
  ConsumerState<GlobalUsersTab> createState() => _GlobalUsersTabState();
}

class _GlobalUsersTabState extends ConsumerState<GlobalUsersTab> {
  String _searchQuery = '';
  UserRole? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final saService = ref.watch(superAdminServiceProvider);
    final allUsers = saService.globalUsers;

    final filteredUsers = allUsers.where((user) {
      if (_roleFilter != null && user.role != _roleFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return user.fullName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search global users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _roleFilter == null,
                      onSelected: (val) => setState(() => _roleFilter = null),
                    ),
                    const SizedBox(width: 8.0),
                    FilterChip(
                      label: const Text('Admins'),
                      selected: _roleFilter == UserRole.collegeAdmin,
                      onSelected: (val) => setState(
                        () => _roleFilter = val ? UserRole.collegeAdmin : null,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    FilterChip(
                      label: const Text('Coordinators'),
                      selected: _roleFilter == UserRole.busCoordinator,
                      onSelected: (val) => setState(
                        () =>
                            _roleFilter = val ? UserRole.busCoordinator : null,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    FilterChip(
                      label: const Text('Drivers'),
                      selected: _roleFilter == UserRole.driver,
                      onSelected: (val) => setState(
                        () => _roleFilter = val ? UserRole.driver : null,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    FilterChip(
                      label: const Text('Students'),
                      selected: _roleFilter == UserRole.student,
                      onSelected: (val) => setState(
                        () => _roleFilter = val ? UserRole.student : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredUsers.isEmpty
              ? const Center(child: Text('No users found matching criteria'))
              : ListView.builder(
                  itemCount: filteredUsers.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    // Find college name if available
                    // Ideally user model should have collegeName or we lookup from college list
                    // For now, simple display
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            user.fullName.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        title: Text(user.fullName),
                        subtitle: Text(
                          '${user.email}\n${user.role.displayName} • ${user.collegeId.isNotEmpty ? "College ID: ${user.collegeId}" : "No College"}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) async {
                            final saService = ref.read(
                              superAdminServiceProvider,
                            );
                            if (action == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete User'),
                                  content: Text(
                                    'Are you sure you want to delete ${user.fullName}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                if (context.mounted) {
                                  await saService.deleteUser(user.id);
                                }
                              }
                            } else if (action == 'promote') {
                              // Example: Promote to admin if student, etc.
                              final newRole = user.role == UserRole.student
                                  ? UserRole.collegeAdmin
                                  : UserRole.student;
                              await saService.updateUserRole(user.id, newRole);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'promote',
                              child: Text('Toggle Role (Admin/Student)'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete User',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}





