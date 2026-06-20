import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;
import 'route_edit_screen.dart';
import 'package:collegebus/shared/widgets/shimmer_skeletons.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';
import 'package:collegebus/features/coordinator/presentation/widgets/coordinator_search_bar.dart';
import 'package:collegebus/features/coordinator/presentation/widgets/coordinator_list_layout.dart';

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
    if (!mounted) return;
    final bottomInset = WidgetsBinding
        .instance
        .platformDispatcher
        .views
        .first
        .viewInsets
        .bottom;
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

    final routesAsync = ref.watch(collegeRoutesProvider(collegeId));

    if (routesAsync.isLoading) {
      return const BusListSkeleton();
    }

    if (routesAsync.hasError) {
      return Center(child: Text('Error loading routes: ${routesAsync.error}'));
    }

    final allRoutes = routesAsync.valueOrNull ?? [];
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              CoordinatorSearchBar(
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
                child: CoordinatorListLayout<RouteModel>(
                  pageStorageKey: const PageStorageKey<String>('routes_list'),
                  items: filteredRoutes,
                  emptyState: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.08),
                          width: 1.5,
                        ),
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  Colors.white.withValues(alpha: 0.05),
                                  Colors.white.withValues(alpha: 0.01),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.7),
                                  Colors.white.withValues(alpha: 0.3),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: VStack(
                            [
                              // Icon with glowing background circle
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFF0097B2,
                                  ).withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF0097B2,
                                    ).withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.route_outlined,
                                  size: 48,
                                  color: Color(0xFF00C6E6),
                                ),
                              ),
                              20.heightBox,
                              (_searchQuery.isNotEmpty
                                      ? 'No routes found matching "$_searchQuery"'
                                      : l10n.noRoutesCreated)
                                  .text
                                  .size(18)
                                  .bold
                                  .color(
                                    Theme.of(context).colorScheme.onSurface,
                                  )
                                  .center
                                  .make(),
                              8.heightBox,
                              (_searchQuery.isNotEmpty
                                      ? 'Try checking your spelling or search terms.'
                                      : l10n.createRoutesPrompt)
                                  .text
                                  .size(13)
                                  .color(
                                    Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  )
                                  .center
                                  .make(),
                            ],
                            alignment: MainAxisAlignment.center,
                            crossAlignment: CrossAxisAlignment.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  itemBuilder: (context, route, index) {
                    return _RouteCard(
                      route: route,
                      index: index,
                      l10n: l10n,
                      onEdit: () async {
                        _focusNode.unfocus();
                        await _pushWithTransition(
                          context,
                          RouteEditScreen(route: route),
                        );
                      },
                      onDelete: () async {
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
                          final repo = ref.read(routeRepositoryProvider);
                          await repo.deleteRoute(route.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.routeDeletedSuccess),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // Floating Action Button
          Positioned(
            bottom:
                CurvedBottomNavBar.clearance(context) + AppSizes.paddingMedium,
            right: AppSizes.paddingMedium,
            child: _FloatingAddButton(
              onTap: () async {
                _focusNode.unfocus();
                await _pushWithTransition(context, const RouteEditScreen());
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pushWithTransition(BuildContext context, Widget screen) async {
    await Navigator.push(
      context,
      PageRouteBuilder<bool>(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.34, 1.56, 0.64, 1.0),
            ),
          );
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium RouteCard and Timeline components
// ─────────────────────────────────────────────────────────────────────────────

class _RouteCard extends StatefulWidget {
  final RouteModel route;
  final int index;
  final coord_l10n.CoordinatorLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RouteCard({
    required this.route,
    required this.index,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isStopsExpanded = false;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
      ),
    );

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) {
        _cardController.forward();
      }
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Color _parseHexColor(String hex) {
    try {
      final hexVal = hex.replaceAll('#', '');
      if (hexVal.length == 6) {
        return Color(int.parse('FF$hexVal', radix: 16));
      } else if (hexVal.length == 8) {
        return Color(int.parse(hexVal, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF0097B2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPickup = widget.route.routeType == 'pickup';
    final parsedColor = _parseHexColor(widget.route.color);
    final accentColor = parsedColor != const Color(0xFF0097B2)
        ? parsedColor
        : (isPickup ? const Color(0xFF10B981) : const Color(0xFF6366F1));

    final displayType = isPickup
        ? widget.l10n.pickup.toUpperCase()
        : (widget.route.routeType == 'drop'
              ? widget.l10n.drop.toUpperCase()
              : widget.route.routeType.toUpperCase());

    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0.0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
            width: 1.5,
          ),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: 0.06),
                    accentColor.withValues(alpha: 0.02),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.75),
                    accentColor.withValues(alpha: 0.04),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.12 : 0.05),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _cardController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _RouteVectorPainter(
                          color: accentColor,
                          progress: _cardController.value,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.route.routeName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.route.isActive
                                        ? const Color(0xFF10B981)
                                        : Colors.grey,
                                    boxShadow: widget.route.isActive
                                        ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF10B981,
                                              ).withValues(alpha: 0.5),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildActionsMenu(context),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.3),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPickup
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 12,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  displayType,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              '${widget.route.stopPoints.length} ${widget.l10n.stops.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildTimelinePath(context, isDark, accentColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActionsBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = widget.l10n;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2732) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Sheet Title
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Text(
                    'Route Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              // Edit Option Card
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onEdit();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFE0F2FE),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          l10n.edit,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Delete Option Card
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDelete();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFFEE2E2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Theme.of(context).colorScheme.error.withValues(alpha: 0.15)
                                : Theme.of(context).colorScheme.error.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          l10n.delete,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.more_vert_rounded,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        _showActionsBottomSheet(context);
      },
    );
  }

  Widget _buildTimelinePath(
    BuildContext context,
    bool isDark,
    Color accentColor,
  ) {
    final startName = widget.route.startPoint.name;
    final endName = widget.route.endPoint.name;
    final stopsList = widget.route.stopPoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineNode(
          context,
          icon: Icons.circle,
          iconColor: accentColor,
          title: startName,
          subtitle: 'Start Point',
          isFirst: true,
          isLast: stopsList.isEmpty && endName.isEmpty,
          accentColor: accentColor,
        ),

        if (stopsList.isNotEmpty) ...[
          GestureDetector(
            onTap: () {
              setState(() {
                _isStopsExpanded = !_isStopsExpanded;
              });
              HapticFeedback.selectionClick();
            },
            behavior: HitTestBehavior.opaque,
            child: _buildTimelineNode(
              context,
              icon: Icons.linear_scale_rounded,
              iconColor: accentColor.withValues(alpha: 0.8),
              title: '${stopsList.length} stop points',
              subtitle: _isStopsExpanded
                  ? 'Tap to hide list'
                  : 'Tap to show details',
              accentColor: accentColor,
              isMiddle: true,
              trailing: AnimatedRotation(
                turns: _isStopsExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: _isStopsExpanded
                      ? accentColor
                      : (isDark ? Colors.white54 : Colors.black54),
                ),
              ),
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isStopsExpanded
                ? Column(
                    children: [
                      for (int i = 0; i < stopsList.length; i++)
                        _buildTimelineNode(
                          context,
                          icon: Icons.radio_button_unchecked,
                          iconColor: accentColor.withValues(alpha: 0.6),
                          title: stopsList[i].name,
                          subtitle: 'Stop ${i + 1}',
                          accentColor: accentColor,
                          isMiddle: true,
                          isSubNode: true,
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],

        _buildTimelineNode(
          context,
          icon: Icons.location_on_rounded,
          iconColor: const Color(0xFFFF3D00),
          title: endName,
          subtitle: 'Destination',
          isLast: true,
          accentColor: accentColor,
        ),
      ],
    );
  }

  Widget _buildTimelineNode(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
    bool isMiddle = false,
    bool isSubNode = false,
    required Color accentColor,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: 10.0, // Centered inside the 22px zone (22/2 - 1 = 10)
            top: 22,    // Starts after the icon container (height 22)
            bottom: 0,
            child: Container(
              width: isSubNode ? 1.0 : 2.0,
              decoration: BoxDecoration(
                color: isSubNode
                    ? (isDark ? Colors.white12 : Colors.black12)
                    : (isDark ? Colors.white24 : Colors.black12),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSubNode || isMiddle
                    ? Colors.transparent
                    : iconColor.withValues(alpha: 0.15),
              ),
              child: Icon(
                icon,
                size: isSubNode
                    ? 8
                    : (isMiddle ? 14 : (icon == Icons.circle ? 8 : 14)),
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isSubNode ? 13 : 14,
                            fontWeight: isSubNode
                                ? FontWeight.normal
                                : (isMiddle ? FontWeight.w500 : FontWeight.w600),
                            color: isSubNode
                                ? (isDark ? Colors.white54 : Colors.black54)
                                : (isMiddle
                                      ? (isDark ? Colors.white70 : Colors.black87)
                                      : (isDark ? Colors.white : Colors.black87)),
                          ),
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing,
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    maxLines: isMiddle ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isSubNode ? 10 : 11,
                      color: isSubNode
                          ? (isDark ? Colors.white24 : Colors.black26)
                          : (isDark ? Colors.white30 : Colors.black38),
                    ),
                  ),
                  if (!isLast) const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RouteVectorPainter extends CustomPainter {
  final Color color;
  final double progress;

  _RouteVectorPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.85);
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.9,
      size.width * 0.4,
      size.height * 0.2,
      size.width * 0.65,
      size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.8,
      size.height * 0.6,
      size.width * 0.9,
      size.height * 0.1,
      size.width,
      size.height * 0.15,
    );

    // Compute metrics and extract subpath based on progress
    final Path drawPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      final double extractLength = metric.length * progress;
      drawPath.addPath(metric.extractPath(0.0, extractLength), Offset.zero);
    }

    // Convert the subpath to a dashed path with animated dash phase shift
    final double dashWidth = 8.0;
    final double dashGap = 6.0;
    final double phase =
        -progress * 40.0; // Phase shifts backwards to simulate forward flow
    final Path dashedPath = _toDashedPath(drawPath, dashWidth, dashGap, phase);

    canvas.drawPath(dashedPath, paint);

    // Draw glowing nodes scaling up as progress reaches their positions


    // Node 1 (Start) - scales up from progress 0.0 to 0.2
    final double node1Scale = (progress / 0.2).clamp(0.0, 1.0);
    // Node 2 (Stop 1) - scales up from progress 0.45 to 0.65
    final double node2Scale = ((progress - 0.45) / 0.2).clamp(0.0, 1.0);
    // Node 3 (Destination) - scales up from progress 0.8 to 1.0
    final double node3Scale = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);

    if (node1Scale > 0.0) {
      final node1Paint = Paint()
        ..color = const Color(0xFF4CAF50).withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final glow1Paint = Paint()
        ..color = const Color(0xFF4CAF50).withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(0, size.height * 0.85),
        8 * node1Scale,
        glow1Paint,
      );
      canvas.drawCircle(
        Offset(0, size.height * 0.85),
        4 * node1Scale,
        node1Paint,
      );
    }

    if (node2Scale > 0.0) {
      final node2Paint = Paint()
        ..color = const Color(0xFFFF9800).withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final glow2Paint = Paint()
        ..color = const Color(0xFFFF9800).withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width * 0.51, size.height * 0.33),
        6 * node2Scale,
        glow2Paint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.51, size.height * 0.33),
        3 * node2Scale,
        node2Paint,
      );
    }

    if (node3Scale > 0.0) {
      final node3Paint = Paint()
        ..color = const Color(0xFFF44336).withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final glow3Paint = Paint()
        ..color = const Color(0xFFF44336).withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width, size.height * 0.15),
        10 * node3Scale,
        glow3Paint,
      );
      canvas.drawCircle(
        Offset(size.width, size.height * 0.15),
        5 * node3Scale,
        node3Paint,
      );
    }
  }

  Path _toDashedPath(
    Path source,
    double dashWidth,
    double dashGap,
    double phase,
  ) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      final double period = dashWidth + dashGap;
      double distance = phase % period;
      if (distance < 0) {
        distance += period;
      }

      bool draw = distance < dashWidth;
      if (!draw) {
        distance = period - distance;
      }

      while (distance < metric.length) {
        final double len = draw ? dashWidth : dashGap;
        final double end = (distance + len).clamp(0.0, metric.length);
        if (draw) {
          dest.addPath(metric.extractPath(distance, end), Offset.zero);
        }
        distance = end;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _RouteVectorPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _FloatingAddButton extends StatefulWidget {
  final VoidCallback onTap;

  const _FloatingAddButton({required this.onTap});

  @override
  State<_FloatingAddButton> createState() => _FloatingAddButtonState();
}

class _FloatingAddButtonState extends State<_FloatingAddButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.90,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _controller.reverse();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF0097B2), Color(0xFF00C6E6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF00C6E6,
                ).withValues(alpha: 0.45 * (2.0 - _pulseAnimation.value)),
                blurRadius: 12 + 6 * _pulseAnimation.value,
                spreadRadius: 0.5 * _pulseAnimation.value,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _RouteSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String searchQuery;

  const _RouteSearchBar({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    required this.searchQuery,
  });

  @override
  State<_RouteSearchBar> createState() => _RouteSearchBarState();
}

class _RouteSearchBarState extends State<_RouteSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
      ),
    );

    widget.focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (widget.focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
      if (_isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0097B2);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _isFocused
                ? primaryColor.withValues(alpha: 0.5)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08)),
            width: 1.5,
          ),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: _isFocused ? 0.08 : 0.05),
                    Colors.white.withValues(alpha: _isFocused ? 0.04 : 0.02),
                  ]
                : [
                    Colors.white.withValues(alpha: _isFocused ? 0.9 : 0.8),
                    Colors.white.withValues(alpha: _isFocused ? 0.8 : 0.7),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _isFocused
                  ? primaryColor.withValues(alpha: 0.15)
                  : (isDark
                        ? Colors.black.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.03)),
              blurRadius: _isFocused ? 12 : 8,
              spreadRadius: _isFocused ? 1 : -1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: _isFocused
                        ? primaryColor
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.4)),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      onChanged: widget.onChanged,
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white30 : Colors.black38,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: widget.searchQuery.isNotEmpty
                        ? IconButton(
                            key: const ValueKey('clear_button'),
                            icon: Icon(
                              Icons.close_rounded,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.black.withValues(alpha: 0.6),
                              size: 20,
                            ),
                            onPressed: () {
                              widget.onClear();
                              HapticFeedback.lightImpact();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
