import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';

class RoutesTab extends StatelessWidget {
  final List<RouteModel> routes;
  final Function() onRefresh;

  const RoutesTab({super.key, required this.routes, required this.onRefresh});

  void _showCreateOrEditRouteDialog(BuildContext context, {RouteModel? route}) {
    final isEditing = route != null;
    final TextEditingController nameController = TextEditingController(
      text: route?.routeName ?? '',
    );
    final TextEditingController startController = TextEditingController(
      text: route?.startPoint.name ?? '',
    );
    final TextEditingController endController = TextEditingController(
      text: route?.endPoint.name ?? '',
    );
    String selectedType = route?.routeType ?? 'pickup';
    List<TextEditingController> stopControllers = (route?.stopPoints ?? [])
        .map((s) => TextEditingController(text: s.name))
        .toList();
    if (stopControllers.isEmpty) stopControllers.add(TextEditingController());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Route' : 'Create Route'),
              content: SingleChildScrollView(
                child: VStack([
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Route Name'),
                  ),
                  8.heightBox,
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Route Type'),
                    items: const [
                      DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
                      DropdownMenuItem(value: 'drop', child: Text('Drop')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  8.heightBox,
                  TextField(
                    controller: startController,
                    decoration: const InputDecoration(labelText: 'Start Point'),
                    enabled: !isEditing,
                  ),
                  8.heightBox,
                  ...stopControllers.asMap().entries.map((entry) {
                    int idx = entry.key;
                    TextEditingController controller = entry.value;
                    return HStack([
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Stop ${idx + 1}',
                        ),
                      ).expand(),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: stopControllers.length > 1
                            ? () {
                                setState(() {
                                  stopControllers.removeAt(idx);
                                });
                              }
                            : null,
                      ),
                    ]);
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Stop'),
                      onPressed: () {
                        setState(() {
                          stopControllers.add(TextEditingController());
                        });
                      },
                    ),
                  ),
                  TextField(
                    controller: endController,
                    decoration: const InputDecoration(labelText: 'End Point'),
                    enabled: !isEditing,
                  ),
                ]),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final firestoreService = Provider.of<DataService>(
                      context,
                      listen: false,
                    );
                    final authService = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final collegeId = authService.currentUserModel?.collegeId;
                    if (collegeId == null) return;
                    final stops = stopControllers
                        .map((c) => c.text.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    if (startController.text.trim().isEmpty ||
                        endController.text.trim().isEmpty) {
                      return;
                    }
                    if (isEditing) {
                      await firestoreService.updateRoute(route.id, {
                        'routeName': nameController.text.trim(),
                        'routeType': selectedType,
                        'stopPoints': stops
                            .map(
                              (s) => {
                                'name': s,
                                'location': {'lat': 0, 'lng': 0},
                              },
                            )
                            .toList(),
                        'updatedAt': DateTime.now().toIso8601String(),
                      });
                    } else {
                      final newRoute = RouteModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        routeName: nameController.text.trim().isNotEmpty
                            ? nameController.text.trim()
                            : '${startController.text.trim()} - ${endController.text.trim()}',
                        routeType: selectedType,
                        startPoint: RoutePoint(
                          name: startController.text.trim(),
                          lat: 0,
                          lng: 0,
                        ),
                        endPoint: RoutePoint(
                          name: endController.text.trim(),
                          lat: 0,
                          lng: 0,
                        ),
                        stopPoints: stops
                            .map((s) => RoutePoint(name: s, lat: 0, lng: 0))
                            .toList(),
                        collegeId: collegeId,
                        createdBy: authService.currentUserModel?.id ?? '',
                        isActive: true,
                        createdAt: DateTime.now(),
                        updatedAt: null,
                      );
                      await firestoreService.createRoute(newRoute);
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    onRefresh();
                  },
                  child: Text(isEditing ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return VStack([
      HStack(
        [
          'Routes'.text.size(20).bold.make(),
          ElevatedButton.icon(
            onPressed: () => _showCreateOrEditRouteDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
        alignment: MainAxisAlignment.spaceBetween,
        axisSize: MainAxisSize.max,
      ).p(AppSizes.paddingMedium),
      Expanded(
        child: routes.isEmpty
            ? VStack(
                [
                  Icon(
                    Icons.route_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  AppSizes.paddingMedium.heightBox,
                  'No routes created yet'.text
                      .size(18)
                      .color(AppColors.textSecondary)
                      .make(),
                  AppSizes.paddingSmall.heightBox,
                  'Create routes for drivers to select'.text
                      .size(14)
                      .color(AppColors.textSecondary)
                      .center
                      .make(),
                ],
                alignment: MainAxisAlignment.center,
                crossAlignment: CrossAxisAlignment.center,
              ).centered()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMedium,
                ),
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final route = routes[index];
                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: AppSizes.paddingMedium,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: route.routeType == 'pickup'
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).primaryColor,
                        child: Icon(
                          route.routeType == 'pickup'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      title: route.routeName.text.semiBold.make(),
                      subtitle: VStack([
                        'Type: ${route.routeType.toUpperCase()}'.text.make(),
                        '${route.startPoint.name} → ${route.endPoint.name}'.text
                            .make(),
                        if (route.stopPoints.isNotEmpty)
                          'Stops: ${route.stopPoints.map((s) => s.name).join(', ')}'
                              .text
                              .size(12)
                              .make(),
                      ]),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showCreateOrEditRouteDialog(context, route: route);
                          } else if (value == 'delete') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Route'),
                                content: Text(
                                  'Are you sure you want to delete ${route.routeName}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              if (!context.mounted) return;
                              final firestoreService = Provider.of<DataService>(
                                context,
                                listen: false,
                              );
                              await firestoreService.deleteRoute(route.id);
                              onRefresh();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Route deleted successfully'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      isThreeLine: route.stopPoints.isNotEmpty,
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}
