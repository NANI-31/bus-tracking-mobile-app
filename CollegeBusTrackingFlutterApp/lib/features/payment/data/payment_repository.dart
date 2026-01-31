import 'package:collegebus/core/data/base_repository.dart';

class PaymentRepository extends BaseRepository {
  Future<Map<String, dynamic>> createOrder(int amount, String currency) async {
    try {
      final response = await dio.post(
        '/payment/create-order',
        data: {'amount': amount, 'currency': currency},
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyPayment(
    String orderId,
    String paymentId,
    String signature,
  ) async {
    try {
      final response = await dio.post(
        '/payment/verify-payment',
        data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        },
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }
}
