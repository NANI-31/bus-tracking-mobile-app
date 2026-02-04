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

class ScheduleManagementScreen extends ConsumerStatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  ConsumerState<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState
    extends ConsumerState<ScheduleManagementScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
            return AlertDialog(
              title: 'Create $shift Shift Timetable'.text.make(),
              content: VStack([
                DropdownButtonFormField<RouteModel>(
                  initialValue: selectedRoute,
                  decoration: const InputDecoration(
                    labelText: 'Select Route',
                    border: OutlineInputBorder(),
                  ),
                  items: routes
                      .map(
                        (route) => DropdownMenuItem(
                          value: route,
                          child:
                              '${route.routeName} (${route.routeType.toUpperCase()})'
                                  .text
                                  .ellipsis
                                  .make(),
                        ),
                      )
                      .toList(),
                  onChanged: (route) {
                    setState(() {
                      selectedRoute = route;
                    });
                  },
                ),
                16.heightBox,
                DropdownButtonFormField<BusModel>(
                  value: selectedBus,
                  decoration: const InputDecoration(
                    labelText: 'Select Bus',
                    border: OutlineInputBorder(),
                  ),
                  items: buses
                      .map(
                        (bus) => DropdownMenuItem(
                          value: bus,
                          child: 'Bus ${bus.busNumber}'.text.ellipsis.make(),
                        ),
                      )
                      .toList(),
                  onChanged: (bus) => setState(() => selectedBus = bus),
                ),
                16.heightBox,
                DropdownButtonFormField<String>(
                  value: selectedTripType,
                  decoration: const InputDecoration(
                    labelText: 'Trip Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
                    DropdownMenuItem(value: 'drop', child: Text('Drop')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedTripType = val);
                  },
                ),
                16.heightBox,
                if (selectedRoute != null)
                  VStack([
                    VStack([
                          'Route Information:'.text.size(16).semiBold.make(),
                          8.heightBox,
                          '${selectedRoute!.startPoint.name} → ${selectedRoute!.endPoint.name}'
                              .text
                              .size(14)
                              .make(),
                          if (selectedRoute!.stopPoints.isNotEmpty)
                            VStack([
                              4.heightBox,
                              'Stops: ${selectedRoute!.stopPoints.map((s) => s.name).join(' → ')}'
                                  .text
                                  .size(12)
                                  .ellipsis
                                  .maxLines(2)
                                  .make(),
                            ]),
                          4.heightBox,
                          'Type: ${selectedRoute!.routeType.toUpperCase()}'.text
                              .size(12)
                              .make(),
                        ]).box
                        .padding(const EdgeInsets.all(12))
                        .color(
                          Theme.of(context).primaryColor.withOpacity(0.1),
                        )
                        .rounded
                        .make(),
                    16.heightBox,
                    VStack([
                          'Note:'.text.size(14).semiBold.make(),
                          4.heightBox,
                          'This will create a timetable showing which bus goes to which stops. No specific times are needed.'
                              .text
                              .size(12)
                              .make(),
                        ]).box
                        .padding(const EdgeInsets.all(12))
                        .color(
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.1),
                        )
                        .rounded
                        .make(),
                  ]),
              ]).scrollVertical(),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedRoute != null && selectedBus != null
                      ? () async {
                          final user = ref.read(currentUserProvider);
                          final api = ref.read(apiServiceProvider);

                          // Create stop schedules without specific times
                          final stopSchedules = <StopSchedule>[];
                          final allStops = [
                            selectedRoute!.startPoint.name,
                            ...selectedRoute!.stopPoints.map((s) => s.name),
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
                            id: DateTime.now().millisecondsSinceEpoch
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
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
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
                  ).colorScheme.onPrimary.withOpacity(0.7),
                  indicatorColor: Theme.of(context).colorScheme.onPrimary,
                  tabs: tabs as List<Widget>,
                )
              : null,
        ),
        body: schedulesAsync.when(
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
              return _buildScheduleTab('Morning', schedules, routes, buses);
            }
          },
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
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
              ).colorScheme.onSurface.withOpacity(0.6),
            ),
            AppSizes.paddingMedium.heightBox,
            'No $shift shift timetables created yet'.text
                .size(18)
                .center
                .color(
                  Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                )
                .make(),
            AppSizes.paddingSmall.heightBox,
            'Tap the + button to create a timetable'.text
                .size(14)
                .center
                .color(
                  Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                )
                .make(),
          ],
        ),
      );
    }

    return ListView.builder(
      key: PageStorageKey('mgmt_schedule_list_$shift'),
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
            stopPoints: const [],
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
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                shift == '1st' ? Icons.wb_sunny : Icons.nights_stay,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            title: 'Bus ${bus.busNumber}'.text.semiBold.make(),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                'Route: ${route.routeName}'.text.make(),
                'Type: ${route.routeType.toUpperCase()}'.text.make(),
                '${route.startPoint.name} → ${route.endPoint.name}'.text.make(),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      8.widthBox,
                      'Delete'.text.make(),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Timetable'),
                      content: const Text(
                        'Are you sure you want to delete this timetable?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
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
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Timetable deleted successfully'),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                      ),
                    );
                  }
                }
              },
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    'Bus Stops on this Route:'.text.size(16).semiBold.make(),
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
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondary
                                        : isEnd
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(
                                            context,
                                          ).colorScheme.tertiary)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isStart
                                  ? Theme.of(context).colorScheme.secondary
                                  : isEnd
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.tertiary,
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
                                    ? Theme.of(context).colorScheme.secondary
                                    : isEnd
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.tertiary,
                              ),
                              12.widthBox,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
      },
    );
  }
}





