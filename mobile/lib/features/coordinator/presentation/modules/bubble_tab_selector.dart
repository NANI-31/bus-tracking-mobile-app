import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';

class BubbleTabSelector extends StatefulWidget {
  final List<IconData> icons;
  final List<String> labels;

  const BubbleTabSelector({
    super.key,
    required this.icons,
    required this.labels,
  });

  @override
  State<BubbleTabSelector> createState() => _BubbleTabSelectorState();
}

class _BubbleTabSelectorState extends State<BubbleTabSelector> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  
  double _dragOffsetX = 0.0;
  double _dragOffsetY = 0.0;
  
  late AnimationController _springController;
  double _springStartX = 0.0;
  double _springStartY = 0.0;
  
  bool _isGestureTransition = false;
  int _gestureOldIndex = 0;
  int _gestureTargetIndex = 0;
  double _gestureReleasedOffsetX = 0.0;
  double _gestureReleasedOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _springController.addListener(() {
      final double val = const Cubic(0.15, 1.4, 0.3, 1.0).transform(_springController.value);
      setState(() {
        _dragOffsetX = lerp(_springStartX, 0.0, val);
        _dragOffsetY = lerp(_springStartY, 0.0, val);
      });
    });
  }

  double lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = DefaultTabController.of(context);
    if (newController != _tabController) {
      _tabController?.animation?.removeListener(_handleAnimationTick);
      _tabController = newController;
      _tabController?.animation?.addListener(_handleAnimationTick);
    }
  }

  @override
  void dispose() {
    _tabController?.animation?.removeListener(_handleAnimationTick);
    _springController.dispose();
    super.dispose();
  }

  void _handleAnimationTick() {
    if (mounted) {
      setState(() {});
    }
  }

  void _springBack() {
    _springStartX = _dragOffsetX;
    _springStartY = _dragOffsetY;
    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double animValue = _tabController!.animation?.value ?? _tabController!.index.toDouble();
    final int totalTabs = widget.icons.length;

    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingMedium),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : const Color(0xFFE6F8FA).withValues(alpha: 0.32),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFF0097B2).withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth = constraints.maxWidth;
                final double tabWidth = totalWidth / totalTabs;
                final double basePillH = 46.0;
                final double basePillW = tabWidth - 16.0;

                final double clampedAnimVal = animValue.clamp(0.0, (totalTabs - 1).toDouble());
                final int floorVal = clampedAnimVal.floor();
                final double fraction = clampedAnimVal - floorVal;

                double visualDragX = _dragOffsetX;
                double visualDragY = _dragOffsetY;

                if (_isGestureTransition && _tabController!.animation != null) {
                  final double currentVal = _tabController!.animation!.value;
                  final double denom = (_gestureTargetIndex - _gestureOldIndex).toDouble();
                  if (denom != 0.0) {
                    final double t = ((currentVal - _gestureOldIndex) / denom).clamp(0.0, 1.0);
                    visualDragX = (1.0 - t) * _gestureReleasedOffsetX;
                    visualDragY = (1.0 - t) * _gestureReleasedOffsetY;
                    if (t >= 1.0) {
                      _isGestureTransition = false;
                      _dragOffsetX = 0.0;
                      _dragOffsetY = 0.0;
                    }
                  }
                }

                final double dragSensX = 0.003;
                final double dragSensY = 0.005;
                final double dragStretchX = 1.0 + (visualDragX.abs() * dragSensX).clamp(0.0, 0.35);
                final double dragStretchY = 1.0 + (visualDragY.abs() * dragSensY).clamp(0.0, 0.2);

                final double horizontalSquish = 1.0 + (0.45 * math.sin(fraction * math.pi));
                final double verticalSquish = 1.0 - (0.25 * math.sin(fraction * math.pi));
                double pillW = basePillW * horizontalSquish * dragStretchX / (dragStretchY * 0.4 + 0.6);
                double pillH = basePillH * verticalSquish * dragStretchY / (dragStretchX * 0.4 + 0.6);

                final double currentTabCenter = (animValue + 0.5) * tabWidth + visualDragX;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: currentTabCenter - (pillW / 2),
                      top: (56 - pillH) / 2 + visualDragY - 1.0,
                      child: Container(
                        width: pillW,
                        height: pillH,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: List.generate(totalTabs, (index) {
                          final double diff = (animValue - index).abs();
                          final double selectProgress = (1.0 - diff).clamp(0.0, 1.0);

                          final double scale = 1.0 + (0.12 * selectProgress);
                          final double rotation = (0.15 * math.pi) *
                              (1.0 - selectProgress) *
                              (animValue > index ? 1 : -1) *
                              (diff < 1.0 ? diff : 0.0);

                          final Color contentColor = Color.lerp(
                            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            Colors.white,
                            selectProgress,
                          )!;

                          final isSelected = animValue.round() == index;

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _tabController!.animateTo(index);
                                HapticFeedback.lightImpact();
                              },
                              onPanStart: (details) {
                                if (isSelected) {
                                  _springController.stop();
                                  _springStartX = _dragOffsetX;
                                  _springStartY = _dragOffsetY;
                                }
                              },
                              onPanUpdate: (details) {
                                if (isSelected) {
                                  setState(() {
                                    _dragOffsetX += details.delta.dx;
                                    _dragOffsetY += details.delta.dy * 0.65;
                                    
                                    final double minDragX = -index * tabWidth;
                                    final double maxDragX = (totalTabs - 1 - index) * tabWidth;
                                    
                                    _dragOffsetX = _dragOffsetX.clamp(
                                      minDragX - tabWidth * 0.25,
                                      maxDragX + tabWidth * 0.25,
                                    );
                                    _dragOffsetY = _dragOffsetY.clamp(-6.0, 6.0);
                                  });
                                }
                              },
                              onPanEnd: (details) {
                                if (isSelected) {
                                  final double t = 0.35;
                                  final double val = _dragOffsetX / tabWidth;
                                  int targetOffset = 0;
                                  if (val >= 0) {
                                    final int integer = val.floor();
                                    final double fraction = val - integer;
                                    targetOffset = fraction >= t ? integer + 1 : integer;
                                  } else {
                                    final int integer = val.ceil();
                                    final double fraction = val - integer;
                                    targetOffset = fraction.abs() >= t ? integer - 1 : integer;
                                  }

                                  if (targetOffset != 0) {
                                    final int targetIndex = (index + targetOffset).clamp(0, totalTabs - 1);
                                    if (targetIndex != index) {
                                      HapticFeedback.mediumImpact();
                                      _gestureOldIndex = index;
                                      _gestureTargetIndex = targetIndex;
                                      _gestureReleasedOffsetX = _dragOffsetX;
                                      _gestureReleasedOffsetY = _dragOffsetY;
                                      _isGestureTransition = true;
                                      _tabController!.animateTo(targetIndex);
                                    } else {
                                      _springBack();
                                    }
                                  } else {
                                    _springBack();
                                  }
                                }
                              },
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Transform.scale(
                                        scale: scale,
                                        child: Transform.rotate(
                                          angle: rotation,
                                          child: Icon(
                                            widget.icons[index],
                                            size: 20,
                                            color: contentColor,
                                          ),
                                        ),
                                      ),
                                      6.widthBox,
                                      Text(
                                        widget.labels[index],
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: contentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
