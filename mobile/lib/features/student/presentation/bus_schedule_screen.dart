import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/features/schedule/domain/schedule_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/college/application/college_provider.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'widgets/home/student_skeletons.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';

class BusScheduleScreen extends ConsumerStatefulWidget {
  final bool isTab;
  final Function(BusModel)? onBusSelected;
  const BusScheduleScreen({super.key, this.isTab = false, this.onBusSelected});

  @override
  ConsumerState<BusScheduleScreen> createState() => _BusScheduleScreenState();
}

class _BusScheduleScreenState extends ConsumerState<BusScheduleScreen> {
  String? _selectedBusNumber;
  String? _selectedRoute;
  String? _selectedStop;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedBusNumber = null;
      _selectedRoute = null;
      _selectedStop = null;
      _selectedStatus = 'all';
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedBusNumber != null) count++;
    if (_selectedRoute != null) count++;
    if (_selectedStop != null) count++;
    if (_selectedStatus != 'all') count++;
    return count;
  }

  bool get _hasActiveFilters =>
      _selectedBusNumber != null ||
      _selectedRoute != null ||
      _selectedStop != null ||
      _selectedStatus != 'all';


  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (collegeId == null) {
      return const Scaffold(body: BusScheduleSkeleton());
    }

    final busesAsync = ref.watch(collegeBusesStreamProvider(collegeId));
    final routesAsync = ref.watch(collegeRoutesProvider(collegeId));
    final schedulesAsync = ref.watch(collegeSchedulesProvider(collegeId));
    final collegesAsync = ref.watch(collegeServiceProvider);

    final college = collegesAsync.valueOrNull?.firstWhere(
      (c) => c.id == collegeId,
      orElse: () => CollegeModel(
        id: '',
        name: '',
        allowedDomains: [],
        createdBy: '',
        createdAt: DateTime.now(),
      ),
    );

    if (college == null || college.id.isEmpty) {
      return const Scaffold(body: BusScheduleSkeleton());
    }

    final hasMultipleShifts =
        college.shiftCount > 1 && college.shifts.isNotEmpty;
    final int tabLength = college.shifts.isNotEmpty ? college.shifts.length : 1;

    final tabs = hasMultipleShifts
        ? college.shifts
              .map(
                (s) => Tab(
                  child: Text(
                    s.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList()
        : <Widget>[];

    final shiftTabBar = hasMultipleShifts
        ? Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C6E6), Color(0xFF0097B2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C6E6).withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark
                  ? Colors.white.withValues(alpha: 0.45)
                  : Colors.black.withValues(alpha: 0.45),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: tabs,
            ),
          )
        : null;

    return DefaultTabController(
      key: ValueKey('shift_tabs_$tabLength'),
      length: tabLength,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: widget.isTab
            ? (hasMultipleShifts
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(62.0),
                      child: SafeArea(child: shiftTabBar!),
                    )
                  : null)
            : PreferredSize(
                preferredSize: Size.fromHeight(
                  kToolbarHeight + (hasMultipleShifts ? 62.0 : 0),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  elevation: 0,
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness:
                        isDark ? Brightness.light : Brightness.dark,
                    statusBarBrightness:
                        isDark ? Brightness.dark : Brightness.light,
                  ),
                  title: const Text(
                    'Bus Schedule',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  bottom: hasMultipleShifts
                      ? PreferredSize(
                          preferredSize: const Size.fromHeight(62.0),
                          child: shiftTabBar!,
                        )
                      : null,
                ),
              ),
        body: SafeArea(
          bottom: false,
          child: _buildMainScheduleUI(
            context,
            ref,
            user!,
            collegeId,
            college,
            busesAsync,
            routesAsync,
            schedulesAsync,
            hasMultipleShifts,
          ),
        ),
      ),
    );
  }

  Widget _buildMainScheduleUI(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    String collegeId,
    CollegeModel college,
    AsyncValue<List<BusModel>> busesAsync,
    AsyncValue<List<RouteModel>> routesAsync,
    AsyncValue<List<ScheduleModel>> schedulesAsync,
    bool hasMultipleShifts,
  ) {
    final buses = busesAsync.valueOrNull ?? [];
    final routes = routesAsync.valueOrNull ?? [];
    final allSchedules = schedulesAsync.valueOrNull ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allBusNumbersList = buses.map((b) => b.busNumber).toSet().toList()
      ..sort();
    final allRoutesList = routes.map((r) => r.routeName).toSet().toList()
      ..sort();
    final stopsSet = <String>{};
    for (final route in routes) {
      stopsSet.add(route.startPoint.name);
      stopsSet.add(route.endPoint.name);
      stopsSet.addAll(route.stopPoints.map((s) => s.name));
    }
    final allStopsList = stopsSet.toList()..sort();

    List<ScheduleModel> filterSchedules(
      List<ScheduleModel> schedules,
      String? shiftId,
    ) {
      return schedules.where((schedule) {
        if (shiftId != null && schedule.shift != shiftId) return false;
        final bus = buses.firstWhere(
          (b) => b.id == schedule.busId,
          orElse: () => BusModel(
            id: '',
            busNumber: '',
            driverId: '',
            collegeId: '',
            createdAt: DateTime.now(),
          ),
        );
        if (_selectedBusNumber != null) {
          if (bus.busNumber != _selectedBusNumber) return false;
        }
        final targetRouteId = (bus.assignmentStatus == 'accepted' && bus.routeId != null)
            ? bus.routeId!
            : schedule.routeId;
        if (_selectedRoute != null) {
          final route = routes.firstWhere(
            (r) => r.id == targetRouteId,
            orElse: () => RouteModel(
              id: '',
              routeName: '',
              routeType: '',
              startPoint: RoutePoint(name: '', lat: 0, lng: 0),
              endPoint: RoutePoint(name: '', lat: 0, lng: 0),
              stopPoints: [],
              collegeId: '',
              createdBy: '',
              isActive: false,
              createdAt: DateTime.now(),
            ),
          );
          if (route.routeName != _selectedRoute) return false;
        }
        if (_selectedStop != null) {
          final route = routes.firstWhere(
            (r) => r.id == targetRouteId,
            orElse: () => RouteModel(
              id: '',
              routeName: '',
              routeType: '',
              startPoint: RoutePoint(name: '', lat: 0, lng: 0),
              endPoint: RoutePoint(name: '', lat: 0, lng: 0),
              stopPoints: [],
              collegeId: '',
              createdBy: '',
              isActive: false,
              createdAt: DateTime.now(),
            ),
          );
          final hasStop = route.id != schedule.routeId
              ? (route.startPoint.name == _selectedStop ||
                  route.endPoint.name == _selectedStop ||
                  route.stopPoints.any((s) => s.name == _selectedStop))
              : schedule.stopSchedules.any((s) => s.stopName == _selectedStop);
          if (!hasStop) return false;
        }
        if (_selectedStatus != 'all') {
          if (bus.status != _selectedStatus) return false;
        }
        return true;
      }).toList();
    }

    return Column(
      children: [
        // ─── Top Horizontal Filter Bar ──────────────────────────────────────────
        _buildHorizontalFilterBar(
          context,
          isDark,
          allBusNumbersList,
          allRoutesList,
          allStopsList,
          filterSchedules,
          allSchedules,
          buses,
          routes,
        ),
        // ─── Schedule List ──────────────────────────────────────────────────────
        Expanded(
          child: schedulesAsync.when(
            loading: () => const BusScheduleSkeleton(),
            error: (err, stack) => const Center(
              child: Text(
                'Unable to load schedules',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            data: (_) {
              if (hasMultipleShifts) {
                return Material(
                  color: Colors.transparent,
                  child: TabBarView(
                    children: college.shifts.map((shift) {
                      final shiftSchedules = filterSchedules(
                        allSchedules,
                        shift.shiftId,
                      );
                      return _buildScheduleList(
                        shiftSchedules,
                        shift.name,
                        buses,
                        routes,
                        user,
                      );
                    }).toList(),
                  ),
                );
              } else {
                return _buildScheduleList(
                  filterSchedules(allSchedules, null),
                  'Current',
                  buses,
                  routes,
                  user,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalFilterBar(
    BuildContext context,
    bool isDark,
    List<String> buses,
    List<String> routes,
    List<String> stops,
    List<ScheduleModel> Function(List<ScheduleModel>, String?) filterSchedules,
    List<ScheduleModel> allSchedules,
    List<BusModel> allBuses,
    List<RouteModel> allRoutes,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0D1B2A).withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.45),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1.2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1 & 2 combined using IntrinsicHeight
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left 2x2 grid for Status Cards (Row 1 and Row 2)
                    Expanded(
                      child: Column(
                        children: [
                          // Row 1: Status Card 1, Status Card 2
                          Row(
                            children: [
                              Expanded(child: _buildGridStatusCard('all', 'All Status', Icons.grid_view_rounded, isDark)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildGridStatusCard('on-time', 'On Time', Icons.offline_pin_rounded, isDark)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Row 2: Status Card 3, Status Card 4
                          Row(
                            children: [
                              Expanded(child: _buildGridStatusCard('delayed', 'Delayed', Icons.watch_later_rounded, isDark)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildGridStatusCard('not-running', 'Offline', Icons.power_settings_new_rounded, isDark)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Right column: Filter Icon Card spanning Row 1 and Row 2
                    _buildGridFilterCard(context, isDark, buses, routes, stops, filterSchedules, allSchedules, allBuses, allRoutes),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Row 3: Active chips in Col 1 & 2, Reset Badge in Col 3
              Row(
                children: [
                  Expanded(
                    child: _buildGridActiveChips(isDark, buses, routes, stops, filterSchedules, allSchedules),
                  ),
                  const SizedBox(width: 8),
                  _buildRow1Col3Badge(isDark), // Vertically aligned under the filter card
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridStatusCard(String status, String label, IconData icon, bool isDark) {
    final isSelected = _selectedStatus == status;
    
    final Map<String, Color> statusColors = {
      'all': const Color(0xFF00C6E6),
      'on-time': const Color(0xFF10B981),
      'delayed': const Color(0xFFF59E0B),
      'not-running': const Color(0xFFEF4444),
    };
    
    final Map<String, List<Color>> statusGradients = {
      'all': [const Color(0xFF00C6E6), const Color(0xFF0097B2)],
      'on-time': [const Color(0xFF10B981), const Color(0xFF059669)],
      'delayed': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      'not-running': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
    };

    final color = statusColors[status]!;
    final gradient = statusGradients[status]!;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedStatus = status);
      },
      child: AnimatedScale(
        scale: isSelected ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark
                    ? color.withValues(alpha: 0.05)
                    : color.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.35)
                  : (isDark
                      ? color.withValues(alpha: 0.22)
                      : color.withValues(alpha: 0.16)),
              width: 1.2,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              else
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Row(
            children: [
              // Premium vertical status line on the left side of the card
              Container(
                width: 3.5,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 13,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B)),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow1Col3Badge(bool isDark) {
    final count = _activeFilterCount;
    final hasFilters = count > 0;

    return AnimatedScale(
      scale: hasFilters ? 1.0 : 0.85,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: hasFilters ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: hasFilters
              ? () {
                  HapticFeedback.mediumImpact();
                  _clearFilters();
                }
              : null,
          child: Container(
            width: 48,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                if (hasFilters)
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.rotate_left_rounded,
              size: 18,
              color: Color(0xFFEF4444),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridFilterCard(
    BuildContext context,
    bool isDark,
    List<String> buses,
    List<String> routes,
    List<String> stops,
    List<ScheduleModel> Function(List<ScheduleModel>, String?) filterSchedules,
    List<ScheduleModel> allSchedules,
    List<BusModel> allBuses,
    List<RouteModel> allRoutes,
  ) {
    final count = _activeFilterCount;
    final primary = const Color(0xFF00C6E6);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showFilterBottomSheet(
          context, buses, routes, stops, filterSchedules, allSchedules, allBuses, allRoutes,
        );
      },
      child: AnimatedScale(
        scale: count > 0 ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          width: 48,
          decoration: BoxDecoration(
            gradient: count > 0
                ? const LinearGradient(
                    colors: [Color(0xFF00C6E6), Color(0xFF7B61FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: count > 0
                ? null
                : (isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.65)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: count > 0
                  ? Colors.white.withValues(alpha: 0.3)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08)),
              width: 1.2,
            ),
            boxShadow: [
              if (count > 0)
                BoxShadow(
                  color: const Color(0xFF00C6E6).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                )
              else
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: count > 0
                      ? Colors.white.withValues(alpha: 0.22)
                      : primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: count > 0 ? Colors.white : primary,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7B61FF),
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

  Widget _buildGridActiveChips(
    bool isDark,
    List<String> buses,
    List<String> routes,
    List<String> stops,
    List<ScheduleModel> Function(List<ScheduleModel>, String?) filterSchedules,
    List<ScheduleModel> allSchedules,
  ) {
    final count = _activeFilterCount;
    if (count == 0) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: isDark ? Colors.white30 : Colors.black38,
            ),
            const SizedBox(width: 6),
            Text(
              'Select status or tap filter icon to customize list',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          if (_selectedBusNumber != null) ...[
            _buildGridActiveChip(
              label: 'Bus: $_selectedBusNumber',
              color: const Color(0xFF00C6E6),
              isDark: isDark,
              onClear: () => setState(() => _selectedBusNumber = null),
            ),
            const SizedBox(width: 6),
          ],
          if (_selectedRoute != null) ...[
            _buildGridActiveChip(
              label: 'Route: $_selectedRoute',
              color: const Color(0xFF7B61FF),
              isDark: isDark,
              onClear: () => setState(() => _selectedRoute = null),
            ),
            const SizedBox(width: 6),
          ],
          if (_selectedStop != null) ...[
            _buildGridActiveChip(
              label: 'Stop: $_selectedStop',
              color: const Color(0xFFF97316),
              isDark: isDark,
              onClear: () => setState(() => _selectedStop = null),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildGridActiveChip({
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onClear,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.08 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF1E293B),
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onClear();
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 11,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    List<String> buses,
    List<String> routes,
    List<String> stops,
    List<ScheduleModel> Function(List<ScheduleModel>, String?) filterSchedules,
    List<ScheduleModel> allSchedules,
    List<BusModel> allBuses,
    List<RouteModel> allRoutes, {
    String initialCategory = 'bus',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) {
        String activeCategory = initialCategory;
        String? tempBusNumber = _selectedBusNumber;
        String? tempRoute = _selectedRoute;
        String? tempStop = _selectedStop;
        String tempStatus = _selectedStatus;
        final searchController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            final viewInsets = MediaQuery.of(context).viewInsets;
            final isKeyboardOpen = viewInsets.bottom > 0;
            final availableHeight = MediaQuery.of(context).size.height - viewInsets.bottom;
            final sheetHeight = isKeyboardOpen
                ? availableHeight * 0.88
                : MediaQuery.of(context).size.height * 0.68;

            return Padding(
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: Container(
                height: sheetHeight,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0D1B2A)
                      : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    const SizedBox(height: 10),
                    Container(
                      width: 38,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Header: "Filters", "Clear All", Close Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
                      child: Row(
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempBusNumber = null;
                                tempRoute = null;
                                tempStop = null;
                                tempStatus = 'all';
                              });
                            },
                            child: const Text(
                              'Clear All',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                    // Main Content: Left category tabs, Right options pane
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Category Navigation Pane
                          Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.02),
                              border: Border(
                                right: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                            child: ListView(
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _buildCategoryTab(
                                  label: 'Bus Number',
                                  subtitle: tempBusNumber,
                                  isActive: activeCategory == 'bus',
                                  onTap: () => setModalState(() {
                                    activeCategory = 'bus';
                                    searchController.clear();
                                    FocusScope.of(context).unfocus();
                                  }),
                                  isDark: isDark,
                                ),
                                _buildCategoryTab(
                                  label: 'Route Name',
                                  subtitle: tempRoute,
                                  isActive: activeCategory == 'route',
                                  onTap: () => setModalState(() {
                                    activeCategory = 'route';
                                    searchController.clear();
                                    FocusScope.of(context).unfocus();
                                  }),
                                  isDark: isDark,
                                ),
                                _buildCategoryTab(
                                  label: 'Stop Point',
                                  subtitle: tempStop,
                                  isActive: activeCategory == 'stop',
                                  onTap: () => setModalState(() {
                                    activeCategory = 'stop';
                                    searchController.clear();
                                    FocusScope.of(context).unfocus();
                                  }),
                                  isDark: isDark,
                                ),
                                _buildCategoryTab(
                                  label: 'Bus Status',
                                  subtitle: tempStatus == 'all'
                                      ? null
                                      : (tempStatus == 'on-time'
                                          ? 'On Time'
                                          : tempStatus == 'delayed'
                                              ? 'Delayed'
                                              : 'Offline'),
                                  isActive: activeCategory == 'status',
                                  onTap: () => setModalState(() {
                                    activeCategory = 'status';
                                    searchController.clear();
                                    FocusScope.of(context).unfocus();
                                  }),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                          // Right Options Pane
                          Expanded(
                            child: Column(
                              children: [
                                // Show search bar if category is Bus, Route, or Stop
                                if (activeCategory != 'status') ...[
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : Colors.black.withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.black.withValues(alpha: 0.08),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: searchController,
                                        onChanged: (val) => setModalState(() {}),
                                        decoration: InputDecoration(
                                          hintText: 'Search $activeCategory...',
                                          hintStyle: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.38)
                                                : Colors.black.withValues(alpha: 0.38),
                                          ),
                                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                          suffixIcon: searchController.text.isNotEmpty
                                              ? GestureDetector(
                                                  onTap: () {
                                                    searchController.clear();
                                                    setModalState(() {});
                                                  },
                                                  child: const Icon(Icons.clear_rounded, size: 18),
                                                )
                                              : null,
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                                // Scrollable Option List
                                Expanded(
                                  child: _buildCategoryOptions(
                                    activeCategory,
                                    searchController.text.toLowerCase(),
                                    buses,
                                    routes,
                                    stops,
                                    tempBusNumber,
                                    tempRoute,
                                    tempStop,
                                    tempStatus,
                                    (newVal) => setModalState(() {
                                      if (activeCategory == 'bus') tempBusNumber = newVal;
                                      if (activeCategory == 'route') tempRoute = newVal;
                                      if (activeCategory == 'stop') tempStop = newVal;
                                    }),
                                    (newStatus) => setModalState(() {
                                      tempStatus = newStatus!;
                                    }),
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                    // Bottom Action Bar: Show count & Apply button
                    _buildApplyFooter(
                      context: context,
                      isDark: isDark,
                      tempBusNumber: tempBusNumber,
                      tempRoute: tempRoute,
                      tempStop: tempStop,
                      tempStatus: tempStatus,
                      allSchedules: allSchedules,
                      buses: allBuses,
                      routes: allRoutes,
                      onApply: () {
                        // Apply changes
                        setState(() {
                          _selectedBusNumber = tempBusNumber;
                          _selectedRoute = tempRoute;
                          _selectedStop = tempStop;
                          _selectedStatus = tempStatus;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryTab({
    required String label,
    required String? subtitle,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final primary = const Color(0xFF00C6E6);
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          border: isActive
              ? Border(
                  left: BorderSide(
                    color: primary,
                    width: 3.5,
                  ),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOptions(
    String category,
    String query,
    List<String> buses,
    List<String> routes,
    List<String> stops,
    String? currentBus,
    String? currentRoute,
    String? currentStop,
    String currentStatus,
    void Function(String?) onSelectString,
    void Function(String?) onSelectStatus,
    bool isDark,
  ) {
    if (category == 'status') {
      final statuses = [
        ('all', 'All Statuses', Icons.apps_rounded, const Color(0xFF00C6E6)),
        ('on-time', 'On Time', Icons.check_circle_rounded, const Color(0xFF10B981)),
        ('delayed', 'Delayed', Icons.schedule_rounded, const Color(0xFFF59E0B)),
        ('not-running', 'Offline', Icons.cancel_rounded, const Color(0xFFEF4444)),
      ];
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: statuses.map((item) {
          final (statusVal, label, icon, color) = item;
          final isSelected = currentStatus == statusVal;
          return _buildOptionRow(
            label: label,
            icon: icon,
            iconColor: color,
            isSelected: isSelected,
            isDark: isDark,
            onTap: () => onSelectStatus(statusVal),
          );
        }).toList(),
      );
    }

    // Bus, Route, Stop lists
    List<String> items = [];
    String? currentSelection;
    IconData icon;
    Color iconColor;

    if (category == 'bus') {
      items = buses;
      currentSelection = currentBus;
      icon = Icons.directions_bus_rounded;
      iconColor = const Color(0xFF00C6E6);
    } else if (category == 'route') {
      items = routes;
      currentSelection = currentRoute;
      icon = Icons.alt_route_rounded;
      iconColor = const Color(0xFF7B61FF);
    } else {
      items = stops;
      currentSelection = currentStop;
      icon = Icons.place_rounded;
      iconColor = const Color(0xFFF97316);
    }

    final filteredItems = items
        .where((item) => item.toLowerCase().contains(query))
        .toList();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: filteredItems.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // "All" / Clear option
          final isSelected = currentSelection == null;
          return _buildOptionRow(
            label: 'All ${category[0].toUpperCase()}${category.substring(1)}s',
            icon: Icons.clear_all_rounded,
            iconColor: isDark ? Colors.white30 : Colors.black26,
            isSelected: isSelected,
            isDark: isDark,
            onTap: () => onSelectString(null),
          );
        }

        final item = filteredItems[index - 1];
        final isSelected = item == currentSelection;
        return _buildOptionRow(
          label: item,
          icon: icon,
          iconColor: iconColor,
          isSelected: isSelected,
          isDark: isDark,
          onTap: () => onSelectString(item),
        );
      },
    );
  }

  Widget _buildOptionRow({
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final primary = const Color(0xFF00C6E6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha: isDark ? 0.12 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? primary : iconColor.withValues(alpha: isDark ? 0.6 : 0.8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? primary
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: primary,
                )
              else
                Icon(
                  Icons.radio_button_off_rounded,
                  size: 18,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplyFooter({
    required BuildContext context,
    required bool isDark,
    required String? tempBusNumber,
    required String? tempRoute,
    required String? tempStop,
    required String tempStatus,
    required List<ScheduleModel> allSchedules,
    required List<BusModel> buses,
    required List<RouteModel> routes,
    required VoidCallback onApply,
  }) {
    final matchCount = allSchedules.where((schedule) {
      final bus = buses.firstWhere(
        (b) => b.id == schedule.busId,
        orElse: () => BusModel(
          id: '',
          busNumber: '',
          driverId: '',
          collegeId: '',
          createdAt: DateTime.now(),
        ),
      );
      if (tempBusNumber != null) {
        if (bus.busNumber != tempBusNumber) return false;
      }
      final targetRouteId = (bus.assignmentStatus == 'accepted' && bus.routeId != null)
          ? bus.routeId!
          : schedule.routeId;
      if (tempRoute != null) {
        final route = routes.firstWhere(
          (r) => r.id == targetRouteId,
          orElse: () => RouteModel(
            id: '',
            routeName: '',
            routeType: '',
            startPoint: RoutePoint(name: '', lat: 0, lng: 0),
            endPoint: RoutePoint(name: '', lat: 0, lng: 0),
            stopPoints: [],
            collegeId: '',
            createdBy: '',
            isActive: false,
            createdAt: DateTime.now(),
          ),
        );
        if (route.routeName != tempRoute) return false;
      }
      if (tempStop != null) {
        final route = routes.firstWhere(
          (r) => r.id == targetRouteId,
          orElse: () => RouteModel(
            id: '',
            routeName: '',
            routeType: '',
            startPoint: RoutePoint(name: '', lat: 0, lng: 0),
            endPoint: RoutePoint(name: '', lat: 0, lng: 0),
            stopPoints: [],
            collegeId: '',
            createdBy: '',
            isActive: false,
            createdAt: DateTime.now(),
          ),
        );
        final hasStop = route.id != schedule.routeId
            ? (route.startPoint.name == tempStop ||
                route.endPoint.name == tempStop ||
                route.stopPoints.any((s) => s.name == tempStop))
            : schedule.stopSchedules.any((s) => s.stopName == tempStop);
        if (!hasStop) return false;
      }
      if (tempStatus != 'all') {
        if (bus.status != tempStatus) return false;
      }
      return true;
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onApply,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C6E6), Color(0xFF0097B2)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C6E6).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Apply Filters ($matchCount schedules)',
                  style: const TextStyle(
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
    );
  }


  // ─── Schedule List ─────────────────────────────────────────────────────────
  Widget _buildScheduleList(
    List<ScheduleModel> schedules,
    String shift,
    List<BusModel> buses,
    List<RouteModel> routes,
    dynamic user,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFF00C6E6).withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _hasActiveFilters
                    ? Icons.search_off_rounded
                    : (shift.toLowerCase().contains('1st') ||
                          shift.toLowerCase().contains('morning')
                        ? Icons.wb_sunny_rounded
                        : Icons.nights_stay_rounded),
                size: 42,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFF00C6E6).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _hasActiveFilters
                  ? 'No schedules match\nyour filters'
                  : 'No schedules available\nfor this shift',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.35),
              ),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _clearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C6E6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00C6E6).withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Text(
                    'Clear Filters',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00C6E6),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      key: PageStorageKey('schedule_list_$shift'),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      itemCount: schedules.length + 2,
      itemBuilder: (context, index) {
        // Header count row
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4, left: 2),
            child: Text(
              '${schedules.length} schedule${schedules.length == 1 ? '' : 's'} found',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.35),
                letterSpacing: 0.3,
              ),
            ),
          );
        }
        if (index == schedules.length + 1) {
          return const BottomNavSpacer();
        }

        final schedule = schedules[index - 1];
        final bus = buses.firstWhere(
          (b) => b.id == schedule.busId,
          orElse: () => BusModel(
            id: '',
            busNumber: 'N/A',
            driverId: '',
            collegeId: '',
            createdAt: DateTime.now(),
          ),
        );
        final targetRouteId = (bus.assignmentStatus == 'accepted' && bus.routeId != null)
            ? bus.routeId!
            : schedule.routeId;
        final route = routes.firstWhere(
          (r) => r.id == targetRouteId,
          orElse: () => RouteModel(
            id: '',
            routeName: 'Unknown Route',
            routeType: '',
            startPoint: RoutePoint(name: '', lat: 0, lng: 0),
            endPoint: RoutePoint(name: '', lat: 0, lng: 0),
            stopPoints: [],
            collegeId: '',
            createdBy: '',
            isActive: false,
            createdAt: DateTime.now(),
          ),
        );

        return _buildScheduleCard(
          context: context,
          schedule: schedule,
          bus: bus,
          route: route,
          user: user,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildScheduleCard({
    required BuildContext context,
    required ScheduleModel schedule,
    required BusModel bus,
    required RouteModel route,
    required dynamic user,
    required bool isDark,
  }) {
    final displayStopSchedules = route.id != schedule.routeId
        ? [
            StopSchedule(stopName: route.startPoint.name, arrivalTime: '--:--', departureTime: '--:--'),
            ...route.stopPoints.map((s) => StopSchedule(stopName: s.name, arrivalTime: '--:--', departureTime: '--:--')),
            StopSchedule(stopName: route.endPoint.name, arrivalTime: '--:--', departureTime: '--:--'),
          ].where((s) => s.stopName.isNotEmpty).toList()
        : schedule.stopSchedules;

    final stopCount = displayStopSchedules.length;
    final routeTypeIsPickup = route.routeType.toLowerCase() == 'pickup';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: PageStorageKey('schedule_tile_${schedule.id}_v3'),
                initiallyExpanded: false,
                maintainState: false,
                tilePadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C6E6), Color(0xFF0076A3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C6E6).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      Text(
                        bus.busNumber.replaceAll(RegExp(r'[A-Za-z\s]'), '').trim().isEmpty
                            ? bus.busNumber.substring(0, bus.busNumber.length.clamp(0, 3))
                            : bus.busNumber.replaceAll(RegExp(r'[A-Za-z\s]'), '').trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bus ${bus.busNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.3,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRouteTypeChip(routeTypeIsPickup, isDark),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.linear_scale_rounded,
                            size: 12,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.35)
                                : Colors.black.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              route.startPoint.name.isNotEmpty
                                  ? '${route.startPoint.name} → ${route.endPoint.name}'
                                  : 'Route not assigned',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : Colors.black.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(bus.status, bus.delay),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 11,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.25),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$stopCount stop${stopCount == 1 ? '' : 's'} on this route',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.3),
                    size: 18,
                  ),
                ),
                children: [
                  // ── Expanded Detail ─────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C6E6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.access_time_filled_rounded,
                              size: 14,
                              color: Color(0xFF00C6E6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stop Schedule',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      if (widget.onBusSelected != null)
                        _buildTrackButton(context, bus, user, isDark),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Column headers
                  Padding(
                    padding: const EdgeInsets.only(left: 34),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'STOP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        Text(
                          'ARR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Text(
                          'DEP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Timeline rows
                  ...displayStopSchedules.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final stopSchedule = entry.value;
                    final totalStops = displayStopSchedules.length;
                    final isFirst = idx == 0;
                    final isLast = idx == totalStops - 1;

                    final Color nodeColor;
                    if (isFirst) {
                      nodeColor = const Color(0xFF10B981);
                    } else if (isLast) {
                      nodeColor = const Color(0xFFEF4444);
                    } else {
                      nodeColor = const Color(0xFFF97316);
                    }

                    // Dynamically calculate connector line gradient colors
                    final Color startLineColor = (isFirst ? const Color(0xFF10B981) : const Color(0xFFF97316))
                        .withValues(alpha: isDark ? 0.35 : 0.25);
                    final Color endLineColor = (isLast ? const Color(0xFFEF4444) : (idx == totalStops - 2 ? const Color(0xFFEF4444) : const Color(0xFFF97316)))
                        .withValues(alpha: isDark ? 0.35 : 0.25);

                    return SizedBox(
                      height: 50,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Timeline column
                          SizedBox(
                            width: 24,
                            height: 50, // CRITICAL: Explicit height matches parent height to ensure Stack stretches fully
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Connector line
                                Positioned(
                                  top: isFirst ? 25 : 0,
                                  bottom: isLast ? 25 : 0,
                                  width: 2.2, // Slightly thicker line for better visual presence
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [startLineColor, endLineColor],
                                      ),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ),
                                // Node dot
                                isFirst || isLast
                                    ? Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: nodeColor,
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: nodeColor.withValues(alpha: 0.45),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: nodeColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: nodeColor.withValues(alpha: 0.4),
                                              blurRadius: 4,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Stop name
                          Expanded(
                            child: Text(
                              stopSchedule.stopName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isFirst || isLast
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isDark
                                    ? (isFirst || isLast
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : Colors.white.withValues(alpha: 0.7))
                                    : (isFirst || isLast
                                        ? const Color(0xFF0F172A)
                                        : Colors.black.withValues(alpha: 0.6)),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Arrival
                          Text(
                            stopSchedule.arrivalTime,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00C6E6),
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Departure
                          Text(
                            stopSchedule.departureTime,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.45),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteTypeChip(bool isPickup, bool isDark) {
    final color = isPickup ? const Color(0xFF6366F1) : const Color(0xFF10B981);
    final label = isPickup ? 'Pickup' : 'Drop';
    final icon = isPickup ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackButton(
    BuildContext context,
    BusModel bus,
    dynamic user,
    bool isDark,
  ) {
    // Commented out premium checking logic for testing live tracking
    // final canTrack = user.isPremium && bus.assignmentStatus == 'accepted';
    final canTrack = bus.assignmentStatus == 'accepted';
    final color = canTrack ? const Color(0xFF00C6E6) : Colors.grey;

    return GestureDetector(
      onTap: () {
        // Commented out premium check for testing live tracking
        /*
        if (!user.isPremium) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upgrade to Premium to track live buses.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        */
        if (bus.assignmentStatus != 'accepted') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Bus ${bus.busNumber} is not active yet.',
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        widget.onBusSelected!(bus);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: canTrack
              ? const LinearGradient(
                  colors: [Color(0xFF00C6E6), Color(0xFF0097B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: canTrack ? null : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(22),
          boxShadow: canTrack
              ? [
                  BoxShadow(
                    color: const Color(0xFF00C6E6).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              canTrack ? Icons.my_location_rounded : Icons.lock_rounded,
              size: 13,
              color: canTrack ? Colors.white : color,
            ),
            const SizedBox(width: 5),
            Text(
              canTrack ? 'Track Live' : 'Premium',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: canTrack ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Redundant absolute options expansion was removed in favor of shopping-cart-style bottom sheet filters

  // ─── Status Badge ──────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status, int delay) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'on-time':
        color = const Color(0xFF10B981);
        label = 'On Time';
        icon = Icons.check_circle_rounded;
        break;
      case 'delayed':
        color = const Color(0xFFF59E0B);
        label = delay > 0 ? '+$delay m' : 'Delayed';
        icon = Icons.schedule_rounded;
        break;
      case 'not-running':
        color = const Color(0xFFEF4444);
        label = 'Offline';
        icon = Icons.cancel_rounded;
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
        icon = Icons.help_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
