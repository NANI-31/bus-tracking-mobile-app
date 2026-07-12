import 'dart:ui';
import 'dart:math' as math;
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
import 'package:collegebus/features/coordinator/presentation/teacher_override_requests_screen.dart';
import 'package:collegebus/shared/widgets/shimmer_skeletons.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';
import 'package:flutter/cupertino.dart' show RefreshIndicatorMode;

class OverviewTab extends ConsumerWidget {
  final VoidCallback? onSosTap;
  final VoidCallback? onActiveBusesTap;

  const OverviewTab({super.key, this.onSosTap, this.onActiveBusesTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;

    if (collegeId == null) return const SizedBox.shrink();

    final double screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = AppSizes.paddingMedium;
    if (screenWidth >= 800) {
      horizontalPadding = screenWidth * 0.08;
    } else if (screenWidth >= 600) {
      horizontalPadding = screenWidth * 0.04;
    }

    final routesAsync = ref.watch(collegeRoutesProvider(collegeId));
    final busesAsync = ref.watch(collegeBusesStreamProvider(collegeId));
    final pendingDriversAsync = ref.watch(pendingApprovalsProvider(collegeId));
    final busNumbersAsync = ref.watch(busNumbersProvider(collegeId));
    final overrideRequestsAsync = ref.watch(teacherOverrideRequestsProvider);

    if (routesAsync.isLoading ||
        busesAsync.isLoading ||
        pendingDriversAsync.isLoading ||
        busNumbersAsync.isLoading) {
      return const StatCardsSkeleton();
    }

    final routes = routesAsync.valueOrNull ?? [];
    final buses = busesAsync.valueOrNull ?? [];
    final pendingDrivers = pendingDriversAsync.valueOrNull ?? [];
    final busNumbers = busNumbersAsync.valueOrNull ?? [];
    final pendingOverridesCount = overrideRequestsAsync.valueOrNull?.length ?? 0;
    final rawActiveSosCount = ref.watch(
      activeSosProvider(collegeId).select((v) => v.valueOrNull?.length ?? 0),
    );
    final activeSosCount = rawActiveSosCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LiquidSpringRefresh(
      onRefresh: () async {
        ref.invalidate(collegeRoutesProvider(collegeId));
        ref.invalidate(collegeBusesStreamProvider(collegeId));
        ref.invalidate(pendingApprovalsProvider(collegeId));
        ref.invalidate(busNumbersProvider(collegeId));
        ref.invalidate(activeSosProvider(collegeId));
        ref.invalidate(teacherOverrideRequestsProvider);
        await Future.delayed(const Duration(milliseconds: 1500));
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: AppSizes.paddingMedium,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome / Theme-Responsive Illustration
                const ResponsiveDashboardIllustration(),
                AppSizes.paddingMedium.heightBox,

                // Statistics Cards (Responsive grid)
                Builder(
                  builder: (context) {
                    final double screenWidth = MediaQuery.of(
                      context,
                    ).size.width;

                    final totalBuses = buses.length;
                    final activeBuses = buses.where((b) => b.isActive).length;
                    final activeBusesProgress = totalBuses > 0
                        ? activeBuses / totalBuses
                        : 0.0;

                    final activeBusesCard = StatCard(
                      title: 'Active Buses',
                      value: activeBuses.toString(),
                      icon: Icons.directions_bus,
                      accentColor: AppColors.primary,
                      staggerIndex: 0,
                      progress: activeBusesProgress,
                      onTap: onActiveBusesTap,
                    );

                    final totalRoutesCard = StatCard(
                      title: 'Total Routes',
                      value: routes.length.toString(),
                      icon: Icons.route,
                      accentColor: Colors.grey,
                      staggerIndex: 1,
                    );

                    final pendingDriversCard = StatCard(
                      title: 'Pending Drivers',
                      value: pendingDrivers.length.toString(),
                      icon: Icons.pending,
                      accentColor: AppColors.error,
                      staggerIndex: 2,
                    );

                    final busNumbersCard = StatCard(
                      title: 'Bus Numbers',
                      value: busNumbers.length.toString(),
                      icon: Icons.confirmation_number,
                      accentColor: AppColors.warning,
                      staggerIndex: 3,
                    );

                    if (screenWidth >= 650) {
                      return Row(
                        children: [
                          Expanded(child: activeBusesCard),
                          const SizedBox(width: 12),
                          Expanded(child: totalRoutesCard),
                          const SizedBox(width: 12),
                          Expanded(child: pendingDriversCard),
                          const SizedBox(width: 12),
                          Expanded(child: busNumbersCard),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: activeBusesCard),
                              const SizedBox(width: 12),
                              Expanded(child: totalRoutesCard),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: pendingDriversCard),
                              const SizedBox(width: 12),
                              Expanded(child: busNumbersCard),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),

                AppSizes.paddingMedium.heightBox,

                // Broadcast Card (Glassmorphic)
                GlassmorphicCard(
                  staggerIndex: 4,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const BroadcastModal(),
                    );
                  },
                  accentColor: AppColors.primary,
                  child: CustomPaint(
                    painter: DotMatrixPainter(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                    ),
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
                            .color(
                              context.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            )
                            .size(12)
                            .make(),
                      ]).expand(),
                      Icon(
                        Icons.chevron_right,
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ]).p(16),
                  ),
                ),

                AppSizes.paddingMedium.heightBox,

                // Teacher Override Requests Card
                GlassmorphicCard(
                  staggerIndex: 5,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherOverrideRequestsScreen(),
                      ),
                    );
                  },
                  accentColor: AppColors.warning,
                  child: CustomPaint(
                    painter: DotMatrixPainter(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                    ),
                    child: HStack([
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                Icons.alt_route,
                                color: Colors.white,
                                size: 28,
                              ),
                              if (pendingOverridesCount > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Center(
                                      child: '$pendingOverridesCount'
                                          .text
                                          .color(Colors.white)
                                          .size(9)
                                          .bold
                                          .make(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      16.widthBox,
                      VStack([
                        'Teacher Override Requests'.text.bold.make(),
                        'Review teacher tracking authorization requests'.text
                            .color(
                              context.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            )
                            .size(12)
                            .make(),
                      ]).expand(),
                      Icon(
                        Icons.chevron_right,
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ]).p(16),
                  ),
                ),

                AppSizes.paddingMedium.heightBox,
                const TelemetryChartsCard(),

                if (activeSosCount > 0) ...[
                  AppSizes.paddingMedium.heightBox,
                  GestureDetector(
                    onTap: () => onSosTap?.call(),
                    child: Container(
                      height: 84,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(
                              alpha: isDark ? 0.35 : 0.10,
                            ),
                            blurRadius: 18,
                            spreadRadius: -2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(
                                          0xFF450A0A,
                                        ).withValues(alpha: 0.65),
                                        const Color(
                                          0xFF7F1D1D,
                                        ).withValues(alpha: 0.65),
                                      ]
                                    : [
                                        const Color(
                                          0xFFFFF1F2,
                                        ).withValues(alpha: 0.32),
                                        const Color(
                                          0xFFFFE4E6,
                                        ).withValues(alpha: 0.24),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.error.withValues(alpha: 0.5)
                                    : const Color(
                                        0xFFF43F5E,
                                      ).withValues(alpha: 0.15),
                                width: 2.0,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Caution Warning Stripes on the left side
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: 24,
                                  child: ClipRect(
                                    child: CustomPaint(
                                      painter: CautionStripePainter(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.15,
                                              )
                                            : Colors.red.withValues(
                                                alpha: 0.15,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Dot Matrix texture in background
                                Positioned.fill(
                                  left: 24,
                                  child: CustomPaint(
                                    painter: DotMatrixPainter(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.03)
                                          : Colors.black.withValues(
                                              alpha: 0.02,
                                            ),
                                    ),
                                  ),
                                ),

                                // Content
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 32,
                                    right: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          const MicroLottieRadarCircle(
                                            color: AppColors.error,
                                            size: 56.0,
                                          ),
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: isDark
                                                ? Colors.redAccent
                                                : AppColors.error,
                                            size: 28,
                                          ),
                                        ],
                                      ),
                                      16.widthBox,
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          'EMERGENCY ALERTS'.text
                                              .color(
                                                isDark
                                                    ? Colors.red.shade200
                                                    : AppColors.error,
                                              )
                                              .bold
                                              .lg
                                              .letterSpacing(0.5)
                                              .make(),
                                          2.heightBox,
                                          '$activeSosCount driver(s) requesting help!'
                                              .text
                                              .size(13)
                                              .medium
                                              .color(
                                                isDark
                                                    ? Colors.white70
                                                    : Colors.red.shade900,
                                              )
                                              .make(),
                                        ],
                                      ).expand(),
                                      Icon(
                                        Icons.chevron_right,
                                        color: isDark
                                            ? Colors.red.shade300
                                            : AppColors.error,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const BottomNavSpacer(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final int staggerIndex;
  final double? progress;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.staggerIndex = 0,
    this.progress,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with TickerProviderStateMixin {
  late AnimationController _countController;
  late Animation<int> _countAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Staggered entrance animation
  late AnimationController _entryController;
  late Animation<double> _entryFadeAnimation;
  late Animation<double> _entrySlideAnimation;

  // Progress animation
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

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

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _entryFadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _entrySlideAnimation = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0), // overshoot spring curve
      ),
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress ?? 0.0)
        .animate(
          CurvedAnimation(
            parent: _progressController,
            curve: const Cubic(0.34, 1.56, 0.64, 1.0),
          ),
        );

    _countController.forward();

    if (widget.progress != null) {
      _progressController.forward();
    }

    Future.delayed(Duration(milliseconds: widget.staggerIndex * 70), () {
      if (mounted) {
        _entryController.forward();
      }
    });
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
    if (oldWidget.progress != widget.progress) {
      final oldProgress = oldWidget.progress ?? 0.0;
      final newProgress = widget.progress ?? 0.0;
      _progressAnimation = Tween<double>(begin: oldProgress, end: newProgress)
          .animate(
            CurvedAnimation(
              parent: _progressController,
              curve: const Cubic(0.34, 1.56, 0.64, 1.0),
            ),
          );
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    _scaleController.dispose();
    _entryController.dispose();
    _progressController.dispose();
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
    } else if (widget.accentColor == Colors.grey) {
      gradientColors = [const Color(0xFF9E9E9E), const Color(0xFF616161)];
    } else {
      gradientColors = [const Color(0xFF00C6E6), const Color(0xFF0097B2)];
    }

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0.0, _entrySlideAnimation.value),
          child: Opacity(opacity: _entryFadeAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          _scaleController.forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        onTap: widget.onTap ?? () {},
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.08),
                            widget.accentColor.withValues(alpha: 0.04),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.70),
                            widget.accentColor.withValues(alpha: 0.05),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: widget.accentColor.withValues(
                      alpha: isDark ? 0.25 : 0.15,
                    ),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(
                        alpha: isDark ? 0.15 : 0.06,
                      ),
                      blurRadius: 16,
                      spreadRadius: -2,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.15 : 0.03,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: DotMatrixPainter(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.02),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        widget.progress != null
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _progressAnimation,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        size: const Size(36, 36),
                                        painter: ProgressRingPainter(
                                          progress: _progressAnimation.value,
                                          trackColor: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.08,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                          progressColors: gradientColors,
                                        ),
                                      );
                                    },
                                  ),
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: gradientColors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: Icon(
                                      widget.icon,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : ShaderMask(
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
          ),
        ),
      ),
    );
  }
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final List<Color> progressColors;

  ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4.5) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: progressColors,
          startAngle: 0.0,
          endAngle: 2 * math.pi,
          transform: GradientRotation(startAngle),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.0;

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColors != progressColors;
  }
}

class GlassmorphicCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color accentColor;
  final int staggerIndex;

  const GlassmorphicCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.accentColor,
    this.staggerIndex = 0,
  });

  @override
  State<GlassmorphicCard> createState() => _GlassmorphicCardState();
}

class _GlassmorphicCardState extends State<GlassmorphicCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Staggered entrance animation
  late AnimationController _entryController;
  late Animation<double> _entryFadeAnimation;
  late Animation<double> _entrySlideAnimation;

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

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _entryFadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entrySlideAnimation = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
      ),
    );

    Future.delayed(Duration(milliseconds: widget.staggerIndex * 70), () {
      if (mounted) {
        _entryController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0.0, _entrySlideAnimation.value),
          child: Opacity(opacity: _entryFadeAnimation.value, child: child),
        );
      },
      child: GestureDetector(
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
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.08),
                            widget.accentColor.withValues(alpha: 0.04),
                          ]
                        : [
                            const Color(0xFFE6F8FA).withValues(alpha: 0.32),
                            const Color(0xFFE0F2FE).withValues(alpha: 0.24),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? widget.accentColor.withValues(alpha: 0.25)
                        : const Color(0xFF0097B2).withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(
                        alpha: isDark ? 0.15 : 0.06,
                      ),
                      blurRadius: 16,
                      spreadRadius: -2,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.15 : 0.03,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MicroLottieRadarCircle extends StatefulWidget {
  final Color color;
  final double size;

  const MicroLottieRadarCircle({
    super.key,
    this.color = const Color(0xFFFF1744),
    this.size = 48.0,
  });

  @override
  State<MicroLottieRadarCircle> createState() => _MicroLottieRadarCircleState();
}

class _MicroLottieRadarCircleState extends State<MicroLottieRadarCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: RadarCirclePainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class RadarCirclePainter extends CustomPainter {
  final double progress;
  final Color color;

  RadarCirclePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw 3 concentric pulsing rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i / 3.0)) % 1.0;
      final opacity = (1.0 - ringProgress) * 0.6;
      final radius = maxRadius * ringProgress;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, paint);

      final strokePaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, radius, strokePaint);
    }

    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6.0, corePaint);

    final coreGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10.0, coreGlowPaint);
  }

  @override
  bool shouldRepaint(covariant RadarCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class ResponsiveDashboardIllustration extends ConsumerWidget {
  final double height;

  const ResponsiveDashboardIllustration({super.key, this.height = 140.0});

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return "${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF00C6E6).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Dot Matrix
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: DotMatrixPainter(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                ),
              ),
            ),
          ),

          // Background details
          Positioned(
            right: 20,
            top: 15,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: isDark
                  ? const Icon(
                      Icons.nights_stay_rounded,
                      color: Colors.amber,
                      size: 48,
                      key: ValueKey('moon'),
                    )
                  : const Icon(
                      Icons.wb_sunny_rounded,
                      color: Colors.orangeAccent,
                      size: 48,
                      key: ValueKey('sun'),
                    ),
            ),
          ),

          if (isDark) ...[
            const Positioned(
              left: 40,
              top: 20,
              child: Icon(Icons.star, color: Colors.white24, size: 8),
            ),
            const Positioned(
              left: 100,
              top: 15,
              child: Icon(Icons.star, color: Colors.white30, size: 12),
            ),
            const Positioned(
              left: 180,
              top: 35,
              child: Icon(Icons.star, color: Colors.white24, size: 10),
            ),
          ] else ...[
            Positioned(
              left: 30,
              top: 25,
              child: Icon(
                Icons.cloud_queue_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 36,
              ),
            ),
            Positioned(
              left: 120,
              top: 15,
              child: Icon(
                Icons.cloud_queue_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 28,
              ),
            ),
          ],

          // Drawing path/route line
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.white24, Colors.white10]
                      : [
                          AppColors.primary.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),

          // Bus symbol/illustration
          Positioned(
            right: 20,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : AppColors.primary.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF00C6E6).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_bus,
                    color: Color(0xFF00C6E6),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Fleet Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Text(
                        isDark ? 'All Systems Glowing' : 'All Systems Active',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark
                              ? Colors.greenAccent
                              : AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Greeting text overlay
          Positioned(
            left: 20,
            top: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                'Welcome back,'.text
                    .size(14)
                    .semiBold
                    .color(isDark ? Colors.white70 : Colors.teal.shade800)
                    .make(),
                2.heightBox,
                (user?.fullName ?? 'Coordinator').text
                    .size(22)
                    .bold
                    .color(isDark ? Colors.white : Colors.teal.shade900)
                    .make(),
                8.heightBox,
                _getFormattedDate().text
                    .size(11)
                    .color(isDark ? Colors.white54 : Colors.teal.shade700)
                    .make(),
              ],
            ),
          ),

          // Glowing system status nominal badge
          Positioned(
            left: 20,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SystemStatusRadarDot(),
                  6.widthBox,
                  'SYSTEM NOMINAL'.text
                      .size(9)
                      .bold
                      .letterSpacing(0.5)
                      .color(Colors.green)
                      .make(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SystemStatusRadarDot extends StatefulWidget {
  const SystemStatusRadarDot({super.key});

  @override
  State<SystemStatusRadarDot> createState() => _SystemStatusRadarDotState();
}

class _SystemStatusRadarDotState extends State<SystemStatusRadarDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      height: 8,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final ringOpacity = (1.0 - _controller.value) * 0.7;
          final scale = 1.0 + (_controller.value * 2.0);

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withValues(alpha: ringOpacity),
                  ),
                ),
              ),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DotMatrixPainter extends CustomPainter {
  final Color color;
  const DotMatrixPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double step = 14.0;
    for (double x = 7.0; x < size.width; x += step) {
      for (double y = 7.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotMatrixPainter oldDelegate) =>
      oldDelegate.color != color;
}

class CautionStripePainter extends CustomPainter {
  final Color color;
  const CautionStripePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const double gap = 16.0;
    const double angleOffset = 10.0;

    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height + angleOffset, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CautionStripePainter oldDelegate) =>
      oldDelegate.color != color;
}

enum CustomRefreshState { idle, pulling, armed, refreshing, done }

class LiquidSpringRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const LiquidSpringRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  State<LiquidSpringRefresh> createState() => _LiquidSpringRefreshState();
}

class _LiquidSpringRefreshState extends State<LiquidSpringRefresh>
    with TickerProviderStateMixin {
  CustomRefreshState _state = CustomRefreshState.idle;
  CustomRefreshState _lastTriggerState = CustomRefreshState.idle;
  double _pullDistance = 0.0;
  List<double> _particleAngles = [];

  late AnimationController _waveController;
  late AnimationController _spinController;
  late AnimationController _transitionController;

  double _animatingOffset = 0.0;
  bool _isAnimatingOffset = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _spinController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _startRefresh() {
    HapticFeedback.mediumImpact();

    // Initialize 6 splash particles at different angles
    final rand = math.Random();
    _particleAngles = List.generate(6, (i) {
      return (i * 2 * math.pi / 6) + (rand.nextDouble() * 0.4 - 0.2);
    });

    setState(() {
      _state = CustomRefreshState.refreshing;
      _spinController.repeat();
      _isAnimatingOffset = true;
    });

    final double startOffset = _pullDistance;
    final Animation<double> curveAnim = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutBack,
    );

    final Animation<double> offsetTween = Tween<double>(
      begin: startOffset,
      end: 50.0,
    ).animate(curveAnim);

    void listener() {
      setState(() {
        _animatingOffset = offsetTween.value;
      });
    }

    _transitionController.addListener(listener);
    _transitionController.forward(from: 0.0).then((_) {
      _transitionController.removeListener(listener);
      setState(() {
        _pullDistance = 50.0;
        _isAnimatingOffset = false;
      });

      widget.onRefresh().then((_) {
        if (mounted) {
          _endRefresh();
        }
      });
    });
  }

  void _endRefresh() {
    setState(() {
      _state = CustomRefreshState.done;
      _spinController.stop();
      _isAnimatingOffset = true;
    });

    final Animation<double> curveAnim = CurvedAnimation(
      parent: _transitionController,
      curve: const Cubic(0.34, 1.56, 0.64, 1.0),
    );

    final Animation<double> offsetTween = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(curveAnim);

    void listener() {
      setState(() {
        _animatingOffset = offsetTween.value;
      });
    }

    _transitionController.addListener(listener);
    _transitionController.forward(from: 0.0).then((_) {
      _transitionController.removeListener(listener);
      setState(() {
        _pullDistance = 0.0;
        _animatingOffset = 0.0;
        _isAnimatingOffset = false;
        _state = CustomRefreshState.idle;
        _lastTriggerState = CustomRefreshState.idle;
        _particleAngles = [];
      });
    });
  }

  void _snapBackToZero() {
    setState(() {
      _isAnimatingOffset = true;
    });

    final double startOffset = _pullDistance;
    final Animation<double> curveAnim = CurvedAnimation(
      parent: _transitionController,
      curve: const Cubic(0.34, 1.56, 0.64, 1.0),
    );

    final Animation<double> offsetTween = Tween<double>(
      begin: startOffset,
      end: 0.0,
    ).animate(curveAnim);

    void listener() {
      setState(() {
        _animatingOffset = offsetTween.value;
      });
    }

    _transitionController.addListener(listener);
    _transitionController.forward(from: 0.0).then((_) {
      _transitionController.removeListener(listener);
      setState(() {
        _pullDistance = 0.0;
        _animatingOffset = 0.0;
        _isAnimatingOffset = false;
        _state = CustomRefreshState.idle;
        _lastTriggerState = CustomRefreshState.idle;
        _particleAngles = [];
      });
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_state == CustomRefreshState.refreshing ||
        _state == CustomRefreshState.done) {
      return false;
    }
    if (notification.depth != 0) return false;

    final double pixels = notification.metrics.pixels;

    if (pixels < 0) {
      final double pullDistance = -pixels;

      setState(() {
        _pullDistance = pullDistance;
        _state = pullDistance >= 90.0
            ? CustomRefreshState.armed
            : CustomRefreshState.pulling;
      });

      if (_state == CustomRefreshState.armed &&
          _lastTriggerState != CustomRefreshState.armed) {
        HapticFeedback.mediumImpact();
        _lastTriggerState = CustomRefreshState.armed;
      } else if (_state == CustomRefreshState.pulling) {
        _lastTriggerState = CustomRefreshState.pulling;
      }
    } else {
      if (_state == CustomRefreshState.pulling ||
          _state == CustomRefreshState.armed) {
        setState(() {
          _pullDistance = 0.0;
          _state = CustomRefreshState.idle;
          _lastTriggerState = CustomRefreshState.idle;
        });
      }
    }

    if (notification is ScrollEndNotification) {
      if (_state == CustomRefreshState.armed) {
        _startRefresh();
      } else if (_state == CustomRefreshState.pulling) {
        _snapBackToZero();
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double displayOffset = _isAnimatingOffset
        ? _animatingOffset
        : _pullDistance;
    final double pullRatio = (displayOffset / 90.0).clamp(0.0, 1.0);

    RefreshIndicatorMode painterState;
    switch (_state) {
      case CustomRefreshState.idle:
        painterState = RefreshIndicatorMode.inactive;
        break;
      case CustomRefreshState.pulling:
        painterState = RefreshIndicatorMode.drag;
        break;
      case CustomRefreshState.armed:
        painterState = RefreshIndicatorMode.armed;
        break;
      case CustomRefreshState.refreshing:
        painterState = RefreshIndicatorMode.refresh;
        break;
      case CustomRefreshState.done:
        painterState = RefreshIndicatorMode.done;
        break;
    }

    double opacity = 1.0;
    if (_state == CustomRefreshState.done ||
        (_isAnimatingOffset && _state == CustomRefreshState.idle)) {
      opacity = (displayOffset / 50.0).clamp(0.0, 1.0);
    } else if (displayOffset <= 10.0) {
      opacity = (displayOffset / 10.0).clamp(0.0, 1.0);
    }

    double splashProgress = 1.0;
    if (_state == CustomRefreshState.refreshing && _isAnimatingOffset) {
      splashProgress = _transitionController.value;
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        children: [
          widget.child,
          if (displayOffset > 0.0 || _state == CustomRefreshState.refreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(
                        0.0,
                        (displayOffset - 60.0).clamp(-50.0, 10.0),
                      ),
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _waveController,
                          _spinController,
                        ]),
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(60, 60),
                            painter: LiquidIndicatorPainter(
                              pullRatio: pullRatio,
                              waveValue: _waveController.value,
                              spinValue: _spinController.value,
                              state: painterState,
                              isDark: isDark,
                              splashProgress: splashProgress,
                              particleAngles: _particleAngles,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LiquidIndicatorPainter extends CustomPainter {
  final double pullRatio;
  final double waveValue;
  final double spinValue;
  final RefreshIndicatorMode state;
  final bool isDark;
  final double splashProgress;
  final List<double> particleAngles;

  LiquidIndicatorPainter({
    required this.pullRatio,
    required this.waveValue,
    required this.spinValue,
    required this.state,
    required this.isDark,
    required this.splashProgress,
    required this.particleAngles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height;

    // Define colors
    final List<Color> liquidColors = [
      const Color(0xFF00C6E6),
      const Color(0xFF0097B2),
    ];
    final Color glassColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);
    final Color glowColor = const Color(0xFF00C6E6).withValues(alpha: 0.3);

    // Draw background ambient glow
    final glowPaint = Paint()
      ..color = liquidColors[0].withValues(alpha: 0.12 * pullRatio)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 22.0 * pullRatio, glowPaint);

    // If state is refresh, draw the spinning liquid loader
    if (state == RefreshIndicatorMode.refresh) {
      _paintRefreshing(canvas, center, liquidColors, glowColor);
      _paintSplashParticles(canvas, center, liquidColors);
      return;
    }

    // Otherwise, draw the stretchy droplet (drag, armed, inactive, done)
    _paintDroplet(canvas, width, height, liquidColors, glassColor, glowColor);
  }

  void _paintRefreshing(
    Canvas canvas,
    Offset center,
    List<Color> colors,
    Color glowColor,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Draw main glowing background
    canvas.drawCircle(center, 16.0, glowPaint);

    final rect = Rect.fromCircle(center: center, radius: 14);
    paint.shader = LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(rect);

    // Draw center core
    canvas.drawCircle(center, 12.0, paint);

    // Draw glossySpecular highlight on center core
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(center.dx - 6, center.dy - 6, 6, 3),
      highlightPaint,
    );

    // Draw 3 orbiting metaball droplets
    final numDroplets = 3;
    final orbitRadius = 14.0;

    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: 10.0));

    for (int i = 0; i < numDroplets; i++) {
      final angle = spinValue * 2 * math.pi + (i * 2 * math.pi / numDroplets);
      final dropCenter =
          center +
          Offset(math.cos(angle) * orbitRadius, math.sin(angle) * orbitRadius);
      final dropRadius = 5.0 + math.sin(spinValue * 2 * math.pi * 2 + i) * 1.0;

      path.addOval(Rect.fromCircle(center: dropCenter, radius: dropRadius));

      final perpAngle = angle + math.pi / 2;
      final bridgeWidth = 4.0;
      final p1 =
          center +
          Offset(
            math.cos(perpAngle) * bridgeWidth,
            math.sin(perpAngle) * bridgeWidth,
          );
      final p2 =
          center -
          Offset(
            math.cos(perpAngle) * bridgeWidth,
            math.sin(perpAngle) * bridgeWidth,
          );
      final p3 =
          dropCenter -
          Offset(
            math.cos(perpAngle) * bridgeWidth,
            math.sin(perpAngle) * bridgeWidth,
          );
      final p4 =
          dropCenter +
          Offset(
            math.cos(perpAngle) * bridgeWidth,
            math.sin(perpAngle) * bridgeWidth,
          );

      final bridgePath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(
          (center.dx + dropCenter.dx) / 2,
          (center.dy + dropCenter.dy) / 2,
          p4.dx,
          p4.dy,
        )
        ..lineTo(p3.dx, p3.dy)
        ..quadraticBezierTo(
          (center.dx + dropCenter.dx) / 2,
          (center.dy + dropCenter.dy) / 2,
          p2.dx,
          p2.dy,
        )
        ..close();

      path.addPath(bridgePath, Offset.zero);
    }

    canvas.drawPath(path, paint);
  }

  void _paintSplashParticles(Canvas canvas, Offset center, List<Color> colors) {
    if (splashProgress >= 1.0 || particleAngles.isEmpty) return;

    for (final angle in particleAngles) {
      final distance = splashProgress * 32.0;
      final opacity = (1.0 - splashProgress).clamp(0.0, 1.0);
      final particleCenter =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      final particleRadius = 3.5 * (1.0 - splashProgress);

      final dropPaint = Paint()
        ..shader =
            LinearGradient(
              colors: [
                colors[0].withValues(alpha: opacity),
                colors[1].withValues(alpha: opacity),
              ],
            ).createShader(
              Rect.fromCircle(center: particleCenter, radius: particleRadius),
            )
        ..style = PaintingStyle.fill;
      canvas.drawCircle(particleCenter, particleRadius, dropPaint);
    }
  }

  void _paintDroplet(
    Canvas canvas,
    double width,
    double height,
    List<Color> colors,
    Color glassColor,
    Color glowColor,
  ) {
    if (pullRatio <= 0.05) return;

    final xCenter = width / 2;

    final y1 = 15.0;
    final r1 = 12.0 * (1.0 - pullRatio * 0.25);

    final maxDistance = 30.0;
    final y2 = y1 + maxDistance * pullRatio;
    final r2 = 6.0 + 8.0 * pullRatio;

    final path = Path();

    final neckWidth = r2 * (1.0 - pullRatio * 0.45);

    final p1L = Offset(xCenter - r1, y1);
    final p1R = Offset(xCenter + r1, y1);
    final p2L = Offset(xCenter - r2, y2);
    final p2R = Offset(xCenter + r2, y2);

    final midY = (y1 + y2) / 2;
    final cpL = Offset(xCenter - neckWidth, midY);
    final cpR = Offset(xCenter + neckWidth, midY);

    path.moveTo(p1L.dx, p1L.dy);
    path.quadraticBezierTo(cpL.dx, cpL.dy, p2L.dx, p2L.dy);
    path.arcToPoint(p2R, radius: Radius.circular(r2), clockwise: false);
    path.quadraticBezierTo(cpR.dx, cpR.dy, p1R.dx, p1R.dy);
    path.arcToPoint(p1L, radius: Radius.circular(r1), clockwise: false);
    path.close();

    final glassPaint = Paint()
      ..color = glassColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, glassPaint);

    final fillTintPaint = Paint()
      ..color = colors[0].withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillTintPaint);

    canvas.save();
    canvas.clipPath(path);

    final liquidHeight = (y2 + r2) - (y1 - r1);
    final currentLiquidHeight = liquidHeight * pullRatio;
    final yLiquid = (y2 + r2) - currentLiquidHeight;

    final waveAmplitude = 3.0 * (1.0 - pullRatio);
    final waveWavelength = 20.0;

    // Layer 2 Wave (Teal Parallax Background Wave)
    final liquidPath2 = Path();
    liquidPath2.moveTo(xCenter - 30, yLiquid + 2);
    for (double x = xCenter - 30; x <= xCenter + 30; x += 1.0) {
      final angle =
          (x / waveWavelength) * 2 * math.pi + (waveValue + 0.5) * 2 * math.pi;
      final waveY = (yLiquid + 2) + math.cos(angle) * (waveAmplitude * 0.8);
      liquidPath2.lineTo(x, waveY);
    }
    liquidPath2.lineTo(xCenter + 30, y2 + r2 + 10);
    liquidPath2.lineTo(xCenter - 30, y2 + r2 + 10);
    liquidPath2.close();

    // Layer 1 Wave (Primary Turkish Blue Wave)
    final liquidPath1 = Path();
    liquidPath1.moveTo(xCenter - 30, yLiquid);
    for (double x = xCenter - 30; x <= xCenter + 30; x += 1.0) {
      final angle =
          (x / waveWavelength) * 2 * math.pi + waveValue * 2 * math.pi;
      final waveY = yLiquid + math.sin(angle) * waveAmplitude;
      liquidPath1.lineTo(x, waveY);
    }
    liquidPath1.lineTo(xCenter + 30, y2 + r2 + 10);
    liquidPath1.lineTo(xCenter - 30, y2 + r2 + 10);
    liquidPath1.close();

    final liquidPaint1 = Paint()
      ..shader =
          LinearGradient(
            colors: colors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTRB(xCenter - r1, y1 - r1, xCenter + r1, y2 + r2),
          )
      ..style = PaintingStyle.fill;

    final liquidPaint2 = Paint()
      ..shader =
          LinearGradient(
            colors: [const Color(0xFF00E6C6), colors[1].withValues(alpha: 0.5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTRB(xCenter - r1, y1 - r1, xCenter + r1, y2 + r2),
          )
      ..style = PaintingStyle.fill;

    if (state == RefreshIndicatorMode.armed) {
      final glowPaint = Paint()
        ..color = colors[0].withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(liquidPath1, glowPaint);
    }

    // Paint wave background then primary wave on top
    canvas.drawPath(liquidPath2, liquidPaint2);
    canvas.drawPath(liquidPath1, liquidPaint1);

    // Specular Highlight (3D glossy reflection)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(xCenter - r2 * 0.4, y2 - r2 * 0.4, r2 * 0.5, r2 * 0.25),
      highlightPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LiquidIndicatorPainter oldDelegate) {
    return oldDelegate.pullRatio != pullRatio ||
        oldDelegate.waveValue != waveValue ||
        oldDelegate.spinValue != spinValue ||
        oldDelegate.state != state ||
        oldDelegate.isDark != isDark ||
        oldDelegate.splashProgress != splashProgress ||
        oldDelegate.particleAngles != particleAngles;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interactive Dashboard Telemetry Charts Card & Painters
// ─────────────────────────────────────────────────────────────────────────────

class TelemetryChartsCard extends StatefulWidget {
  const TelemetryChartsCard({super.key});

  @override
  State<TelemetryChartsCard> createState() => _TelemetryChartsCardState();
}

class _TelemetryChartsCardState extends State<TelemetryChartsCard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // 0 for Delay Trends, 1 for Route Coverage
  int? _hoveredIndex;
  Offset? _hoverPos;

  late AnimationController _animationController;
  late Animation<double> _chartProgress;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _chartProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  final List<double> delayData = [5.0, 12.0, 8.0, 15.0, 4.0, 9.0, 2.0];
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<double> routeCoverage = [0.85, 0.90, 0.60, 0.95, 0.40];
  final List<String> routes = [
    'Route A',
    'Route B',
    'Route C',
    'Route D',
    'Route E',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.06),
                        const Color(0xFF00C6E6).withValues(alpha: 0.02),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.70),
                        const Color(0xFF00C6E6).withValues(alpha: 0.03),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFF0097B2).withValues(alpha: 0.10),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, headerConstraints) {
                      final useVerticalLayout =
                          headerConstraints.maxWidth < 330;
                      if (useVerticalLayout) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            'Telemetry Analytics'.text.bold.lg.make(),
                            'Live system monitoring metrics'.text
                                .color(
                                  context.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                )
                                .size(11)
                                .make(),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildToggleButton('Delay Trends', 0),
                                  _buildToggleButton('Route Coverage', 1),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  'Telemetry Analytics'.text.bold.lg.make(),
                                  'Live system monitoring metrics'.text
                                      .color(
                                        context.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      )
                                      .size(11)
                                      .make(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  _buildToggleButton('Delay Trends', 0),
                                  _buildToggleButton('Route Coverage', 1),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _chartProgress,
                    builder: (context, child) {
                      return SizedBox(
                        height: 180,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final height = constraints.maxHeight;

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onPanStart: (details) => _handleHover(
                                    details.localPosition,
                                    width,
                                    height,
                                  ),
                                  onPanUpdate: (details) => _handleHover(
                                    details.localPosition,
                                    width,
                                    height,
                                  ),
                                  onPanEnd: (_) => setState(() {
                                    _hoveredIndex = null;
                                  }),
                                  onTapDown: (details) => _handleHover(
                                    details.localPosition,
                                    width,
                                    height,
                                  ),
                                  onTapUp: (_) => setState(() {
                                    _hoveredIndex = null;
                                  }),
                                  onTapCancel: () => setState(() {
                                    _hoveredIndex = null;
                                  }),
                                  child: CustomPaint(
                                    size: Size(width, height),
                                    painter: _selectedIndex == 0
                                        ? DelayTrendsPainter(
                                            data: delayData,
                                            days: days,
                                            progress: _chartProgress.value,
                                            hoveredIndex: _hoveredIndex,
                                            isDark: isDark,
                                          )
                                        : RouteStatusPainter(
                                            data: routeCoverage,
                                            routes: routes,
                                            progress: _chartProgress.value,
                                            hoveredIndex: _hoveredIndex,
                                            isDark: isDark,
                                          ),
                                  ),
                                ),
                                if (_hoveredIndex != null)
                                  _buildTooltipPositioned(width, height),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _hoveredIndex = null;
          _animationController.reset();
          _animationController.forward();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? const Color(0xFF00C6E6)
                    : const Color(0xFF0097B2).withValues(alpha: 0.15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0097B2))
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }

  void _handleHover(
    Offset localPosition,
    double totalWidth,
    double totalHeight,
  ) {
    if (_selectedIndex == 0) {
      const leftPadding = 40.0;
      const rightPadding = 20.0;
      final usableWidth = totalWidth - leftPadding - rightPadding;
      if (usableWidth > 0) {
        final relativeX = localPosition.dx - leftPadding;
        final index = (relativeX / (usableWidth / 6)).round().clamp(0, 6);
        setState(() {
          _hoveredIndex = index;
          final x = leftPadding + index * (usableWidth / 6);
          final usableHeight = totalHeight - 50.0;
          final y =
              20.0 + usableHeight - (delayData[index] / 20.0) * usableHeight;
          _hoverPos = Offset(x, y);
        });
      }
    } else {
      const topPadding = 15.0;
      const bottomPadding = 15.0;
      final usableHeight = totalHeight - topPadding - bottomPadding;
      if (usableHeight > 0) {
        final relativeY = localPosition.dy - topPadding;
        final index = (relativeY / (usableHeight / 5)).floor().clamp(0, 4);
        setState(() {
          _hoveredIndex = index;
          const leftPadding = 80.0;
          const rightPadding = 20.0;
          final usableWidth = totalWidth - leftPadding - rightPadding;
          final x = leftPadding + (routeCoverage[index] * usableWidth);
          final y = topPadding + (index + 0.5) * (usableHeight / 5);
          _hoverPos = Offset(x, y);
        });
      }
    }
  }

  Widget _buildTooltipPositioned(double totalWidth, double totalHeight) {
    if (_hoveredIndex == null || _hoverPos == null)
      return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String title;
    final String detail;
    if (_selectedIndex == 0) {
      title = days[_hoveredIndex!];
      detail = '${delayData[_hoveredIndex!].toStringAsFixed(1)} mins delay';
    } else {
      title = routes[_hoveredIndex!];
      detail = '${(routeCoverage[_hoveredIndex!] * 100).toInt()}% coverage';
    }

    double left = _hoverPos!.dx - 60;
    double top = _hoverPos!.dy - 65;
    if (left < 0) left = 5;
    if (left + 120 > totalWidth) left = totalWidth - 125;
    if (top < 0) top = _hoverPos!.dy + 15;

    return Positioned(
      left: left,
      top: top,
      child: AnimatedOpacity(
        opacity: _hoveredIndex != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFF0097B2).withValues(alpha: 0.15),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFF0097B2),
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

class DelayTrendsPainter extends CustomPainter {
  final List<double> data;
  final List<String> days;
  final double progress;
  final int? hoveredIndex;
  final bool isDark;

  DelayTrendsPainter({
    required this.data,
    required this.days,
    required this.progress,
    this.hoveredIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 40.0;
    const rightPadding = 20.0;
    const topPadding = 20.0;
    const bottomPadding = 30.0;

    final usableWidth = size.width - leftPadding - rightPadding;
    final usableHeight = size.height - topPadding - bottomPadding;

    if (usableWidth <= 0 || usableHeight <= 0) return;

    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 4; i++) {
      final delayVal = i * 5;
      final y = topPadding + usableHeight - (delayVal / 20.0) * usableHeight;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      textPainter.text = TextSpan(
        text: '${delayVal}m',
        style: TextStyle(
          fontSize: 9,
          color: isDark ? Colors.white38 : Colors.black38,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = leftPadding + i * (usableWidth / 6);
      final value = data[i] * progress;
      final y = topPadding + usableHeight - (value / 20.0) * usableHeight;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, topPadding + usableHeight);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlX1 = p1.dx + (p2.dx - p1.dx) / 2;
        final controlY1 = p1.dy;
        final controlX2 = p1.dx + (p2.dx - p1.dx) / 2;
        final controlY2 = p2.dy;

        fillPath.cubicTo(
          controlX1,
          controlY1,
          controlX2,
          controlY2,
          p2.dx,
          p2.dy,
        );
      }

      fillPath.lineTo(points.last.dx, topPadding + usableHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader =
            LinearGradient(
              colors: [
                const Color(0xFF00C6E6).withValues(alpha: isDark ? 0.25 : 0.15),
                const Color(0xFF00C6E6).withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(
              Rect.fromLTRB(
                leftPadding,
                topPadding,
                size.width - rightPadding,
                topPadding + usableHeight,
              ),
            )
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);

      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlX1 = p1.dx + (p2.dx - p1.dx) / 2;
        final controlY1 = p1.dy;
        final controlX2 = p1.dx + (p2.dx - p1.dx) / 2;
        final controlY2 = p2.dy;

        linePath.cubicTo(
          controlX1,
          controlY1,
          controlX2,
          controlY2,
          p2.dx,
          p2.dy,
        );
      }

      final linePaint = Paint()
        ..color = const Color(0xFF00C6E6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      final glowPaint = Paint()
        ..color = const Color(0xFF00C6E6).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawPath(linePath, glowPaint);
      canvas.drawPath(linePath, linePaint);
    }

    if (hoveredIndex != null && hoveredIndex! < points.length) {
      final hoveredPoint = points[hoveredIndex!];
      final verticalLinePaint = Paint()
        ..color = const Color(0xFF00C6E6).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(hoveredPoint.dx, topPadding),
        Offset(hoveredPoint.dx, topPadding + usableHeight),
        verticalLinePaint,
      );
    }

    final pointPaint = Paint()
      ..color = const Color(0xFF0097B2)
      ..style = PaintingStyle.fill;

    final borderPointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final isHovered = hoveredIndex == i;

      textPainter.text = TextSpan(
        text: days[i],
        style: TextStyle(
          fontSize: 9,
          color: isHovered
              ? (isDark ? Colors.white : const Color(0xFF0097B2))
              : (isDark ? Colors.white38 : Colors.black38),
          fontWeight: isHovered ? FontWeight.bold : FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(p.dx - textPainter.width / 2, topPadding + usableHeight + 8),
      );

      canvas.drawCircle(p, isHovered ? 6.0 : 4.0, pointPaint);
      canvas.drawCircle(p, isHovered ? 6.0 : 4.0, borderPointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DelayTrendsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.isDark != isDark;
  }
}

class RouteStatusPainter extends CustomPainter {
  final List<double> data;
  final List<String> routes;
  final double progress;
  final int? hoveredIndex;
  final bool isDark;

  RouteStatusPainter({
    required this.data,
    required this.routes,
    required this.progress,
    this.hoveredIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 80.0;
    const rightPadding = 20.0;
    const topPadding = 15.0;
    const bottomPadding = 15.0;

    final usableWidth = size.width - leftPadding - rightPadding;
    final usableHeight = size.height - topPadding - bottomPadding;

    if (usableWidth <= 0 || usableHeight <= 0) return;

    final int itemCount = data.length;
    final rowHeight = usableHeight / itemCount;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < itemCount; i++) {
      final yCenter = topPadding + (i + 0.5) * rowHeight;
      final isHovered = hoveredIndex == i;

      textPainter.text = TextSpan(
        text: routes[i],
        style: TextStyle(
          fontSize: 11,
          color: isHovered
              ? (isDark ? Colors.white : const Color(0xFF0097B2))
              : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isHovered ? FontWeight.bold : FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          leftPadding - textPainter.width - 12,
          yCenter - textPainter.height / 2,
        ),
      );

      final barHeight = 10.0;
      final barRect = Rect.fromLTWH(
        leftPadding,
        yCenter - barHeight / 2,
        usableWidth,
        barHeight,
      );
      final bgPaint = Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;
      final rrectBg = RRect.fromRectAndRadius(
        barRect,
        const Radius.circular(5.0),
      );
      canvas.drawRRect(rrectBg, bgPaint);

      final filledWidth = usableWidth * data[i] * progress;
      if (filledWidth > 0) {
        final filledRect = Rect.fromLTWH(
          leftPadding,
          yCenter - barHeight / 2,
          filledWidth,
          barHeight,
        );
        final progressColors = isHovered
            ? [const Color(0xFF00E5FF), const Color(0xFF0097B2)]
            : [const Color(0xFF00C6E6), const Color(0xFF0097B2)];

        final fillPaint = Paint()
          ..shader = LinearGradient(
            colors: progressColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(filledRect)
          ..style = PaintingStyle.fill;

        final rrectFilled = RRect.fromRectAndRadius(
          filledRect,
          const Radius.circular(5.0),
        );
        canvas.drawRRect(rrectFilled, fillPaint);

        if (isHovered) {
          final glowPaint = Paint()
            ..color = const Color(0xFF00C6E6).withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawRRect(rrectFilled, glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant RouteStatusPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.isDark != isDark;
  }
}
