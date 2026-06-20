import 'package:flutter/material.dart';

/// Standard controller layout interface for map overlays to coordinate
/// sizes and visibility of active panels and floating elements.
class MapOverlayController extends ChangeNotifier {
  double _bottomPanelHeight = 0.0;
  bool _isTopBarVisible = true;

  double get bottomPanelHeight => _bottomPanelHeight;
  bool get isTopBarVisible => _isTopBarVisible;

  set bottomPanelHeight(double val) {
    if (_bottomPanelHeight != val) {
      _bottomPanelHeight = val;
      notifyListeners();
    }
  }

  set isTopBarVisible(bool val) {
    if (_isTopBarVisible != val) {
      _isTopBarVisible = val;
      notifyListeners();
    }
  }
}

/// A standardized layout wrapper for mapping screens that aligns
/// a primary map widget with top headers, bottom panels, center pins, and floating action buttons.
///
/// It isolates painting boundaries and automatically adjusts FAB positions when the bottom panel changes height.
class MapOverlayLayout extends StatelessWidget {
  final Widget map;
  final Widget? topBar;
  final Widget? bottomPanel;
  final List<Widget> floatingActions;
  final Widget? centerCrosshair;
  final MapOverlayController? controller;

  const MapOverlayLayout({
    super.key,
    required this.map,
    this.topBar,
    this.bottomPanel,
    this.floatingActions = const [],
    this.centerCrosshair,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    // Use a local ListenableBuilder to adjust overlay elements reactively
    final Widget overlayStack = ListenableBuilder(
      listenable: controller ?? MapOverlayController(),
      builder: (context, _) {
        final currentBottomHeight = controller?.bottomPanelHeight ?? 0.0;
        final currentTopVisible = controller?.isTopBarVisible ?? true;

        return Stack(
          children: [
            // 1. Google Map (Isolate repaint)
            Positioned.fill(
              child: RepaintBoundary(child: map),
            ),

            // 2. Top Bar (Isolate repaint)
            if (topBar != null && currentTopVisible)
              Positioned(
                top: topPad + 8,
                left: 12,
                right: 12,
                child: RepaintBoundary(child: topBar!),
              ),

            // 3. Center Crosshair pin (Isolate repaint)
            if (centerCrosshair != null)
              Center(
                child: RepaintBoundary(child: centerCrosshair!),
              ),

            // 4. Floating Action Buttons and Bottom Panel stack
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RepaintBoundary(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Floating Action Buttons aligned above bottom panel
                    if (floatingActions.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          right: 14,
                          bottom: currentBottomHeight > 0 ? 0 : 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: floatingActions
                              .map(
                                (action) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: action,
                                ),
                              )
                              .toList(),
                        ),
                      ),

                    // Bottom Panel
                    if (bottomPanel != null) bottomPanel!,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: overlayStack,
    );
  }
}
