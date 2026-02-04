import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/core/utils/app_logger.dart';

// We'll use standard colors to avoid dependency issues if any
enum SnackBarType { success, error, warning, info }

class AppColors {
  static const Color primary = Color(0xFF2563EB); // blue-600
  static const Color background = Color(0xFFF8FAFC); // slate-50
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B); // slate-800
  static const Color textSecondary = Color(0xFF64748B); // slate-500
  static const Color success = Color(0xFF16A34A); // green-600
  static const Color error = Color(0xFFDC2626); // red-600
}

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isLoading = false;

  final int _fixedAmount = 20;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      AppLogger.d(
        "Payment Success: ${response.paymentId}, Order: ${response.orderId}, Sig: ${response.signature}",
      );

      if (response.paymentId != null &&
          response.orderId != null &&
          response.signature != null) {
        await api.verifyPayment(
          response.orderId!,
          response.paymentId!,
          response.signature!,
        );

        if (mounted) {
          // 1. Optimistic Update (Immediate Feedback)
          final user = ref.read(currentUserProvider);
          if (user != null) {
            final updatedUser = user.copyWith(isPremium: true);
            ref.read(authProvider.notifier).updateCurrentUser(updatedUser);
          }

          // 2. Sync with Backend
          ref.read(authProvider.notifier).refreshUser();

          _showSnackBar(
            "Payment Verified Successfully! You are now Premium.",
            type: SnackBarType.success,
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showSnackBar(
            "Payment Successful (Check Status)", // Ambiguous case
            type: SnackBarType.warning,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Verification Failed: $e", type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    AppLogger.e("Payment Error: ${response.code} - ${response.message}");

    String message = response.message ?? "Payment Failed";
    int code = response.code ?? 0;

    // Handle User Cancellation or "undefined" error typically associated with back press
    if (code == Razorpay.PAYMENT_CANCELLED ||
        message.toLowerCase().contains("undefined") ||
        message.toLowerCase().contains("cancelled")) {
      _showSnackBar("Payment Process Cancelled", type: SnackBarType.warning);
    } else {
      // Actual Error
      _showSnackBar("Payment Failed: $message", type: SnackBarType.error);
    }
    setState(() => _isLoading = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    AppLogger.i("External Wallet: ${response.walletName}");
    _showSnackBar(
      "External Wallet: ${response.walletName}",
      type: SnackBarType.info,
    );
  }

  Future<void> _initiatePayment() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final user = ref.read(currentUserProvider);

      if (user == null) throw "User not logged in";

      final amount = _fixedAmount;
      final orderData = await api.createPaymentOrder(amount, "INR");
      final orderId = orderData['id']?.toString() ?? "";
      final keyId =
          orderData['key_id']?.toString() ?? 'rzp_test_1DP5mmOlF5G5ag';

      AppLogger.i("Initiating Razorpay with Order: $orderId and Key: $keyId");

      final options = {
        'key': keyId,
        'amount': amount * 100,
        'name': 'College Bus Tracking',
        'description': 'Premium Access',
        'order_id': orderId,
        'retry': {'enabled': true, 'max_count': 1},
        'send_sms_hash': true,
        'prefill': {'contact': user.phoneNumber ?? "", 'email': user.email},
      };

      AppLogger.d("Razorpay Options: $options");

      if (!mounted) return;
      _razorpay.open(options);
    } catch (e) {
      AppLogger.e("Payment Initiation Failed: $e");
      if (mounted) {
        _showSnackBar("Failed to start payment: $e", type: SnackBarType.error);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {SnackBarType type = SnackBarType.info}) {
    if (!mounted) return;

    Color bgColor;
    IconData icon;
    Color textColor = Colors.white;

    switch (type) {
      case SnackBarType.success:
        bgColor = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        bgColor = AppColors.error;
        icon = Icons.error_rounded;
        break;
      case SnackBarType.warning:
        bgColor = Colors.orange.shade700;
        icon = Icons.warning_rounded;
        break;
      case SnackBarType.info:
        bgColor = AppColors.textPrimary;
        icon = Icons.info_rounded;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = ref.watch(themeServiceProvider);
    final isDark = themeService.isDarkMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // Transparent background so it mimics the app bar color
        statusBarColor: Colors.transparent,
        // Light Mode -> Dark Icons (Black). Dark Mode -> Light Icons (White).
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        // iOS: Light Mode -> Light Background (Dark Icons). Dark Mode -> Dark Background (Light Icons).
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(""), // Minimalist Header
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.textTheme.bodyLarge?.color,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "Premium Access",
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Get full access to live tracking, detailed reports, and priority support.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Comparison Headers
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                "Standard",
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 60,
                              child: Text(
                                "Premium",
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Feature Comparison Table
                      _buildFeatureRow("Live Bus Tracking", true, true, theme),
                      _buildFeatureRow(
                        "Arrival Alerts (2 Stops Away)", // Renamed as requested
                        false, // Standard: No
                        true, // Premium: Yes
                        theme,
                      ),
                      _buildFeatureRow(
                        "Detailed Analytics",
                        false,
                        true,
                        theme,
                      ),
                      _buildFeatureRow(
                        "Ad-Free Experience",
                        false,
                        true,
                        theme,
                      ),
                      _buildFeatureRow("Priority Support", false, true, theme),
                      _buildFeatureRow(
                        "Early Access Features",
                        false,
                        true,
                        theme,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Payment Button Area
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _initiatePayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Pay ₹$_fixedAmount",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      "One-time payment. Secure & Encrypted.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.5,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    String feature,
    bool standard,
    bool premium,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              feature,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),

          // Standard Column
          SizedBox(
            width: 60,
            child: Center(
              child: Icon(
                standard ? Icons.check_rounded : Icons.close_rounded,
                color: standard
                    ? theme.textTheme.bodyLarge?.color?.withOpacity(0.7)
                    : theme.disabledColor.withOpacity(0.3),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Premium Column
          SizedBox(
            width: 60,
            child: Center(
              child: Icon(
                premium ? Icons.check_circle_rounded : Icons.close_rounded,
                color: premium
                    ? theme.colorScheme.primary
                    : theme.disabledColor,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
