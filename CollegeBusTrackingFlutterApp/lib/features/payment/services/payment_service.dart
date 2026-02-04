import 'dart:async';
import 'package:collegebus/core/services/api_service.dart';
import 'package:flutter/material.dart';

class PaymentService extends ChangeNotifier {
  ApiService _apiService;
  String? _lastError;

  String? get lastError => _lastError;

  PaymentService(this._apiService);

  void updateDependencies(ApiService api) {
    _apiService = api;
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
    String currency,
  ) async {
    try {
      final result = await _apiService.createPaymentOrder(amount, currency);
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
      final result = await _apiService.verifyPayment(
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





