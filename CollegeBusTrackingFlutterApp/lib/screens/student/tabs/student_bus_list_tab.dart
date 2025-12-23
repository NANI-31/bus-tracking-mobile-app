import 'package:flutter/material.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/utils/constants.dart';

class StudentBusListTab extends StatelessWidget {
  final List<BusModel> filteredBuses;
  final List<RouteModel> routes;
  final BusModel? selectedBus;
  final Function(BusModel) onBusSelected;

  const StudentBusListTab({
    super.key,
    required this.filteredBuses,
    required this.routes,
    required this.selectedBus,
    required this.onBusSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (filteredBuses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppSizes.paddingMedium),
            Text(
              'No buses found',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: filteredBuses.length,
      itemBuilder: (context, index) {
        final bus = filteredBuses[index];
        final isSelected = selectedBus?.id == bus.id;

        final route = routes.firstWhere(
          (r) => r.id == bus.routeId,
          orElse: () => RouteModel(
            id: '',
            routeName: 'Unknown Route',
            routeType: 'pickup',
            startPoint: 'N/A',
            endPoint: 'N/A',
            stopPoints: [],
            collegeId: '',
            createdBy: '',
            isActive: false,
            createdAt: DateTime.now(),
          ),
        );

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.directions_bus,
                color: isSelected ? AppColors.onPrimary : AppColors.primary,
              ),
            ),
            title: Text(
              'Bus ${bus.busNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route.routeName),
                Text(
                  '${route.startPoint} → ${route.endPoint}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => onBusSelected(bus),
          ),
        );
      },
    );
  }
}
