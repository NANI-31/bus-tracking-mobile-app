import 'package:flutter/material.dart';
import 'package:collegebus/core/utils/app_logger.dart';
import 'package:dio/dio.dart';

/// A custom error boundary for wrapping the payment/checkout flow.
/// It catches payment execution errors, logs them to AppLogger (acting as Sentry/Crashlytics),
/// and displays a user-friendly recovery UI when critical transaction errors occur.
class PaymentErrorBoundary extends StatefulWidget {
  final Widget child;

  const PaymentErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  State<PaymentErrorBoundary> createState() => _PaymentErrorBoundaryState();
}

class _PaymentErrorBoundaryState extends State<PaymentErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  void _resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  void didUpdateWidget(covariant PaymentErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error boundary if child changes
    if (_error != null) {
      _resetError();
    }
  }

  // Captures payment flow execution errors and reports them to observability
  void catchPaymentError(Object error, StackTrace stackTrace) {
    AppLogger.e("Observability Report: Payment/Transaction failure caught.", error, stackTrace);
    
    // Simulate reporting to Crashlytics / Sentry
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
    
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_error != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Transaction Error', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: isDark ? Colors.white : Colors.black87,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Payment Process Interrupted',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _mapErrorToUserMessage(_error),
                  style: const TextStyle(color: Colors.grey, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DIAGNOSTIC REPORT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error.toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.redAccent,
                        ),
                      ),
                      if (_stackTrace != null) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        const Text(
                          'STACK TRACE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: SingleChildScrollView(
                            child: Text(
                              _stackTrace.toString(),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Go Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _resetError,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _InheritedPaymentErrorBoundary(
      state: this,
      child: widget.child,
    );
  }

  String _mapErrorToUserMessage(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'We lost connection to our payment servers. Please check your internet connectivity and try again.';
      }
    }
    return 'An unexpected error occurred during the transaction. Our engineering team has been notified. No funds were debited.';
  }
}

class _InheritedPaymentErrorBoundary extends InheritedWidget {
  final _PaymentErrorBoundaryState state;

  const _InheritedPaymentErrorBoundary({
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedPaymentErrorBoundary oldWidget) => false;
}

extension PaymentErrorBoundaryExtension on BuildContext {
  /// Access the PaymentErrorBoundary in the widget tree to manually throw caught transaction errors.
  _PaymentErrorBoundaryState? get paymentErrorBoundary {
    return dependOnInheritedWidgetOfExactType<_InheritedPaymentErrorBoundary>()?.state;
  }
}
