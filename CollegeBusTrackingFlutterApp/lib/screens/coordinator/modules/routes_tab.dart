import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;
import 'package:collegebus/screens/coordinator/modules/route_edit_screen.dart';

class RoutesTab extends StatelessWidget {
  final List<RouteModel> routes;
  final Function() onRefresh;

  const RoutesTab({super.key, required this.routes, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    return VStack([
      HStack(
        [
          l10n.routes.text.size(20).bold.make(),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RouteEditScreen()),
              );
              if (result == true) onRefresh();
            },
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
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RouteEditScreen(route: route),
                              ),
                            );
                            if (result == true) onRefresh();
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
