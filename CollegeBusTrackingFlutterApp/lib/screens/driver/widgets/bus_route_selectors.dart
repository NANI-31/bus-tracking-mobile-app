import 'package:flutter/material.dart';
import 'package:collegebus/l10n/driver/app_localizations.dart';
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
        decoration: InputDecoration(
          labelText: DriverLocalizations.of(context)!.selectBusNumberLabel,
          border: const OutlineInputBorder(),
          hintText: DriverLocalizations.of(context)!.selectBusNumberHint,
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
        decoration: InputDecoration(
          labelText: DriverLocalizations.of(context)!.selectRouteLabel,
          border: const OutlineInputBorder(),
          hintText: DriverLocalizations.of(context)!.selectRouteHint,
        ),
      ),
      AppSizes.paddingLarge.heightBox,
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: canAssign ? onAssign : null,
          icon: const Icon(Icons.directions_bus),
          label: Text(DriverLocalizations.of(context)!.assignBusButton),
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
