import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collegebus/features/audit/domain/audit_log_model.dart';
import 'package:collegebus/features/super_admin/application/super_admin_provider.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/widgets/analytics/analytics_charts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

// Helper for consistency in colors based on string (matching React)
Color stringToColor(String str) {
  if (str.isEmpty) return Colors.grey;
  int hash = 0;
  for (int i = 0; i < str.length; i++) {
    hash = str.codeUnitAt(i) + ((hash << 5) - hash);
  }
  final int r = (hash & 0xFF0000) >> 16;
  final int g = (hash & 0x00FF00) >> 8;
  final int b = hash & 0x0000FF;
  
  // Enforce a minimum brightness
  return Color.fromARGB(255, (r % 160) + 40, (g % 160) + 40, (b % 160) + 40);
}

String getInitials(String email) {
  if (email.isEmpty) return "?";
  final prefix = email.split("@")[0];
  if (prefix.isEmpty) return "?";
  if (prefix.length <= 2) {
    return prefix.toUpperCase();
  }
  return prefix.substring(0, 2).toUpperCase();
}

IconData getResourceIcon(String resource) {
  switch (resource.toLowerCase()) {
    case 'user':
      return Icons.group_outlined;
    case 'bus':
      return Icons.directions_bus_outlined;
    case 'college':
      return Icons.school_outlined;
    case 'route':
      return Icons.map_outlined;
    case 'schedule':
      return Icons.calendar_month_outlined;
    case 'sos':
      return Icons.warning_amber_rounded;
    case 'config':
      return Icons.settings_outlined;
    default:
      return Icons.info_outline_rounded;
  }
}

class AuditTab extends ConsumerStatefulWidget {
  const AuditTab({super.key});

  @override
  ConsumerState<AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends ConsumerState<AuditTab> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _socketSub;

  // Filters State
  final Set<String> _selectedColleges = {};
  final Set<String> _selectedActions = {};
  final Set<String> _selectedResources = {};
  DateTime? _selectedDate;

  bool _isInitialLoading = false;

  final actionOptions = const [
    {'label': 'Create Bus', 'value': 'BUS_CREATE'},
    {'label': 'Update Bus', 'value': 'BUS_UPDATE'},
    {'label': 'Delete Bus', 'value': 'BUS_DELETE'},
    {'label': 'Create Route', 'value': 'ROUTE_CREATE'},
    {'label': 'Update Route', 'value': 'ROUTE_UPDATE'},
    {'label': 'Delete Route', 'value': 'ROUTE_DELETE'},
    {'label': 'Create Schedule', 'value': 'SCHEDULE_CREATE'},
    {'label': 'Update Schedule', 'value': 'SCHEDULE_UPDATE'},
    {'label': 'Delete Schedule', 'value': 'SCHEDULE_DELETE'},
    {'label': 'Create User', 'value': 'USER_CREATE'},
    {'label': 'Update User', 'value': 'USER_UPDATE'},
    {'label': 'Delete User', 'value': 'USER_DELETE'},
    {'label': 'Activate Premium', 'value': 'USER_PREMIUM_ACTIVATE'},
    {'label': 'Bulk Premium', 'value': 'USER_PREMIUM_BULK'},
    {'label': 'System Config', 'value': 'SYSTEM_CONFIG_UPDATE'},
    {'label': 'Login', 'value': 'LOGIN'},
    {'label': 'Logout', 'value': 'LOGOUT'},
  ];

  final resourceOptions = const [
    'User',
    'College',
    'Bus',
    'Route',
    'Schedule',
    'SOS',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Setup real-time live log listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socketSub = ref.read(socketServiceProvider).newAuditLogStream.listen((data) {
        if (mounted && !hasActiveFilters) {
          final newLog = AuditLogModel.fromMap(data, data['_id'] ?? '');
          ref.read(superAdminServiceProvider.notifier).addLiveLog(newLog);
        }
      });
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(superAdminServiceProvider).valueOrNull;
      if (state != null && state.auditLogsHasMore) {
        _fetchLogs(isLoadMore: true);
      }
    }
  }

  bool get hasActiveFilters =>
      _selectedColleges.isNotEmpty ||
      _selectedActions.isNotEmpty ||
      _selectedResources.isNotEmpty ||
      _selectedDate != null;

  int get activeFiltersCount {
    int count = 0;
    count += _selectedColleges.length;
    count += _selectedActions.length;
    count += _selectedResources.length;
    if (_selectedDate != null) count += 1;
    return count;
  }

  void _fetchLogs({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() => _isInitialLoading = true);
    }
    final collegesList = _selectedColleges.toList();
    final actionsList = _selectedActions.toList();
    final resourcesList = _selectedResources.toList();

    await ref.read(superAdminServiceProvider.notifier).fetchAuditLogs(
          collegeId: collegesList.isNotEmpty ? collegesList.first : null,
          actions: actionsList,
          resources: resourcesList,
          date: _selectedDate,
          isLoadMore: isLoadMore,
        );
    
    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
  }

  void _clearFilters() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedColleges.clear();
      _selectedActions.clear();
      _selectedResources.clear();
      _selectedDate = null;
    });
    _fetchLogs(isLoadMore: false);
  }

  void _openFiltersSheet(List<CollegeModel> colleges) async {
    HapticFeedback.selectionClick();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AuditFilterBottomSheet(
        initialColleges: _selectedColleges,
        initialActions: _selectedActions,
        initialResources: _selectedResources,
        colleges: colleges,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedColleges.clear();
        _selectedColleges.addAll(result['colleges'] as Set<String>);
        _selectedActions.clear();
        _selectedActions.addAll(result['actions'] as Set<String>);
        _selectedResources.clear();
        _selectedResources.addAll(result['resources'] as Set<String>);
      });
      _fetchLogs(isLoadMore: false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    HapticFeedback.selectionClick();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: Colors.deepPurple.shade300,
                    onPrimary: Colors.white,
                    surface: const Color(0xFF1E293B),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Colors.deepPurple,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
                ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchLogs(isLoadMore: false);
    }
  }

  List<FlSpot> _getChartSpots(List<AuditLogModel> logs) {
    if (logs.isEmpty) return [];

    // Group logs by hour
    final Map<int, int> groups = {};
    for (final log in logs) {
      final date = log.createdAt.toLocal();
      final key = DateTime(date.year, date.month, date.day, date.hour).millisecondsSinceEpoch;
      groups[key] = (groups[key] ?? 0) + 1;
    }

    // Sort keys
    final sortedKeys = groups.keys.toList()..sort();
    if (sortedKeys.isEmpty) return [];

    // Generate spots. The x-axis is index-based, y-axis is log count.
    return List.generate(sortedKeys.length, (index) {
      final key = sortedKeys[index];
      final count = groups[key] ?? 0;
      return FlSpot(index.toDouble(), count.toDouble());
    });
  }

  Widget _buildActivityChart(List<AuditLogModel> logs, bool isDark) {
    final spots = _getChartSpots(logs);
    if (spots.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVITY DENSITY (RECENT LOGS)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                Icons.trending_up_rounded,
                size: 16,
                color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppLineChart(
            spots: spots,
            title: '',
            height: 110,
            lineColor: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  void _openLogDetails(AuditLogModel log) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogMetadataDetailsSheet(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(superAdminServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (state) {
        final auditLogs = state.auditLogs;
        final colleges = state.colleges;

        return Column(
          children: [
            // Custom Filter & Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'System Logs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  if (hasActiveFilters)
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: Icon(Icons.refresh_rounded, size: 16, color: Colors.red.shade600),
                      label: Text(
                        'Reset',
                        style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Date Filter Button
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedDate != null
                            ? (isDark ? Colors.deepPurple.shade300 : Colors.deepPurple)
                            : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedDate != null
                              ? Colors.transparent
                              : (isDark ? Colors.white10 : Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 16,
                            color: _selectedDate != null
                                ? Colors.white
                                : (isDark ? Colors.white60 : const Color(0xFF475569)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedDate != null
                                ? DateFormat('MM/dd').format(_selectedDate!)
                                : 'Date',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: _selectedDate != null
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filter Sheet Trigger
                  GestureDetector(
                    onTap: () => _openFiltersSheet(colleges),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: activeFiltersCount > 0
                                ? (isDark
                                    ? Colors.deepPurple.withValues(alpha: 0.15)
                                    : Colors.deepPurple.withValues(alpha: 0.08))
                                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: activeFiltersCount > 0
                                  ? (isDark ? Colors.deepPurple.shade300 : Colors.deepPurple.withValues(alpha: 0.4))
                                  : (isDark ? Colors.white10 : Colors.grey.shade200),
                            ),
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            size: 18,
                            color: activeFiltersCount > 0
                                ? (isDark ? Colors.deepPurple.shade300 : Colors.deepPurple)
                                : (isDark ? Colors.white60 : const Color(0xFF475569)),
                          ),
                        ),
                        if (activeFiltersCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$activeFiltersCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Active Filter Chips (if any)
            if (hasActiveFilters)
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (_selectedDate != null)
                      _buildFilterChip(
                        'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                        () => setState(() {
                          _selectedDate = null;
                          _fetchLogs(isLoadMore: false);
                        }),
                        isDark,
                      ),
                    ..._selectedColleges.map((cId) {
                      final matched = colleges.where((c) => c.id == cId);
                      final collegeName = matched.isNotEmpty ? matched.first.name : cId;
                      return _buildFilterChip(
                        'College: $collegeName',
                        () => setState(() {
                          _selectedColleges.remove(cId);
                          _fetchLogs(isLoadMore: false);
                        }),
                        isDark,
                      );
                    }),
                    ..._selectedActions.map((act) => _buildFilterChip(
                          'Action: $act',
                          () => setState(() {
                            _selectedActions.remove(act);
                            _fetchLogs(isLoadMore: false);
                          }),
                          isDark,
                        )),
                    ..._selectedResources.map((res) => _buildFilterChip(
                          'Resource: $res',
                          () => setState(() {
                            _selectedResources.remove(res);
                            _fetchLogs(isLoadMore: false);
                          }),
                          isDark,
                        )),
                  ],
                ),
              ),

            // Logs Listing & Loading State
            Expanded(
              child: _isInitialLoading
                  ? const _AuditLogShimmerList()
                  : auditLogs.isEmpty
                      ? _buildEmptyState(isDark)
                      : RefreshIndicator(
                          onRefresh: () async {
                            _fetchLogs(isLoadMore: false);
                          },
                          color: Colors.deepPurple,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            itemCount: auditLogs.length + (state.auditLogsHasMore ? 1 : 0) + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildActivityChart(auditLogs, isDark);
                              }
                              final logIndex = index - 1;
                              if (logIndex == auditLogs.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                    ),
                                  ),
                                );
                              }

                              final log = auditLogs[logIndex];
                              return _buildAuditLogCard(log, isDark);
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF1E293B),
          ),
        ),
        deleteIcon: Icon(
          Icons.close_rounded,
          size: 13,
          color: isDark ? Colors.white.withValues(alpha: 0.54) : const Color(0xFF475569),
        ),
        onDeleted: onDelete,
        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildAuditLogCard(AuditLogModel log, bool isDark) {
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(log.createdAt.toLocal());
    final bool isDelete = log.action.contains('DELETE') || log.action.contains('suspend');
    final bool isCreate = log.action.contains('CREATE') || log.action.contains('verify') || log.action.contains('approve');
    final String resLower = log.resource.toLowerCase();
    final bool isNavigable = resLower == 'college' || resLower == 'bus' || resLower == 'driver' || resLower == 'schedule';
    final String iconHeroTag = '$resLower-icon-${log.resourceId}';
    final String nameHeroTag = '$resLower-name-${log.resourceId}';

    final Color actionBgColor = isDelete
        ? Colors.red.shade50.withValues(alpha: isDark ? 0.08 : 0.8)
        : isCreate
            ? const Color(0xFFECFDF5).withValues(alpha: isDark ? 0.08 : 0.8)
            : Colors.indigo.shade50.withValues(alpha: isDark ? 0.08 : 0.8);

    final Color actionTextColor = isDelete
        ? (isDark ? Colors.red.shade300 : Colors.red.shade700)
        : isCreate
            ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
            : (isDark ? Colors.indigo.shade300 : Colors.indigo.shade700);

    final Color actionBorderColor = isDelete
        ? Colors.red.withValues(alpha: 0.2)
        : isCreate
            ? const Color(0xFF10B981).withValues(alpha: 0.2)
            : Colors.indigo.withValues(alpha: 0.2);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 4,
                color: isDelete
                    ? Colors.red.shade500
                    : isCreate
                        ? const Color(0xFF10B981)
                        : Colors.indigo.shade500,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Action pill, details button & timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: actionBgColor,
                      border: Border.all(color: actionBorderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.action.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: actionTextColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openLogDetails(log),
                    icon: Icon(
                      Icons.code_rounded,
                      size: 20,
                      color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Actor Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: stringToColor(log.userEmail),
                    child: Text(
                      getInitials(log.userEmail),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.userName.isNotEmpty ? log.userName : 'System Admin',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                        Text(
                          log.userEmail,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.5),

              // Target resource & timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isNavigable
                          ? () {
                              HapticFeedback.selectionClick();
                              if (resLower == 'college') {
                                context.push('/super-admin/colleges/${log.resourceId}');
                              } else if (resLower == 'bus') {
                                final busNumber = log.resourceName ?? log.resourceId;
                                context.push('/super-admin/buses/$busNumber');
                              } else if (resLower == 'driver') {
                                context.push('/super-admin/drivers/${log.resourceId}');
                              } else if (resLower == 'schedule') {
                                context.push('/super-admin/schedules');
                              }
                            }
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          isNavigable
                              ? Hero(
                                  tag: iconHeroTag,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Icon(
                                      getResourceIcon(log.resource),
                                      size: 14,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Icon(
                                    getResourceIcon(log.resource),
                                    size: 14,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                isNavigable
                                    ? Hero(
                                        tag: nameHeroTag,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: Text(
                                            log.resourceName ?? log.resource,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? Colors.deepPurple.shade300
                                                  : Colors.deepPurple.shade700,
                                              decoration: TextDecoration.underline,
                                              decorationStyle: TextDecorationStyle.dashed,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        log.resourceName ?? log.resource,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                Text(
                                  log.resourceId,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontFamily: 'monospace',
                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: isDark ? Colors.white10 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No audit logs found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting filters or checking connection',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

// Split Pane Categories Bottom Sheet (Unified styling with UsersTab)
class _AuditFilterBottomSheet extends StatefulWidget {
  final Set<String> initialColleges;
  final Set<String> initialActions;
  final Set<String> initialResources;
  final List<CollegeModel> colleges;

  const _AuditFilterBottomSheet({
    required this.initialColleges,
    required this.initialActions,
    required this.initialResources,
    required this.colleges,
  });

  @override
  State<_AuditFilterBottomSheet> createState() => _AuditFilterBottomSheetState();
}

class _AuditFilterBottomSheetState extends State<_AuditFilterBottomSheet> {
  int _activeTab = 0; // 0 = College, 1 = Action, 2 = Resource
  final Set<String> _tempSelectedColleges = {};
  final Set<String> _tempSelectedActions = {};
  final Set<String> _tempSelectedResources = {};

  String _collegeSearchQuery = '';

  final actionOptions = const [
    {'label': 'Create Bus', 'value': 'BUS_CREATE'},
    {'label': 'Update Bus', 'value': 'BUS_UPDATE'},
    {'label': 'Delete Bus', 'value': 'BUS_DELETE'},
    {'label': 'Create Route', 'value': 'ROUTE_CREATE'},
    {'label': 'Update Route', 'value': 'ROUTE_UPDATE'},
    {'label': 'Delete Route', 'value': 'ROUTE_DELETE'},
    {'label': 'Create Schedule', 'value': 'SCHEDULE_CREATE'},
    {'label': 'Update Schedule', 'value': 'SCHEDULE_UPDATE'},
    {'label': 'Delete Schedule', 'value': 'SCHEDULE_DELETE'},
    {'label': 'Create User', 'value': 'USER_CREATE'},
    {'label': 'Update User', 'value': 'USER_UPDATE'},
    {'label': 'Delete User', 'value': 'USER_DELETE'},
    {'label': 'Activate Premium', 'value': 'USER_PREMIUM_ACTIVATE'},
    {'label': 'Bulk Premium', 'value': 'USER_PREMIUM_BULK'},
    {'label': 'System Config', 'value': 'SYSTEM_CONFIG_UPDATE'},
    {'label': 'Login', 'value': 'LOGIN'},
    {'label': 'Logout', 'value': 'LOGOUT'},
  ];

  final resourceOptions = const [
    'User',
    'College',
    'Bus',
    'Route',
    'Schedule',
    'SOS',
  ];

  @override
  void initState() {
    super.initState();
    _tempSelectedColleges.addAll(widget.initialColleges);
    _tempSelectedActions.addAll(widget.initialActions);
    _tempSelectedResources.addAll(widget.initialResources);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                      _tempSelectedColleges.clear();
                      _tempSelectedActions.clear();
                      _tempSelectedResources.clear();
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
                // Left Tabs Nav bar (width 120)
                Container(
                  width: 120,
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeftTabTile(
                        index: 0,
                        title: 'College',
                        isActive: _activeTab == 0,
                        isDark: isDark,
                        badgeCount: _tempSelectedColleges.length,
                      ),
                      _buildLeftTabTile(
                        index: 1,
                        title: 'Action',
                        isActive: _activeTab == 1,
                        isDark: isDark,
                        badgeCount: _tempSelectedActions.length,
                      ),
                      _buildLeftTabTile(
                        index: 2,
                        title: 'Resource',
                        isActive: _activeTab == 2,
                        isDark: isDark,
                        badgeCount: _tempSelectedResources.length,
                      ),
                    ],
                  ),
                ),
                // Divider
                VerticalDivider(
                  width: 1,
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
                ),
                // Right Option lists
                Expanded(
                  child: _activeTab == 0
                      ? _buildCollegeOptionsList(isDark)
                      : _activeTab == 1
                          ? _buildActionOptionsList(isDark)
                          : _buildResourceOptionsList(isDark),
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
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade400],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context, {
                          'colleges': _tempSelectedColleges,
                          'actions': _tempSelectedActions,
                          'resources': _tempSelectedResources,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeTab = index);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF161F28) : Colors.white)
              : Colors.transparent,
          border: isActive
              ? Border(
                  left: BorderSide(
                    color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
                    width: 3.5,
                  ),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                  color: isActive
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.white60 : const Color(0xFF475569)),
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
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
              fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.deepPurple.withValues(alpha: 0.4)),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _collegeSearchQuery = val;
              });
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: filteredColleges.length,
            itemBuilder: (context, index) {
              final college = filteredColleges[index];
              final isSelected = _tempSelectedColleges.contains(college.id);

              return CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onChanged: (bool? checked) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (checked == true) {
                      _tempSelectedColleges.clear(); // Only single college can be selected at a time on backend
                      _tempSelectedColleges.add(college.id);
                    } else {
                      _tempSelectedColleges.remove(college.id);
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

  Widget _buildActionOptionsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: actionOptions.length,
      itemBuilder: (context, index) {
        final option = actionOptions[index];
        final val = option['value']!;
        final label = option['label']!;
        final isSelected = _tempSelectedActions.contains(val);

        return CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onChanged: (bool? checked) {
            HapticFeedback.selectionClick();
            setState(() {
              if (checked == true) {
                _tempSelectedActions.add(val);
              } else {
                _tempSelectedActions.remove(val);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildResourceOptionsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: resourceOptions.length,
      itemBuilder: (context, index) {
        final res = resourceOptions[index];
        final isSelected = _tempSelectedResources.contains(res);

        return CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            res,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onChanged: (bool? checked) {
            HapticFeedback.selectionClick();
            setState(() {
              if (checked == true) {
                _tempSelectedResources.add(res);
              } else {
                _tempSelectedResources.remove(res);
              }
            });
          },
        );
      },
    );
  }
}

// Log Metadata Diff details Bottom Sheet (Monospace style, matching React modal)
class _LogMetadataDetailsSheet extends StatelessWidget {
  final AuditLogModel log;

  const _LogMetadataDetailsSheet({required this.log});

  Widget _buildFieldRow(String label, String val, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white.withValues(alpha: 0.38) : const Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJSONDiffBlock(String title, Map<String, dynamic>? prev, Map<String, dynamic>? next, bool isDark) {
    if ((prev == null || prev.isEmpty) && (next == null || next.isEmpty)) return const SizedBox.shrink();

    final List<TextSpan> spans = [];
    final Color addedColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
    final Color deletedColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
    final Color normalColor = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF475569);

    // Gather all unique keys from both maps
    final allKeys = <String>{};
    if (prev != null) allKeys.addAll(prev.keys);
    if (next != null) allKeys.addAll(next.keys);

    final sortedKeys = allKeys.toList()..sort();

    for (final key in sortedKeys) {
      final hasPrev = prev != null && prev.containsKey(key);
      final hasNext = next != null && next.containsKey(key);

      if (hasPrev && hasNext) {
        final prevVal = prev[key];
        final nextVal = next[key];

        if (prevVal.toString() != nextVal.toString()) {
          // Modification
          spans.add(TextSpan(
            text: '- "$key": ${const JsonEncoder().convert(prevVal)},\n',
            style: TextStyle(
              color: deletedColor,
              fontFamily: 'monospace',
              fontSize: 11,
              decoration: TextDecoration.lineThrough,
            ),
          ));
          spans.add(TextSpan(
            text: '+ "$key": ${const JsonEncoder().convert(nextVal)},\n',
            style: TextStyle(
              color: addedColor,
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ));
        } else {
          // Unchanged
          spans.add(TextSpan(
            text: '  "$key": ${const JsonEncoder().convert(prevVal)},\n',
            style: TextStyle(
              color: normalColor,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ));
        }
      } else if (hasPrev) {
        // Deleted
        final prevVal = prev[key];
        spans.add(TextSpan(
          text: '- "$key": ${const JsonEncoder().convert(prevVal)},\n',
          style: TextStyle(
            color: deletedColor,
            fontFamily: 'monospace',
            fontSize: 11,
            decoration: TextDecoration.lineThrough,
          ),
        ));
      } else if (hasNext) {
        // Added
        final nextVal = next[key];
        spans.add(TextSpan(
          text: '+ "$key": ${const JsonEncoder().convert(nextVal)},\n',
          style: TextStyle(
            color: addedColor,
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ));
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Icon(Icons.difference_outlined, size: 14, color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(text: '{\n', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey)),
                    ...spans,
                    const TextSpan(text: '}', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
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
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Log Metadata Details',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Info block
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      _buildFieldRow('ID', log.id, isDark),
                      _buildFieldRow('Action', log.action, isDark),
                      _buildFieldRow('Resource', log.resource, isDark),
                      _buildFieldRow('Resource ID', log.resourceId, isDark),
                      _buildFieldRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss').format(log.createdAt.toLocal()), isDark),
                      _buildFieldRow('IP Address', log.ipAddress ?? 'N/A', isDark),
                      _buildFieldRow('User Agent', log.userAgent ?? 'N/A', isDark),
                    ],
                  ),
                ),
                
                // State diff blocks (highlighting updates, additions, and deletions)
                _buildJSONDiffBlock('STATE CHANGES (PREVIOUS vs NEW)', log.previousState, log.newState, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Shimmer Loader for logs list
class _AuditLogShimmerList extends StatefulWidget {
  const _AuditLogShimmerList();

  @override
  State<_AuditLogShimmerList> createState() => _AuditLogShimmerListState();
}

class _AuditLogShimmerListState extends State<_AuditLogShimmerList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.85).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 80.0 + (index % 2) * 20.0,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 110.0 + (index % 3) * 15.0,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 130,
                          height: 9,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 60,
                              height: 9,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 90,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
