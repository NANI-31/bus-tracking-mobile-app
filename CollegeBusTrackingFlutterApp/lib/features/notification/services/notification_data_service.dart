import 'dart:async';
import 'package:collegebus/features/notification/domain/notification_model.dart';
import 'package:collegebus/core/data/repositories.dart';
import 'package:flutter/material.dart';

class NotificationDataService extends ChangeNotifier {
  NotificationRepository _notificationRepo;
  String? _lastError;

  String? get lastError => _lastError;

  NotificationDataService(this._notificationRepo);

  void updateDependencies(NotificationRepository repo) {
    _notificationRepo = repo;
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
      await _notificationRepo.sendNotification(notification);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return Stream.fromFuture(
      _notificationRepo.getUserNotifications(userId).catchError((e) {
        _setError(e);
        throw e;
      }),
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationRepo.markNotificationAsRead(notificationId);
      clearError();
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> broadcastNotification(String message) async {
    try {
      await _notificationRepo.broadcastToCollege(message);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }
}
