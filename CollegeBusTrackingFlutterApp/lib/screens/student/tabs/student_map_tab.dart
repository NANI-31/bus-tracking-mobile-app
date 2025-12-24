import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:velocity_x/velocity_x.dart';

class StudentMapTab extends StatelessWidget {
  final LatLng? currentLocation;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final BusModel? selectedBus;
  final String? selectedRouteType;
  final String? selectedBusNumber;
  final List<String> allBusNumbers;
  final int filteredBusesCount;
  final Function(GoogleMapController) onMapCreated;
  final Function(String?) onRouteTypeSelected;
  final Function(String?) onBusNumberSelected;
  final VoidCallback onClearFilters;
  final Function(BusModel?) onBusSelected;

  const StudentMapTab({
    super.key,
    required this.currentLocation,
    required this.markers,
    required this.polylines,
    required this.selectedBus,
    required this.selectedRouteType,
    required this.selectedBusNumber,
    required this.allBusNumbers,
    required this.filteredBusesCount,
    required this.onMapCreated,
    required this.onRouteTypeSelected,
    required this.onBusNumberSelected,
    required this.onClearFilters,
    required this.onBusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return VStack([
      // Location display
      VxBox(
            child: HStack([
              Icon(
                Icons.location_on,
                color: currentLocation != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              AppSizes.paddingSmall.widthBox,
              (currentLocation != null
                      ? 'Your Location: ${currentLocation!.latitude.toStringAsFixed(4)}, ${currentLocation!.longitude.toStringAsFixed(4)}'
                      : 'Acquiring location...')
                  .text
                  .medium
                  .color(
                    currentLocation != null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                  )
                  .make()
                  .expand(),
            ]),
          )
          .color(
            currentLocation != null
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
          )
          .make()
          .p(AppSizes.paddingMedium),
      // Filter Controls
      VxBox(
            child: VStack([
              HStack([
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedRouteType,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  decoration: const InputDecoration(
                    labelText: 'Route Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Types'),
                    ),
                    DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
                    DropdownMenuItem(value: 'drop', child: Text('Drop')),
                  ],
                  onChanged: onRouteTypeSelected,
                ).expand(),

                AppSizes.paddingSmall.widthBox,

                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: allBusNumbers.contains(selectedBusNumber)
                      ? selectedBusNumber
                      : null,
                  dropdownColor: Theme.of(context).colorScheme.surface,
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
                    ...allBusNumbers.map(
                      (busNumber) => DropdownMenuItem(
                        value: busNumber,
                        child: Text(busNumber),
                      ),
                    ),
                  ],
                  onChanged: onBusNumberSelected,
                ).expand(),
              ]),

              AppSizes.paddingSmall.heightBox,

              if (selectedBusNumber != null || selectedRouteType != null) ...[
                AppSizes.paddingSmall.heightBox,
                HStack([
                  '$filteredBusesCount bus(es) found'.text
                      .size(12)
                      .color(
                        Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      )
                      .make(),
                  TextButton.icon(
                    onPressed: onClearFilters,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear Filters'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ], alignment: MainAxisAlignment.spaceBetween),
              ],
            ]),
          )
          .color(Theme.of(context).colorScheme.surface)
          .make()
          .p(AppSizes.paddingMedium),

      // Map
      (currentLocation != null
              ? GoogleMap(
                  onMapCreated: onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: currentLocation!,
                    zoom: 14.0,
                  ),
                  markers: markers,
                  polylines: polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                )
              : const Center(child: CircularProgressIndicator()))
          .expand(flex: 3),

      // Selected bus info
      if (selectedBus != null)
        VxBox(
              child: VStack([
                HStack([
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(
                      Icons.directions_bus,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  AppSizes.paddingMedium.widthBox,
                  VStack([
                    'Bus ${selectedBus!.busNumber}'.text.size(18).bold.make(),
                    4.heightBox,
                    'Selected Bus'.text
                        .size(14)
                        .color(
                          Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        )
                        .make(),
                  ]).expand(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => onBusSelected(null),
                  ),
                ]),
              ]),
            )
            .color(Theme.of(context).colorScheme.surface)
            .customRounded(
              const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusLarge),
                topRight: Radius.circular(AppSizes.radiusLarge),
              ),
            )
            .make()
            .p(AppSizes.paddingMedium),
    ]);
  }
}
