import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/success_modal.dart';
import 'package:collegebus/widgets/api_error_modal.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'modules/bus_tab_components/route_selection_modal.dart';

class DriverSelectionScreen extends StatefulWidget {
  final String busNumber;

  const DriverSelectionScreen({super.key, required this.busNumber});

  @override
  State<DriverSelectionScreen> createState() => _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends State<DriverSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserModel> _allDrivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;

    if (collegeId != null) {
      try {
        // Fetch drivers, buses, and routes in parallel
        final results = await Future.wait([
          dataService.getUsersByRole(UserRole.driver, collegeId).first,
          dataService.getBusesByCollege(collegeId).first,
          dataService.getRoutesByCollege(collegeId).first,
        ]);

        final drivers = results[0] as List<UserModel>;
        final buses = results[1] as List<BusModel>;
        final routes = results[2] as List<RouteModel>;

        // Identify drivers who are already assigned to a bus (active assignment)
        final assignedDriverIds = buses
            .where((b) {
              return b.driverId.isNotEmpty;
            })
            .map((b) => b.driverId)
            .toSet();

        final availableDrivers = drivers
            .where((d) => !assignedDriverIds.contains(d.id))
            .toList();

        setState(() {
          _allDrivers = availableDrivers;
          _allBuses = buses;
          _allRoutes = routes;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error loading drivers: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  List<BusModel> _allBuses = [];
  List<RouteModel> _allRoutes = [];

  Future<void> _showAssignConfirmation(UserModel driver) async {
    // 1. Open Route Selection Modal
    final selectedRoute = await showDialog<RouteModel>(
      context: context,
      builder: (context) => RouteSelectionModal(
        routes: _allRoutes,
        buses: _allBuses,
        busNumberToAssign: widget.busNumber,
      ),
    );

    // If no route selected (cancelled), just return
    if (selectedRoute == null) return;

    if (!mounted) return;

    // 2. Show Final Confirmation
    await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Assignment'),
        content: RichText(
          text: TextSpan(
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 16,
            ),
            children: [
              const TextSpan(text: 'Assign driver '),
              TextSpan(
                text: driver.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' and route '),
              TextSpan(
                text: selectedRoute.routeName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '\nto bus '),
              TextSpan(
                text: widget.busNumber,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final dataService = Provider.of<DataService>(
                context,
                listen: false,
              );
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );

              final currentUser = authService.currentUserModel;
              if (currentUser == null || currentUser.collegeId.isEmpty) {
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  ApiErrorModal.show(
                    context: context,
                    error: "Session Invalid. Please login again.",
                  );
                }
                return;
              }

              try {
                await dataService.assignDriverToBus(
                  busNumber: widget.busNumber,
                  driverId: driver.id,
                  collegeId: currentUser.collegeId,
                  routeId: selectedRoute.id,
                );

                if (context.mounted) {
                  Navigator.pop(dialogContext); // Close Confirm Dialog

                  // Show Success Modal
                  await SuccessModal.show(
                    context: context,
                    title: 'Success',
                    message:
                        'Successfully assigned ${driver.fullName} and route ${selectedRoute.routeName}',
                    primaryActionText: 'OK',
                  );

                  if (context.mounted) {
                    Navigator.pop(context); // Return to bus list
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ApiErrorModal.show(context: context, error: e);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Assign', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDrivers = _allDrivers.where((d) {
      final name = d.fullName.toLowerCase();
      final email = d.email.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Assign Driver to ${widget.busNumber}')),
      body: VStack([
        // Search Bar
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search drivers by name or email...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 0,
            ),
          ),
        ).p(AppSizes.paddingMedium),

        if (_isLoading)
          const CircularProgressIndicator().centered().expand()
        else if (filteredDrivers.isEmpty)
          VStack([
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            16.heightBox,
            'No drivers found'.text
                .size(18)
                .color(AppColors.textSecondary)
                .make(),
          ]).centered().expand()
        else
          ListView.builder(
            itemCount: filteredDrivers.length,
            itemBuilder: (context, index) {
              final driver = filteredDrivers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child:
                        (driver.fullName.isNotEmpty ? driver.fullName[0] : '?')
                            .text
                            .white
                            .bold
                            .make(),
                  ),
                  title: driver.fullName.text.semiBold.make(),
                  subtitle: driver.email.text.make(),
                  onTap: () => _showAssignConfirmation(driver),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          ).expand(),
      ]),
    );
  }
}
