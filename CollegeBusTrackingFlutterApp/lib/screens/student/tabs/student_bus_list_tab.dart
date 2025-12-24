import 'package:flutter/material.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/utils/constants.dart';

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
            startPoint: '',
            endPoint: '',
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

    return Column(
      children: [
        if (widget.selectedStop != null)
          // ... (existing selectedStop indicator)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingMedium,
              AppSizes.paddingMedium,
              AppSizes.paddingMedium,
              0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtered by: ${widget.selectedStop}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onClearFilters,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingMedium,
            AppSizes.paddingMedium,
            AppSizes.paddingMedium,
            AppSizes.paddingSmall,
          ),
          child: TextField(
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
          ),
        ),

        // Status Filter Buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingMedium,
            0,
            AppSizes.paddingMedium,
            AppSizes.paddingSmall,
          ),
          child: Row(
            children: [
              _buildFilterButton('all', 'All'),
              const SizedBox(width: 8),
              _buildFilterButton('on-time', 'On Time'),
              const SizedBox(width: 8),
              _buildFilterButton('delayed', 'Delayed'),
              const SizedBox(width: 8),
              _buildFilterButton('not-running', 'Not Running'),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.paddingSmall),

        // List Content
        Expanded(
          child: filteredBuses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_bus_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),
                      Text(
                        _searchQuery.isEmpty && _selectedStatus == 'all'
                            ? 'No buses found'
                            : 'No matches found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
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
                        startPoint: 'N/A',
                        endPoint: 'N/A',
                        stopPoints: [],
                        collegeId: '',
                        createdBy: '',
                        isActive: false,
                        createdAt: DateTime.now(),
                      ),
                    );

                    final isNotRunning = bus.status == 'not-running';

                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: AppSizes.paddingMedium,
                      ),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).cardTheme.color ??
                            Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusLarge,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => widget.onBusSelected(bus),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusLarge,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.paddingMedium),
                          child: Row(
                            children: [
                              // Bus Icon in rounded box
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(
                                          context,
                                        ).primaryColor.withValues(alpha: 0.2)
                                      : Theme.of(
                                          context,
                                        ).primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMedium,
                                  ),
                                ),
                                child: Icon(
                                  isNotRunning
                                      ? Icons.bus_alert_rounded
                                      : Icons.directions_bus_rounded,
                                  color: isNotRunning
                                      ? Colors.grey
                                      : Theme.of(context).primaryColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: AppSizes.paddingMedium),

                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bus ${bus.busNumber}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      bus.status == 'not-running'
                                          ? route.routeName
                                          : '${route.startPoint} → ${route.endPoint}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Status and Chevron
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      _buildStatusBadge(bus.status),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.grey.withValues(
                                          alpha: 0.6,
                                        ),
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                  if (bus.status == 'delayed' && bus.delay > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 4,
                                        right: 32,
                                      ),
                                      child: Text(
                                        '+${bus.delay} min',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String status, String label) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).primaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
