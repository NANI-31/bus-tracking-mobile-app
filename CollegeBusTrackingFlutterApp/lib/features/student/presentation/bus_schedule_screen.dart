import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/features/schedule/domain/schedule_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/shared/widgets/app_drawer.dart';
import 'package:velocity_x/velocity_x.dart';

class BusScheduleScreen extends ConsumerStatefulWidget {
  final bool isTab;
  const BusScheduleScreen({super.key, this.isTab = false});

  @override
  ConsumerState<BusScheduleScreen> createState() => _BusScheduleScreenState();
}

class _BusScheduleScreenState extends ConsumerState<BusScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter variables
  String? _selectedBusNumber;
  String? _selectedRoute;
  String? _selectedStop;

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

  void _clearFilters() {
    setState(() {
      _selectedBusNumber = null;
      _selectedRoute = null;
      _selectedStop = null;
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

    return schedulesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (allSchedules) => busesAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) =>
            Scaffold(body: Center(child: Text('Error: $err'))),
        data: (buses) => routesAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, stack) =>
              Scaffold(body: Center(child: Text('Error: $err'))),
          data: (routes) {
            // Helper for all bus numbers
            final allBusNumbersList =
                buses.map((b) => b.busNumber).toSet().toList()..sort();
            // Helper for all routes
            final allRoutesList =
                routes.map((r) => r.routeName).toSet().toList()..sort();
            // Helper for all stops
            final stopsSet = <String>{};
            for (final route in routes) {
              stopsSet.add(route.startPoint.name);
              stopsSet.add(route.endPoint.name);
              stopsSet.addAll(route.stopPoints.map((s) => s.name));
            }
            final allStopsList = stopsSet.toList()..sort();

            // Apply filters
            List<ScheduleModel> filterSchedules(List<ScheduleModel> schedules) {
              return schedules.where((schedule) {
                // Bus filter
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
                // Route filter
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
                // Stop filter
                if (_selectedStop != null) {
                  if (!schedule.stopSchedules.any(
                    (s) => s.stopName == _selectedStop,
                  )) {
                    return false;
                  }
                }
                return true;
              }).toList();
            }

            final firstShift = filterSchedules(
              allSchedules.where((s) => s.shift == '1st').toList(),
            );
            final secondShift = filterSchedules(
              allSchedules.where((s) => s.shift == '2nd').toList(),
            );

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              drawer: widget.isTab ? null : AppDrawer(user: user),
              appBar: widget.isTab
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(kTextTabBarHeight),
                      child: Material(
                        color: Theme.of(context).primaryColor,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Theme.of(context).colorScheme.onPrimary,
                          unselectedLabelColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.7),
                          indicatorColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          tabs: const [
                            Tab(text: '1st Shift', icon: Icon(Icons.wb_sunny)),
                            Tab(
                              text: '2nd Shift',
                              icon: Icon(Icons.nights_stay),
                            ),
                          ],
                        ),
                      ),
                    )
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(
                        kToolbarHeight + kTextTabBarHeight,
                      ),
                      child: AppBar(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        title: const Text('Bus Schedule'),
                        bottom: TabBar(
                          controller: _tabController,
                          labelColor: Theme.of(context).colorScheme.onPrimary,
                          unselectedLabelColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.7),
                          indicatorColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          tabs: const [
                            Tab(text: '1st Shift', icon: Icon(Icons.wb_sunny)),
                            Tab(
                              text: '2nd Shift',
                              icon: Icon(Icons.nights_stay),
                            ),
                          ],
                        ),
                      ),
                    ),
              body: VStack([
                // Filter Panel
                VxBox(
                      child: VStack([
                        HStack([
                          DropdownButtonFormField<String>(
                            initialValue: _selectedBusNumber,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Bus Number',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Buses'),
                              ),
                              ...allBusNumbersList.map(
                                (busNumber) => DropdownMenuItem(
                                  value: busNumber,
                                  child: Text(busNumber),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedBusNumber = value),
                          ).expand(),
                          AppSizes.paddingSmall.widthBox,
                          DropdownButtonFormField<String>(
                            initialValue: _selectedRoute,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Route',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Routes'),
                              ),
                              ...allRoutesList.map(
                                (route) => DropdownMenuItem(
                                  value: route,
                                  child: Text(route),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedRoute = value),
                          ).expand(),
                        ]),
                        AppSizes.paddingSmall.heightBox,
                        HStack([
                          DropdownButtonFormField<String>(
                            initialValue: _selectedStop,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Stop',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Stops'),
                              ),
                              ...allStopsList.map(
                                (stop) => DropdownMenuItem(
                                  value: stop,
                                  child: Text(stop),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedStop = value),
                          ).expand(),
                          if (_selectedBusNumber != null ||
                              _selectedRoute != null ||
                              _selectedStop != null) ...[
                            AppSizes.paddingSmall.widthBox,
                            IconButton(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear),
                            ),
                          ],
                        ]),
                      ]),
                    )
                    .padding(const EdgeInsets.all(AppSizes.paddingMedium))
                    .color(Theme.of(context).colorScheme.surface)
                    .make(),

                // Schedule Content
                TabBarView(
                  controller: _tabController,
                  children: [
                    _buildScheduleList(firstShift, '1st', buses, routes),
                    _buildScheduleList(secondShift, '2nd', buses, routes),
                  ],
                ).expand(),
              ]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScheduleList(
    List<ScheduleModel> schedules,
    String shift,
    List<BusModel> buses,
    List<RouteModel> routes,
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
          (_selectedBusNumber != null ||
                      _selectedRoute != null ||
                      _selectedStop != null
                  ? 'No schedules match your filters'
                  : 'No $shift shift schedules available')
              .text
              .size(18)
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
            title: Text(
              'Bus ${bus.busNumber}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: VStack([
              'Route: ${route.routeName}'.text.make(),
              '${route.startPoint.name} → ${route.endPoint.name}'.text
                  .size(12)
                  .color(
                    Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  )
                  .make(),
            ]),
            trailing: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.location_on, size: 16),
              label: const Text('Track Live'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            children: [
              VStack([
                'Stop Timings:'.text.semiBold.size(16).make(),
                AppSizes.paddingSmall.heightBox,
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
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Arrival',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Departure',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ]).p(AppSizes.paddingMedium),
            ],
          ),
        );
      },
    );
  }
}
