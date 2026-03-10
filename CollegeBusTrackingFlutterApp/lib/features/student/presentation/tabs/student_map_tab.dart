import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/shared/widgets/maps/live_bus_map.dart';
import 'package:velocity_x/velocity_x.dart';

class StudentMapTab extends ConsumerStatefulWidget {
  final LatLng? currentLocation;
  final List<BusModel> buses;
  final BusModel? selectedBus;
  final String? selectedRouteType;
  final List<BusModel> allBuses;
  final int filteredBusesCount;
  final Function(GoogleMapController) onMapCreated;
  final Function(String?) onRouteTypeSelected;
  final Function(String?) onBusNumberSelected;
  final VoidCallback onClearFilters;
  final Function(BusModel?) onBusSelected;

  const StudentMapTab({
    super.key,
    required this.currentLocation,
    required this.buses,
    required this.selectedBus,
    required this.selectedRouteType,
    required this.allBuses,
    required this.filteredBusesCount,
    required this.onMapCreated,
    required this.onRouteTypeSelected,
    required this.onBusNumberSelected,
    required this.onClearFilters,
    required this.onBusSelected,
  });

  @override
  ConsumerState<StudentMapTab> createState() => _StudentMapTabState();
}

class _StudentMapTabState extends ConsumerState<StudentMapTab>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;
  final GlobalKey<LiveBusMapState> _mapStateKey = GlobalKey<LiveBusMapState>();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    widget.onMapCreated(controller);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final filteredBuses = widget.allBuses
        .where(
          (b) => b.busNumber.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Stack(
      children: [
        // Map as bottom layer
        Positioned.fill(
          child: widget.currentLocation != null
              ? LiveBusMap(
                  key: _mapStateKey,
                  buses: widget.buses,
                  selectedBus: widget.selectedBus,
                  onMapCreated: _onMapCreated,
                  onBusTap: (bus) => widget.onBusSelected(bus),
                  bottomPadding: widget.selectedBus != null ? 100.0 : 0.0,
                )
              : const Center(child: CircularProgressIndicator()),
        ),

        // Floating Search Bar & Expanded Results
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _isSearchExpanded = true;
                    });
                  },
                  onTap: () => setState(() => _isSearchExpanded = true),
                  decoration: InputDecoration(
                    hintText: 'Search Bus Number...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearchExpanded
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _isSearchExpanded = false;
                                _searchController.clear();
                                _searchQuery = '';
                              });
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              // Expanded Results Panel
              if (_isSearchExpanded)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            "Available Buses".text.semiBold
                                .color(Colors.grey)
                                .size(12)
                                .make(),
                            "${filteredBuses.length} found".text
                                .size(11)
                                .color(Colors.grey)
                                .make(),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: filteredBuses.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text(
                                  "No buses found matching your search",
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                itemCount: filteredBuses.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                      height: 1,
                                      color: Colors.transparent,
                                    ),
                                itemBuilder: (context, index) {
                                  final bus = filteredBuses[index];
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.directions_bus_rounded,
                                          color: Theme.of(context).primaryColor,
                                          size: 26,
                                        ),
                                      ),
                                      title: "Bus ${bus.busNumber}".text.bold
                                          .size(16)
                                          .make(),
                                      subtitle: "Tracking Active • Tap to view"
                                          .text
                                          .size(11)
                                          .color(
                                            Colors.grey.withValues(alpha: 0.8),
                                          )
                                          .make(),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6.0,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            8.widthBox,
                                            "LIVE".text
                                                .color(Colors.green)
                                                .size(10)
                                                .bold
                                                .letterSpacing(1)
                                                .make(),
                                          ],
                                        ),
                                      ),
                                      onTap: () {
                                        widget.onBusNumberSelected(
                                          bus.busNumber,
                                        );
                                        widget.onBusSelected(bus);
                                        setState(() {
                                          _isSearchExpanded = false;
                                          _searchController.text =
                                              "Bus ${bus.busNumber}";
                                        });
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Selected bus info at bottom
        if (widget.selectedBus != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                _mapStateKey.currentState?.resumeFollowing();
                if (_mapController != null) {
                  final repo = ref.read(busRepositoryProvider);
                  repo.getBusLocation(widget.selectedBus!.id).then((location) {
                    if (location != null && mounted) {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          location.currentLocation,
                          17.0,
                        ),
                      );
                    }
                  });
                }
              },
              child:
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
                              'Tap to center on map'.text
                                  .size(12)
                                  .italic
                                  .color(
                                    Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.6),
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
            ),
          ),
      ],
    );
  }
}
