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
import 'package:collegebus/shared/widgets/app_drawer.dart';

class ScheduleManagementScreen extends ConsumerStatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  ConsumerState<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState
    extends ConsumerState<ScheduleManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateScheduleDialog({
    required String shift,
    required List<RouteModel> routes,
    required List<BusModel> buses,
  }) {
    RouteModel? selectedRoute;
    BusModel? selectedBus;

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
                  initialValue: selectedBus,
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
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                          ).colorScheme.secondary.withValues(alpha: 0.1),
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
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final routesAsync = ref.watch(collegeRoutesProvider(collegeId));
    final busesAsync = ref.watch(collegeBusesStreamProvider(collegeId));
    final schedulesAsync = ref.watch(collegeSchedulesProvider(collegeId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: AppDrawer(user: user),
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onPrimary.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(text: '1st Shift', icon: Icon(Icons.wb_sunny)),
            Tab(text: '2nd Shift', icon: Icon(Icons.nights_stay)),
          ],
        ),
      ),
      body: schedulesAsync.when(
        data: (schedules) => routesAsync.when(
          data: (routes) => busesAsync.when(
            data: (buses) => TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleTab(
                  '1st',
                  schedules.where((s) => s.shift == '1st').toList(),
                  routes,
                  buses,
                ),
                _buildScheduleTab(
                  '2nd',
                  schedules.where((s) => s.shift == '2nd').toList(),
                  routes,
                  buses,
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: schedulesAsync.maybeWhen(
        data: (schedules) => routesAsync.maybeWhen(
          data: (routes) => busesAsync.maybeWhen(
            data: (buses) => FloatingActionButton.extended(
              onPressed: () {
                final currentShift = _tabController.index == 0 ? '1st' : '2nd';
                _showCreateScheduleDialog(
                  shift: currentShift,
                  routes: routes,
                  buses: buses,
                );
              },
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              icon: const Icon(Icons.add),
              label: const Text('Create Timetable'),
            ),
            orElse: () => null,
          ),
          orElse: () => null,
        ),
        orElse: () => null,
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
      return VStack(
        [
          Icon(
            shift == '1st' ? Icons.wb_sunny : Icons.nights_stay,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          AppSizes.paddingMedium.heightBox,
          'No $shift shift timetables created yet'.text
              .size(18)
              .color(
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              )
              .make(),
          AppSizes.paddingSmall.heightBox,
          'Tap the + button to create a timetable'.text
              .size(14)
              .color(
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              )
              .make(),
        ],
        alignment: MainAxisAlignment.center,
        crossAlignment: CrossAxisAlignment.center,
      ).centered();
    }

    return ListView.builder(
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
            subtitle: VStack([
              'Route: ${route.routeName}'.text.make(),
              'Type: ${route.routeType.toUpperCase()}'.text.make(),
              '${route.startPoint.name} → ${route.endPoint.name}'.text.make(),
            ]),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: HStack([
                    Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    8.widthBox,
                    'Delete'.text.make(),
                  ]),
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
              VStack([
                'Bus Stops on this Route:'.text.size(16).semiBold.make(),
                AppSizes.paddingSmall.heightBox,

                // Show route stops in order
                Column(
                  children: schedule.stopSchedules.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stopSchedule = entry.value;
                    final isStart = index == 0;
                    final isEnd = index == schedule.stopSchedules.length - 1;

                    return HBox(
                          child: HStack([
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
                            VStack([
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
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(
                                            context,
                                          ).colorScheme.tertiary,
                                  )
                                  .make(),
                            ]).expand(),
                          ]),
                        ).box
                        .padding(const EdgeInsets.all(12))
                        .color(
                          isStart
                              ? Theme.of(
                                  context,
                                ).colorScheme.secondary.withValues(alpha: 0.1)
                              : isEnd
                              ? Theme.of(
                                  context,
                                ).colorScheme.error.withValues(alpha: 0.1)
                              : Theme.of(
                                  context,
                                ).colorScheme.tertiary.withValues(alpha: 0.1),
                        )
                        .rounded
                        .border(
                          color: isStart
                              ? Theme.of(context).colorScheme.secondary
                              : isEnd
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.tertiary,
                        )
                        .make()
                        .pOnly(bottom: 8);
                  }).toList(),
                ),
              ]).p(AppSizes.paddingMedium),
            ],
          ),
        );
      },
    );
  }
}

// Helper widget for HStack inside the loop to make it cleaner
class HBox extends StatelessWidget {
  final Widget child;
  const HBox({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}
