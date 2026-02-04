import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/features/user/application/user_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'modules/bus_tab_components/route_selection_modal.dart';

class DriverSelectionScreen extends ConsumerStatefulWidget {
  final String busNumber;

  const DriverSelectionScreen({super.key, required this.busNumber});

  @override
  ConsumerState<DriverSelectionScreen> createState() =>
      _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends ConsumerState<DriverSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAssignConfirmation({
    required UserModel driver,
    required List<RouteModel> routes,
    required List<BusModel> buses,
  }) async {
    // 1. Open Route Selection Modal
    final selectedRoute = await showDialog<RouteModel>(
      context: context,
      builder: (context) => RouteSelectionModal(
        routes: routes,
        buses: buses,
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
              final api = ref.read(apiServiceProvider);
              final currentUser = ref.read(currentUserProvider);

              if (currentUser == null || currentUser.collegeId.isEmpty) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  ApiErrorModal.show(
                    context: context,
                    error: "Session Invalid. Please login again.",
                  );
                }
                return;
              }

              try {
                await api.assignDriverToBus(
                  busNumber: widget.busNumber,
                  driverId: driver.id,
                  collegeId: currentUser.collegeId,
                  routeId: selectedRoute.id,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext); // Close Confirm Dialog
                }

                if (mounted) {
                  // Show Success Modal
                  await SuccessModal.show(
                    context: context,
                    title: 'Success',
                    message:
                        'Successfully assigned ${driver.fullName} and route ${selectedRoute.routeName}',
                    primaryActionText: 'OK',
                  );

                  if (mounted) {
                    Navigator.pop(context); // Return to bus list
                  }
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
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
    final collegeId = ref.watch(currentUserProvider)?.collegeId;

    if (collegeId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Assign Driver to ${widget.busNumber}')),
        body: const Center(child: Text('College context error')),
      );
    }

    final driversAsync = ref.watch(
      usersByRoleProvider((role: UserRole.driver, collegeId: collegeId)),
    );
    final busesAsync = ref.watch(collegeBusesStreamProvider(collegeId));
    final routesAsync = ref.watch(collegeRoutesProvider(collegeId));

    return Scaffold(
      appBar: AppBar(title: Text('Assign Driver to ${widget.busNumber}')),
      body: driversAsync.when(
        data: (drivers) => busesAsync.when(
          data: (buses) => routesAsync.when(
            data: (routes) {
              // Identify drivers who are already assigned to a bus
              final assignedDriverIds = buses
                  .where((b) => b.driverId.isNotEmpty)
                  .map((b) => b.driverId)
                  .toSet();

              final availableDrivers = drivers
                  .where((d) => !assignedDriverIds.contains(d.id))
                  .toList();

              final filteredDrivers = availableDrivers.where((d) {
                final name = d.fullName.toLowerCase();
                final email = d.email.toLowerCase();
                final query = _searchQuery.toLowerCase();
                return name.contains(query) || email.contains(query);
              }).toList();

              return VStack([
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
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                  ),
                ).p(AppSizes.paddingMedium),

                if (filteredDrivers.isEmpty)
                  VStack([
                    Icon(
                      Icons.person_off_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    16.heightBox,
                    'No available drivers found'.text
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
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child:
                                (driver.fullName.isNotEmpty
                                        ? driver.fullName[0]
                                        : '?')
                                    .text
                                    .white
                                    .bold
                                    .make(),
                          ),
                          title: driver.fullName.text.semiBold.make(),
                          subtitle: driver.email.text.make(),
                          onTap: () => _showAssignConfirmation(
                            driver: driver,
                            routes: routes,
                            buses: buses,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ).expand(),
              ]);
            },
            loading: () =>
                const CircularProgressIndicator().centered().expand(),
            error: (e, s) =>
                Text('Error loading routes: $e').centered().expand(),
          ),
          loading: () => const CircularProgressIndicator().centered().expand(),
          error: (e, s) => Text('Error loading buses: $e').centered().expand(),
        ),
        loading: () => const CircularProgressIndicator().centered().expand(),
        error: (e, s) => Text('Error loading drivers: $e').centered().expand(),
      ),
    );
  }
}





