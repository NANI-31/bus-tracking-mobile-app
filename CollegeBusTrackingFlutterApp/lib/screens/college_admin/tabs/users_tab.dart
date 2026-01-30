import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:collegebus/services/admin/college_admin_service.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/screens/college_admin/widgets/user_card.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  UserRole? _selectedRoleFilter;
  bool? _selectedApprovalFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final collegeAdminService = Provider.of<CollegeAdminService>(context);
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
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Students'),
                selected: _selectedRoleFilter == UserRole.student,
                onSelected: (val) =>
                    setState(() => _selectedRoleFilter = UserRole.student),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Drivers'),
                selected: _selectedRoleFilter == UserRole.driver,
                onSelected: (val) =>
                    setState(() => _selectedRoleFilter = UserRole.driver),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Coordinators'),
                selected: _selectedRoleFilter == UserRole.busCoordinator,
                onSelected: (val) => setState(
                  () => _selectedRoleFilter = UserRole.busCoordinator,
                ),
              ),
              const SizedBox(width: 8),
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
                    return UserCard(user: user, caService: collegeAdminService);
                  },
                ),
        ),
      ],
    );
  }
}
