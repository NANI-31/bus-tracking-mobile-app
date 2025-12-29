import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/maps/live_bus_map.dart';
import 'package:velocity_x/velocity_x.dart';

class StudentMapTab extends StatefulWidget {
  final LatLng? currentLocation;
  final List<BusModel> buses;
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
  final String? mapStyle;

  const StudentMapTab({
    super.key,
    required this.currentLocation,
    required this.buses,
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
    this.mapStyle,
  });

  @override
  State<StudentMapTab> createState() => _StudentMapTabState();
}

class _StudentMapTabState extends State<StudentMapTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VStack([
      // Location display
      VxBox(
            child: HStack([
              Icon(
                Icons.location_on,
                color: widget.currentLocation != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              AppSizes.paddingSmall.widthBox,
              (widget.currentLocation != null
                      ? 'Your Location: ${widget.currentLocation!.latitude.toStringAsFixed(4)}, ${widget.currentLocation!.longitude.toStringAsFixed(4)}'
                      : 'Acquiring location...')
                  .text
                  .medium
                  .color(
                    widget.currentLocation != null
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
            widget.currentLocation != null
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
                  value: widget.selectedRouteType,
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
                  onChanged: widget.onRouteTypeSelected,
                ).expand(),

                AppSizes.paddingSmall.widthBox,

                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: widget.allBusNumbers.contains(widget.selectedBusNumber)
                      ? widget.selectedBusNumber
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
                    ...widget.allBusNumbers.map(
                      (busNumber) => DropdownMenuItem(
                        value: busNumber,
                        child: Text(busNumber),
                      ),
                    ),
                  ],
                  onChanged: widget.onBusNumberSelected,
                ).expand(),
              ]),

              AppSizes.paddingSmall.heightBox,

              if (widget.selectedBusNumber != null ||
                  widget.selectedRouteType != null) ...[
                AppSizes.paddingSmall.heightBox,
                HStack([
                  '${widget.filteredBusesCount} bus(es) found'.text
                      .size(12)
                      .color(
                        Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      )
                      .make(),
                  TextButton.icon(
                    onPressed: widget.onClearFilters,
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
      (widget.currentLocation != null
              ? LiveBusMap(
                  buses: widget.buses,
                  selectedBus: widget.selectedBus,
                  onMapCreated: widget.onMapCreated,
                  mapStyle: widget.mapStyle,
                  onBusTap: (bus) => widget.onBusSelected(bus),
                )
              : const Center(child: CircularProgressIndicator()))
          .expand(flex: 3),

      // Selected bus info
      if (widget.selectedBus != null)
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
                    'Bus ${widget.selectedBus!.busNumber}'.text
                        .size(18)
                        .bold
                        .make(),
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
                    onPressed: () => widget.onBusSelected(null),
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
