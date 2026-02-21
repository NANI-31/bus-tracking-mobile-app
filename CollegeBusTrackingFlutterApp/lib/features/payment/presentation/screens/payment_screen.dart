import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/utils/app_logger.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/payment/presentation/screens/transaction_history_screen.dart';

// We'll use standard colors to avoid dependency issues if any
enum SnackBarType { success, error, warning, info }

// Redundant local AppColors removed to use global Theme system

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final TextEditingController _couponController = TextEditingController();
  int _discountPercentage = 0;
  bool _isEarlyRenewal = false;
  String? _appliedCoupon;
  late Razorpay _razorpay;
  bool _isLoading = false;
  String _selectedPlan = 'monthly'; // 'monthly' or 'semester'
  Timer? _countdownTimer;
  String? _couponError;
  List<dynamic> _plans = []; // Store fetched plans
  bool _fetchingPlans = true;

  int get _currentAmount {
    if (_plans.isEmpty) return 0;
    final plan = _plans.firstWhere(
      (p) => p['alias'] == _selectedPlan,
      orElse: () => null,
    );
    return plan != null ? plan['price'] : 0;
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _startTimer();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final api = ref.read(apiServiceProvider);
      final plans = await api.getPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _fetchingPlans = false;
          // Default selection to the first non-trial plan or just the first plan
          if (_plans.isNotEmpty && _selectedPlan == 'monthly') {
            // Try to find a logical default if 'monthly' doesn't exist,
            // but for now keeping 'monthly' as default string is risky if alias changes.
            // Let's default to the first plan's alias.
            _selectedPlan = _plans[0]['alias'];
          }
        });
      }
    } catch (e) {
      AppLogger.e("Error fetching plans: $e");
      if (mounted) {
        setState(() => _fetchingPlans = false);
        _showSnackBar("Failed to load plans", type: SnackBarType.error);
      }
    }
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _countdownTimer?.cancel();
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
            // If the plan is 'semester', it's premium. Otherwise, assume premium unless logic dictates otherwise.
            final isPremium = true;

            final Duration duration = _selectedPlan == 'semester'
                ? const Duration(seconds: 90)
                : const Duration(seconds: 60);

            final updatedUser = user.copyWith(
              isPremium: isPremium,
              premiumUntil: DateTime.now().add(duration),
              subscriptionPlan: _selectedPlan,
            );
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

      final amount = _currentAmount;
      // Calculate totalAmount after discount if any
      final double totalAmount = amount * (1 - _discountPercentage / 100.0);

      final orderData = await api.createPaymentOrder(
        totalAmount.toInt(), // Pass integer amount to backend
        "INR",
        plan: _selectedPlan,
        couponCode: _appliedCoupon, // Include coupon code
      );
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
        bgColor = Theme.of(context).colorScheme.onSurface;
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
    // Use Theme.of(context) for reliable brightness check aligned with UI
    final isDark = theme.brightness == Brightness.dark;

    final user = ref.watch(currentUserProvider);
    if (user != null && user.isPremium && user.premiumUntil != null) {
      final threeDaysInMs = 3 * 24 * 60 * 60 * 1000;
      final timeRemaining = user.premiumUntil!
          .difference(DateTime.now())
          .inMilliseconds;
      _isEarlyRenewal = timeRemaining > threeDaysInMs;
    } else {
      _isEarlyRenewal = false;
    }

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
          title: const Text("Payments"),
          backgroundColor: isDark ? Colors.transparent : theme.primaryColor,
          elevation: 0,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history_rounded),
              tooltip: "Transaction History",
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildSubscriptionStatus(theme),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildPremiumBanner(theme),
                      const SizedBox(height: 32),

                      Text(
                        "Select Your Plan",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_fetchingPlans)
                        const Center(child: CircularProgressIndicator())
                      else if (_plans.isEmpty)
                        Center(
                          child: Text(
                            "No plans available",
                            style: theme.textTheme.bodyLarge,
                          ),
                        )
                      else
                        Row(
                          children: _plans.map((plan) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                ),
                                child: _buildPlanCard(
                                  title: plan['name'],
                                  price: "₹${plan['price']}",
                                  duration: "${plan['durationDays']} Days",
                                  isSelected: _selectedPlan == plan['alias'],
                                  onTap: () => setState(
                                    () => _selectedPlan = plan['alias'],
                                  ),
                                  theme: theme,
                                  isBestValue: plan['isBestValue'] ?? false,
                                  benefits: List<String>.from(
                                    plan['features'] ?? [],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 32),
                      _buildComparisonTable(theme),

                      const SizedBox(height: 32),
                      _buildCouponField(theme),

                      const SizedBox(height: 32),
                      _buildPaymentSummary(theme),
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
                      color: theme.dividerColor.withValues(alpha: 0.1),
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
                            "Pay ₹$_currentAmount",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security_rounded,
                          size: 14,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Secured by Razorpay. Encrypted Payment.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String duration,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    List<String> benefits = const [],
    bool isBestValue = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyMedium?.color?.withValues(
                                alpha: 0.6,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "/ $duration",
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...benefits.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 12,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.disabledColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          b,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isBestValue)
              Positioned(
                top: -32,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    "MOST POPULAR",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionStatus(ThemeData theme) {
    final user = ref.watch(currentUserProvider);
    if (user == null || !user.isPremium || user.premiumUntil == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final expiry = user.premiumUntil!;
    final totalDuration = expiry.difference(now);

    if (totalDuration.isNegative) {
      return const SizedBox.shrink();
    }

    final days = totalDuration.inDays;
    final hours = totalDuration.inHours % 24;
    final minutes = totalDuration.inMinutes % 60;

    final String timeRemainingText;
    if (days > 0) {
      timeRemainingText = "$days Days Left";
    } else if (hours > 0) {
      timeRemainingText = "$hours Hours Left";
    } else {
      final seconds = totalDuration.inSeconds % 60;
      timeRemainingText =
          "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }

    // Make progress bar dynamic for both testing and real production times
    final int totalPlanSeconds;
    if (totalDuration.inDays > 2) {
      // Real plan
      totalPlanSeconds =
          (user.subscriptionPlan == 'semester' ? 180 : 30) * 24 * 3600;
    } else {
      // Testing plan
      totalPlanSeconds = user.subscriptionPlan == 'semester' ? 90 : 60;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Premium Active",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Text(
                timeRemainingText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: totalDuration.inSeconds / totalPlanSeconds,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponField(ThemeData theme) {
    bool hasError = _couponError != null;
    bool hasApplied = _appliedCoupon != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Have a Coupon?",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _couponController,
                    onChanged: (v) {
                      if (_couponError != null)
                        setState(() => _couponError = null);
                    },
                    decoration: InputDecoration(
                      hintText: "Enter Code (e.g. SEM20)",
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: theme.disabledColor,
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                      prefixIcon: Icon(
                        Icons.confirmation_num_outlined,
                        color: hasError
                            ? theme.colorScheme.error
                            : (hasApplied
                                  ? theme.colorScheme.primary
                                  : theme.disabledColor),
                        size: 20,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: hasError
                              ? theme.colorScheme.error
                              : (hasApplied
                                    ? theme.colorScheme.primary
                                    : theme.dividerColor.withValues(
                                        alpha: 0.1,
                                      )),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: hasError
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  if (hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        _couponError!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (hasApplied && !hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        "Coupon Applied: $_appliedCoupon ✨",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final code = _couponController.text.trim().toUpperCase();
                  if (code.isEmpty) {
                    setState(() => _couponError = "Please enter a code");
                    return;
                  }

                  setState(() {
                    // Simple mock validation
                    if (code.startsWith("SAVE") || code.startsWith("SEM")) {
                      _appliedCoupon = code;
                      _couponError = null;
                      _showSnackBar(
                        "Coupon Applied Successfully!",
                        type: SnackBarType.success,
                      );
                    } else {
                      _appliedCoupon = null;
                      _couponError = "Invalid coupon code";
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  elevation: 0,
                ),
                child: const Text(
                  "Apply",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        if (_isEarlyRenewal)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Early Renewal Active! 5% extra discount applied automatically. 🚀",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
            theme.colorScheme.secondary.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "PREMIUM",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 10,
                  ),
                ),
              ),
              const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Go Premium. Get More.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Join 500+ students using live alerts and advanced trip insights.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Scroll to plans? For now just small feedback
              _showSnackBar(
                "Scroll down to select your plan!",
                type: SnackBarType.info,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              "Upgrade Now",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Plan Comparison",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              _buildModernTableRow(
                ["Feature", "Standard", "Premium"],
                isHeader: true,
                theme: theme,
              ),
              _buildModernTableRow([
                "Live Bus Tracking",
                true,
                true,
              ], theme: theme),
              _buildModernTableRow([
                "Bus Load Insights",
                false,
                true,
              ], theme: theme),
              _buildModernTableRow([
                "Priority Support",
                false,
                true,
              ], theme: theme),
              _buildModernTableRow([
                "Ad-Free Access",
                false,
                true,
              ], theme: theme),
              _buildModernTableRow([
                "Early Renewal Disc.",
                false,
                true,
              ], theme: theme),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildModernTableRow(
    List<dynamic> cells, {
    bool isHeader = false,
    required ThemeData theme,
  }) {
    return TableRow(
      children: cells.map((cell) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: cell is bool
              ? Center(
                  child: Icon(
                    cell ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: cell
                        ? theme.colorScheme.primary
                        : theme.disabledColor.withValues(alpha: 0.3),
                    size: 20,
                  ),
                )
              : Text(
                  cell.toString(),
                  textAlign: isHeader && cells.indexOf(cell) != 0
                      ? TextAlign.center
                      : TextAlign.start,
                  style: TextStyle(
                    fontWeight: isHeader ? FontWeight.w900 : FontWeight.w500,
                    fontSize: isHeader ? 12 : 13,
                    color: isHeader
                        ? theme.disabledColor
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentSummary(ThemeData theme) {
    final amount = _currentAmount.toDouble();
    final earlyRenewalDiscount = _isEarlyRenewal ? (amount * 0.05) : 0.0;

    // Simple mock logic for coupon discount (assuming 10% for any valid coupon for UI)
    final couponDiscount = _appliedCoupon != null ? (amount * 0.1) : 0.0;

    final totalDiscount = earlyRenewalDiscount + couponDiscount;
    final finalAmount = amount - totalDiscount;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Summary",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow(
            "Plan Price",
            "₹${amount.toStringAsFixed(0)}",
            theme,
          ),
          if (_isEarlyRenewal)
            _buildSummaryRow(
              "Early Renewal Discount (5%)",
              "- ₹${earlyRenewalDiscount.toStringAsFixed(2)}",
              theme,
              isDiscount: true,
            ),
          if (_appliedCoupon != null)
            _buildSummaryRow(
              "Coupon Discount",
              "- ₹${couponDiscount.toStringAsFixed(2)}",
              theme,
              isDiscount: true,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Payable",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                "₹${finalAmount.toStringAsFixed(2)}",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDiscount
                  ? Colors.green
                  : theme.textTheme.bodySmall?.color,
              fontWeight: isDiscount ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDiscount
                  ? Colors.green
                  : theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
