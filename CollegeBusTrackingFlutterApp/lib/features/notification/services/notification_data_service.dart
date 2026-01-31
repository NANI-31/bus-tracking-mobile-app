import 'dart:async';
import 'package:collegebus/features/notification/domain/notification_model.dart';
import 'package:collegebus/core/services/api_service.dart';
import 'package:flutter/material.dart';

class NotificationDataService extends ChangeNotifier {
  ApiService _apiService;
  String? _lastError;

  String? get lastError => _lastError;

  NotificationDataService(this._apiService);

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

  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _apiService.sendNotification(notification);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return Stream.fromFuture(
      _apiService.getUserNotifications(userId).catchError((e) {
        _setError(e);
        throw e;
      }),
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);
      clearError();
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> broadcastNotification(String message) async {
    try {
      await _apiService.broadcastToCollege(message);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }
}
