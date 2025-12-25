import 'package:flutter/material.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:velocity_x/velocity_x.dart';

class StudentBusListTab extends StatefulWidget {
  final List<BusModel> filteredBuses;
  final List<RouteModel> routes;
  final BusModel? selectedBus;
  final String? selectedStop;
  final VoidCallback onClearFilters;
  final Function(BusModel) onBusSelected;

  const StudentBusListTab({
    super.key,
    required this.filteredBuses,
    required this.routes,
    required this.selectedBus,
    required this.onBusSelected,
    required this.selectedStop,
    required this.onClearFilters,
  });

  @override
  State<StudentBusListTab> createState() => _StudentBusListTabState();
}

class _StudentBusListTabState extends State<StudentBusListTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all'; // Default to 'all'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Apply local search and status filters
    final filteredBuses = widget.filteredBuses.where((bus) {
      // Search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final busNumberMatch = bus.busNumber.toLowerCase().contains(query);

        final route = widget.routes.firstWhere(
          (r) => r.id == bus.routeId,
          orElse: () => RouteModel(
            id: '',
            routeName: '',
            routeType: '',
            startPoint: RoutePoint(name: '', lat: 0, lng: 0),
            endPoint: RoutePoint(name: '', lat: 0, lng: 0),
            stopPoints: [],
            collegeId: '',
            createdBy: '',
            isActive: false,
            createdAt: DateTime.now(),
          ),
        );
        final routeNameMatch = route.routeName.toLowerCase().contains(query);
        matchesSearch = busNumberMatch || routeNameMatch;
      }

      // Status filter
      bool matchesStatus = true;
      if (_selectedStatus != 'all') {
        matchesStatus = bus.status == _selectedStatus;
      }

      return matchesSearch && matchesStatus;
    }).toList();

    return VStack([
      if (widget.selectedStop != null)
        HStack([
              Icon(
                Icons.location_on,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              8.widthBox,
              'Filtered by: ${widget.selectedStop}'.text
                  .size(13)
                  .medium
                  .color(Theme.of(context).primaryColor)
                  .make()
                  .expand(),
              GestureDetector(
                onTap: widget.onClearFilters,
                child: 'Clear'.text
                    .color(Theme.of(context).primaryColor)
                    .make(),
              ),
            ])
            .pSymmetric(h: 12, v: 8)
            .box
            .color(Theme.of(context).primaryColor.withValues(alpha: 0.1))
            .rounded
            .border(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            )
            .make()
            .pOnly(
              left: AppSizes.paddingMedium,
              right: AppSizes.paddingMedium,
              top: AppSizes.paddingMedium,
            ),

      // Search Bar
      TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search bus number or route...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ).p(AppSizes.paddingMedium),

      // Status Filter Buttons
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingMedium,
          0,
          AppSizes.paddingMedium,
          AppSizes.paddingSmall,
        ),
        child: HStack([
          _buildFilterButton('all', 'All'),
          8.widthBox,
          _buildFilterButton('on-time', 'On Time'),
          8.widthBox,
          _buildFilterButton('delayed', 'Delayed'),
          8.widthBox,
          _buildFilterButton('not-running', 'Not Running'),
        ]),
      ),

      AppSizes.paddingSmall.heightBox,

      // List Content
      filteredBuses.isEmpty
          ? VStack(
              [
                Icon(
                  Icons.directions_bus_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                AppSizes.paddingMedium.heightBox,
                (_searchQuery.isEmpty && _selectedStatus == 'all'
                        ? 'No buses found'
                        : 'No matches found')
                    .text
                    .size(18)
                    .color(
                      Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                    )
                    .make(),
              ],
              alignment: MainAxisAlignment.center,
              crossAlignment: CrossAxisAlignment.center,
            ).centered().expand()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
              ),
              itemCount: filteredBuses.length,
              itemBuilder: (context, index) {
                final bus = filteredBuses[index];
                final isSelected = widget.selectedBus?.id == bus.id;

                final route = widget.routes.firstWhere(
                  (r) => r.id == bus.routeId,
                  orElse: () => RouteModel(
                    id: '',
                    routeName: 'Unknown Route',
                    routeType: 'pickup',
                    startPoint: RoutePoint(name: 'N/A', lat: 0, lng: 0),
                    endPoint: RoutePoint(name: 'N/A', lat: 0, lng: 0),
                    stopPoints: [],
                    collegeId: '',
                    createdBy: '',
                    isActive: false,
                    createdAt: DateTime.now(),
                  ),
                );

                final isNotRunning = bus.status == 'not-running';

                return VxBox(
                      child: HStack([
                        // Bus Icon in rounded box
                        Icon(
                              isNotRunning
                                  ? Icons.bus_alert_rounded
                                  : Icons.directions_bus_rounded,
                              color: isNotRunning
                                  ? Colors.grey
                                  : Theme.of(context).primaryColor,
                              size: 28,
                            ).box
                            .color(
                              isSelected
                                  ? Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.2)
                                  : Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.08),
                            )
                            .rounded
                            .size(56, 56)
                            .make(),

                        AppSizes.paddingMedium.widthBox,

                        // Info Column
                        VStack([
                          'Bus ${bus.busNumber}'.text
                              .size(20)
                              .black
                              .color(Theme.of(context).colorScheme.onSurface)
                              .make(),
                          4.heightBox,
                          (bus.status == 'not-running'
                                  ? route.routeName
                                  : '${route.startPoint.name} → ${route.endPoint.name}')
                              .text
                              .size(14)
                              .color(AppColors.textSecondary)
                              .maxLines(1)
                              .ellipsis
                              .make(),
                        ]).expand(),

                        // Status and Chevron
                        VStack([
                          HStack([
                            _buildStatusBadge(bus.status),
                            8.widthBox,
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey.withValues(alpha: 0.6),
                              size: 24,
                            ),
                          ]),
                          if (bus.status == 'delayed' && bus.delay > 0)
                            Text('+${bus.delay} min').text
                                .size(12)
                                .medium
                                .color(AppColors.textSecondary)
                                .make()
                                .pOnly(top: 4, right: 32),
                        ], crossAlignment: CrossAxisAlignment.end),
                      ]),
                    )
                    .padding(const EdgeInsets.all(AppSizes.paddingMedium))
                    .color(
                      Theme.of(context).cardTheme.color ??
                          Theme.of(context).colorScheme.surface,
                    )
                    .withShadow([
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ])
                    .rounded
                    .make()
                    .onInkTap(() => widget.onBusSelected(bus))
                    .pOnly(bottom: AppSizes.paddingMedium);
              },
            ).expand(),
    ]);
  }

  Widget _buildFilterButton(String status, String label) {
    final isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child:
          VxBox(
                child: label.text
                    .color(
                      isSelected
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                    )
                    .size(12)
                    .fontWeight(
                      isSelected ? FontWeight.bold : FontWeight.normal,
                    )
                    .make(),
              )
              .padding(const EdgeInsets.symmetric(horizontal: 16, vertical: 8))
              .color(
                isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).primaryColor.withValues(alpha: 0.1),
              )
              .customRounded(BorderRadius.circular(24))
              .border(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).primaryColor.withValues(alpha: 0.2),
              )
              .make(),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'on-time':
        color = const Color(0xFF4CAF50);
        label = 'On Time';
        break;
      case 'delayed':
        color = const Color(0xFFE67E22);
        label = 'Delayed';
        break;
      case 'not-running':
        color = const Color(0xFFE74C3C);
        label = 'Not Running';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return HStack([
          VxBox().size(8, 8).color(color).roundedFull.make(),
          8.widthBox,
          label.text.size(13).bold.color(color.withValues(alpha: 0.9)).make(),
        ])
        .pSymmetric(h: 12, v: 6)
        .box
        .color(color.withValues(alpha: 0.1))
        .rounded
        .make();
  }
}
