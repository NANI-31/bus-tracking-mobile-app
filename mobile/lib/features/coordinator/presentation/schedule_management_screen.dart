import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/schedule/domain/schedule_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/college/application/college_provider.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/features/coordinator/presentation/edit_schedule_screen.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';
import 'package:collegebus/shared/widgets/shimmer_skeletons.dart';

class ScheduleManagementScreen extends ConsumerStatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  ConsumerState<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState
    extends ConsumerState<ScheduleManagementScreen> {
  final Set<String> _expandedScheduleIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTripFilter = 'all';
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateScheduleDialog({
    required String shift,
    required List<RouteModel> routes,
    required List<BusModel> buses,
  }) {
    RouteModel? selectedRoute;
    BusModel? selectedBus;
    String selectedTripType = 'pickup';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E2732) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SizedBox(
                width: 340,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            12.widthBox,
                            Expanded(
                              child: Text(
                                'Create $shift Shift Timetable',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF111418),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<RouteModel>(
                          initialValue: selectedRoute,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E2732) : Colors.white,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF111418),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Select Route',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 28),
                          items: routes
                              .map(
                                (route) => DropdownMenuItem(
                                  value: route,
                                  child: Text(
                                    '${route.routeName} (${route.routeType.toUpperCase()})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (route) {
                            setState(() {
                              selectedRoute = route;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<BusModel>(
                          initialValue: selectedBus,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E2732) : Colors.white,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF111418),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Select Bus',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 28),
                          items: buses
                              .map(
                                (bus) => DropdownMenuItem(
                                  value: bus,
                                  child: Text(
                                    'Bus ${bus.busNumber}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (bus) => setState(() => selectedBus = bus),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTripType,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E2732) : Colors.white,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF111418),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Trip Type',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 28),
                          items: const [
                            DropdownMenuItem(
                              value: 'pickup',
                              child: Text('Pickup'),
                            ),
                            DropdownMenuItem(
                              value: 'drop',
                              child: Text('Drop'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => selectedTripType = val);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        if (selectedRoute != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    8.widthBox,
                                    Text(
                                      'Route Information:',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF111418),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${selectedRoute!.startPoint.name} → ${selectedRoute!.endPoint.name}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade800,
                                  ),
                                ),
                                if (selectedRoute!.stopPoints.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Stops: ${selectedRoute!.stopPoints.map((s) => s.name).join(' → ')}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed:
                                  selectedRoute != null && selectedBus != null
                                  ? () async {
                                      final user = ref.read(
                                        currentUserProvider,
                                      );
                                      final repo = ref.read(
                                        scheduleRepositoryProvider,
                                      );

                                      // Create stop schedules without specific times
                                      final stopSchedules = <StopSchedule>[];
                                      final allStops = [
                                        selectedRoute!.startPoint.name,
                                        ...selectedRoute!.stopPoints.map(
                                          (s) => s.name,
                                        ),
                                        selectedRoute!.endPoint.name,
                                      ];

                                      for (final stop in allStops) {
                                        stopSchedules.add(
                                          StopSchedule(
                                            stopName: stop,
                                            arrivalTime: 'As per schedule',
                                            departureTime: 'As per schedule',
                                          ),
                                        );
                                      }

                                      final schedule = ScheduleModel(
                                        id: DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString(),
                                        routeId: selectedRoute!.id,
                                        busId: selectedBus!.id,
                                        shift: shift,
                                        tripType: selectedTripType,
                                        stopSchedules: stopSchedules,
                                        collegeId: user!.collegeId,
                                        createdBy: user.id,
                                        createdAt: DateTime.now(),
                                      );

                                      try {
                                        await repo.createSchedule(schedule);
                                        ref.invalidate(
                                          collegeSchedulesProvider(
                                            user.collegeId,
                                          ),
                                        );
                                        if (!context.mounted) return;
                                        Navigator.of(context).pop();
                                        SuccessModal.show(
                                          context: context,
                                          title: 'Timetable Created',
                                          message: '$shift shift timetable created successfully',
                                          primaryActionText: 'OK',
                                        );
                                      } catch (e) {
                                        ApiErrorModal.show(
                                          context: context,
                                          error: e.toString().replaceAll(
                                                'Exception: ',
                                                '',
                                              ),
                                        );
                                      }
                                    }
                                  : null,
                              child: const Text('Create Timetable'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;

    if (collegeId == null) {
      return const Scaffold(body: ScheduleListSkeleton());
    }

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
      return const Scaffold(body: ScheduleListSkeleton());
    }

    final hasMultipleShifts =
        college.shiftCount > 1 && college.shifts.isNotEmpty;
    // Always use at least 1 tab to prevent errors.
    final int tabLength = college.shifts.isNotEmpty ? college.shifts.length : 1;

    final tabs = hasMultipleShifts
        ? college.shifts
              .map((s) => Tab(text: s.name, icon: const Icon(Icons.schedule)))
              .toList()
        : [];

    final routesAsync = ref.watch(collegeRoutesProvider(collegeId));
    final busesAsync = ref.watch(collegeBusesStreamProvider(collegeId));
    final schedulesAsync = ref.watch(collegeSchedulesProvider(collegeId));

    return DefaultTabController(
      key: ValueKey('mgmt_shift_tabs_$tabLength'),
      length: tabLength,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Manage Schedules'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: AppColors.primary,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          bottom: hasMultipleShifts
              ? TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                  indicatorColor: Colors.white,
                  tabs: tabs as List<Widget>,
                )
              : null,
        ),
        body: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (!mounted) return true;
            if (notification.direction == ScrollDirection.reverse) {
              if (_isFabVisible) {
                setState(() {
                  _isFabVisible = false;
                });
              }
            } else if (notification.direction == ScrollDirection.forward) {
              if (!_isFabVisible) {
                setState(() {
                  _isFabVisible = true;
                });
              }
            }
            return true;
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.15
                              : 0.04,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF111418),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by bus number or route...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E2732)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'All',
                      value: 'all',
                      icon: Icons.filter_list_rounded,
                    ),
                    8.widthBox,
                    _buildFilterChip(
                      label: 'Pickup',
                      value: 'pickup',
                      icon: Icons.south_west_rounded,
                    ),
                    8.widthBox,
                    _buildFilterChip(
                      label: 'Drop',
                      value: 'drop',
                      icon: Icons.north_east_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: schedulesAsync.when(
                  loading: () => const ScheduleListSkeleton(),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (schedules) {
                    final routes = routesAsync.valueOrNull ?? [];
                    final buses = busesAsync.valueOrNull ?? [];
  
                    if (hasMultipleShifts) {
                      return TabBarView(
                        children: college.shifts.map((shift) {
                          final shiftSchedules = schedules
                              .where((s) => s.shift == shift.shiftId)
                              .toList();
                          return _buildScheduleTab(
                            shift.name,
                            shiftSchedules,
                            routes,
                            buses,
                          );
                        }).toList(),
                      );
                    } else {
                      return _buildScheduleTab(
                        'Morning',
                        schedules,
                        routes,
                        buses,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: CurvedBottomNavBar.clearance(context),
              ),
              child: AnimatedScale(
                scale: _isFabVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    // If single shift, just take the first one; multiple shifts use the tab index
                    final currentShift = hasMultipleShifts
                        ? college
                              .shifts[DefaultTabController.of(context).index]
                              .shiftId
                        : (college.shifts.isNotEmpty
                              ? college.shifts.first.shiftId
                              : '1st');
                    _showCreateScheduleDialog(
                      shift: currentShift,
                      routes: routesAsync.valueOrNull ?? [],
                      buses: busesAsync.valueOrNull ?? [],
                    );
                  },
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  label: const Text('Add Timetable'),
                  icon: const Icon(Icons.add),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedTripFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTripFilter = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF1E2732) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0x14000000)),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.grey.shade700),
              ),
              6.widthBox,
              label.text
                  .size(13)
                  .bold
                  .color(
                    isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.grey.shade700),
                  )
                  .make(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleTab(
    String shift,
    List<ScheduleModel> schedules,
    List<RouteModel> routes,
    List<BusModel> buses,
  ) {
    // Apply filters
    final filteredSchedules = schedules.where((schedule) {
      if (_selectedTripFilter != 'all' && schedule.tripType != _selectedTripFilter) {
        return false;
      }

      if (_searchQuery.isEmpty) return true;

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

      final route = routes.firstWhere(
        (r) => r.id == schedule.routeId,
        orElse: () => RouteModel(
          id: '',
          routeName: '',
          routeType: '',
          startPoint: RoutePoint(name: '', lat: 0, lng: 0),
          endPoint: RoutePoint(name: '', lat: 0, lng: 0),
          stopPoints: const [],
          collegeId: '',
          createdBy: '',
          isActive: false,
          createdAt: DateTime.now(),
        ),
      );

      return bus.busNumber.toLowerCase().contains(_searchQuery) ||
          route.routeName.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredSchedules.isEmpty) {
      return Center(
        child: InactiveScheduleIllustration(
          shift: shift,
          searchQuery: _searchQuery,
        ),
      );
    }

    return ListView.builder(
      key: PageStorageKey('mgmt_schedule_list_${shift}_$_searchQuery'),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: filteredSchedules.length + 1,
      itemBuilder: (context, index) {
        if (index == filteredSchedules.length) {
          return const BottomNavSpacer();
        }
        try {
          final schedule = filteredSchedules[index];
          final isExpanded = _expandedScheduleIds.contains(schedule.id);
          // Determine Route
          final route = routes.firstWhere(
            (r) => r.id == schedule.routeId,
            orElse: () => RouteModel(
              id: '',
              routeName: 'Unknown Route',
              routeType: '',
              startPoint: RoutePoint(name: '', lat: 0, lng: 0),
              endPoint: RoutePoint(name: '', lat: 0, lng: 0),
              stopPoints: const [],
              collegeId: '',
              createdBy: '',
              isActive: false,
              createdAt: DateTime.now(),
            ),
          );

          // Determine Bus
          final bus = buses.firstWhere(
            (b) => b.id == schedule.busId,
            orElse: () => BusModel(
              id: '',
              busNumber: 'Unknown Bus',
              driverId: '',
              collegeId: '',
              createdAt: DateTime.now(),
            ),
          );          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2732) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0x14000000),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedScheduleIds.remove(schedule.id);
                      } else {
                        _expandedScheduleIds.add(schedule.id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              shift == '1st' ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ),
                        16.widthBox,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  'Bus ${bus.busNumber}'.text
                                      .bold
                                      .size(16)
                                      .color(isDark ? Colors.white : const Color(0xFF111418))
                                      .make(),
                                  8.widthBox,
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (schedule.tripType == 'pickup' ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: (schedule.tripType == 'pickup' ? 'Pickup' : 'Drop')
                                        .text
                                        .size(10)
                                        .bold
                                        .color(schedule.tripType == 'pickup' ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
                                        .make(),
                                  ),
                                ],
                              ),
                              4.heightBox,
                              'Route: ${route.routeName}'
                                  .text
                                  .size(13)
                                  .color(isDark ? Colors.white60 : Colors.grey.shade600)
                                  .make(),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) {
                        return SizeTransition(
                          sizeFactor: animation,
                          axisAlignment: -1.0,
                          child: ExcludeSemantics(
                            excluding: !animation.isCompleted && !animation.isDismissed,
                            child: child,
                          ),
                        );
                      },
                    );
                  },
                  child: isExpanded
                      ? Column(
                          key: ValueKey('expanded_${schedule.id}'),
                          children: [
                            const Divider(height: 1, thickness: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.edit_rounded, size: 18),
                                          label: const Text('Edit'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                            foregroundColor: AppColors.primary,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => EditScheduleScreen(
                                                  schedule: schedule,
                                                  routes: routes,
                                                  buses: buses,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      12.widthBox,
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.delete_rounded, size: 18),
                                          label: const Text('Delete'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.error.withValues(alpha: 0.1),
                                            foregroundColor: AppColors.error,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Timetable'),
                                                content: const Text(
                                                  'Are you sure you want to delete this timetable?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context).pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.of(context).pop(true),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                                    ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirmed == true) {
                                              if (!context.mounted) return;
                                              final repo = ref.read(
                                                scheduleRepositoryProvider,
                                              );
                                              await repo.deleteSchedule(schedule.id);
                                              ref.invalidate(
                                                collegeSchedulesProvider(
                                                  schedule.collegeId,
                                                ),
                                              );
                                              if (!context.mounted) return;
                                              SuccessModal.show(
                                                context: context,
                                                title: 'Timetable Deleted',
                                                message: 'Timetable deleted successfully',
                                                primaryActionText: 'OK',
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  12.heightBox,
                                  'Bus Stops Sequence'.text.size(15).bold.color(isDark ? Colors.white : const Color(0xFF111418)).make(),
                                  8.heightBox,
                                  Column(
                                    children: List.generate(
                                      schedule.stopSchedules.length,
                                      (stopIndex) {
                                        final stop = schedule.stopSchedules[stopIndex];
                                        final isStart = stopIndex == 0;
                                        final isEnd = stopIndex == schedule.stopSchedules.length - 1;
                                        final nodeColor = isStart
                                            ? const Color(0xFF10B981)
                                            : isEnd
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFFF97316);
                                        return Stack(
                                          children: [
                                            // Left connector line
                                            Positioned(
                                              left: 15,
                                              top: isStart ? 9 : 0,
                                              bottom: isEnd ? null : 0,
                                              child: isEnd
                                                  ? const SizedBox.shrink()
                                                  : Container(
                                                      width: 2,
                                                      color: Colors.grey.withValues(alpha: 0.3),
                                                    ),
                                            ),
                                            if (isEnd)
                                              Positioned(
                                                left: 15,
                                                top: 0,
                                                child: Container(
                                                  width: 2,
                                                  height: 9,
                                                  color: Colors.grey.withValues(alpha: 0.3),
                                                ),
                                              ),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: 32,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(top: 2.0),
                                                    child: Center(
                                                      child: Container(
                                                        width: 14,
                                                        height: 14,
                                                        decoration: BoxDecoration(
                                                          color: nodeColor,
                                                          shape: BoxShape.circle,
                                                          border: Border.all(
                                                            color: isDark ? const Color(0xFF1E2732) : Colors.white,
                                                            width: 2.5,
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: nodeColor.withValues(alpha: 0.4),
                                                              blurRadius: 6,
                                                              spreadRadius: 1,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                12.widthBox,
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(top: 2.0, bottom: 10.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        stop.stopName.text
                                                            .size(14)
                                                            .semiBold
                                                            .color(isDark ? Colors.white : const Color(0xFF111418))
                                                            .make(),
                                                        4.heightBox,
                                                        (isStart
                                                                ? 'Starting Point'
                                                                : isEnd
                                                                    ? 'Destination'
                                                                    : 'Intermediate Stop')
                                                            .text
                                                            .size(11)
                                                            .color(isDark ? Colors.white60 : Colors.grey.shade600)
                                                            .make(),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          key: ValueKey('collapsed_${schedule.id}'),
                        ),
                  ),
                ],
              ),
            );
        } catch (e) {
          return Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading item: $e',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rich Status Sleeping Bus Empty State Illustration
// ─────────────────────────────────────────────────────────────────────────────

class InactiveScheduleIllustration extends StatefulWidget {
  final String shift;
  final String searchQuery;

  const InactiveScheduleIllustration({
    super.key,
    required this.shift,
    required this.searchQuery,
  });

  @override
  State<InactiveScheduleIllustration> createState() => _InactiveScheduleIllustrationState();
}

class _InactiveScheduleIllustrationState extends State<InactiveScheduleIllustration> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(200, 160),
              painter: SleepingBusPainter(
                animationValue: _controller.value,
                isDark: isDark,
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        (widget.searchQuery.isEmpty
                ? 'No ${widget.shift} shift timetables created yet'
                : 'No matching timetables found')
            .text
            .size(18)
            .bold
            .center
            .color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85))
            .make(),
        const SizedBox(height: 8),
        (widget.searchQuery.isEmpty
                ? 'Tap the + button below to schedule a route'
                : 'Try searching for another bus number or route name')
            .text
            .size(13)
            .center
            .color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))
            .make(),
      ],
    );
  }
}

class SleepingBusPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  SleepingBusPainter({required this.animationValue, required this.isDark});

  Path _createCloudPath(Offset start, double scale) {
    final path = Path();
    final x = start.dx;
    final y = start.dy;
    path.moveTo(x, y);
    path.quadraticBezierTo(x + 5 * scale, y - 10 * scale, x + 15 * scale, y - 8 * scale);
    path.quadraticBezierTo(x + 25 * scale, y - 20 * scale, x + 40 * scale, y - 12 * scale);
    path.quadraticBezierTo(x + 55 * scale, y - 10 * scale, x + 58 * scale, y);
    path.quadraticBezierTo(x + 65 * scale, y + 8 * scale, x + 55 * scale, y + 12 * scale);
    path.lineTo(x + 5 * scale, y + 12 * scale);
    path.quadraticBezierTo(x - 5 * scale, y + 10 * scale, x, y);
    path.close();
    return path;
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, double opacity) {
    final paint = Paint()
      ..color = Colors.amber.shade200.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
      
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerBusX = size.width / 2;
    final centerBusY = size.height / 2 + 15;

    final breatheOffsetY = math.sin(animationValue * 2 * math.pi) * 3.0;

    // --------------------------------------------------------
    // Background Stars (Twinkling)
    // --------------------------------------------------------
    final star1Opacity = (0.2 + 0.8 * math.sin(animationValue * 2 * math.pi)).clamp(0.0, 1.0);
    _drawSparkle(canvas, Offset(centerBusX - 20, centerBusY - 65), 4.0, star1Opacity);

    final star2Opacity = (0.2 + 0.8 * math.sin(animationValue * 2 * math.pi + math.pi / 2)).clamp(0.0, 1.0);
    _drawSparkle(canvas, Offset(centerBusX + 45, centerBusY - 60), 3.0, star2Opacity);

    final star3Opacity = (0.2 + 0.8 * math.sin(animationValue * 2 * math.pi + math.pi)).clamp(0.0, 1.0);
    _drawSparkle(canvas, Offset(centerBusX - 75, centerBusY - 30), 3.5, star3Opacity);

    // --------------------------------------------------------
    // Crescent Moon with independent floating & rotation & pulse glow
    // --------------------------------------------------------
    final moonX = centerBusX - 55;
    final moonY = centerBusY - 50;

    final moonFloatX = math.sin(animationValue * 2 * math.pi) * 3.0;
    final moonFloatY = math.cos(animationValue * 2 * math.pi + math.pi / 2) * 2.0;

    // Glowing aura behind the moon
    final moonGlowPaint = Paint()
      ..color = Colors.amber.shade300.withValues(alpha: 0.12 + 0.04 * math.sin(animationValue * 2 * math.pi))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(moonX + moonFloatX, moonY + moonFloatY), 16, moonGlowPaint);

    canvas.save();
    canvas.translate(moonX + moonFloatX, moonY + moonFloatY);
    
    final moonRot = math.sin(animationValue * 2 * math.pi) * 0.05;
    canvas.rotate(moonRot);

    final moonPath2 = Path();
    moonPath2.moveTo(0, -18);
    moonPath2.quadraticBezierTo(12, 0, 0, 18);
    moonPath2.quadraticBezierTo(7, 0, 0, -18);
    moonPath2.close();
    
    final crescentPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawPath(moonPath2, crescentPaint);
    canvas.restore();

    // --------------------------------------------------------
    // Background Clouds (Drifting/Floating)
    // --------------------------------------------------------
    // Cloud 1: Right side, behind the bus
    final cloud1FloatX = math.sin(animationValue * 2 * math.pi - math.pi / 3) * 6.0;
    final cloud1FloatY = math.cos(animationValue * 2 * math.pi) * 2.5;
    final cloud1X = centerBusX + 50 + cloud1FloatX;
    final cloud1Y = centerBusY - 45 + cloud1FloatY;

    final cloudPaint1 = Paint()
      ..color = (isDark ? Colors.white : Colors.blueGrey.shade100).withValues(alpha: isDark ? 0.08 : 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(_createCloudPath(Offset(cloud1X, cloud1Y), 0.9), cloudPaint1);

    // Cloud 2: Left side, slightly lower
    final cloud2FloatX = math.cos(animationValue * 2 * math.pi + math.pi / 6) * 5.0;
    final cloud2FloatY = math.sin(animationValue * 2 * math.pi) * 3.0;
    final cloud2X = centerBusX - 95 + cloud2FloatX;
    final cloud2Y = centerBusY - 15 + cloud2FloatY;

    final cloudPaint2 = Paint()
      ..color = (isDark ? Colors.white : Colors.blueGrey.shade200).withValues(alpha: isDark ? 0.06 : 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(_createCloudPath(Offset(cloud2X, cloud2Y), 0.75), cloudPaint2);

    // --------------------------------------------------------
    // Bus shadow (Scales/fades with breathing motion)
    // --------------------------------------------------------
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: (isDark ? 0.25 : 0.08) * (1.0 - (breatheOffsetY.abs() / 15.0)))
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerBusX, centerBusY + 33),
        width: 120 - breatheOffsetY * 2,
        height: 10 - breatheOffsetY * 0.5,
      ),
      shadowPaint,
    );

    // --------------------------------------------------------
    // Bus body & parts (breathing up and down)
    // --------------------------------------------------------
    canvas.save();
    canvas.translate(0, breatheOffsetY);

    final busPaint = Paint()
      ..color = Colors.amber.shade400
      ..style = PaintingStyle.fill;
    final busRect = Rect.fromCenter(center: Offset(centerBusX, centerBusY), width: 100, height: 50);
    canvas.drawRRect(RRect.fromRectAndRadius(busRect, const Radius.circular(12)), busPaint);

    final roofPaint = Paint()
      ..color = Colors.amber.shade600
      ..style = PaintingStyle.fill;
    final roofRect = Rect.fromLTWH(centerBusX - 50, centerBusY - 25, 100, 8);
    canvas.drawRect(roofRect, roofPaint);

    final windowPaint = Paint()
      ..color = isDark ? Colors.blueGrey.shade800 : Colors.blue.shade100
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final winRect = Rect.fromLTWH(centerBusX - 42 + i * 28, centerBusY - 12, 20, 16);
      canvas.drawRRect(RRect.fromRectAndRadius(winRect, const Radius.circular(4)), windowPaint);
    }

    final wheelPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;
    final hubCapPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerBusX - 30, centerBusY + 25), 12, wheelPaint);
    canvas.drawCircle(Offset(centerBusX - 30, centerBusY + 25), 5, hubCapPaint);

    canvas.drawCircle(Offset(centerBusX + 30, centerBusY + 25), 12, wheelPaint);
    canvas.drawCircle(Offset(centerBusX + 30, centerBusY + 25), 5, hubCapPaint);

    final eyePaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final rightEyeCenter = Offset(centerBusX + 28, centerBusY - 4);
    canvas.drawArc(
      Rect.fromCircle(center: rightEyeCenter, radius: 4),
      0,
      math.pi,
      false,
      eyePaint,
    );

    canvas.restore();

    // --------------------------------------------------------
    // Zzz rising drift
    // --------------------------------------------------------
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final double busTopRightX = centerBusX + 35;
    final double busTopRightY = centerBusY - 25;

    final zPhases = [
      animationValue,
      (animationValue + 0.33) % 1.0,
      (animationValue + 0.66) % 1.0,
    ];

    for (int i = 0; i < zPhases.length; i++) {
      final t = zPhases[i];
      double opacity = 0.0;
      if (t < 0.2) {
        opacity = t / 0.2;
      } else if (t < 0.8) {
        opacity = 1.0;
      } else {
        opacity = (1.0 - t) / 0.2;
      }
      opacity = opacity.clamp(0.0, 1.0);

      final driftX = math.sin(t * 2 * math.pi) * 12.0;
      final riseY = t * 60.0;

      final sizeText = 10.0 + i * 4.0;

      textPainter.text = TextSpan(
        text: 'Z',
        style: TextStyle(
          fontSize: sizeText,
          fontWeight: FontWeight.bold,
          color: Colors.amber.withValues(alpha: opacity),
        ),
      );
      textPainter.layout();
      canvas.save();
      canvas.translate(busTopRightX + driftX, busTopRightY - riseY);
      canvas.rotate(math.sin(t * math.pi) * 0.2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant SleepingBusPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.isDark != isDark;
  }
}
