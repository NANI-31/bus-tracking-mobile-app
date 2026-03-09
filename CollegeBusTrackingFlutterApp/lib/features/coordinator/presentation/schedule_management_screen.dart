import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/schedule/domain/schedule_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/college/application/college_provider.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/features/coordinator/presentation/edit_schedule_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
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
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: 320,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create $shift Shift Timetable',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<RouteModel>(
                          initialValue: selectedRoute,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Route',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
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
                          decoration: const InputDecoration(
                            labelText: 'Select Bus',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
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
                          decoration: const InputDecoration(
                            labelText: 'Trip Type',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
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
                        const SizedBox(height: 16),
                        if (selectedRoute != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Route Information:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${selectedRoute!.startPoint.name} → ${selectedRoute!.endPoint.name}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (selectedRoute!.stopPoints.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stops: ${selectedRoute!.stopPoints.map((s) => s.name).join(' → ')}',
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'Type: ${selectedRoute!.routeType.toUpperCase()}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Note:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'This will create a timetable showing which bus goes to which stops. No specific times are needed.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed:
                                  selectedRoute != null && selectedBus != null
                                  ? () async {
                                      final user = ref.read(
                                        currentUserProvider,
                                      );
                                      final api = ref.read(apiServiceProvider);

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
                                        await api.createSchedule(schedule);
                                        ref.invalidate(
                                          collegeSchedulesProvider(
                                            user.collegeId,
                                          ),
                                        );
                                        if (!context.mounted) return;
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '$shift shift timetable created successfully',
                                            ),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.toString().replaceAll(
                                                'Exception: ',
                                                '',
                                              ),
                                            ),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.error,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
        appBar: AppBar(
          title: const Text('Manage Schedules'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          bottom: hasMultipleShifts
              ? TabBar(
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.7),
                  indicatorColor: Theme.of(context).colorScheme.onPrimary,
                  tabs: tabs as List<Widget>,
                )
              : null,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by bus number or route...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
            ),
            Expanded(
              child: schedulesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (schedules) {
                  final routes = routesAsync.value ?? [];
                  final buses = busesAsync.value ?? [];

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
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton.extended(
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
                  routes: routesAsync.value ?? [],
                  buses: busesAsync.value ?? [],
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              label: const Text('Add Timetable'),
              icon: const Icon(Icons.add),
            );
          },
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
    // Apply search filter
    final filteredSchedules = schedules.where((schedule) {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              shift == '1st' ? Icons.wb_sunny : Icons.nights_stay,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
            AppSizes.paddingMedium.heightBox,
            (_searchQuery.isEmpty
                    ? 'No $shift shift timetables created yet'
                    : 'No matching timetables found')
                .text
                .size(18)
                .center
                .color(
                  Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                )
                .make(),
            AppSizes.paddingSmall.heightBox,
            (_searchQuery.isEmpty
                    ? 'Tap the + button to create a timetable'
                    : 'Try a different search term')
                .text
                .size(14)
                .center
                .color(
                  Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                )
                .make(),
          ],
        ),
      );
    }

    return ListView.builder(
      key: PageStorageKey('mgmt_schedule_list_${shift}_$_searchQuery'),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: filteredSchedules.length,
      itemBuilder: (context, index) {
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
          );

          return Card(
            margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      shift == '1st' ? Icons.wb_sunny : Icons.nights_stay,
                      color: Colors.white,
                    ),
                  ),
                  title: 'Bus ${bus.busNumber}'.text.semiBold.make(),
                  subtitle: 'Route: ${route.routeName}'.text.make(),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedScheduleIds.remove(schedule.id);
                      } else {
                        _expandedScheduleIds.add(schedule.id);
                      }
                    });
                  },
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Edit'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.delete, size: 18),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(color: AppColors.error),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
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
                                    final api = ref.read(apiServiceProvider);
                                    await api.deleteSchedule(schedule.id);
                                    ref.invalidate(
                                      collegeSchedulesProvider(
                                        schedule.collegeId,
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Timetable deleted successfully',
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        'Bus Stops on this Route:'.text
                            .size(16)
                            .semiBold
                            .make(),
                        AppSizes.paddingSmall.heightBox,
                        Column(
                          children: schedule.stopSchedules.asMap().entries.map((
                            entry,
                          ) {
                            final index = entry.key;
                            final stopSchedule = entry.value;
                            final isStart = index == 0;
                            final isEnd =
                                index == schedule.stopSchedules.length - 1;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    (isStart
                                            ? AppColors.secondary
                                            : isEnd
                                            ? AppColors.error
                                            : AppColors.primary)
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isStart
                                      ? AppColors.secondary
                                      : isEnd
                                      ? AppColors.error
                                      : AppColors.primary,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isStart
                                        ? Icons.play_arrow
                                        : isEnd
                                        ? Icons.stop
                                        : Icons.location_on,
                                    color: isStart
                                        ? AppColors.secondary
                                        : isEnd
                                        ? AppColors.error
                                        : AppColors.primary,
                                  ),
                                  12.widthBox,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        stopSchedule.stopName.text
                                            .size(16)
                                            .semiBold
                                            .make(),
                                        (isStart
                                                ? 'Starting Point'
                                                : isEnd
                                                ? 'End Point'
                                                : 'Bus Stop')
                                            .text
                                            .size(12)
                                            .color(
                                              isStart
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.secondary
                                                  : isEnd
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.error
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.tertiary,
                                            )
                                            .make(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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
