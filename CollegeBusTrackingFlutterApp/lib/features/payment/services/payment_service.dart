import 'dart:async';
import 'package:collegebus/core/data/repositories.dart';
import 'package:flutter/material.dart';

class PaymentService extends ChangeNotifier {
  PaymentRepository _paymentRepo;
  String? _lastError;

  String? get lastError => _lastError;

  PaymentService(this._paymentRepo);

  void updateDependencies(PaymentRepository repo) {
    _paymentRepo = repo;
  }

  void clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  void _setError(dynamic e) {
    _lastError = e.toString();
    notifyListeners();
  }

  Future<Map<String, dynamic>> createPaymentOrder(
    int amount,
    String currency, {
    String? plan,
  }) async {
    try {
      final result = await _paymentRepo.createOrder(
        amount,
        currency,
        plan: plan,
      );
      clearError();
      return result;
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyPayment(
    String orderId,
    String paymentId,
    String signature,
  ) async {
    try {
      final result = await _paymentRepo.verifyPayment(
        orderId,
        paymentId,
        signature,
      );
      clearError();
      return result;
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }
}
