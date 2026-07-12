import 'dart:ui' show ImageFilter;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/features/user/application/user_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'modules/bus_tab_components/route_selection_modal.dart';
import 'package:collegebus/shared/widgets/shimmer_skeletons.dart';
import 'package:collegebus/shared/widgets/vector_empty_state.dart';

class SineCurve extends Curve {
  final double count;
  const SineCurve({this.count = 3});
  @override
  double transformInternal(double t) {
    return math.sin(t * count * 2 * math.pi);
  }
}

class DriverSelectionScreen extends ConsumerStatefulWidget {
  final String busNumber;

  const DriverSelectionScreen({super.key, required this.busNumber});

  @override
  ConsumerState<DriverSelectionScreen> createState() =>
      _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends ConsumerState<DriverSelectionScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _searchAnimController;
  late Animation<double> _searchFocusAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  String _searchQuery = '';
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

  Widget _buildConfirmDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: context.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black45,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

    // 2. Show Final Confirmation with Premium Styling
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Confirm Assignment',
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
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.assignment_ind_rounded,
                          color: context.colorScheme.primary,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Confirm Assignment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Details Grid
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildConfirmDetailRow(
                              context,
                              'Driver',
                              driver.fullName,
                              Icons.person_rounded,
                            ),
                            const Divider(height: 24),
                            _buildConfirmDetailRow(
                              context,
                              'Route',
                              selectedRoute.routeName,
                              Icons.route_rounded,
                            ),
                            const Divider(height: 24),
                            _buildConfirmDetailRow(
                              context,
                              'Bus Number',
                              widget.busNumber,
                              Icons.directions_bus_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
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
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  final repo = ref.read(busRepositoryProvider);
                                  final currentUser = ref.read(
                                    currentUserProvider,
                                  );

                                  if (currentUser == null ||
                                      currentUser.collegeId.isEmpty) {
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                    if (mounted) {
                                      ApiErrorModal.show(
                                        context: context,
                                        error:
                                            "Session Invalid. Please login again.",
                                      );
                                    }
                                    return;
                                  }

                                  final bus = buses.firstWhere(
                                    (b) =>
                                        b.busNumber == widget.busNumber &&
                                        b.collegeId == currentUser.collegeId,
                                    orElse: () =>
                                        throw Exception('Bus not found'),
                                  );

                                  await repo.assignDriverToBus(
                                    busId: bus.id,
                                    driverId: driver.id,
                                    routeId: selectedRoute.id,
                                  );

                                  ref
                                      .read(socketServiceProvider)
                                      .sendBusListUpdate();

                                  if (dialogContext.mounted) {
                                    Navigator.pop(
                                      dialogContext,
                                    ); // Close Confirm Dialog
                                  }

                                  if (dialogContext.mounted && mounted) {
                                    await SuccessModal.show(
                                      context: context,
                                      title: 'Success',
                                      message:
                                          'Successfully assigned ${driver.fullName} and route ${selectedRoute.routeName}',
                                      primaryActionText: 'OK',
                                    );

                                    if (mounted) {
                                      Navigator.pop(
                                        context,
                                      ); // Return to bus list
                                    }
                                  }
                                } catch (e) {
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                  if (mounted) {
                                    ApiErrorModal.show(
                                      context: context,
                                      error: e,
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Assign',
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final collegeId = ref.watch(currentUserProvider)?.collegeId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (collegeId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Assign Driver to ${widget.busNumber}'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('College context error')),
      );
    }

    final driversAsync = ref.watch(
      usersByRoleProvider((role: UserRole.driver, collegeId: collegeId)),
    );
    final busesAsync = ref.watch(allCollegeBusesStreamProvider(collegeId));
    final routesAsync = ref.watch(collegeRoutesProvider(collegeId));

    final isLoading =
        driversAsync.isLoading || busesAsync.isLoading || routesAsync.isLoading;
    final hasError =
        driversAsync.hasError || busesAsync.hasError || routesAsync.hasError;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Assign Driver (Bus ${widget.busNumber})'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const DriverSelectionSkeleton(),
      );
    }

    if (hasError) {
      final error = driversAsync.error ?? busesAsync.error ?? routesAsync.error;
      return Scaffold(
        appBar: AppBar(
          title: Text('Assign Driver (Bus ${widget.busNumber})'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text('Error loading assignment data: $error')),
      );
    }

    final drivers = driversAsync.value ?? [];
    final buses = busesAsync.value ?? [];
    final routes = routesAsync.value ?? [];

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

    final hasNoResults = filteredDrivers.isEmpty && _searchQuery.isNotEmpty;
    if (hasNoResults && !_wasEmpty) {
      _wasEmpty = true;
      _shakeController.forward(from: 0.0);
    } else if (!hasNoResults) {
      _wasEmpty = false;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Assign Driver (Bus ${widget.busNumber})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFF0097B2), const Color(0xFF00C6E6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: VStack([
        // Search Bar with sliding animation, glow, validation, and shake
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
              final double glowOpacity = 0.08 * _searchFocusAnimation.value;
              final baseBorderColor = hasNoResults
                  ? AppColors.warning.withValues(alpha: 0.4)
                  : context.colorScheme.onSurface.withValues(alpha: 0.08);
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
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: borderColor, width: borderWidth),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(
                        alpha: hasNoResults ? 0.06 : glowOpacity,
                      ),
                      blurRadius: 8 * _searchFocusAnimation.value,
                      spreadRadius: 2 * _searchFocusAnimation.value,
                    ),
                    BoxShadow(
                      color: isDark
                          ? Colors.black26
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
                  onChanged: (val) => setState(() => _searchQuery = val),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    prefixIcon: AnimatedBuilder(
                      animation: _searchFocusAnimation,
                      builder: (context, child) {
                        final double rotation =
                            -0.12 *
                            (1.0 - _searchFocusAnimation.value) *
                            2 *
                            math.pi;
                        final normalColor = Color.lerp(
                          context.colorScheme.onSurface.withValues(alpha: 0.4),
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
                              key: const ValueKey('clear_driver_search'),
                              icon: Icon(
                                Icons.clear,
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
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
                          0.4 + (0.2 - 0.4) * _searchFocusAnimation.value;

                      return Padding(
                        padding: EdgeInsets.only(left: currentOffset),
                        child: Text(
                          'Search drivers by name or email...',
                          style: TextStyle(
                            color: context.colorScheme.onSurface.withValues(
                              alpha: opacity,
                            ),
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
        ).pOnly(left: 16, right: 16, top: 16, bottom: 12),

        if (filteredDrivers.isEmpty)
          VectorEmptyState(
            title: 'No Drivers Found',
            description: _searchQuery.isNotEmpty
                ? 'No drivers match "$_searchQuery". Try searching for a different name or email.'
                : 'There are no drivers available for assignment right now.',
          ).expand()
        else
          ListView.builder(
            itemCount: filteredDrivers.length,
            padding: const EdgeInsets.only(bottom: 24),
            itemBuilder: (context, index) {
              final driver = filteredDrivers[index];
              final driverName = driver.fullName;
              final initials = driverName.isNotEmpty ? driverName[0] : '?';

              return Card(
                elevation: 0,
                color: context.cardColor,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: context.colorScheme.onSurface.withValues(
                      alpha: 0.08,
                    ),
                    width: 1.2,
                  ),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [
                                const Color(0xFF0097B2),
                                const Color(0xFF00C6E6),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark
                              ? Colors.black26
                              : const Color(0xFF0097B2).withValues(alpha: 0.2)),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: initials.text.white.bold.size(16).make(),
                    ),
                  ),
                  title: driverName.text.semiBold.size(16).make(),
                  subtitle: driver.email.text
                      .size(13)
                      .color(
                        context.colorScheme.onSurface.withValues(alpha: 0.6),
                      )
                      .make(),
                  onTap: () => _showAssignConfirmation(
                    driver: driver,
                    routes: routes,
                    buses: buses,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary.withValues(
                        alpha: 0.08,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: context.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ).expand(),
      ]),
    );
  }
}
