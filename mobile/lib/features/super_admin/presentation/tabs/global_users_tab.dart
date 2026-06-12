import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/super_admin/application/super_admin_provider.dart';
import 'package:collegebus/core/constants/constants.dart';

class GlobalUsersTab extends ConsumerStatefulWidget {
  const GlobalUsersTab({super.key});

  @override
  ConsumerState<GlobalUsersTab> createState() => _GlobalUsersTabState();
}

class _GlobalUsersTabState extends ConsumerState<GlobalUsersTab> {
  String _searchQuery = '';
  UserRole? _roleFilter;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final asyncState = ref.read(superAdminServiceProvider);
      final hasMore = asyncState.valueOrNull?.globalUsersHasMore ?? false;
      if (!asyncState.isLoading && hasMore) {
        ref.read(superAdminServiceProvider.notifier).fetchGlobalUsers(
              search: _searchQuery,
              role: _roleFilter?.value,
              isLoadMore: true,
            );
      }
    }
  }

  void _onFilterChanged() {
    ref.read(superAdminServiceProvider.notifier).fetchGlobalUsers(
          search: _searchQuery,
          role: _roleFilter?.value,
          isLoadMore: false,
        );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(superAdminServiceProvider);
    final globalUsers = asyncState.valueOrNull?.globalUsers ?? [];
    final hasMore = asyncState.valueOrNull?.globalUsersHasMore ?? false;
    final isLoading = asyncState.isLoading;

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
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                  _onFilterChanged();
                },
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _roleFilter == null,
                      onSelected: (val) {
                        setState(() => _roleFilter = null);
                        _onFilterChanged();
                      },
                    ),
                    const SizedBox(width: 8.0),
                    FilterChip(
                      label: const Text('Admins'),
                      selected: _roleFilter == UserRole.collegeAdmin,
                      onSelected: (val) {
                        setState(() => _roleFilter = val ? UserRole.collegeAdmin : null);
                        _onFilterChanged();
                      },
                    ),
                    const SizedBox(width: 8.0),
                    FilterChip(
                      label: const Text('Coordinators'),
                      selected: _roleFilter == UserRole.busCoordinator,
                      onSelected: (val) {
                        setState(() => _roleFilter = val ? UserRole.busCoordinator : null);
                        _onFilterChanged();
                      },
                    ),
                    const SizedBox(width: 8.0),
                    FilterChip(
                      label: const Text('Drivers'),
                      selected: _roleFilter == UserRole.driver,
                      onSelected: (val) {
                        setState(() => _roleFilter = val ? UserRole.driver : null);
                        _onFilterChanged();
                      },
                    ),
                    const SizedBox(width: 8.0),
                    FilterChip(
                      label: const Text('Students'),
                      selected: _roleFilter == UserRole.student,
                      onSelected: (val) {
                        setState(() => _roleFilter = val ? UserRole.student : null);
                        _onFilterChanged();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: globalUsers.isEmpty && !isLoading
              ? const Center(child: Text('No users found matching criteria'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: globalUsers.length + (hasMore ? 1 : 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    if (index >= globalUsers.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final user = globalUsers[index];
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
                          '${user.email}\n${user.role.name} • ${user.collegeId.isNotEmpty ? "College ID: ${user.collegeId}" : "No College"}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) async {
                            final saNotifier = ref.read(
                              superAdminServiceProvider.notifier,
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
                                  await saNotifier.deleteUser(user.id);
                                }
                              }
                            } else if (action == 'promote') {
                              final newRole = user.role == UserRole.student
                                  ? UserRole.collegeAdmin
                                  : UserRole.student;
                              await saNotifier.updateUserRole(user.id, newRole);
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
