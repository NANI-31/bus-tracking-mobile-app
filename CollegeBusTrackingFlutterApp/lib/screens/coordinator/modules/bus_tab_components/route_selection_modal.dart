import 'package:flutter/material.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/utils/constants.dart';

class RouteSelectionModal extends StatefulWidget {
  final List<RouteModel> routes;
  final List<BusModel> buses;
  final String busNumberToAssign;

  const RouteSelectionModal({
    super.key,
    required this.routes,
    required this.buses,
    required this.busNumberToAssign,
  });

  @override
  State<RouteSelectionModal> createState() => _RouteSelectionModalState();
}

class _RouteSelectionModalState extends State<RouteSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  RouteModel? _selectedRoute;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  BusModel? _findBusWithRoute(String routeId) {
    try {
      return widget.buses.firstWhere(
        (b) =>
            b.routeId == routeId &&
            b.busNumber != widget.busNumberToAssign &&
            b.isActive &&
            b.assignmentStatus !=
                'unassigned', // Only consider active assignments
      );
    } catch (_) {
      return null;
    }
  }

  void _handleRouteSelection(RouteModel route) {
    // Check for conflicts
    final conflictingBus = _findBusWithRoute(route.id);

    if (conflictingBus != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Route Already Assigned'),
          content: Text(
            'Route "${route.routeName}" is already assigned to Bus ${conflictingBus.busNumber}. \n\nDo you want to proceed anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _selectedRoute = route;
                });
              },
              child: const Text('Assign Anyway'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _selectedRoute = route;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRoutes = widget.routes.where((r) {
      final query = _searchQuery.toLowerCase();
      return r.routeName.toLowerCase().contains(query);
    }).toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Select Route',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search routes...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.2),
                  ),
                ),
              ),

              // Routes List
              Expanded(
                child: filteredRoutes.isEmpty
                    ? const Center(child: Text('No routes found'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredRoutes.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final route = filteredRoutes[index];
                          final isSelected = _selectedRoute?.id == route.id;
                          final conflictingBus = _findBusWithRoute(route.id);

                          return ListTile(
                            title: Text(
                              route.routeName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primary
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                              ),
                            ),
                            subtitle: conflictingBus != null
                                ? Text(
                                    'Assigned to Bus ${conflictingBus.busNumber}',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 12,
                                    ),
                                  )
                                : Text('${route.stopPoints.length} stops'),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                  )
                                : null,
                            tileColor: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : null,
                            onTap: () => _handleRouteSelection(route),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSizes.radiusLarge),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedRoute == null
                            ? null
                            : () => Navigator.pop(context, _selectedRoute),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Assign Route'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
