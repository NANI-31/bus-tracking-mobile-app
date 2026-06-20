import 'dart:ui' show ImageFilter;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/shared/widgets/vector_empty_state.dart';

class SineCurve extends Curve {
  final double count;
  const SineCurve({this.count = 3});
  @override
  double transformInternal(double t) {
    return math.sin(t * count * 2 * math.pi);
  }
}

class RouteSelectionModal extends StatefulWidget {
  final List<RouteModel> routes;
  final List<BusModel> buses;
  final String busNumberToAssign;

  const RouteSelectionModal({
    super.key,
    required this.routes,
    required this.buses,
    required this.busNumberToAssign,
  });

  @override
  State<RouteSelectionModal> createState() => _RouteSelectionModalState();
}

class _RouteSelectionModalState extends State<RouteSelectionModal>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _searchAnimController;
  late Animation<double> _searchFocusAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  String _searchQuery = '';
  RouteModel? _selectedRoute;
  bool _isSearchFocused = false;
  bool _wasEmpty = false;

  @override
  void initState() {
    super.initState();
    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _searchFocusAnimation = CurvedAnimation(
      parent: _searchAnimController,
      curve: const Cubic(0.05, 0.7, 0.1, 1.0),
    );
    _searchFocusNode.addListener(_handleSearchFocusChange);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: const SineCurve(count: 3),
      ),
    );
  }

  void _handleSearchFocusChange() {
    if (!mounted) return;
    final hasFocus = _searchFocusNode.hasFocus;
    if (hasFocus != _isSearchFocused) {
      setState(() {
        _isSearchFocused = hasFocus;
      });
      if (hasFocus) {
        _searchAnimController.forward();
      } else {
        _searchAnimController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchFocusNode.dispose();
    _searchAnimController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  BusModel? _findBusWithRoute(String routeId) {
    try {
      return widget.buses.firstWhere(
        (b) =>
            b.routeId == routeId &&
            b.busNumber != widget.busNumberToAssign &&
            b.isActive &&
            b.assignmentStatus != 'unassigned',
      );
    } catch (_) {
      return null;
    }
  }

  void _handleRouteSelection(RouteModel route) {
    final conflictingBus = _findBusWithRoute(route.id);

    if (conflictingBus != null) {
      // Custom Glassmorphic Dialog for Conflicts
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Route Assigned Warning',
        barrierColor: Colors.black.withValues(alpha: 0.6),
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (ctx, anim1, anim2, child) {
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: anim1,
              curve: const Cubic(0.34, 1.56, 0.64, 1.0),
            ),
            child: FadeTransition(opacity: anim1, child: child),
          );
        },
        pageBuilder: (dialogContext, anim1, anim2) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A1508).withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Route Already Assigned',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Route "${route.routeName}" is already assigned to Bus ${conflictingBus.busNumber}.\n\nDo you want to proceed anyway?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                setState(() {
                                  _selectedRoute = route;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Assign Anyway',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      setState(() {
        _selectedRoute = route;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRoutes = widget.routes.where((r) {
      final query = _searchQuery.toLowerCase();
      return r.routeName.toLowerCase().contains(query);
    }).toList();

    final hasNoResults = filteredRoutes.isEmpty && _searchQuery.isNotEmpty;
    if (hasNoResults && !_wasEmpty) {
      _wasEmpty = true;
      _shakeController.forward(from: 0.0);
    } else if (!hasNoResults) {
      _wasEmpty = false;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSizes.paddingMedium),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: context.colorScheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMedium,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.route_rounded,
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Select Route',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Search Bar with sliding anim, glow, validation, and shake
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: AnimatedBuilder(
                    animation: _searchFocusAnimation,
                    builder: (context, child) {
                      final double glowOpacity =
                          0.08 * _searchFocusAnimation.value;
                      final baseBorderColor = hasNoResults
                          ? AppColors.warning.withValues(alpha: 0.4)
                          : context.colorScheme.onSurface.withValues(
                              alpha: 0.08,
                            );
                      final targetBorderColor = hasNoResults
                          ? AppColors.warning
                          : (isDark
                                ? const Color(0xFF00E5FF)
                                : const Color(0xFF0097B2));
                      final borderColor = Color.lerp(
                        baseBorderColor,
                        targetBorderColor,
                        _searchFocusAnimation.value,
                      )!;
                      final borderWidth =
                          1.0 + (1.5 - 1.0) * _searchFocusAnimation.value;
                      final glowColor = hasNoResults
                          ? AppColors.warning
                          : (isDark
                                ? const Color(0xFF00E5FF)
                                : const Color(0xFF0097B2));

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(
                            color: borderColor,
                            width: borderWidth,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withValues(
                                alpha: hasNoResults ? 0.06 : glowOpacity,
                              ),
                              blurRadius: 8 * _searchFocusAnimation.value,
                              spreadRadius: 2 * _searchFocusAnimation.value,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          focusNode: _searchFocusNode,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: context.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            prefixIcon: AnimatedBuilder(
                              animation: _searchFocusAnimation,
                              builder: (context, child) {
                                final double rotation =
                                    -0.12 *
                                    (1.0 - _searchFocusAnimation.value) *
                                    2 *
                                    math.pi;
                                final normalColor = Color.lerp(
                                  context.colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                  isDark
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFF0097B2),
                                  _searchFocusAnimation.value,
                                )!;
                                final color = hasNoResults
                                    ? AppColors.warning
                                    : normalColor;

                                return Transform.rotate(
                                  angle: rotation,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: hasNoResults
                                        ? Icon(
                                            Icons.search_off_rounded,
                                            key: const ValueKey('search_off'),
                                            color: color,
                                            size: 28,
                                          )
                                        : Icon(
                                            Icons.search,
                                            key: const ValueKey('search_on'),
                                            color: color,
                                            size: 28,
                                          ),
                                  ),
                                );
                              },
                            ),
                            suffixIcon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: CurvedAnimation(
                                    parent: animation,
                                    curve: const Cubic(0.05, 0.7, 0.1, 1.0),
                                  ),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      key: const ValueKey(
                                        'clear_route_modal_search',
                                      ),
                                      icon: Icon(
                                        Icons.clear,
                                        color: context.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _searchFocusAnimation,
                            builder: (context, child) {
                              final showHint = _searchController.text.isEmpty;
                              if (!showHint) return const SizedBox.shrink();

                              final double startOffset = 52.0;
                              final double endOffset = 44.0;
                              final currentOffset =
                                  startOffset +
                                  (endOffset - startOffset) *
                                      _searchFocusAnimation.value;
                              final double opacity =
                                  0.4 +
                                  (0.2 - 0.4) * _searchFocusAnimation.value;

                              return Padding(
                                padding: EdgeInsets.only(left: currentOffset),
                                child: Text(
                                  'Search routes...',
                                  style: TextStyle(
                                    color: context.colorScheme.onSurface
                                        .withValues(alpha: opacity),
                                    fontSize: 15,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ).p(AppSizes.paddingMedium),

                // Routes List
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: Builder(
                      builder: (context) {
                        String? defaultRouteId;
                        try {
                          defaultRouteId = widget.buses
                              .firstWhere(
                                (b) => b.busNumber == widget.busNumberToAssign,
                              )
                              .defaultRouteId;
                        } catch (_) {}

                        return filteredRoutes.isEmpty
                            ? VectorEmptyState(
                                title: 'No Routes Found',
                                description: _searchQuery.isNotEmpty
                                    ? 'No routes match "$_searchQuery". Try searching for a different route name.'
                                    : 'There are no routes available to select.',
                              ).p(16)
                            : ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filteredRoutes.length,
                                itemBuilder: (context, index) {
                                  final route = filteredRoutes[index];
                                  final isSelected =
                                      _selectedRoute?.id == route.id;
                                  final isDefault = route.id == defaultRouteId;
                                  final conflictingBus = _findBusWithRoute(
                                    route.id,
                                  );

                                  return Card(
                                    elevation: 0,
                                    color: isSelected
                                        ? context.colorScheme.primary
                                              .withValues(alpha: 0.08)
                                        : Colors.transparent,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: isSelected
                                            ? context.colorScheme.primary
                                                  .withValues(alpha: 0.4)
                                            : context.colorScheme.onSurface
                                                  .withValues(alpha: 0.06),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              route.routeName,
                                              style: TextStyle(
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: isSelected
                                                    ? context
                                                          .colorScheme
                                                          .primary
                                                    : context
                                                          .colorScheme
                                                          .onSurface,
                                              ),
                                            ),
                                          ),
                                          if (isDefault)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.success
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: AppColors.success
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                              child: Text(
                                                'DEFAULT',
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.success,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: conflictingBus != null
                                          ? Text(
                                              'Assigned to Bus ${conflictingBus.busNumber}',
                                              style: TextStyle(
                                                color: AppColors.warning,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          : Text(
                                              '${route.stopPoints.length} stops',
                                              style: TextStyle(
                                                color: context
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                      trailing: isSelected
                                          ? Icon(
                                              Icons.check_circle_rounded,
                                              color:
                                                  context.colorScheme.primary,
                                            )
                                          : null,
                                      onTap: () => _handleRouteSelection(route),
                                    ),
                                  );
                                },
                              );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom Actions
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.01),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            String? defaultRouteId;
                            try {
                              defaultRouteId = widget.buses
                                  .firstWhere(
                                    (b) =>
                                        b.busNumber == widget.busNumberToAssign,
                                  )
                                  .defaultRouteId;
                            } catch (_) {}

                            final isDefault =
                                _selectedRoute != null &&
                                _selectedRoute!.id == defaultRouteId;

                            return ElevatedButton(
                              onPressed: _selectedRoute == null
                                  ? null
                                  : () =>
                                        Navigator.pop(context, _selectedRoute),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isDefault ? 'Assign Default' : 'Assign Route',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
        ),
      ),
    );
  }
}
