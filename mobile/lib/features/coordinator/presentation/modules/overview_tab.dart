import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/features/sos/application/sos_provider.dart';
import 'package:collegebus/features/user/application/user_provider.dart';
import 'package:collegebus/features/coordinator/presentation/modules/overview_components/broadcast_modal.dart';
import 'package:collegebus/shared/widgets/shimmer_skeletons.dart';

class OverviewTab extends ConsumerWidget {
  final VoidCallback? onSosTap;

  const OverviewTab({super.key, this.onSosTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;

    if (collegeId == null) return const SizedBox.shrink();

    final routesAsync = ref.watch(collegeRoutesProvider(collegeId));
    final busesAsync = ref.watch(collegeBusesStreamProvider(collegeId));
    final pendingDriversAsync = ref.watch(pendingApprovalsProvider(collegeId));
    final busNumbersAsync = ref.watch(busNumbersProvider(collegeId));

    if (routesAsync.isLoading ||
        busesAsync.isLoading ||
        pendingDriversAsync.isLoading ||
        busNumbersAsync.isLoading) {
      return const StatCardsSkeleton();
    }

    final routes = routesAsync.value ?? [];
    final buses = busesAsync.value ?? [];
    final pendingDrivers = pendingDriversAsync.value ?? [];
    final busNumbers = busNumbersAsync.value ?? [];
    final activeSosCount = ref.watch(
      activeSosProvider(collegeId).select((v) => v.value?.length ?? 0),
    );

    return SingleChildScrollView(
      child: VStack([
        'System Overview'.text
            .size(24)
            .bold
            .color(
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : context.colorScheme.onSurface,
            )
            .make(),
        AppSizes.paddingLarge.heightBox,

        // Statistics Cards
        HStack([
          StatCard(
            title: 'Active Buses',
            value: buses.where((b) => b.isActive).length.toString(),
            icon: Icons.directions_bus,
            accentColor: AppColors.primary,
          ).expand(),
          AppSizes.paddingMedium.widthBox,
          StatCard(
            title: 'Total Routes',
            value: routes.length.toString(),
            icon: Icons.route,
            accentColor: AppColors.primary,
          ).expand(),
        ]),

        AppSizes.paddingMedium.heightBox,

        HStack([
          StatCard(
            title: 'Pending Drivers',
            value: pendingDrivers.length.toString(),
            icon: Icons.pending,
            accentColor: AppColors.error,
          ).expand(),
          AppSizes.paddingMedium.widthBox,
          StatCard(
            title: 'Bus Numbers',
            value: busNumbers.length.toString(),
            icon: Icons.confirmation_number,
            accentColor: AppColors.warning,
          ).expand(),
        ]),

        AppSizes.paddingMedium.heightBox,

        // Broadcast Card (Glassmorphic)
        GlassmorphicCard(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const BroadcastModal(),
            );
          },
          accentColor: AppColors.primary,
          child: HStack([
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00C6E6), Color(0xFF0097B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            16.widthBox,
            VStack([
              'Send Broadcast Message'.text.bold.lg.make(),
              'Notify all students, teachers & parents'.text
                  .color(context.colorScheme.onSurface.withValues(alpha: 0.6))
                  .size(12)
                  .make(),
            ]).expand(),
            Icon(
              Icons.chevron_right,
              color: context.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ]).p(16),
        ),

        if (activeSosCount > 0) ...[
          AppSizes.paddingMedium.heightBox,
          Card(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.error, width: 2.0),
            ),
            child: HStack([
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 40,
              ),
              16.widthBox,
              VStack([
                'EMERGENCY ALERTS'.text.color(AppColors.error).bold.xl.make(),
                '$activeSosCount driver(s) requesting help!'.text
                    .color(AppColors.error)
                    .make(),
              ]).expand(),
              Icon(Icons.chevron_right, color: AppColors.error),
            ]).p(16),
          ).onTap(() {
            onSosTap?.call();
          }),
        ],
      ]).p(AppSizes.paddingMedium),
    );
  }

}

class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with TickerProviderStateMixin {
  late AnimationController _countController;
  late Animation<int> _countAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final parsedValue = int.tryParse(widget.value) ?? 0;

    _countController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _countAnimation = IntTween(begin: 0, end: parsedValue).animate(
      CurvedAnimation(parent: _countController, curve: Curves.easeOutCubic),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _countController.forward();
  }

  @override
  void didUpdateWidget(StatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final oldVal = int.tryParse(oldWidget.value) ?? 0;
      final newVal = int.tryParse(widget.value) ?? 0;
      _countAnimation = IntTween(begin: oldVal, end: newVal).animate(
        CurvedAnimation(parent: _countController, curve: Curves.easeOutCubic),
      );
      _countController.reset();
      _countController.forward();
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Color> gradientColors;
    if (widget.accentColor == AppColors.error) {
      gradientColors = [const Color(0xFFFF5252), const Color(0xFFFF1744)];
    } else if (widget.accentColor == AppColors.warning) {
      gradientColors = [const Color(0xFFFFD54F), const Color(0xFFFF8F00)];
    } else {
      gradientColors = [const Color(0xFF00C6E6), const Color(0xFF0097B2)];
    }

    return GestureDetector(
      onTapDown: (_) {
        _scaleController.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: () {},
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: isDark
                    ? widget.accentColor.withValues(alpha: 0.1)
                    : widget.accentColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Icon(
                      widget.icon,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  AppSizes.paddingSmall.heightBox,
                  AnimatedBuilder(
                    animation: _countAnimation,
                    builder: (context, child) {
                      final valText = int.tryParse(widget.value) != null
                          ? _countAnimation.value.toString()
                          : widget.value;
                      return ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          valText,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  AppSizes.paddingSmall.heightBox,
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.6),
                    ),
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

class GlassmorphicCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color accentColor;

  const GlassmorphicCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.accentColor,
  });

  @override
  State<GlassmorphicCard> createState() => _GlassmorphicCardState();
}

class _GlassmorphicCardState extends State<GlassmorphicCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) {
        _scaleController.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? widget.accentColor.withValues(alpha: 0.1)
                    : widget.accentColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
