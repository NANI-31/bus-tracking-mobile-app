import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/utils/app_logger.dart';

// We'll use standard colors to avoid dependency issues if any
class AppColors {
  static const Color primary = Color(0xFF2563EB); // blue-600
  static const Color background = Color(0xFFF8FAFC); // slate-50
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B); // slate-800
  static const Color textSecondary = Color(0xFF64748B); // slate-500
  static const Color success = Color(0xFF16A34A); // green-600
  static const Color error = Color(0xFFDC2626); // red-600
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  final List<int> _presets = [30, 100, 500, 1000, 2000];

  @override
  void initState() {
    super.initState();
    _amountController.text = "30";
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      AppLogger.d(
        "Payment Success: ${response.paymentId}, Order: ${response.orderId}, Sig: ${response.signature}",
      );

      if (response.paymentId != null &&
          response.orderId != null &&
          response.signature != null) {
        await dataService.verifyPayment(
          response.orderId!,
          response.paymentId!,
          response.signature!,
        );

        if (mounted) {
          _showSnackBar("Payment Verified Successfully!");
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showSnackBar("Payment Successful (Client Side Check)");
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Verification Failed: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    AppLogger.e("Payment Error: ${response.code} - ${response.message}");
    _showSnackBar("Payment Failed: ${response.message}", isError: true);
    setState(() => _isLoading = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    AppLogger.i("External Wallet: ${response.walletName}");
    _showSnackBar("External Wallet: ${response.walletName}");
  }

  Future<void> _initiatePayment() async {
    if (_amountController.text.isEmpty) {
      _showSnackBar("Please enter an amount", isError: true);
      return;
    }

    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar("Invalid amount", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUserModel;

      if (user == null) throw "User not logged in";

      final orderData = await dataService.createPaymentOrder(amount, "INR");
      final orderId = orderData['id']?.toString() ?? "";
      final keyId =
          orderData['key_id']?.toString() ?? 'rzp_test_1DP5mmOlF5G5ag';

      AppLogger.i("Initiating Razorpay with Order: $orderId and Key: $keyId");

      final options = {
        'key': keyId,
        'amount': amount * 100,
        'name': 'College Bus Tracking',
        'description': 'Fee Payment',
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
        _showSnackBar("Failed to start payment: $e", isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Make a Payment",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Enter Amount",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                "₹",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "0",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Text(
                      "Quick Select",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Presets
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _presets.map((amount) {
                        return ChoiceChip(
                          label: Text("₹$amount"),
                          selected: _amountController.text == amount.toString(),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _amountController.text = amount.toString();
                              });
                            }
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: _amountController.text == amount.toString()
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _amountController.text == amount.toString()
                                  ? AppColors.primary
                                  : Colors.grey[300]!,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Pay Button at bottom
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Pay Now",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
