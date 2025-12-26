import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/utils/constants.dart';

class BusRouteSelectors extends StatelessWidget {
  final String? selectedBusNumber;
  final RouteModel? selectedRoute;
  final List<String> busNumbers;
  final List<RouteModel> routes;
  final Function(String?) onBusNumberChanged;
  final Function(RouteModel?) onRouteChanged;
  final VoidCallback? onAssign;

  const BusRouteSelectors({
    super.key,
    required this.selectedBusNumber,
    required this.selectedRoute,
    required this.busNumbers,
    required this.routes,
    required this.onBusNumberChanged,
    required this.onRouteChanged,
    this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final canAssign = selectedRoute != null && selectedBusNumber != null;

    return VStack([
      DropdownButtonFormField<String>(
        isExpanded: true,
        value: selectedBusNumber,
        items: busNumbers
            .map(
              (busNumber) => DropdownMenuItem(
                value: busNumber,
                child: busNumber.text.make(),
              ),
            )
            .toList(),
        onChanged: onBusNumberChanged,
        decoration: const InputDecoration(
          labelText: 'Select Bus Number',
          border: OutlineInputBorder(),
          hintText: 'Choose your bus number',
        ),
      ),
      AppSizes.paddingMedium.heightBox,
      DropdownButtonFormField<RouteModel>(
        isExpanded: true,
        value: selectedRoute,
        items: routes
            .map(
              (route) => DropdownMenuItem(
                value: route,
                child: '${route.routeName} (${route.routeType.toUpperCase()})'
                    .text
                    .make(),
              ),
            )
            .toList(),
        onChanged: onRouteChanged,
        decoration: const InputDecoration(
          labelText: 'Select Route',
          border: OutlineInputBorder(),
          hintText: 'Choose your route',
        ),
      ),
      AppSizes.paddingLarge.heightBox,
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: canAssign ? onAssign : null,
          icon: const Icon(Icons.directions_bus),
          label: const Text('Assign Bus'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    ]);
  }
}
