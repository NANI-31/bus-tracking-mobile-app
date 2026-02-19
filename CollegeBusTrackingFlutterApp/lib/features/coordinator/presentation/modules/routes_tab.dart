import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;
import 'route_edit_screen.dart';
import 'bus_tab_components/bus_search_bar.dart';

class RoutesTab extends ConsumerStatefulWidget {
  const RoutesTab({super.key});

  @override
  ConsumerState<RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends ConsumerState<RoutesTab>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0.0;

    if (_isKeyboardVisible && !isKeyboardOpen) {
      _focusNode.unfocus();
    }

    _isKeyboardVisible = isKeyboardOpen;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;

    if (collegeId == null) return const SizedBox.shrink();

    final allRoutes = ref.watch(collegeRoutesProvider(collegeId)).value ?? [];
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;

    // Filter routes based on search query
    final filteredRoutes = allRoutes.where((route) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return route.routeName.toLowerCase().contains(query) ||
          route.startPoint.name.toLowerCase().contains(query) ||
          route.endPoint.name.toLowerCase().contains(query);
    }).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              // Search Bar
              BusSearchBar(
                controller: _searchController,
                focusNode: _focusNode,
                hintText: l10n.search,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                onClear: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                searchQuery: _searchQuery,
              ),

              // Routes List
              Expanded(
                child: filteredRoutes.isEmpty
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
                          (_searchQuery.isNotEmpty
                                  ? 'No routes found matching "$_searchQuery"'
                                  : l10n.noRoutesCreated)
                              .text
                              .size(18)
                              .color(
                                context.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              )
                              .center
                              .make(),
                          AppSizes.paddingSmall.heightBox,
                          if (_searchQuery.isEmpty)
                            l10n.createRoutesPrompt.text
                                .size(14)
                                .color(
                                  context.colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                )
                                .center
                                .make(),
                        ],
                        alignment: MainAxisAlignment.center,
                        crossAlignment: CrossAxisAlignment.center,
                      ).centered()
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          left: AppSizes.paddingMedium,
                          right: AppSizes.paddingMedium,
                          bottom: 80,
                          top: 8,
                        ),
                        itemCount: filteredRoutes.length,
                        itemBuilder: (context, index) {
                          final route = filteredRoutes[index];
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                              title: route.routeName.text.semiBold.make(),
                              subtitle: VStack([
                                'Type: $displayType'.text.make(),
                                '${route.startPoint.name} → ${route.endPoint.name}'
                                    .text
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
                                        const SizedBox(width: 8.0),
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
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                        const SizedBox(width: 8.0),
                                        Text(l10n.delete),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    _focusNode.unfocus();
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            RouteEditScreen(route: route),
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(l10n.deleteRoute),
                                        content: Text(
                                          l10n.deleteRouteConfirmation(
                                            route.routeName,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
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
                                      final api = ref.read(apiServiceProvider);
                                      await api.deleteRoute(route.id);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.routeDeletedSuccess,
                                          ),
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
            ],
          ),
          // Floating Action Button
          Positioned(
            bottom: AppSizes.paddingMedium,
            right: AppSizes.paddingMedium,
            child: FloatingActionButton(
              onPressed: () async {
                _focusNode.unfocus();
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RouteEditScreen()),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
