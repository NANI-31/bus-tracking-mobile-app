import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/schedule/domain/schedule_model.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:velocity_x/velocity_x.dart';

class EditScheduleScreen extends ConsumerStatefulWidget {
  final ScheduleModel schedule;
  final List<BusModel> buses;
  final List<RouteModel> routes;

  const EditScheduleScreen({
    super.key,
    required this.schedule,
    required this.buses,
    required this.routes,
  });

  @override
  ConsumerState<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends ConsumerState<EditScheduleScreen> {
  late RouteModel? _selectedRoute;
  late BusModel? _selectedBus;
  bool _isLoading = false;
  final TextEditingController _routeSearchController = TextEditingController();
  String _routeSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.routes.firstWhere(
      (r) => r.id == widget.schedule.routeId,
      orElse: () => widget.routes.first,
    );
    _selectedBus = widget.buses.firstWhere(
      (b) => b.id == widget.schedule.busId,
      orElse: () => widget.buses.first,
    );

    _routeSearchController.addListener(() {
      setState(() {
        _routeSearchQuery = _routeSearchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _routeSearchController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_selectedRoute == null || _selectedBus == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(scheduleRepositoryProvider);

      // If route changed, we might want to update stop schedules too.
      // For now, we follow the logic in createSchedule which regenerates stops from the route.
      final stopSchedules = <StopSchedule>[];
      final allStops = [
        _selectedRoute!.startPoint.name,
        ..._selectedRoute!.stopPoints.map((s) => s.name),
        _selectedRoute!.endPoint.name,
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

      final updatedSchedule = widget.schedule.copyWith(
        routeId: _selectedRoute!.id,
        busId: _selectedBus!.id,
        stopSchedules: stopSchedules,
        updatedAt: DateTime.now(),
      );

      await repo.updateSchedule(widget.schedule.id, updatedSchedule.toMap());

      // Invalidate the provider to refresh the list
      ref.invalidate(collegeSchedulesProvider(widget.schedule.collegeId));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating schedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Schedule'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Update Route & Bus',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Shift: ${widget.schedule.shift} | Type: ${widget.schedule.tripType.toUpperCase()}',
              style: TextStyle(color: theme.disabledColor, fontSize: 14),
            ),
            const SizedBox(height: 24),

            const Text(
              'Select Route',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _routeSearchController,
              decoration: InputDecoration(
                hintText: 'Search routes...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                filled: true,
                fillColor: theme.dividerColor.withValues(alpha: 0.05),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: Builder(
                  builder: (context) {
                    final filteredRoutes = widget.routes.where((route) {
                      final nameMatch = route.routeName.toLowerCase().contains(
                        _routeSearchQuery,
                      );
                      final startMatch = route.startPoint.name
                          .toLowerCase()
                          .contains(_routeSearchQuery);
                      final endMatch = route.endPoint.name
                          .toLowerCase()
                          .contains(_routeSearchQuery);
                      return nameMatch || startMatch || endMatch;
                    }).toList();

                    if (filteredRoutes.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              color: theme.disabledColor,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            'No matching routes found'.text.center
                                .color(theme.disabledColor)
                                .make(),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: filteredRoutes.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                      itemBuilder: (context, index) {
                        final route = filteredRoutes[index];
                        final isSelected = _selectedRoute?.id == route.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedRoute = route),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            color: isSelected
                                ? theme.primaryColor.withValues(alpha: 0.05)
                                : null,
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSelected
                                      ? theme.primaryColor
                                      : theme.disabledColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      route.routeName.text.semiBold.make(),
                                      '${route.startPoint.name} → ${route.endPoint.name}'
                                          .text
                                          .size(12)
                                          .color(theme.disabledColor)
                                          .make(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bus Selection
            DropdownButtonFormField<BusModel>(
              initialValue: _selectedBus,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select Bus',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_bus_outlined),
              ),
              items: widget.buses
                  .map(
                    (bus) => DropdownMenuItem(
                      value: bus,
                      child: Text('Bus ${bus.busNumber}'),
                    ),
                  )
                  .toList(),
              onChanged: (bus) => setState(() => _selectedBus = bus),
            ),

            const SizedBox(height: 32),

            // Route Preview Info
            if (_selectedRoute != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.list_alt_outlined,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Route Stops Sequence',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Vertical stops list
                    _buildStopListItem(
                      context,
                      _selectedRoute!.startPoint.name,
                      true,
                      false,
                      _selectedRoute!.stopPoints.isEmpty,
                    ),

                    ...List.generate(_selectedRoute!.stopPoints.length, (
                      index,
                    ) {
                      return _buildStopListItem(
                        context,
                        _selectedRoute!.stopPoints[index].name,
                        false,
                        false,
                        false,
                      );
                    }),

                    _buildStopListItem(
                      context,
                      _selectedRoute!.endPoint.name,
                      false,
                      true,
                      false,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Discard Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopListItem(
    BuildContext context,
    String name,
    bool isStart,
    bool isEnd,
    bool isOnlyStop,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isStart || isEnd
                        ? theme.primaryColor
                        : Colors.transparent,
                    border: Border.all(color: theme.primaryColor, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isEnd)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isStart || isEnd
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
