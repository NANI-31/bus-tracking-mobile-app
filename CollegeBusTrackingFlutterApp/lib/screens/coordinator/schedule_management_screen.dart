import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/schedule_model.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/app_drawer.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<ScheduleModel> _firstShiftSchedules = [];
  List<ScheduleModel> _secondShiftSchedules = [];
  List<RouteModel> _routes = [];
  List<BusModel> _buses = [];

  // Stream subscriptions
  StreamSubscription? _routesSubscription;
  StreamSubscription? _busesSubscription;
  StreamSubscription? _schedulesSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _routesSubscription?.cancel();
    _busesSubscription?.cancel();
    _schedulesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<DataService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;

    if (collegeId == null) return;

    await _routesSubscription?.cancel();
    _routesSubscription = firestoreService.getRoutesByCollege(collegeId).listen(
      (routes) {
        if (mounted) {
          setState(() => _routes = routes);
        }
      },
    );

    await _busesSubscription?.cancel();
    _busesSubscription = firestoreService.getBusesByCollege(collegeId).listen((
      buses,
    ) {
      if (mounted) {
        setState(() => _buses = buses);
      }
    });

    await _schedulesSubscription?.cancel();
    _schedulesSubscription = firestoreService
        .getSchedulesByCollege(collegeId)
        .listen((schedules) {
          if (mounted) {
            setState(() {
              _firstShiftSchedules = schedules
                  .where((s) => s.shift == '1st')
                  .toList();
              _secondShiftSchedules = schedules
                  .where((s) => s.shift == '2nd')
                  .toList();
            });
          }
        });
  }

  void _showCreateScheduleDialog(String shift) {
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
                  value: selectedRoute,
                  decoration: const InputDecoration(
                    labelText: 'Select Route',
                    border: OutlineInputBorder(),
                  ),
                  items: _routes
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
                  items: _buses
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
                          '${selectedRoute!.startPoint} → ${selectedRoute!.endPoint}'
                              .text
                              .size(14)
                              .make(),
                          if (selectedRoute!.stopPoints.isNotEmpty)
                            VStack([
                              4.heightBox,
                              'Stops: ${selectedRoute!.stopPoints.join(' → ')}'
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
                          final authService = Provider.of<AuthService>(
                            context,
                            listen: false,
                          );
                          final firestoreService = Provider.of<DataService>(
                            context,
                            listen: false,
                          );

                          // Create stop schedules without specific times
                          final stopSchedules = <StopSchedule>[];
                          final allStops = [
                            selectedRoute!.startPoint,
                            ...selectedRoute!.stopPoints,
                            selectedRoute!.endPoint,
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
                            collegeId: authService.currentUserModel!.collegeId,
                            createdBy: authService.currentUserModel!.id,
                            createdAt: DateTime.now(),
                          );

                          await firestoreService.createSchedule(schedule);
                          if (!mounted) return;
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: AppDrawer(
        user: Provider.of<AuthService>(context).currentUserModel,
        authService: Provider.of<AuthService>(context),
      ),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScheduleTab('1st', _firstShiftSchedules),
          _buildScheduleTab('2nd', _secondShiftSchedules),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentShift = _tabController.index == 0 ? '1st' : '2nd';
          _showCreateScheduleDialog(currentShift);
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Create Timetable'),
      ),
    );
  }

  Widget _buildScheduleTab(String shift, List<ScheduleModel> schedules) {
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
        final route = _routes.firstWhere(
          (r) => r.id == schedule.routeId,
          orElse: () => RouteModel(
            id: '',
            routeName: 'Unknown Route',
            routeType: '',
            startPoint: '',
            endPoint: '',
            stopPoints: const [],
            collegeId: '',
            createdBy: '',
            isActive: false,
            createdAt: DateTime.now(),
          ),
        );
        final bus = _buses.firstWhere(
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
              '${route.startPoint} → ${route.endPoint}'.text.make(),
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
                    final firestoreService = Provider.of<DataService>(
                      context,
                      listen: false,
                    );
                    await firestoreService.deleteSchedule(schedule.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Timetable deleted successfully'),
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
