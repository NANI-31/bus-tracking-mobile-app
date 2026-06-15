import 'package:flutter/material.dart';

class MapErrorBoundary extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;
  final String? errorMessage;

  const MapErrorBoundary({
    super.key,
    required this.child,
    this.onRetry,
    this.errorMessage,
  });

  @override
  State<MapErrorBoundary> createState() => _MapErrorBoundaryState();
}

class _MapErrorBoundaryState extends State<MapErrorBoundary> {
  bool _hasError = false;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorUI();
    }

    final oldBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (details) {
      _hasError = true;
      _error = details.exception;
      _stackTrace = details.stack;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
      
      return const SizedBox.shrink();
    };

    try {
      return widget.child;
    } catch (e, stack) {
      setState(() {
        _hasError = true;
        _error = e;
        _stackTrace = stack;
      });
      return _buildErrorUI();
    } finally {
      ErrorWidget.builder = oldBuilder;
    }
  }

  Widget _buildErrorUI() {
    debugPrint('MapErrorBoundary caught: $_error\n$_stackTrace');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wrong_location_outlined,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Map Rendering Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.errorMessage ?? 'An error occurred while loading the map view. Please check your network connection or API key configuration.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _error = null;
                  _stackTrace = null;
                });
                widget.onRetry?.call();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
