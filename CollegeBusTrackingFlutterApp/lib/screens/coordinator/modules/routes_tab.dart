import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;

class RoutesTab extends StatelessWidget {
  final List<RouteModel> routes;
  final Function() onRefresh;

  const RoutesTab({super.key, required this.routes, required this.onRefresh});

  void _showCreateOrEditRouteDialog(BuildContext context, {RouteModel? route}) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
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
              title: Text(isEditing ? l10n.editRoute : l10n.createRoute),
              content: SingleChildScrollView(
                child: VStack([
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: l10n.routeName),
                  ),
                  8.heightBox,
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: InputDecoration(labelText: l10n.routeType),
                    items: [
                      DropdownMenuItem(
                        value: 'pickup',
                        child: Text(l10n.pickup),
                      ),
                      DropdownMenuItem(value: 'drop', child: Text(l10n.drop)),
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
                    decoration: InputDecoration(labelText: l10n.startPoint),
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
                          labelText: '${l10n.stopPoint} ${idx + 1}',
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
                      label: Text(l10n.addStop),
                      onPressed: () {
                        setState(() {
                          stopControllers.add(TextEditingController());
                        });
                      },
                    ),
                  ),
                  TextField(
                    controller: endController,
                    decoration: InputDecoration(labelText: l10n.endPoint),
                    enabled: !isEditing,
                  ),
                ]),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
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
                  child: Text(isEditing ? l10n.save : l10n.create),
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
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    return VStack([
      HStack(
        [
          l10n.routes.text.size(20).bold.make(),
          ElevatedButton.icon(
            onPressed: () => _showCreateOrEditRouteDialog(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.createRoute),
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
                  l10n.noRoutesCreated.text
                      .size(18)
                      .color(AppColors.textSecondary)
                      .make(),
                  AppSizes.paddingSmall.heightBox,
                  l10n.createRoutesPrompt.text
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
                  // Localize route type display if possible, or just capitalize
                  final displayType = route.routeType == 'pickup'
                      ? l10n.pickup.toUpperCase()
                      : (route.routeType == 'drop'
                            ? l10n.drop.toUpperCase()
                            : route.routeType.toUpperCase());

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
                        'Type: $displayType'.text.make(),
                        '${route.startPoint.name} → ${route.endPoint.name}'.text
                            .make(),
                        if (route.stopPoints.isNotEmpty)
                          '${l10n.stops}: ${route.stopPoints.map((s) => s.name).join(', ')}'
                              .text
                              .size(12)
                              .make(),
                      ]),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit),
                                const SizedBox(width: 8),
                                Text(l10n.edit),
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
                                const SizedBox(width: 8),
                                Text(l10n.delete),
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
                                title: Text(l10n.deleteRoute),
                                content: Text(
                                  l10n.deleteRouteConfirmation(route.routeName),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text(l10n.cancel),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    child: Text(l10n.delete),
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
                                  content: Text(l10n.routeDeletedSuccess),
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
