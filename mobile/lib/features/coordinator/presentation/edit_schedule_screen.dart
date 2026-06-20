import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collegebus/core/constants/constants.dart';
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
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
              style: TextStyle(
                color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF111418),
              ),
              decoration: InputDecoration(
                hintText: 'Search routes...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.brightness == Brightness.dark
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
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? const Color(0xFF1E2732)
                    : Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? const Color(0xFF1E2732) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0x14000000),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.2 : 0.04,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                          mainAxisSize: MainAxisSize.min,
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
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : theme.dividerColor.withValues(alpha: 0.1),
                      ),
                      itemBuilder: (context, index) {
                        final route = filteredRoutes[index];
                        final isSelected = _selectedRoute?.id == route.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedRoute = route),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                            ),
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
                                      route.routeName.text.semiBold
                                          .color(theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF111418))
                                          .make(),
                                      '${route.startPoint.name} → ${route.endPoint.name}'
                                          .text
                                          .size(12)
                                          .color(theme.brightness == Brightness.dark ? Colors.white60 : Colors.grey.shade600)
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
              dropdownColor: theme.brightness == Brightness.dark
                  ? const Color(0xFF1E2732)
                  : Colors.white,
              style: TextStyle(
                color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF111418),
              ),
              decoration: InputDecoration(
                labelText: 'Select Bus',
                labelStyle: TextStyle(
                  color: theme.brightness == Brightness.dark ? Colors.white60 : Colors.grey.shade600,
                ),
                prefixIcon: const Icon(Icons.directions_bus_outlined, color: AppColors.primary),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? const Color(0xFF1E2732)
                    : Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.brightness == Brightness.dark
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
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 28),
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark ? const Color(0xFF1E2732) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0x14000000),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: theme.brightness == Brightness.dark ? 0.2 : 0.04,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nodeColor = isStart
        ? const Color(0xFF10B981)
        : isEnd
            ? const Color(0xFFEF4444)
            : const Color(0xFFF97316);
    return Stack(
      children: [
        // Left connector line
        Positioned(
          left: 15, // Centered inside the 32px width column
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
                    name.text
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
  }
}
