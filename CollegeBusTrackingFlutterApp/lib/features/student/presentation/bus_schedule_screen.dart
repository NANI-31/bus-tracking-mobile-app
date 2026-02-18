import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/features/schedule/domain/schedule_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/college/application/college_provider.dart';
import 'package:collegebus/features/college/domain/college_model.dart';

class BusScheduleScreen extends ConsumerStatefulWidget {
  final bool isTab;
  final Function(BusModel)? onBusSelected;
  const BusScheduleScreen({super.key, this.isTab = false, this.onBusSelected});

  @override
  ConsumerState<BusScheduleScreen> createState() => _BusScheduleScreenState();
}

class _BusScheduleScreenState extends ConsumerState<BusScheduleScreen> {
  // Filter variables
  String? _selectedBusNumber;
  String? _selectedRoute;
  String? _selectedStop;
  String? _activeFilterType; // 'bus', 'route', 'stop', or 'trip'
  String _selectedStatus = 'all'; // Default to 'all' for status filter

  final LayerLink _layerLink = LayerLink();

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
      _selectedStop = null;
      _activeFilterType = null;
      _selectedStatus = 'all';
    });
  }

  void _toggleFilter(String type) {
    setState(() {
      if (_activeFilterType == type) {
        _activeFilterType = null;
      } else {
        _activeFilterType = type;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;

    if (collegeId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final busesAsync = ref.watch(collegeBusesStreamProvider(collegeId));
    final routesAsync = ref.watch(collegeRoutesProvider(collegeId));
    final schedulesAsync = ref.watch(collegeSchedulesProvider(collegeId));
    final collegesAsync = ref.watch(collegeServiceProvider);

    final college = collegesAsync.value?.firstWhere(
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Ensure checks are safe
    final hasMultipleShifts =
        college.shiftCount > 1 && college.shifts.isNotEmpty;
    // Always use at least 1 tab to prevent errors.
    final int tabLength = college.shifts.isNotEmpty ? college.shifts.length : 1;

    final tabs = hasMultipleShifts
        ? college.shifts
              .map((s) => Tab(text: s.name, icon: const Icon(Icons.schedule)))
              .toList()
        : [];

    return DefaultTabController(
      key: ValueKey('shift_tabs_$tabLength'),
      length: tabLength,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: widget.isTab
            ? (hasMultipleShifts
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(kTextTabBarHeight),
                      child: Material(
                        color: Theme.of(context).primaryColor,
                        child: TabBar(
                          labelColor: Theme.of(context).colorScheme.onPrimary,
                          unselectedLabelColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.7),
                          indicatorColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          tabs: tabs as List<Widget>,
                        ),
                      ),
                    )
                  : null)
            : PreferredSize(
                preferredSize: Size.fromHeight(
                  kToolbarHeight + (hasMultipleShifts ? kTextTabBarHeight : 0),
                ),
                child: AppBar(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  title: const Text('Bus Schedule'),
                  bottom: hasMultipleShifts
                      ? TabBar(
                          labelColor: Theme.of(context).colorScheme.onPrimary,
                          unselectedLabelColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.7),
                          indicatorColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          tabs: tabs as List<Widget>,
                        )
                      : null,
                ),
              ),
        body: SafeArea(
          bottom: false,
          child: _buildMainScheduleUI(
            context,
            ref,
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
    String collegeId,
    CollegeModel college,
    AsyncValue<List<BusModel>> busesAsync,
    AsyncValue<List<RouteModel>> routesAsync,
    AsyncValue<List<ScheduleModel>> schedulesAsync,
    bool hasMultipleShifts,
  ) {
    final buses = busesAsync.value ?? [];
    final routes = routesAsync.value ?? [];
    final allSchedules = schedulesAsync.value ?? [];

    // Helper for all bus numbers
    final allBusNumbersList = buses.map((b) => b.busNumber).toSet().toList()
      ..sort();
    // Helper for all routes
    final allRoutesList = routes.map((r) => r.routeName).toSet().toList()
      ..sort();
    // Helper for all stops
    final stopsSet = <String>{};
    for (final route in routes) {
      stopsSet.add(route.startPoint.name);
      stopsSet.add(route.endPoint.name);
      stopsSet.addAll(route.stopPoints.map((s) => s.name));
    }
    final allStopsList = stopsSet.toList()..sort();

    // Apply filters
    List<ScheduleModel> filterSchedules(
      List<ScheduleModel> schedules,
      String? shiftId,
    ) {
      return schedules.where((schedule) {
        // Shift filter
        if (shiftId != null && schedule.shift != shiftId) return false;

        if (_selectedBusNumber != null) {
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
          if (bus.busNumber != _selectedBusNumber) return false;
        }
        if (_selectedRoute != null) {
          final route = routes.firstWhere(
            (r) => r.id == schedule.routeId,
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
          if (!schedule.stopSchedules.any((s) => s.stopName == _selectedStop)) {
            return false;
          }
        }
        if (_selectedStatus != 'all') {
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
          if (bus.status != _selectedStatus) return false;
        }
        return true;
      }).toList();
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              CompositedTransformTarget(
                link: _layerLink,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.primary.withValues(alpha: 0.45)
                        : Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            "Search Filters",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedBusNumber != null ||
                              _selectedRoute != null ||
                              _selectedStop != null)
                            TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text(
                                "Reset",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterSelector(
                              label: 'Bus',
                              value: _selectedBusNumber,
                              placeholder: 'Bus',
                              icon: Icons.directions_bus_rounded,
                              isActive: _activeFilterType == 'bus',
                              onTap: () => _toggleFilter('bus'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFilterSelector(
                              label: 'Route',
                              value: _selectedRoute,
                              placeholder: 'Route',
                              icon: Icons.alt_route_rounded,
                              isActive: _activeFilterType == 'route',
                              onTap: () => _toggleFilter('route'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildFilterSelector(
                        label: 'Stop Name',
                        value: _selectedStop,
                        placeholder: 'Stop Name',
                        icon: Icons.location_on_rounded,
                        isActive: _activeFilterType == 'stop',
                        onTap: () => _toggleFilter('stop'),
                      ),

                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusFilterButton('all', 'All'),
                            const SizedBox(width: 8),
                            _buildStatusFilterButton('on-time', 'On Time'),
                            const SizedBox(width: 8),
                            _buildStatusFilterButton('delayed', 'Delayed'),
                            const SizedBox(width: 8),
                            _buildStatusFilterButton(
                              'not-running',
                              'Not Running',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: schedulesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Center(
                    child: Text(
                      "Unable to load schedules",
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
                            );
                          }).toList(),
                        ),
                      );
                    } else {
                      final shiftSchedules = filterSchedules(
                        allSchedules,
                        null,
                      );
                      return _buildScheduleList(
                        shiftSchedules,
                        'Current',
                        buses,
                        routes,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        if (_activeFilterType != null)
          _buildAbsoluteOptionsExpansion(
            allBusNumbersList,
            allRoutesList,
            allStopsList,
          ),
      ],
    );
  }

  Widget _buildScheduleList(
    List<ScheduleModel> schedules,
    String shift,
    List<BusModel> buses,
    List<RouteModel> routes,
  ) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              shift == '1st' ? Icons.wb_sunny : Icons.nights_stay,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedBusNumber != null ||
                      _selectedRoute != null ||
                      _selectedStop != null
                  ? 'No schedules match your filters'
                  : 'No $shift shift schedules available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: PageStorageKey('schedule_list_$shift'),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final route = routes.firstWhere(
          (r) => r.id == schedule.routeId,
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
        final bus = buses.firstWhere(
          (b) => b.id == schedule.busId,
          orElse: () => BusModel(
            id: '',
            busNumber: 'Unknown Bus',
            driverId: '',
            collegeId: '',
            createdAt: DateTime.now(),
          ),
        );

        return Card(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: PageStorageKey('schedule_tile_${schedule.id}_v2'),
              initiallyExpanded: false,
              maintainState: false,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4), // Cyan color from image
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  bus.busNumber.replaceAll('Bus ', ''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              title: Text(
                'Bus ${bus.busNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${route.startPoint.name}-${route.endPoint.name}'
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(bus.status, bus.delay),
                  ],
                ),
              ),
              trailing: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              children: [
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_filled_rounded,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Schedule Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (widget.onBusSelected != null)
                      InkWell(
                        onTap: () => widget.onBusSelected!(bus),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.turkishBlue.withValues(alpha: 0.15)
                                : Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Color(0xFF00BCD4),
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Track",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00BCD4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Stop',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Arrival',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Depart',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    ...schedule.stopSchedules.map((stopSchedule) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              stopSchedule.stopName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              stopSchedule.arrivalTime,
                              style: const TextStyle(
                                color: Color(0xFF00BCD4),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              stopSchedule.departureTime,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSelector({
    required String label,
    required String? value,
    required String placeholder,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? primaryColor
                : isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : primaryColor.withValues(alpha: 0.2),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? primaryColor
                  : isDarkMode
                  ? Colors.white.withValues(alpha: 0.5)
                  : primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value ?? placeholder,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: value != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              isActive
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: primaryColor.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsoluteOptionsExpansion(
    List<String> buses,
    List<String> routes,
    List<String> stops,
  ) {
    List<String?> items = [];
    String title = '';
    String? currentVal;
    ValueChanged<String?> onSelect;

    if (_activeFilterType == 'bus') {
      title = 'Select Bus';
      items = [null, ...buses];
      currentVal = _selectedBusNumber;
      onSelect = (val) => setState(() {
        _selectedBusNumber = val;
        _activeFilterType = null;
      });
    } else if (_activeFilterType == 'route') {
      title = 'Select Route';
      items = [null, ...routes];
      currentVal = _selectedRoute;
      onSelect = (val) => setState(() {
        _selectedRoute = val;
        _activeFilterType = null;
      });
    } else {
      title = 'Select Stop';
      items = [null, ...stops];
      currentVal = _selectedStop;
      onSelect = (val) => setState(() {
        _selectedStop = val;
        _activeFilterType = null;
      });
    }

    return CompositedTransformFollower(
      link: _layerLink,
      showWhenUnlinked: false,
      offset: const Offset(0, 50),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _activeFilterType = null),
                    icon: const Icon(Icons.close, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item == currentVal;
                    return _buildOptionItem(
                      label:
                          item ??
                          (title.contains('Stop') ? 'All Stops' : 'All'),
                      isSelected: isSelected,
                      onTap: () => onSelect(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterButton(String status, String label) {
    final isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).primaryColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, int delay) {
    Color color;
    String label;

    switch (status) {
      case 'on-time':
        color = const Color(0xFF4CAF50);
        label = 'On Time';
        break;
      case 'delayed':
        color = const Color(0xFFE67E22);
        label = 'Delayed';
        break;
      case 'not-running':
        color = const Color(0xFFE74C3C);
        label = 'Not Running';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.9),
            ),
          ),
          if (status == 'delayed' && delay > 0) ...[
            const SizedBox(width: 4),
            Text(
              '+$delay m',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
