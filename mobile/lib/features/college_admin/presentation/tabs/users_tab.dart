import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/admin/application/admin_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/college_admin/presentation/widgets/user_card.dart';

class UsersTab extends ConsumerStatefulWidget {
  const UsersTab({super.key});

  @override
  ConsumerState<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<UsersTab> {
  UserRole? _selectedRoleFilter;
  bool? _selectedApprovalFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final collegeAdminService = ref.watch(collegeAdminServiceProvider);
    final collegeUsers = collegeAdminService.collegeUsers;

    // Filtered users logic moved here
    final filteredUsersList = collegeUsers.where((user) {
      if (_selectedRoleFilter != null && user.role != _selectedRoleFilter) {
        return false;
      }
      if (_selectedApprovalFilter != null &&
          user.approved != _selectedApprovalFilter) {
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
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search users...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMedium,
          ),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedRoleFilter == null,
                onSelected: (val) => setState(() => _selectedRoleFilter = null),
              ),
              const SizedBox(width: 8.0),
              FilterChip(
                label: const Text('Students'),
                selected: _selectedRoleFilter == UserRole.student,
                onSelected: (val) =>
                    setState(() => _selectedRoleFilter = UserRole.student),
              ),
              const SizedBox(width: 8.0),
              FilterChip(
                label: const Text('Drivers'),
                selected: _selectedRoleFilter == UserRole.driver,
                onSelected: (val) =>
                    setState(() => _selectedRoleFilter = UserRole.driver),
              ),
              const SizedBox(width: 8.0),
              FilterChip(
                label: const Text('Coordinators'),
                selected: _selectedRoleFilter == UserRole.busCoordinator,
                onSelected: (val) => setState(
                  () => _selectedRoleFilter = UserRole.busCoordinator,
                ),
              ),
              const SizedBox(width: 8.0),
              FilterChip(
                label: const Text('Pending'),
                selected: _selectedApprovalFilter == false,
                onSelected: (val) => setState(() {
                  _selectedApprovalFilter = val ? false : null;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredUsersList.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: filteredUsersList.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsersList[index];
                    return UserCard(user: user);
                  },
                ),
        ),
      ],
    );
  }
}





