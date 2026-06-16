import 'package:flutter/material.dart';
import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/utils/app_logger.dart';
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
  Timer? _countdownTimer;
  List<dynamic> _plans = []; // Store fetched plans
  bool _fetchingPlans = true;

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
    _fetchPlans();
  }

  bool _isEarlyRenewal = false;
  late Razorpay _razorpay;
  bool _isLoading = false;
  String? _selectedPlan;

  void _fetchPlans() async {
    try {
      final repo = ref.read(paymentRepositoryProvider);
      final plans = await repo.getPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _fetchingPlans = false;
          if (_plans.isNotEmpty) {
            // Find standard monthly as default
            final defaultPlan = _plans.firstWhere(
              (p) => p['alias'] == 'standard_30',
              orElse: () => _plans[0],
            );
            _selectedPlan = defaultPlan['alias'];
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          "Subscription Plans",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TransactionHistoryScreen(),
              ),
            ),
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSubscriptionStatus(theme),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _fetchPlans(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      if (_fetchingPlans)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_plans.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text("No active plans found."),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchPlans,
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        _buildBenefitsSection(theme),
                        const SizedBox(height: 32),

                        // 1. Standard Tiers
                        if (_plans.any(
                          (p) =>
                              p['alias']?.toString().contains('standard') ??
                              false,
                        )) ...[
                          _buildTierHeader(
                            "Standard Tiers",
                            theme,
                            Icons.star_outline,
                          ),
                          const SizedBox(height: 16),
                          ..._plans
                              .where(
                                (p) =>
                                    p['alias']?.toString().contains(
                                      'standard',
                                    ) ??
                                    false,
                              )
                              .map(
                                (plan) => _buildEnhancedPlanCard(
                                  plan: plan,
                                  isSelected: _selectedPlan == plan['alias'],
                                  theme: theme,
                                  onTap: () => setState(
                                    () => _selectedPlan = plan['alias'],
                                  ),
                                ),
                              ),
                          const SizedBox(height: 24),
                        ],

                        // 2. Premium Tiers
                        if (_plans.any(
                          (p) =>
                              p['alias']?.toString().contains('premium') ??
                              false,
                        )) ...[
                          _buildTierHeader(
                            "Premium Tiers",
                            theme,
                            Icons.workspace_premium,
                          ),
                          const SizedBox(height: 16),
                          ..._plans
                              .where(
                                (p) =>
                                    p['alias']?.toString().contains(
                                      'premium',
                                    ) ??
                                    false,
                              )
                              .map(
                                (plan) => _buildEnhancedPlanCard(
                                  plan: plan,
                                  isSelected: _selectedPlan == plan['alias'],
                                  theme: theme,
                                  onTap: () => setState(
                                    () => _selectedPlan = plan['alias'],
                                  ),
                                ),
                              ),
                          const SizedBox(height: 24),
                        ],

                        // 3. Fallback for any other plans (e.g. legacy)
                        if (_plans.any(
                          (p) =>
                              !(p['alias']?.toString().contains('standard') ??
                                  false) &&
                              !(p['alias']?.toString().contains('premium') ??
                                  false),
                        )) ...[
                          _buildTierHeader(
                            "Available Plans",
                            theme,
                            Icons.list_alt,
                          ),
                          const SizedBox(height: 16),
                          ..._plans
                              .where(
                                (p) =>
                                    !(p['alias']?.toString().contains(
                                          'standard',
                                        ) ??
                                        false) &&
                                    !(p['alias']?.toString().contains(
                                          'premium',
                                        ) ??
                                        false),
                              )
                              .map(
                                (plan) => _buildEnhancedPlanCard(
                                  plan: plan,
                                  isSelected: _selectedPlan == plan['alias'],
                                  theme: theme,
                                  onTap: () => setState(
                                    () => _selectedPlan = plan['alias'],
                                  ),
                                ),
                              ),
                        ],
                      ],
                      const SizedBox(height: 32),
                      _buildComparisonTable(theme),
                      const SizedBox(height: 32),
                      _buildPaymentSummary(theme),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(theme, user),
          ],
        ),
      ),
    );
  }

  Widget _buildTierHeader(String title, ThemeData theme, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(ThemeData theme) {
    final benefits = [
      {"icon": Icons.speed, "title": "Real-time", "desc": "Live Tracking"},
      {
        "icon": Icons.notifications_active,
        "title": "Instant",
        "desc": "Custom Alerts",
      },
      {"icon": Icons.history, "title": "History", "desc": "Route Logs"},
      {"icon": Icons.shield, "title": "Security", "desc": "SOS & Safety"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Premium Benefits",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: benefits.length,
            itemBuilder: (context, index) {
              final b = benefits[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      b['icon'] as IconData,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      b['title'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      b['desc'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.disabledColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
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
    final String alias = plan['alias']?.toString() ?? '';
    final bool isPremium = alias.contains('premium');
    final bool isYearly = alias.contains('365');
    final String price = "₹${plan['price'] ?? 0}";

    final durationData = plan['durationDays'];
    final int days = (durationData is num)
        ? durationData.toInt()
        : (int.tryParse(durationData?.toString() ?? '0') ?? 0);
    final String durationText = days >= 365 ? "Year" : "$days Days";

    // "Save 17%" logic: if price is 100 and it's yearly, and there's a monthly for 10
    // (10*12 - 100) / 120 = 16.6%
    final String? badgeText = isYearly
        ? "Save 17%"
        : (isPremium ? "Popular" : null);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? (isPremium
                    ? Colors.amber.withValues(alpha: 0.05)
                    : theme.colorScheme.primary.withValues(alpha: 0.05))
              : theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? (isPremium ? Colors.amber : theme.colorScheme.primary)
                : theme.dividerColor.withValues(alpha: 0.1),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        (isPremium ? Colors.amber : theme.colorScheme.primary)
                            .withValues(alpha: 0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        (isPremium ? Colors.amber : theme.colorScheme.primary)
                            .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPremium ? Icons.auto_awesome : Icons.local_activity,
                    color: isPremium
                        ? Colors.amber.shade900
                        : theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${plan['features']?.length ?? 0} Core Features",
                          style: TextStyle(
                            color: theme.disabledColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: isSelected
                            ? (isPremium
                                  ? Colors.amber.shade900
                                  : theme.colorScheme.primary)
                            : null,
                      ),
                    ),
                    Text(
                      "/$durationText",
                      style: TextStyle(
                        color: theme.disabledColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (badgeText != null)
              Positioned(
                top: -36,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isYearly
                          ? [Colors.green.shade600, Colors.green.shade400]
                          : [Colors.orange.shade600, Colors.orange.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isYearly ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
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
    final String timeRemainingText = days > 0
        ? "$days Days Left"
        : "Expiring Soon";
    final double progress = (days / 365).clamp(
      0.0,
      1.0,
    ); // Simple progress for UI

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withBlue(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Current Subscription",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      user.subscriptionPlan
                              ?.replaceAll('_', ' ')
                              .toUpperCase() ??
                          "ACTIVE PLAN",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeRemainingText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Remaining",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Plan Comparison",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.compare_arrows_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              _buildTableRow(
                ["Feature", "Std", "Prem"],
                isHeader: true,
                theme: theme,
              ),
              _buildTableRow(["Real-time Tracking", true, true], theme: theme),
              _buildTableRow(["Basic Notifications", true, true], theme: theme),
              _buildTableRow(["Advanced Logins", false, true], theme: theme),
              _buildTableRow(["Unlimited SOS", false, true], theme: theme),
              _buildTableRow(["Priority Help", false, true], theme: theme),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(
    List<dynamic> cells, {
    bool isHeader = false,
    required ThemeData theme,
  }) {
    return TableRow(
      decoration: isHeader
          ? BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            )
          : null,
      children: cells.map((cell) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Center(
            child: cell is bool
                ? Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cell
                          ? Colors.green.withValues(alpha: 0.1)
                          : theme.disabledColor.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      cell ? Icons.check_rounded : Icons.close_rounded,
                      color: cell
                          ? Colors.green
                          : theme.disabledColor.withValues(alpha: 0.3),
                      size: 16,
                    ),
                  )
                : Text(
                    cell.toString(),
                    style: TextStyle(
                      fontWeight: isHeader ? FontWeight.w900 : FontWeight.w600,
                      fontSize: isHeader ? 13 : 12,
                      color: isHeader ? theme.colorScheme.primary : null,
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentSummary(ThemeData theme) {
    final amount = _currentAmount.toDouble();
    final earlyRenewalDiscount = _isEarlyRenewal ? (amount * 0.05) : 0.0;
    final finalAmount = amount - earlyRenewalDiscount;

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
          const Text(
            "Summary",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text("Base Price"), Text("₹${amount.toInt()}")],
          ),
          if (_isEarlyRenewal)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Early Renewal (5%)",
                    style: TextStyle(color: Colors.green),
                  ),
                  Text(
                    "- ₹${earlyRenewalDiscount.toInt()}",
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                "₹${finalAmount.toInt()}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, dynamic user) {
    final bool isCurrentPlanSelected =
        (user?.isPremium ?? false) && user?.subscriptionPlan == _selectedPlan;
    final amount = _currentAmount;
    final double finalAmount = amount * (1 - (_isEarlyRenewal ? 0.05 : 0.0));

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCurrentPlanSelected)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                "You are currently on this plan",
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: (_isLoading || isCurrentPlanSelected)
                  ? null
                  : _initiatePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: theme.colorScheme.primary.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      "Pay ₹${finalAmount % 1 == 0 ? finalAmount.toInt() : finalAmount.toStringAsFixed(1)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
