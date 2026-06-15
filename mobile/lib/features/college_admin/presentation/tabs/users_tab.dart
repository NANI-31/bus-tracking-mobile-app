import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/college_admin/application/college_admin_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/college_admin/presentation/widgets/user_card.dart';


class UsersTab extends ConsumerStatefulWidget {
  const UsersTab({super.key});

  @override
  ConsumerState<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<UsersTab> {
  String _searchQuery = '';
  final Set<UserRole> _selectedRoles = {};
  final Set<bool> _selectedStatuses = {};
  final TextEditingController _searchController = TextEditingController();
  bool _showStats = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(collegeAdminServiceProvider);
    final collegeUsers = asyncState.valueOrNull?.collegeUsers ?? [];
    final pendingUsers = asyncState.valueOrNull?.pendingUsers ?? [];

    final totalUsers = collegeUsers.length;
    final approvedUsers = collegeUsers.where((u) => u.approved).length;
    final pendingCount = pendingUsers.length;

    final studentCount = collegeUsers.where((u) => u.role == UserRole.student).length;
    final teacherCount = collegeUsers.where((u) => u.role == UserRole.teacher).length;
    final driverCount = collegeUsers.where((u) => u.role == UserRole.driver).length;
    final coordinatorCount = collegeUsers.where((u) => u.role == UserRole.busCoordinator).length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF00C6E6) : const Color(0xFF0097B2);

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    // Filtered users logic
    final filteredUsersList = collegeUsers.where((user) {
      if (_selectedRoles.isNotEmpty && !_selectedRoles.contains(user.role)) {
        return false;
      }
      if (_selectedStatuses.isNotEmpty && !_selectedStatuses.contains(user.approved)) {
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and description header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Users Directory',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage students, drivers, and coordinators registered under your institution.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Search & Filters Panel
        Container(
          margin: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: primaryColor,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A).withOpacity(0.6)
                            : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter trigger button
                  GestureDetector(
                    onTap: () async {
                      final result = await showModalBottomSheet<Map<String, dynamic>>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => _UserFilterBottomSheet(
                          initialSelectedRoles: _selectedRoles,
                          initialSelectedStatuses: _selectedStatuses,
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          _selectedRoles.clear();
                          _selectedRoles.addAll(result['roles'] as Set<UserRole>);
                          _selectedStatuses.clear();
                          _selectedStatuses.addAll(result['statuses'] as Set<bool>);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: (_selectedRoles.isNotEmpty || _selectedStatuses.isNotEmpty)
                            ? (isDark
                                ? primaryColor.withOpacity(0.15)
                                : primaryColor.withOpacity(0.08))
                            : (isDark
                                ? const Color(0xFF0F172A).withOpacity(0.6)
                                : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (_selectedRoles.isNotEmpty || _selectedStatuses.isNotEmpty)
                              ? (isDark
                                  ? primaryColor.withOpacity(0.4)
                                  : primaryColor.withOpacity(0.2))
                              : (isDark ? Colors.white10 : Colors.grey.shade200),
                        ),
                      ),
                      child: Badge(
                        isLabelVisible: _selectedRoles.isNotEmpty || _selectedStatuses.isNotEmpty,
                        label: Text(
                          '${_selectedRoles.length + _selectedStatuses.length}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        alignment: const Alignment(1.3, -1.3),
                        child: Icon(
                          Icons.filter_list_rounded,
                          size: 20,
                          color: (_selectedRoles.isNotEmpty || _selectedStatuses.isNotEmpty)
                              ? primaryColor
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Stats Info Toggle Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showStats = !_showStats;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: _showStats
                            ? (isDark
                                ? primaryColor.withOpacity(0.15)
                                : primaryColor.withOpacity(0.08))
                            : (isDark
                                ? const Color(0xFF0F172A).withOpacity(0.6)
                                : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _showStats
                              ? (isDark
                                  ? primaryColor.withOpacity(0.4)
                                  : primaryColor.withOpacity(0.2))
                              : (isDark ? Colors.white10 : Colors.grey.shade200),
                        ),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: _showStats
                            ? primaryColor
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ),
                ],
              ),
              // Statistics Cards grid inside AnimatedCrossFade
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: isWide ? 4 : 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isWide ? 1.5 : 1.0,
                      children: [
                        _buildStatCard(
                          'TOTAL USERS',
                          totalUsers.toString(),
                          Icons.people_alt_outlined,
                          primaryColor.withOpacity(0.12),
                          primaryColor,
                          isDark,
                        ),
                        _buildStatCard(
                          'APPROVED',
                          approvedUsers.toString(),
                          Icons.check_circle_outline_rounded,
                          const Color(0xFF10B981).withOpacity(0.12),
                          const Color(0xFF10B981),
                          isDark,
                        ),
                        _buildStatCard(
                          'PENDING',
                          pendingCount.toString(),
                          Icons.pending_actions_rounded,
                          const Color(0xFFF59E0B).withOpacity(0.12),
                          const Color(0xFFF59E0B),
                          isDark,
                        ),
                        _buildStatCard(
                          'STUDENTS',
                          studentCount.toString(),
                          Icons.school_outlined,
                          const Color(0xFF3B82F6).withOpacity(0.12),
                          const Color(0xFF3B82F6),
                          isDark,
                        ),
                        _buildStatCard(
                          'TEACHERS',
                          teacherCount.toString(),
                          Icons.assignment_ind_outlined,
                          const Color(0xFFEC4899).withOpacity(0.12),
                          const Color(0xFFEC4899),
                          isDark,
                        ),
                        _buildStatCard(
                          'DRIVERS',
                          driverCount.toString(),
                          Icons.directions_bus_outlined,
                          const Color(0xFF06B6D4).withOpacity(0.12),
                          const Color(0xFF06B6D4),
                          isDark,
                        ),
                        _buildStatCard(
                          'COORDINATORS',
                          coordinatorCount.toString(),
                          Icons.admin_panel_settings_outlined,
                          const Color(0xFF8B5CF6).withOpacity(0.12),
                          const Color(0xFF8B5CF6),
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
                crossFadeState: _showStats ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
              // Dismissible Filter Chips Display
              if (_selectedRoles.isNotEmpty || _selectedStatuses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Filters: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ..._selectedRoles.map((role) => Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: _buildActiveFilterChip(
                                label: _getRoleLabel(role),
                                onClear: () {
                                  setState(() => _selectedRoles.remove(role));
                                },
                                isDark: isDark,
                              ),
                            )),
                            ..._selectedStatuses.map((status) => Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: _buildActiveFilterChip(
                                label: status ? 'Approved' : 'Pending',
                                onClear: () {
                                  setState(() => _selectedStatuses.remove(status));
                                },
                                isDark: isDark,
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // List Area
        Expanded(
          child: filteredUsersList.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filteredUsersList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final user = filteredUsersList[index];
                    return UserCard(user: user);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgOpacityColor,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgOpacityColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.collegeAdmin:
        return 'Admin';
      case UserRole.busCoordinator:
        return 'Coordinator';
      case UserRole.driver:
        return 'Driver';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
      default:
        return 'User';
    }
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onClear,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white.withOpacity(0.87) : Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded, size: 13, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 48,
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No users matched your filters',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search query, clearing your filters, or checking for pending registrations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey.shade500,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _selectedRoles.clear();
                  _selectedStatuses.clear();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset All Filters', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserFilterBottomSheet extends StatefulWidget {
  final Set<UserRole> initialSelectedRoles;
  final Set<bool> initialSelectedStatuses;

  const _UserFilterBottomSheet({
    required this.initialSelectedRoles,
    required this.initialSelectedStatuses,
  });

  @override
  State<_UserFilterBottomSheet> createState() => _UserFilterBottomSheetState();
}

class _UserFilterBottomSheetState extends State<_UserFilterBottomSheet> {
  int _activeTab = 0; // 0 = Role, 1 = Status
  final Set<UserRole> _tempSelectedRoles = {};
  final Set<bool> _tempSelectedStatuses = {};

  @override
  void initState() {
    super.initState();
    _tempSelectedRoles.addAll(widget.initialSelectedRoles);
    _tempSelectedStatuses.addAll(widget.initialSelectedStatuses);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F28) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _tempSelectedRoles.clear();
                      _tempSelectedStatuses.clear();
                    });
                  },
                  child: Text(
                    'Reset All',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 120,
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeftTabTile(
                        index: 0,
                        title: 'Role',
                        isActive: _activeTab == 0,
                        isDark: isDark,
                        badgeCount: _tempSelectedRoles.length,
                      ),
                      _buildLeftTabTile(
                        index: 1,
                        title: 'Status',
                        isActive: _activeTab == 1,
                        isDark: isDark,
                        badgeCount: _tempSelectedStatuses.length,
                      ),
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade200,
                ),
                Expanded(
                  child: _activeTab == 0
                      ? _buildRoleOptionsList(isDark)
                      : _buildStatusOptionsList(isDark),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C6E6), Color(0xFF0097B2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0097B2).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'roles': _tempSelectedRoles,
                          'statuses': _tempSelectedStatuses,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftTabTile({
    required int index,
    required String title,
    required bool isActive,
    required bool isDark,
    required int badgeCount,
  }) {
    final Color activeColor = isDark
        ? const Color(0xFF00C6E6)
        : const Color(0xFF0097B2);
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        color: isActive
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : Colors.transparent,
        child: Row(
          children: [
            if (isActive)
              Container(
                width: 3.5,
                height: 18,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            if (isActive) const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? activeColor
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontSize: 14,
                ),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOptionsList(bool isDark) {
    final roles = [
      {'label': 'All Roles', 'value': null},
      {'label': 'Admins', 'value': UserRole.collegeAdmin},
      {'label': 'Coordinators', 'value': UserRole.busCoordinator},
      {'label': 'Drivers', 'value': UserRole.driver},
      {'label': 'Teachers', 'value': UserRole.teacher},
      {'label': 'Students', 'value': UserRole.student},
    ];

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final roleObj = roles[index];
        final val = roleObj['value'] as UserRole?;
        final label = roleObj['label'] as String;
        
        final bool isSelected = val == null 
            ? _tempSelectedRoles.isEmpty 
            : _tempSelectedRoles.contains(val);

        return CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? (isDark ? const Color(0xFF00C6E6) : const Color(0xFF0097B2))
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          value: isSelected,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: isDark ? const Color(0xFF00C6E6) : const Color(0xFF0097B2),
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onChanged: (bool? checked) {
            setState(() {
              if (val == null) {
                _tempSelectedRoles.clear();
              } else {
                if (checked == true) {
                  _tempSelectedRoles.add(val);
                } else {
                  _tempSelectedRoles.remove(val);
                }
              }
            });
          },
        );
      },
    );
  }

  Widget _buildStatusOptionsList(bool isDark) {
    final statuses = [
      {'label': 'All Statuses', 'value': null},
      {'label': 'Approved', 'value': true},
      {'label': 'Pending', 'value': false},
    ];

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final statusObj = statuses[index];
        final val = statusObj['value'] as bool?;
        final label = statusObj['label'] as String;
        
        final bool isSelected = val == null 
            ? _tempSelectedStatuses.isEmpty 
            : _tempSelectedStatuses.contains(val);

        return CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? (isDark ? const Color(0xFF00C6E6) : const Color(0xFF0097B2))
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          value: isSelected,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: isDark ? const Color(0xFF00C6E6) : const Color(0xFF0097B2),
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onChanged: (bool? checked) {
            setState(() {
              if (val == null) {
                _tempSelectedStatuses.clear();
              } else {
                if (checked == true) {
                  _tempSelectedStatuses.add(val);
                } else {
                  _tempSelectedStatuses.remove(val);
                }
              }
            });
          },
        );
      },
    );
  }
}
