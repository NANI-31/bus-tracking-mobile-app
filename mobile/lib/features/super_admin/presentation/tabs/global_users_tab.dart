import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/super_admin/application/super_admin_provider.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/core/constants/constants.dart';

class GlobalUsersTab extends ConsumerStatefulWidget {
  const GlobalUsersTab({super.key});

  @override
  ConsumerState<GlobalUsersTab> createState() => _GlobalUsersTabState();
}

class _GlobalUsersTabState extends ConsumerState<GlobalUsersTab> {
  String _searchQuery = '';
  final Set<UserRole> _selectedRoles = {};
  final Set<String> _selectedColleges = {};
  late final ScrollController _scrollController;
  bool _showTabletSidebar = true;
  String _tabletCollegeSearchQuery = '';
  bool _isTabletCollegesLoading = false;

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
        ref
            .read(superAdminServiceProvider.notifier)
            .fetchGlobalUsers(
              search: _searchQuery,
              role: _selectedRoles.isNotEmpty
                  ? _selectedRoles.map((r) => r.value).join(',')
                  : null,
              collegeId: _selectedColleges.isNotEmpty
                  ? _selectedColleges.join(',')
                  : null,
              isLoadMore: true,
            );
      }
    }
  }

  void _onFilterChanged() {
    ref
        .read(superAdminServiceProvider.notifier)
        .fetchGlobalUsers(
          search: _searchQuery,
          role: _selectedRoles.isNotEmpty
              ? _selectedRoles.map((r) => r.value).join(',')
              : null,
          collegeId: _selectedColleges.isNotEmpty
              ? _selectedColleges.join(',')
              : null,
          isLoadMore: false,
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
      case UserRole.student:
        return 'Student';
      default:
        return 'User';
    }
  }

  String _getCollegeName(String collegeId, WidgetRef ref) {
    final colleges =
        ref.read(superAdminServiceProvider).valueOrNull?.colleges ?? [];
    final matches = colleges.where((c) => c.id == collegeId);
    if (matches.isNotEmpty) {
      return matches.first.name;
    }
    return 'College';
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(superAdminServiceProvider);
    final globalUsers = asyncState.valueOrNull?.globalUsers ?? [];
    final hasMore = asyncState.valueOrNull?.globalUsersHasMore ?? false;
    final isLoading = asyncState.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasActiveFilters =
        _selectedRoles.isNotEmpty || _selectedColleges.isNotEmpty;

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    final mainContent = Column(
      children: [
        // Premium Search & Filters Panel
        Container(
          margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
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
              // Search input row with filter icon
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search global users by name or email...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: isDark
                              ? Colors.deepPurple.shade300
                              : Colors.deepPurple,
                        ),
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
                            color: isDark
                                ? Colors.white10
                                : Colors.grey.shade200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.deepPurple.withOpacity(0.5),
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                        _onFilterChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter Sheet Trigger Button
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      if (isTablet) {
                        setState(() => _showTabletSidebar = !_showTabletSidebar);
                      } else {
                        final collegesList =
                            ref
                                .read(superAdminServiceProvider)
                                .valueOrNull
                                ?.colleges ??
                            [];

                        final result =
                            await showModalBottomSheet<Map<String, dynamic>>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => _UserFilterBottomSheet(
                                initialSelectedRoles: _selectedRoles,
                                initialSelectedColleges: _selectedColleges,
                                colleges: collegesList,
                              ),
                            );

                        if (result != null) {
                          setState(() {
                            _selectedRoles.clear();
                            _selectedRoles.addAll(result['roles'] as Set<UserRole>);
                            _selectedColleges.clear();
                            _selectedColleges.addAll(result['colleges'] as Set<String>);
                          });
                          _onFilterChanged();
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: hasActiveFilters
                            ? (isDark
                                  ? Colors.deepPurple.withOpacity(0.15)
                                  : Colors.deepPurple.withOpacity(0.08))
                            : (isDark
                                  ? const Color(0xFF0F172A).withOpacity(0.6)
                                  : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasActiveFilters
                              ? (isDark
                                    ? Colors.deepPurple.shade300.withOpacity(
                                        0.4,
                                      )
                                    : Colors.deepPurple.withOpacity(0.2))
                              : (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade200),
                        ),
                      ),
                      child: Badge(
                        isLabelVisible: hasActiveFilters,
                        label: Text(
                          '${_selectedRoles.length + _selectedColleges.length}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        alignment: const Alignment(1.3, -1.3),
                        child: Icon(
                          isTablet 
                              ? (_showTabletSidebar ? Icons.filter_list_off_rounded : Icons.filter_list_rounded)
                              : Icons.filter_list_rounded,
                          size: 20,
                          color: hasActiveFilters
                              ? (isDark
                                    ? Colors.deepPurple.shade200
                                    : Colors.deepPurple)
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Active filters chips display
              if (hasActiveFilters) ...[
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
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
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
                                    _onFilterChanged();
                                  },
                                  isDark: isDark,
                                ),
                              )),
                              ..._selectedColleges.map((collegeId) => Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: _buildActiveFilterChip(
                                  label: _getCollegeName(collegeId, ref),
                                  onClear: () {
                                    setState(() => _selectedColleges.remove(collegeId));
                                    _onFilterChanged();
                                  },
                                  isDark: isDark,
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Global Users List
        Expanded(
          child: globalUsers.isEmpty && !isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 64,
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No users found',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Try adjusting your search query or filters',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: globalUsers.length + (hasMore ? 1 : 0),
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 80,
                  ),
                  itemBuilder: (context, index) {
                    if (index >= globalUsers.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final user = globalUsers[index];
                    return _UserCard(
                      user: user,
                      onPromote: () async {
                        final saNotifier = ref.read(
                          superAdminServiceProvider.notifier,
                        );
                        final newRole = user.role == UserRole.student
                            ? UserRole.collegeAdmin
                            : UserRole.student;
                        await saNotifier.updateUserRole(user.id, newRole);
                      },
                      onDelete: () async {
                        final saNotifier = ref.read(
                          superAdminServiceProvider.notifier,
                        );
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              'Delete User',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              'Are you sure you want to permanently delete ${user.fullName}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await saNotifier.deleteUser(user.id);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );

    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: mainContent),
          if (_showTabletSidebar) ...[
            VerticalDivider(
              width: 1,
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161F28) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: _buildTabletAccordionSidebar(isDark),
            ),
          ],
        ],
      );
    }

    return mainContent;
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onClear,
    required bool isDark,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey(label),
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
              onTap: () {
                HapticFeedback.selectionClick();
                onClear();
              },
              child: const Icon(Icons.close_rounded, size: 13, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletAccordionSidebar(bool isDark) {
    final collegesList = ref.read(superAdminServiceProvider).valueOrNull?.colleges ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (_selectedRoles.isNotEmpty || _selectedColleges.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedRoles.clear();
                      _selectedColleges.clear();
                    });
                    _onFilterChanged();
                  },
                  child: Text(
                    'Reset All',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Row(
                    children: [
                      const Text(
                        'Role',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_selectedRoles.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_selectedRoles.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  children: [
                    _buildRoleOptionsListTablet(isDark),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
              ),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Row(
                    children: [
                      const Text(
                        'College',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_selectedColleges.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_selectedColleges.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search college...',
                          hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade400),
                          prefixIcon: Icon(Icons.search, size: 16, color: isDark ? Colors.white38 : Colors.grey),
                          isDense: true,
                          filled: true,
                          fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.4)),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _tabletCollegeSearchQuery = val;
                            _isTabletCollegesLoading = true;
                          });
                          Future.delayed(const Duration(milliseconds: 250), () {
                            if (mounted) {
                              setState(() {
                                _isTabletCollegesLoading = false;
                              });
                            }
                          });
                        },
                      ),
                    ),
                    _buildCollegeOptionsListTablet(isDark, collegesList),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOptionsListTablet(bool isDark) {
    final roles = [
      {'label': 'All', 'value': null},
      {'label': 'Admins', 'value': UserRole.collegeAdmin},
      {'label': 'Coordinators', 'value': UserRole.busCoordinator},
      {'label': 'Drivers', 'value': UserRole.driver},
      {'label': 'Students', 'value': UserRole.student},
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: roles.map((roleObj) {
        final val = roleObj['value'] as UserRole?;
        final label = roleObj['label'] as String;
        final bool isSelected = val == null 
            ? _selectedRoles.isEmpty 
            : _selectedRoles.contains(val);

        return CheckboxListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? (isDark ? Colors.deepPurple.shade300 : Colors.deepPurple)
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          value: isSelected,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
          checkColor: Colors.white,
          onChanged: (bool? checked) {
            HapticFeedback.selectionClick();
            setState(() {
              if (val == null) {
                _selectedRoles.clear();
              } else {
                if (checked == true) {
                  _selectedRoles.add(val);
                } else {
                  _selectedRoles.remove(val);
                }
              }
            });
            _onFilterChanged();
          },
        );
      }).toList(),
    );
  }

  Widget _buildCollegeOptionsListTablet(bool isDark, List<CollegeModel> colleges) {
    final filteredColleges = colleges.where((c) {
      if (_tabletCollegeSearchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_tabletCollegeSearchQuery.toLowerCase());
    }).toList();

    if (_isTabletCollegesLoading) {
      return const _FilterOptionShimmer();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            'All',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: _selectedColleges.isEmpty ? FontWeight.bold : FontWeight.normal,
              color: _selectedColleges.isEmpty
                  ? (isDark ? Colors.deepPurple.shade300 : Colors.deepPurple)
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          value: _selectedColleges.isEmpty,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
          checkColor: Colors.white,
          onChanged: (bool? checked) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedColleges.clear();
            });
            _onFilterChanged();
          },
        ),
        ...filteredColleges.map((college) {
          final isSelected = _selectedColleges.contains(college.id);
          return CheckboxListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              college.name,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.deepPurple.shade300 : Colors.deepPurple)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            value: isSelected,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
            checkColor: Colors.white,
            onChanged: (bool? checked) {
              HapticFeedback.selectionClick();
              setState(() {
                if (checked == true) {
                  _selectedColleges.add(college.id);
                } else {
                  _selectedColleges.remove(college.id);
                }
              });
              _onFilterChanged();
            },
          );
        }).toList(),
      ],
    );
  }
}

class _UserFilterBottomSheet extends StatefulWidget {
  final Set<UserRole> initialSelectedRoles;
  final Set<String> initialSelectedColleges;
  final List<CollegeModel> colleges;

  const _UserFilterBottomSheet({
    required this.initialSelectedRoles,
    required this.initialSelectedColleges,
    required this.colleges,
  });

  @override
  State<_UserFilterBottomSheet> createState() => _UserFilterBottomSheetState();
}

class _UserFilterBottomSheetState extends State<_UserFilterBottomSheet> {
  int _activeTab = 0; // 0 = Role, 1 = College
  final Set<UserRole> _tempSelectedRoles = {};
  final Set<String> _tempSelectedColleges = {};
  String _collegeSearchQuery = '';
  bool _isCollegesLoading = false;

  @override
  void initState() {
    super.initState();
    _tempSelectedRoles.addAll(widget.initialSelectedRoles);
    _tempSelectedColleges.addAll(widget.initialSelectedColleges);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F28) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
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
          // Title & Reset All Action
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
                    HapticFeedback.selectionClick();
                    setState(() {
                      _tempSelectedRoles.clear();
                      _tempSelectedColleges.clear();
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
          // Split Pane Layout
          Expanded(
            child: Row(
              children: [
                // Left Tabs Nav bar
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
                        title: 'College',
                        isActive: _activeTab == 1,
                        isDark: isDark,
                        badgeCount: _tempSelectedColleges.length,
                      ),
                    ],
                  ),
                ),
                // Divider
                VerticalDivider(
                  width: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade200,
                ),
                // Right Option lists
                Expanded(
                  child: _activeTab == 0
                      ? _buildRoleOptionsList(isDark)
                      : _buildCollegeOptionsList(isDark),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          // Buttons Row
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
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context, {
                          'roles': _tempSelectedRoles,
                          'colleges': _tempSelectedColleges,
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
        ? Colors.deepPurple.shade300
        : Colors.deepPurple;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activeTab = index;
          if (index == 1) {
            _isCollegesLoading = true;
          }
        });
        if (index == 1) {
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) {
              setState(() {
                _isCollegesLoading = false;
              });
            }
          });
        }
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
      {'label': 'All', 'value': null},
      {'label': 'Admins', 'value': UserRole.collegeAdmin},
      {'label': 'Coordinators', 'value': UserRole.busCoordinator},
      {'label': 'Drivers', 'value': UserRole.driver},
      {'label': 'Students', 'value': UserRole.student},
    ];

    return ListView.builder(
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
                  ? (isDark ? Colors.deepPurple.shade300 : Colors.deepPurple)
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          value: isSelected,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onChanged: (bool? checked) {
            HapticFeedback.selectionClick();
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

  Widget _buildCollegeOptionsList(bool isDark) {
    final filteredColleges = widget.colleges.where((c) {
      if (_collegeSearchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_collegeSearchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search colleges...',
              hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, size: 16, color: isDark ? Colors.white38 : Colors.grey),
              isDense: true,
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.4)),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _collegeSearchQuery = val;
                _isCollegesLoading = true;
              });
              Future.delayed(const Duration(milliseconds: 250), () {
                if (mounted) {
                  setState(() {
                    _isCollegesLoading = false;
                  });
                }
              });
            },
          ),
        ),
        Expanded(
          child: _isCollegesLoading
              ? const _FilterOptionShimmer()
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: filteredColleges.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final String? collegeId = isAll ? null : filteredColleges[index - 1].id;
              final String collegeName = isAll ? 'All' : filteredColleges[index - 1].name;
              
              final isSelected = isAll 
                  ? _tempSelectedColleges.isEmpty 
                  : _tempSelectedColleges.contains(collegeId);

              return CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  collegeName,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? (isDark ? Colors.deepPurple.shade300 : Colors.deepPurple)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                value: isSelected,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onChanged: (bool? checked) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isAll) {
                      _tempSelectedColleges.clear();
                    } else {
                      if (checked == true) {
                        if (collegeId != null) _tempSelectedColleges.add(collegeId);
                      } else {
                        if (collegeId != null) _tempSelectedColleges.remove(collegeId);
                      }
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onPromote;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onPromote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Role styling derivation
    Color roleColor;
    String roleLabel;
    IconData roleIcon;
    switch (user.role) {
      case UserRole.superAdmin:
        roleColor = Colors.red.shade700;
        roleLabel = 'Super Admin';
        roleIcon = Icons.admin_panel_settings_rounded;
        break;
      case UserRole.collegeAdmin:
        roleColor = Colors.purple.shade600;
        roleLabel = 'College Admin';
        roleIcon = Icons.supervised_user_circle_rounded;
        break;
      case UserRole.busCoordinator:
        roleColor = Colors.blue.shade600;
        roleLabel = 'Coordinator';
        roleIcon = Icons.co_present_rounded;
        break;
      case UserRole.driver:
        roleColor = Colors.teal.shade600;
        roleLabel = 'Driver';
        roleIcon = Icons.directions_bus_rounded;
        break;
      case UserRole.student:
        roleColor = Colors.amber.shade700;
        roleLabel = 'Student';
        roleIcon = Icons.school_rounded;
        break;
      default:
        roleColor = Colors.grey;
        roleLabel = 'User';
        roleIcon = Icons.person_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left Stripe Indicator for Role
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5.5,
            child: Container(
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Avatar + User Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar bubble
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: roleColor.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user.fullName.isNotEmpty
                              ? user.fullName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: roleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            shadows: [
                              Shadow(
                                color: roleColor.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Names & Role badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          // Custom Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: roleColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(roleIcon, color: roleColor, size: 11),
                                const SizedBox(width: 4),
                                Text(
                                  roleLabel.toUpperCase(),
                                  style: TextStyle(
                                    color: roleColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action Trigger
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      onSelected: (action) {
                        HapticFeedback.selectionClick();
                        if (action == 'delete') {
                          onDelete();
                        } else if (action == 'promote') {
                          onPromote();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'promote',
                          child: Row(
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: 18,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.role == UserRole.student
                                    ? 'Make College Admin'
                                    : 'Demote to Student',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete User',
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade100,
                ),
                const SizedBox(height: 12),

                // Email Detail Row
                Row(
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      size: 15,
                      color: isDark
                          ? Colors.blue.shade300
                          : Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // College Association Detail Row
                Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 15,
                      color: isDark
                          ? Colors.orange.shade300
                          : Colors.orange.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user.collegeId.isNotEmpty
                            ? 'Associated College: ${user.collegeId}'
                            : 'No College Bound',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontStyle: user.collegeId.isNotEmpty
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOptionShimmer extends StatefulWidget {
  const _FilterOptionShimmer();

  @override
  State<_FilterOptionShimmer> createState() => _FilterOptionShimmerState();
}

class _FilterOptionShimmerState extends State<_FilterOptionShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.85).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 100.0 + (index % 3) * 20.0,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
