import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/utils/app_logger.dart';
import 'package:collegebus/features/payment/presentation/screens/transaction_history_screen.dart';
import 'package:collegebus/features/payment/services/subscription_plans_provider.dart';
import 'package:collegebus/features/payment/presentation/widgets/payment_error_boundary.dart';



// We'll use standard colors to avoid dependency issues if any
enum SnackBarType { success, error, warning, info }

// Redundant local AppColors removed to use global Theme system

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  Timer? _countdownTimer;
  List<dynamic> _plans = []; // Store fetched plans

  int get _currentAmount {
    if (_plans.isEmpty) return 0;
    final plan = _plans.firstWhere(
      (p) => p['alias'] == _selectedPlan,
      orElse: () => null,
    );
    if (plan == null) return 0;

    // Safety: ensure price is treated as num and converted to int
    final price = plan['price'];
    if (price is num) return price.toInt();
    if (price is String) return int.tryParse(price) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _startTimer();
  }

  bool _isEarlyRenewal = false;
  late Razorpay _razorpay;
  bool _isLoading = false;
  String? _selectedPlan;
  String _activeTier = 'standard';


  Future<void> _refreshPlans() async {
    try {
      await ref.read(subscriptionPlansProvider.notifier).refresh();
    } catch (e) {
      AppLogger.e("Error refreshing plans via provider: $e");
      _showSnackBar("Failed to refresh plans", type: SnackBarType.error);
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
      final repo = ref.read(paymentRepositoryProvider);
      AppLogger.d(
        "Payment Success: ${response.paymentId}, Order: ${response.orderId}, Sig: ${response.signature}",
      );

      if (response.paymentId != null &&
          response.orderId != null &&
          response.signature != null) {
        await repo.verifyPayment(
          response.orderId!,
          response.paymentId!,
          response.signature!,
        );

        if (mounted) {
          final user = ref.read(currentUserProvider);
          if (user != null) {
            final duration = _selectedPlan?.contains('365') ?? false
                ? const Duration(days: 365)
                : const Duration(days: 30);

            // Stacking logic for optimistic update
            final currentExpiry =
                (user.premiumUntil != null &&
                    user.premiumUntil!.isAfter(DateTime.now()))
                ? user.premiumUntil!
                : DateTime.now();

            final updatedUser = user.copyWith(
              isPremium:
                  true, // Any paid plan (Standard/Premium) counts as isPremium for feature gating
              premiumUntil: currentExpiry.add(duration),
              subscriptionPlan: _selectedPlan,
            );
            ref.read(authProvider.notifier).updateCurrentUser(updatedUser);
          }
          ref.read(authProvider.notifier).refreshUser();

          _showSnackBar(
            "Payment Verified Successfully!",
            type: SnackBarType.success,
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showSnackBar(
            "Payment Successful (Check Status)",
            type: SnackBarType.warning,
          );
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        _showSnackBar("Verification Failed: $e", type: SnackBarType.error);
        context.paymentErrorBoundary?.catchPaymentError(e, stackTrace);
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
    if (code == Razorpay.PAYMENT_CANCELLED ||
        message.toLowerCase().contains("undefined") ||
        message.toLowerCase().contains("cancelled")) {
      _showSnackBar("Payment Process Cancelled", type: SnackBarType.warning);
    } else {
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
      final repo = ref.read(paymentRepositoryProvider);
      final user = ref.read(currentUserProvider);
      if (user == null) throw "User not logged in";

      final amount = _currentAmount;
      final double totalAmount = amount * (1 - (_isEarlyRenewal ? 0.05 : 0.0));

      final orderData = await repo.createOrder(
        totalAmount.toInt(),
        "INR",
        plan: _selectedPlan,
      );
      final orderId = orderData['id']?.toString() ?? "";
      final keyId =
          orderData['key_id']?.toString() ?? 'rzp_test_1DP5mmOlF5G5ag';

      final options = {
        'key': keyId,
        'amount': (totalAmount * 100).toInt(),
        'name': 'College Bus Tracking',
        'description': 'Subscription Plan Selection',
        'order_id': orderId,
        'retry': {'enabled': true, 'max_count': 1},
        'send_sms_hash': true,
        'prefill': {'contact': user.phoneNumber ?? "", 'email': user.email},
      };

      if (!mounted) return;
      _razorpay.open(options);
    } catch (e, stackTrace) {
      AppLogger.e("Payment Initiation Failed: $e");
      if (mounted) {
        _showSnackBar("Failed to start payment: $e", type: SnackBarType.error);
        setState(() => _isLoading = false);
        context.paymentErrorBoundary?.catchPaymentError(e, stackTrace);
      }
    }
  }

  void _showSnackBar(String message, {SnackBarType type = SnackBarType.info}) {
    if (!mounted) return;
    Color bgColor;
    IconData icon;
    switch (type) {
      case SnackBarType.success:
        bgColor = Colors.green.shade800;
        icon = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        bgColor = Colors.red.shade800;
        icon = Icons.error_rounded;
        break;
      case SnackBarType.warning:
        bgColor = Colors.orange.shade700;
        icon = Icons.warning_rounded;
        break;
      case SnackBarType.info:
        bgColor = Colors.black87;
        icon = Icons.info_rounded;
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    // Watch and sync active plans from standardized provider
    final activePlansAsync = ref.watch(activeSubscriptionPlansProvider);
    final bool isFetching = activePlansAsync.isLoading && _plans.isEmpty;
    final bool hasError = activePlansAsync.hasError && _plans.isEmpty;

    if (activePlansAsync.hasValue && activePlansAsync.value != null) {
      final nextPlans = activePlansAsync.value!;
      // Sync only if list changed or selection is empty
      if (_plans.length != nextPlans.length || _selectedPlan == null) {
        _plans = nextPlans;
        if (_plans.isNotEmpty && _selectedPlan == null) {
          final defaultPlan = _plans.firstWhere(
            (p) => p['alias'] == 'standard_30',
            orElse: () => _plans[0],
          );
          _selectedPlan = defaultPlan['alias'];
          final alias = _selectedPlan ?? '';
          if (alias.contains('premium')) {
            _activeTier = 'premium';
          } else {
            _activeTier = 'standard';
          }
        }
      }
    }


    // Calculate early renewal eligibility
    if (user != null && user.isPremium && user.premiumUntil != null) {
      final threeDaysInMs = 3 * 24 * 60 * 60 * 1000;
      final timeRemaining = user.premiumUntil!
          .difference(DateTime.now())
          .inMilliseconds;
      _isEarlyRenewal = timeRemaining > threeDaysInMs;
    } else {
      _isEarlyRenewal = false;
    }

    // Show all active plans
    final isDark = theme.brightness == Brightness.dark;

    return PaymentErrorBoundary(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF060B18) : const Color(0xFFF0F4FF),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Your Plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Unlock premium tracking',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF003D4D), Color(0xFF005F73), Color(0xFF0097B2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -30, right: -20,
                        child: Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00C6E6).withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20, left: -10,
                        child: Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: RefreshIndicator(
            onRefresh: _refreshPlans,
            color: const Color(0xFF0097B2),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildSubscriptionStatus(theme),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      children: [
                        if (isFetching)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(60.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (hasError || _plans.isEmpty)
                          _buildEmptyState(theme)
                        else ...[
                          _buildBenefitsSection(theme),
                          const SizedBox(height: 28),
                          _buildTierSelector(theme),
                          const SizedBox(height: 20),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              final offsetAnimation = Tween<Offset>(
                                begin: const Offset(0.12, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ));
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                ),
                              );
                            },
                            child: _activeTier == 'standard'
                                ? _buildStandardPlans(theme)
                                : _buildPremiumPlans(theme),
                          ),
                        ],
                        const SizedBox(height: 32),
                        _buildComparisonTable(theme),
                        const SizedBox(height: 32),
                        _buildPaymentSummary(theme),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(theme, user),
      ),
    );
  }



  Widget _buildEmptyState(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20, offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.layers_clear_rounded, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
          const Text('No plans available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh or tap retry below.',
            style: TextStyle(color: theme.disabledColor, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshPlans,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0097B2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final benefits = [
      {
        'icon': Icons.my_location_rounded,
        'label': 'Live GPS',
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFF1D4ED8),
      },
      {
        'icon': Icons.notifications_active_rounded,
        'label': 'Smart Alerts',
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFB45309),
      },
      {
        'icon': Icons.timeline_rounded,
        'label': 'Route History',
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFF065F46),
      },
      {
        'icon': Icons.sos_rounded,
        'label': 'SOS Safety',
        'color': const Color(0xFFEF4444),
        'bg': const Color(0xFF991B1B),
      },
      {
        'icon': Icons.people_alt_rounded,
        'label': 'Family Share',
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFF5B21B6),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 18,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0097B2), Color(0xFF00C6E6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'What you unlock',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: benefits.map((b) {
            final Color iconColor = b['color'] as Color;
            final Color bgColor = b['bg'] as Color;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bgColor.withValues(alpha: isDark ? 0.35 : 0.08), iconColor.withValues(alpha: isDark ? 0.1 : 0.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: iconColor.withValues(alpha: isDark ? 0.3 : 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(b['icon'] as IconData, size: 15, color: iconColor),
                  const SizedBox(width: 6),
                  Text(
                    b['label'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEnhancedPlanCard({
    required dynamic plan,
    required bool isSelected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return FlipCardWidget(
      isSelected: isSelected,
      front: _buildCardFace(
        plan: plan,
        isSelected: false,
        theme: theme,
        onTap: onTap,
      ),
      back: _buildCardFace(
        plan: plan,
        isSelected: true,
        theme: theme,
        onTap: onTap,
      ),
    );
  }

  Widget _buildCardFace({
    required dynamic plan,
    required bool isSelected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    final String alias = plan['alias']?.toString() ?? '';
    final bool isPremium = alias.contains('premium');
    final bool isYearly = alias.contains('365');
    final int priceInt = (() {
      final p = plan['price'];
      if (p is num) return p.toInt();
      return int.tryParse(p?.toString() ?? '0') ?? 0;
    })();

    final durationData = plan['durationDays'];
    final int days = (durationData is num)
        ? durationData.toInt()
        : (int.tryParse(durationData?.toString() ?? '0') ?? 0);
    final String billingCycle = days >= 365 ? 'year' : 'month';
    final double perDayPrice = days > 0 ? (priceInt / days) : 0;

    final String? badgeText = isYearly ? 'Best Value' : (isPremium ? 'Popular' : null);

    // Color palette — Turkish blue brand
    final Color accentColor = isPremium ? const Color(0xFFD97706) : const Color(0xFF0097B2);
    final Color accentGlow  = isPremium ? const Color(0xFFF59E0B) : const Color(0xFF00C6E6);

    final selectedGradient = isPremium
        ? const LinearGradient(
            colors: [Color(0xFF1A0A3C), Color(0xFF2D1080), Color(0xFF1E1650)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF003D4D), Color(0xFF005F73), Color(0xFF0097B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final isDark = theme.brightness == Brightness.dark;
    final unselectedBg = isDark ? const Color(0xFF071318) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isSelected ? null : unselectedBg,
          gradient: isSelected ? selectedGradient : null,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? accentGlow.withValues(alpha: 0.6) : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: -4,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative glow blob for selected
              if (isSelected)
                Positioned(
                  top: -30, right: -20,
                  child: Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: icon + name + price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Plan icon
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withValues(alpha: isSelected ? 0.3 : 0.15),
                                accentColor.withValues(alpha: isSelected ? 0.15 : 0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accentColor.withValues(alpha: isSelected ? 0.4 : 0.2),
                            ),
                          ),
                          child: Icon(
                            isPremium ? Icons.diamond_rounded : Icons.bolt_rounded,
                            color: isSelected ? Colors.white : accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Plan name + billing cycle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan['name']?.toString() ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: isSelected ? Colors.white : theme.textTheme.titleMedium?.color,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: isSelected ? 0.25 : 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isYearly ? 'Annual Plan · 12 months' : 'Monthly Plan · 30 days',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? accentGlow : accentColor,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Price block
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹$priceInt',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                color: isSelected ? Colors.white : theme.textTheme.titleLarge?.color,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              '/ $billingCycle',
                              style: TextStyle(
                                color: isSelected ? Colors.white54 : theme.disabledColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '≈ ₹${perDayPrice.toStringAsFixed(1)}/day',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? accentGlow.withValues(alpha: 0.9) : accentColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Features or hint
                    if (isSelected && plan['features'] != null && (plan['features'] as List).isNotEmpty)
                      StaggeredFeaturesList(features: plan['features'] as List)
                    else ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isDark ? 0.1 : 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentColor.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app_rounded, size: 14, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              'Tap to select & expand details',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Selection indicator strip
                    if (isSelected) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'Selected — ready to checkout',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Text(
                              '${plan['features']?.length ?? 0} features',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Badge chip
              if (badgeText != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isYearly
                            ? [const Color(0xFF059669), const Color(0xFF10B981)]
                            : [const Color(0xFFD97706), const Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isYearly ? const Color(0xFF059669) : const Color(0xFFD97706)).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      badgeText.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierSelector(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF071318) : const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: _activeTier == 'standard'
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _activeTier == 'standard'
                      ? const LinearGradient(colors: [Color(0xFF006A80), Color(0xFF0097B2)])
                      : const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(
                      color: (_activeTier == 'standard' ? const Color(0xFF0097B2) : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeTier = 'standard';
                      _autoSelectPlanForTier('standard');
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_outline_rounded,
                          size: 18,
                          color: _activeTier == 'standard' ? Colors.white : theme.disabledColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Standard",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _activeTier == 'standard' ? Colors.white : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeTier = 'premium';
                      _autoSelectPlanForTier('premium');
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: 18,
                          color: _activeTier == 'premium' ? Colors.white : theme.disabledColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Premium",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _activeTier == 'premium' ? Colors.white : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandardPlans(ThemeData theme) {
    final standardPlans = _plans.where(
      (p) => (p['alias']?.toString().contains('standard') ?? false) ||
             (!(p['alias']?.toString().contains('premium') ?? false) &&
              !(p['alias']?.toString().contains('standard') ?? false)),
    ).toList();

    return Column(
      key: const ValueKey('standard_plans_list'),
      children: standardPlans.map((plan) {
        return _buildEnhancedPlanCard(
          plan: plan,
          isSelected: _selectedPlan == plan['alias'],
          theme: theme,
          onTap: () => setState(() => _selectedPlan = plan['alias']),
        );
      }).toList(),
    );
  }

  Widget _buildPremiumPlans(ThemeData theme) {
    final premiumPlans = _plans.where(
      (p) => p['alias']?.toString().contains('premium') ?? false,
    ).toList();

    return Column(
      key: const ValueKey('premium_plans_list'),
      children: premiumPlans.map((plan) {
        return _buildEnhancedPlanCard(
          plan: plan,
          isSelected: _selectedPlan == plan['alias'],
          theme: theme,
          onTap: () => setState(() => _selectedPlan = plan['alias']),
        );
      }).toList(),
    );
  }

  void _autoSelectPlanForTier(String tier) {
    if (_plans.isEmpty || _selectedPlan == null) return;
    final isYearly = _selectedPlan!.contains('365');
    final suffix = isYearly ? '365' : '30';
    final targetAlias = '${tier}_$suffix';

    final exists = _plans.any((p) => p['alias'] == targetAlias);
    if (exists) {
      _selectedPlan = targetAlias;
    } else {
      final firstOfTier = _plans.firstWhere(
        (p) => p['alias']?.toString().contains(tier) ?? false,
        orElse: () => null,
      );
      if (firstOfTier != null) {
        _selectedPlan = firstOfTier['alias'];
      }
    }
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
    final String timeRemainingText = days > 0
        ? "$days Days Left"
        : "Expiring Soon";
    final double progress = (days / 365).clamp(
      0.0,
      1.0,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF003D4D), // Deep teal
            Color(0xFF0097B2), // Turkish blue
            Color(0xFF00C6E6), // Light cyan
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PREMIUM PASS",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            user.subscriptionPlan
                                    ?.replaceAll('_', ' ')
                                    .toUpperCase() ??
                                "ACTIVE MEMBER",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      timeRemainingText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Expiry: ${expiry.day} ${DateFormat('MMM').format(expiry)}, ${expiry.year}",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "${(progress * 100).toInt()}% Cycle Remaining",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    const rows = [
      ['Real-time Bus Tracking', true, true],
      ['Smart Notifications', true, true],
      ['Route Logs & History', true, true],
      ['SOS Emergency Alerts', false, true],
      ['Advanced Login Options', false, true],
      ['Priority Support', false, true],
      ['Family Sharing', false, true],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 18,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0097B2), Color(0xFF00C6E6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Plan Comparison',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF071318) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF003D4D), Color(0xFF0097B2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 5,
                        child: Text(
                          'Feature',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C6E6).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF00C6E6).withValues(alpha: 0.5)),
                              ),
                              child: const Text(
                                'Standard',
                                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.w800),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Premium',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Data rows
                ...rows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final row = entry.value;
                  final bool stdVal = row[1] as bool;
                  final bool premVal = row[2] as bool;
                  final bool isEven = i % 2 == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: isEven
                          ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            row[0] as String,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: _buildCheckCell(stdVal),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: _buildCheckCell(premVal, isPremium: true),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckCell(bool value, {bool isPremium = false}) {
    if (value) {
      return Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isPremium
                ? [const Color(0xFFD97706), const Color(0xFFF59E0B)]
                : [const Color(0xFF006A80), const Color(0xFF00C6E6)],
          ),
          boxShadow: [
            BoxShadow(
              color: (isPremium ? const Color(0xFFF59E0B) : const Color(0xFF0097B2)).withValues(alpha: 0.4),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
      );
    }
    return Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withValues(alpha: 0.12),
      ),
      child: const Icon(Icons.remove_rounded, color: Colors.grey, size: 14),
    );
  }

  Widget _buildPaymentSummary(ThemeData theme) {
    final amount = _currentAmount.toDouble();
    final earlyRenewalDiscount = _isEarlyRenewal ? (amount * 0.05) : 0.0;
    final finalAmount = amount - earlyRenewalDiscount;
    final isDark = theme.brightness == Brightness.dark;

    // Find selected plan name
    final selectedPlanData = _plans.isEmpty ? null : _plans.firstWhere(
      (p) => p['alias'] == _selectedPlan,
      orElse: () => null,
    );
    final selectedName = selectedPlanData?['name']?.toString() ?? 'Selected Plan';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF006A80), Color(0xFF0097B2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.3),
                    ),
                    Text(
                      'Review before payment',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Line items
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSummaryRow(
                  label: selectedName,
                  value: '₹${amount.toInt()}',
                  icon: Icons.confirmation_number_rounded,
                  iconColor: const Color(0xFF0097B2),
                  theme: theme,
                ),
                if (_isEarlyRenewal) ...[
                  const SizedBox(height: 10),
                  _buildSummaryRow(
                    label: 'Early Renewal Discount (5%)',
                    value: '− ₹${earlyRenewalDiscount.toInt()}',
                    icon: Icons.local_offer_rounded,
                    iconColor: const Color(0xFF10B981),
                    valueColor: const Color(0xFF10B981),
                    theme: theme,
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF006A80), Color(0xFF00C6E6)],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Due',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF006A80), Color(0xFF0097B2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0097B2).withValues(alpha: 0.45),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '₹${finalAmount.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, size: 12, color: theme.disabledColor),
                    const SizedBox(width: 5),
                    Text(
                      'Secured by Razorpay · 256-bit SSL',
                      style: TextStyle(fontSize: 11, color: theme.disabledColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    Color? valueColor,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: theme.disabledColor, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: valueColor ?? theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme, dynamic user) {
    final bool isCurrentPlanSelected =
        (user?.isPremium ?? false) && user?.subscriptionPlan == _selectedPlan;
    final amount = _currentAmount;
    final double finalAmount = amount * (1 - (_isEarlyRenewal ? 0.05 : 0.0));
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF060B18) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            offset: const Offset(0, -4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCurrentPlanSelected)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Your active plan — already subscribed',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: _isLoading || isCurrentPlanSelected
                ? Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text(
                              'Already Subscribed',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.grey),
                            ),
                    ),
                  )
                : GestureDetector(
                    onTap: _initiatePayment,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF004D60), Color(0xFF0097B2), Color(0xFF00C6E6)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0097B2).withValues(alpha: 0.55),
                            blurRadius: 20,
                            spreadRadius: -2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_rounded, color: Colors.white70, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Pay ₹${finalAmount % 1 == 0 ? finalAmount.toInt() : finalAmount.toStringAsFixed(1)} Securely',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class FlipCardWidget extends StatefulWidget {
  final bool isSelected;
  final Widget front;
  final Widget back;
  const FlipCardWidget({
    super.key,
    required this.isSelected,
    required this.front,
    required this.back,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FlipCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * 3.141592653589793;
        final isBack = angle >= 3.141592653589793 / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isBack
              ? Transform(
                  transform: Matrix4.identity()..rotateY(3.141592653589793),
                  alignment: Alignment.center,
                  child: widget.back,
                )
              : widget.front,
        );
      },
    );
  }
}

class StaggeredFeaturesList extends StatefulWidget {
  final List<dynamic> features;
  const StaggeredFeaturesList({super.key, required this.features});

  @override
  State<StaggeredFeaturesList> createState() => _StaggeredFeaturesListState();
}

class _StaggeredFeaturesListState extends State<StaggeredFeaturesList> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 12),
        ...List.generate(widget.features.length, (index) {
          final feat = widget.features[index];
          final start = (index * 0.1).clamp(0.0, 1.0);
          final end = (start + 0.4).clamp(0.0, 1.0);

          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(start, end, curve: Curves.easeOut),
            ),
          );

          final slideAnimation = Tween<Offset>(
            begin: const Offset(-0.08, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(start, end, curve: Curves.easeOutCubic),
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feat.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

