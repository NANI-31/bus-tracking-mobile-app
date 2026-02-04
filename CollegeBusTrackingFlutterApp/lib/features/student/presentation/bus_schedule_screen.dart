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
  String _selectedTripType = 'pickup'; // 'pickup' or 'drop'
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
      _activeFilterType = null;
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
                          ).colorScheme.onPrimary.withOpacity(0.7),
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
                          ).colorScheme.onPrimary.withOpacity(0.7),
                          indicatorColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          tabs: tabs as List<Widget>,
                        )
                      : null,
                ),
              ),
        body: _buildMainScheduleUI(
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

        // Trip Type filter
        if (schedule.tripType.toLowerCase() != _selectedTripType.toLowerCase())
          return false;

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
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            "Search Filters",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
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
                        icon: Icons.location_on_rounded,
                        isActive: _activeFilterType == 'stop',
                        onTap: () => _toggleFilter('stop'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            "Trip Type:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          ChoiceChip(
                            label: const Text("Pickup"),
                            selected: _selectedTripType == 'pickup',
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedTripType = 'pickup');
                              }
                            },
                          ),
                          const SizedBox(width: 8.0),
                          ChoiceChip(
                            label: const Text("Drop"),
                            selected: _selectedTripType == 'drop',
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedTripType = 'drop');
                              }
                            },
                          ),
                        ],
                      ),
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
          margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
          child: ExpansionTile(
            key: PageStorageKey('schedule_tile_${schedule.id}_v2'),
            initiallyExpanded: false,
            maintainState: false,
            dense: false,
            showTrailingIcon: true,
            enabled: true,
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                bus.busNumber.replaceAll('Bus ', ''),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.departure_board_rounded,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bus ${bus.busNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildTripTypeBadge(context, schedule.tripType),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8, left: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route: ${route.routeName}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          '${route.startPoint.name} → ${route.endPoint.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bus Stops & Timing:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },
                      children: [
                        const TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Stop',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Arrival',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Departure',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...schedule.stopSchedules.map((stopSchedule) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(stopSchedule.stopName),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  stopSchedule.arrivalTime,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  stopSchedule.departureTime,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                    if (widget.onBusSelected != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => widget.onBusSelected!(bus),
                          icon: const Icon(Icons.location_on, size: 14),
                          label: const Text(
                            'Track Bus',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            foregroundColor: Theme.of(context).primaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripTypeBadge(BuildContext context, String tripType) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (tripType == 'pickup') {
      backgroundColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green;
      icon = Icons.arrow_upward_rounded;
    } else {
      backgroundColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
      icon = Icons.arrow_downward_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4.0),
          Text(
            tripType.isNotEmpty
                ? '${tripType[0].toUpperCase()}${tripType.substring(1)}'
                : '',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector({
    required String label,
    required String? value,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColor.withOpacity(0.1),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColor.withOpacity(0.7),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(
                        context,
                      ).primaryColor.withOpacity(isActive ? 1.0 : 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value ?? 'Select',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isActive
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).primaryColor,
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
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
              ? Theme.of(context).primaryColor.withOpacity(0.1)
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
}
