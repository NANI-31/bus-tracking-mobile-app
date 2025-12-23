import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/utils/constants.dart';

class StudentMapTab extends StatelessWidget {
  final LatLng? currentLocation;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final BusModel? selectedBus;
  final String? selectedRouteType;
  final String? selectedStop;
  final String? selectedBusNumber;
  final List<String> allStops;
  final List<String> allBusNumbers;
  final int filteredBusesCount;
  final Function(GoogleMapController) onMapCreated;
  final Function(String?) onRouteTypeSelected;
  final Function(String?) onStopSelected;
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
    required this.selectedStop,
    required this.selectedBusNumber,
    required this.allStops,
    required this.allBusNumbers,
    required this.filteredBusesCount,
    required this.onMapCreated,
    required this.onRouteTypeSelected,
    required this.onStopSelected,
    required this.onBusNumberSelected,
    required this.onClearFilters,
    required this.onBusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Location display
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          color: currentLocation != null
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: currentLocation != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: Text(
                  currentLocation != null
                      ? 'Your Location: ${currentLocation!.latitude.toStringAsFixed(4)}, ${currentLocation!.longitude.toStringAsFixed(4)}'
                      : 'Acquiring location...',
                  style: TextStyle(
                    color: currentLocation != null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filter Controls
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
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
                        DropdownMenuItem(
                          value: 'pickup',
                          child: Text('Pickup'),
                        ),
                        DropdownMenuItem(value: 'drop', child: Text('Drop')),
                      ],
                      onChanged: onRouteTypeSelected,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: allStops.contains(selectedStop)
                          ? selectedStop
                          : null,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: const InputDecoration(
                        labelText: 'Bus Stop',
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
                        ...allStops.map(
                          (stop) =>
                              DropdownMenuItem(value: stop, child: Text(stop)),
                        ),
                      ],
                      onChanged: onStopSelected,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
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
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  if (selectedStop != null ||
                      selectedBusNumber != null ||
                      selectedRouteType != null)
                    ElevatedButton.icon(
                      onPressed: onClearFilters,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSecondary,
                      ),
                    ),
                ],
              ),
              if (selectedStop != null ||
                  selectedBusNumber != null ||
                  selectedRouteType != null) ...[
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  '$filteredBusesCount bus(es) found',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Map
        Expanded(
          flex: 3,
          child: currentLocation != null
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
              : const Center(child: CircularProgressIndicator()),
        ),

        // Selected bus info
        if (selectedBus != null)
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusLarge),
                topRight: Radius.circular(AppSizes.radiusLarge),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Icon(
                        Icons.directions_bus,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bus ${selectedBus!.busNumber}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Note: We can expand this later with more details if needed
                          Text(
                            'Selected Bus',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => onBusSelected(null),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
