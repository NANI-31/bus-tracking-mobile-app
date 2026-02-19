import 'package:collegebus/core/data/base_repository.dart';

class PaymentRepository extends BaseRepository {
  Future<Map<String, dynamic>> createOrder(
    int amount,
    String currency, {
    String? plan,
  }) async {
    try {
      final response = await dio.post(
        '/payments/create-order',
        data: {'amount': amount, 'currency': currency, 'plan': plan},
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
        '/payments/verify-payment',
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

  Future<List<dynamic>> getTransactions({
    String? plan,
    DateTime? startDate,
    DateTime? endDate,
    String? collegeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (plan != null) queryParams['plan'] = plan;
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (collegeId != null) queryParams['collegeId'] = collegeId;

      final response = await dio.get(
        '/payments/transactions',
        queryParameters: queryParams,
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw handleError(e);
    }
  }
}
