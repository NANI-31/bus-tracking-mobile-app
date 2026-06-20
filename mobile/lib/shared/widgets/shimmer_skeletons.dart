import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/shared/widgets/shimmer_loading.dart';

// Helper to determine the standard base and highlight colors
void _getSkeletonColors(BuildContext context, {required bool isOnline, required isDark, required Function(Color, Color) onColors}) {
  final baseColor = isDark
      ? const Color(0xFF0F172A).withValues(alpha: 0.35)
      : Colors.white.withValues(alpha: 0.30);

  final Color highlightColor;
  if (isOnline) {
    highlightColor = isDark
        ? const Color(0xFF00C6E6).withValues(alpha: 0.32)
        : const Color(0xFF0097B2).withValues(alpha: 0.40);
  } else {
    highlightColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.40)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.80);
  }
  onColors(baseColor, highlightColor);
}

class BusListSkeleton extends StatelessWidget {
  const BusListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmer = Shimmer.of(context);
    final animationValue = shimmer?.value ?? 0.0;

    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMedium,
          vertical: 8,
        ),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 4,
        itemBuilder: (context, index) {
          final isAssigned = index % 2 == 0;
          _getSkeletonColors(context, isOnline: isAssigned, isDark: isDark, onColors: (base, highlight) {
            // Render premium glassmorphic cards with Vector Painters
            showSkeleton(base, highlight);
          });

          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.40),
                ),
                child: Builder(
                  builder: (context) {
                    final base = isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.30);
                    final highlight = isAssigned
                        ? (isDark ? const Color(0xFF00C6E6).withValues(alpha: 0.32) : const Color(0xFF0097B2).withValues(alpha: 0.40))
                        : (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.40) : const Color(0xFFE2E8F0).withValues(alpha: 0.80));

                    return CustomPaint(
                      painter: BusCardOutlinePainter(
                        baseColor: base,
                        highlightColor: highlight,
                        animationValue: animationValue,
                        isAssigned: isAssigned,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void showSkeleton(Color base, Color highlight) {}
}

class BusAssignmentSkeleton extends StatelessWidget {
  const BusAssignmentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmer = Shimmer.of(context);
    final animationValue = shimmer?.value ?? 0.0;
    
    final baseColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.30);
    final highlightColor = isDark
        ? const Color(0xFF00C6E6).withValues(alpha: 0.22)
        : const Color(0xFFE0F7FA).withValues(alpha: 0.60);

    return Shimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            // LocationDisplay Skeleton Outline
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.40),
                  ),
                  child: CustomPaint(
                    painter: LocationOutlinePainter(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      animationValue: animationValue,
                    ),
                  ),
                ),
              ),
            ),
            
            // BusCard Assignment Skeleton Outline
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.40),
                  ),
                  child: CustomPaint(
                    painter: AssignmentOutlinePainter(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      animationValue: animationValue,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverSelectionSkeleton extends StatelessWidget {
  const DriverSelectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmer = Shimmer.of(context);
    final animationValue = shimmer?.value ?? 0.0;

    final baseColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.30);
    final highlightColor = isDark
        ? const Color(0xFF00C6E6).withValues(alpha: 0.22)
        : const Color(0xFFE0F7FA).withValues(alpha: 0.60);

    return Shimmer(
      child: Column(
        children: [
          // Search Bar Skeleton
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.40),
                ),
                child: CustomPaint(
                  painter: SearchBarOutlinePainter(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    animationValue: animationValue,
                  ),
                ),
              ),
            ),
          ),
          // Drivers List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.40),
                      ),
                      child: CustomPaint(
                        painter: SelectionDriverOutlinePainter(
                          baseColor: baseColor,
                          highlightColor: highlightColor,
                          animationValue: animationValue,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StatCardsSkeleton extends StatelessWidget {
  const StatCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmer = Shimmer.of(context);
    final animationValue = shimmer?.value ?? 0.0;

    final baseColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.30);
    final highlightColor = isDark
        ? const Color(0xFF00C6E6).withValues(alpha: 0.22)
        : const Color(0xFFE0F7FA).withValues(alpha: 0.60);

    return Shimmer(
      child: SingleChildScrollView(
        child: VStack([
          // Header placeholder outline
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 28,
              width: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark
                    ? Colors.black.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.40),
              ),
              child: CustomPaint(
                painter: SimpleLineOutlinePainter(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  animationValue: animationValue,
                ),
              ),
            ),
          ),
          AppSizes.paddingLarge.heightBox,

          // Statistics Cards grid
          Builder(
            builder: (context) {
              final double screenWidth = MediaQuery.of(context).size.width;
              
              final card1 = _buildCardPlaceholder(context, baseColor, highlightColor, animationValue);
              final card2 = _buildCardPlaceholder(context, baseColor, highlightColor, animationValue);
              final card3 = _buildCardPlaceholder(context, baseColor, highlightColor, animationValue);
              final card4 = _buildCardPlaceholder(context, baseColor, highlightColor, animationValue);
              
              if (screenWidth >= 650) {
                return Row(
                  children: [
                    Expanded(child: card1),
                    const SizedBox(width: 12),
                    Expanded(child: card2),
                    const SizedBox(width: 12),
                    Expanded(child: card3),
                    const SizedBox(width: 12),
                    Expanded(child: card4),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: card1),
                        const SizedBox(width: 12),
                        Expanded(child: card2),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: card3),
                        const SizedBox(width: 12),
                        Expanded(child: card4),
                      ],
                    ),
                  ],
                );
              }
            },
          ),

          AppSizes.paddingMedium.heightBox,

          // Broadcast card placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isDark
                    ? Colors.black.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.40),
              ),
              child: CustomPaint(
                painter: BroadcastCardOutlinePainter(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  animationValue: animationValue,
                ),
              ),
            ),
          ),
        ]).p(AppSizes.paddingMedium),
      ),
    );
  }

  Widget _buildCardPlaceholder(BuildContext context, Color baseColor, Color highlightColor, double animationValue) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark
                ? Colors.black.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.40),
          ),
          child: CustomPaint(
            painter: StatCardOutlinePainter(
              baseColor: baseColor,
              highlightColor: highlightColor,
              animationValue: animationValue,
            ),
          ),
        ),
      ),
    );
  }
}

class DriverListSkeleton extends StatelessWidget {
  const DriverListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmer = Shimmer.of(context);
    final animationValue = shimmer?.value ?? 0.0;

    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMedium,
          vertical: 8,
        ),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 4,
        itemBuilder: (context, index) {
          final isOnlineCard = index == 0;

          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.40),
                ),
                child: Builder(
                  builder: (context) {
                    final base = isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.30);
                    final highlight = isOnlineCard
                        ? (isDark ? const Color(0xFF00C6E6).withValues(alpha: 0.32) : const Color(0xFF0097B2).withValues(alpha: 0.40))
                        : (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.40) : const Color(0xFFE2E8F0).withValues(alpha: 0.80));

                    return CustomPaint(
                      painter: DriverCardOutlinePainter(
                        baseColor: base,
                        highlightColor: highlight,
                        animationValue: animationValue,
                        isOnline: isOnlineCard,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ScheduleListSkeleton extends StatelessWidget {
  const ScheduleListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmer = Shimmer.of(context);
    final animationValue = shimmer?.value ?? 0.0;

    final baseColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.30);
    final highlightColor = isDark
        ? const Color(0xFF00C6E6).withValues(alpha: 0.22)
        : const Color(0xFFE0F7FA).withValues(alpha: 0.60);

    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMedium,
          vertical: 8,
        ),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 4,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.40),
                ),
                child: CustomPaint(
                  painter: ScheduleCardOutlinePainter(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    animationValue: animationValue,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM VECTOR PAINTERS FOR GLOWING WIREFRAME OUTLINES
// ─────────────────────────────────────────────────────────────────────────────

Paint _createShimmerOutlinePaint(Rect rect, Color baseColor, Color highlightColor, double slide) {
  return Paint()
    ..shader = ui.Gradient.linear(
      rect.topLeft,
      rect.bottomRight,
      [baseColor, highlightColor, baseColor],
      [(slide - 0.28).clamp(0.0, 1.0), slide.clamp(0.0, 1.0), (slide + 0.28).clamp(0.0, 1.0)],
    )
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
}

Paint _createShimmerFillPaint(Rect rect, Color baseColor, Color highlightColor, double slide) {
  return Paint()
    ..shader = ui.Gradient.linear(
      rect.topLeft,
      rect.bottomRight,
      [
        baseColor.withValues(alpha: 0.15),
        highlightColor.withValues(alpha: 0.42),
        baseColor.withValues(alpha: 0.15),
      ],
      [(slide - 0.28).clamp(0.0, 1.0), slide.clamp(0.0, 1.0), (slide + 0.28).clamp(0.0, 1.0)],
    )
    ..style = PaintingStyle.fill;
}

class BusCardOutlinePainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;
  final double animationValue;
  final bool isAssigned;

  BusCardOutlinePainter({
    required this.baseColor,
    required this.highlightColor,
    required this.animationValue,
    required this.isAssigned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    final slide = animationValue;

    final borderPaint = _createShimmerOutlinePaint(rect, baseColor, highlightColor, slide);
    final fillPaint = _createShimmerFillPaint(rect, baseColor, highlightColor, slide);

    // Draw main card boundary
    canvas.drawRRect(rrect, borderPaint);

    // Draw leading bus avatar circle
    canvas.drawCircle(const Offset(42, 40), 20, fillPaint);

    // Draw bus number title outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(78, 24, 95, 14),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // Draw driver assignment subtitle outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(78, 44, 150, 10),
        const Radius.circular(3),
      ),
      fillPaint,
    );

    // Draw trailing expand icon outline
    canvas.drawCircle(Offset(size.width - 32, 40), 10, fillPaint);
  }

  @override
  bool shouldRepaint(covariant BusCardOutlinePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor ||
      oldDelegate.isAssigned != isAssigned;
}

class DriverCardOutlinePainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;
  final double animationValue;
  final bool isOnline;

  DriverCardOutlinePainter({
    required this.baseColor,
    required this.highlightColor,
    required this.animationValue,
    required this.isOnline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    final slide = animationValue;

    final borderPaint = _createShimmerOutlinePaint(rect, baseColor, highlightColor, slide);
    final fillPaint = _createShimmerFillPaint(rect, baseColor, highlightColor, slide);

    // Draw main card boundary
    canvas.drawRRect(rrect, borderPaint);

    // Draw leading driver avatar circle (with outer ring)
    canvas.drawCircle(const Offset(42, 40), 22, borderPaint);
    canvas.drawCircle(const Offset(42, 40), 18, fillPaint);

    // Draw driver name title
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(82, 22, 130, 14),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // Draw status badge outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(82, 44, 75, 16),
        const Radius.circular(8),
      ),
      fillPaint,
    );

    // Draw trailing expand icon
    canvas.drawCircle(Offset(size.width - 32, 40), 10, fillPaint);
  }

  @override
  bool shouldRepaint(covariant DriverCardOutlinePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor ||
      oldDelegate.isOnline != isOnline;
}

class StatCardOutlinePainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;
  final double animationValue;

  StatCardOutlinePainter({
    required this.baseColor,
    required this.highlightColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    final slide = animationValue;

    final borderPaint = _createShimmerOutlinePaint(rect, baseColor, highlightColor, slide);
    final fillPaint = _createShimmerFillPaint(rect, baseColor, highlightColor, slide);

    canvas.drawRRect(rrect, borderPaint);

    // Top icon ring
    canvas.drawCircle(Offset(size.width / 2, 36), 18, borderPaint);
    canvas.drawCircle(Offset(size.width / 2, 36), 12, fillPaint);

    // Middle value text
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width / 2, 80), width: 55, height: 20),
        const Radius.circular(6),
      ),
      fillPaint,
    );

    // Bottom title text
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width / 2, 112), width: 90, height: 11),
        const Radius.circular(4),
      ),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant StatCardOutlinePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor;
}

class ScheduleCardOutlinePainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;
  final double animationValue;

  ScheduleCardOutlinePainter({
    required this.baseColor,
    required this.highlightColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    final slide = animationValue;

    final borderPaint = _createShimmerOutlinePaint(rect, baseColor, highlightColor, slide);
    final fillPaint = _createShimmerFillPaint(rect, baseColor, highlightColor, slide);

    canvas.drawRRect(rrect, borderPaint);

    // Route circle
    canvas.drawCircle(const Offset(36, 36), 16, fillPaint);

    // Route title
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(68, 20, 120, 14),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // Route subtitle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(68, 42, 80, 10),
        const Radius.circular(3),
      ),
      fillPaint,
    );

    // Trailing badge
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 92, 26, 72, 20),
        const Radius.circular(10),
      ),
      fillPaint,
    );

    // Horizontal divider
    canvas.drawLine(const Offset(20, 72), Offset(size.width - 20, 72), borderPaint);

    // Bus info row
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 92, 70, 12),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // Driver info row
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 132, 92, 110, 12),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // Timetable info row
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 114, 110, 12),
        const Radius.circular(4),
      ),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScheduleCardOutlinePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor;
}

class LocationOutlinePainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;
  final double animationValue;

  LocationOutlinePainter({
    required this.baseColor,
    required this.highlightColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    final slide = animationValue;

    final borderPaint = _createShimmerOutlinePaint(rect, baseColor, highlightColor, slide);
    final fillPaint = _createShimmerFillPaint(rect, baseColor, highlightColor, slide);

    canvas.drawRRect(rrect, borderPaint);

    // Circle
    canvas.drawCircle(const Offset(28, 28), 6, fillPaint);

    // Text block
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(52, 21, size.width - 92, 14),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // End circle
    canvas.drawCircle(Offset(size.width - 24, 28), 8, fillPaint);
  }

  @override
  bool shouldRepaint(covariant LocationOutlinePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor;
}

class AssignmentOutlinePainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;
  final double animationValue;

  AssignmentOutlinePainter({
    required this.baseColor,
    required this.highlightColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    final slide = animationValue;

    final borderPaint = _createShimmerOutlinePaint(rect, baseColor, highlightColor, slide);
    final fillPaint = _createShimmerFillPaint(rect, baseColor, highlightColor, slide);

    canvas.drawRRect(rrect, borderPaint);

    // Icon & title row
    canvas.drawCircle(const Offset(44, 44), 12, fillPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(72, 34, 150, 18),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // Large number/content block
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 88, 180, 56),
        const Radius.circular(8),
      ),
      fillPaint,
    );

    // Divider line
    canvas.drawLine(const Offset(24, 172), Offset(size.width - 24, 172), borderPaint);

    // Buttons row
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24, 188, (size.width - 64) / 2, 32),
        const Radius.circular(10),
      ),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width / 2 + 8, 188, (size.width - 64) / 2, 32),
        const Radius.circular(10),
      ),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant AssignmentOutlinePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor;
}

class SearchBarOutlinePainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;
  final double animationValue;

  SearchBarOutlinePainter({
    required this.baseColor,
    required this.highlightColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    final slide = animationValue;

    final borderPaint = _createShimmerOutlinePaint(rect, baseColor, highlightColor, slide);
    final fillPaint = _createShimmerFillPaint(rect, baseColor, highlightColor, slide);

    canvas.drawRRect(rrect, borderPaint);

    // Magnifying glass icon outline
    canvas.drawCircle(const Offset(28, 24), 7, borderPaint);
    canvas.drawLine(const Offset(33, 29), Offset(39, 35), borderPaint);

    // Hint text block
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(60, 18, 140, 12),
        const Radius.circular(4),
      ),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SearchBarOutlinePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor;
}

class SelectionDriverOutlinePainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;
  final double animationValue;

  SelectionDriverOutlinePainter({
    required this.baseColor,
    required this.highlightColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    final slide = animationValue;

    final borderPaint = _createShimmerOutlinePaint(rect, baseColor, highlightColor, slide);
    final fillPaint = _createShimmerFillPaint(rect, baseColor, highlightColor, slide);

    canvas.drawRRect(rrect, borderPaint);

    // Avatar
    canvas.drawCircle(const Offset(36, 36), 20, fillPaint);

    // Title
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(72, 20, 130, 12),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // Subtitle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(72, 40, 190, 10),
        const Radius.circular(3),
      ),
      fillPaint,
    );

    // Check circle
    canvas.drawCircle(Offset(size.width - 28, 36), 12, fillPaint);
  }

  @override
  bool shouldRepaint(covariant SelectionDriverOutlinePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor;
}

class SimpleLineOutlinePainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;
  final double animationValue;

  SimpleLineOutlinePainter({
    required this.baseColor,
    required this.highlightColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    final slide = animationValue;

    final fillPaint = _createShimmerFillPaint(rect, baseColor, highlightColor, slide);
    canvas.drawRRect(rrect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant SimpleLineOutlinePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor;
}

class BroadcastCardOutlinePainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;
  final double animationValue;

  BroadcastCardOutlinePainter({
    required this.baseColor,
    required this.highlightColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    final slide = animationValue;

    final borderPaint = _createShimmerOutlinePaint(rect, baseColor, highlightColor, slide);
    final fillPaint = _createShimmerFillPaint(rect, baseColor, highlightColor, slide);

    canvas.drawRRect(rrect, borderPaint);

    // Leading circle
    canvas.drawCircle(const Offset(38, 40), 22, fillPaint);

    // Title
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 24, 150, 14),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // Subtitle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 46, 220, 10),
        const Radius.circular(3),
      ),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BroadcastCardOutlinePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor;
}
