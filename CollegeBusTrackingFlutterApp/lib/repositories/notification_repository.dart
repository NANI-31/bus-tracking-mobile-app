import 'package:flutter/foundation.dart';
import 'package:collegebus/models/notification_model.dart';
import 'package:collegebus/repositories/base_repository.dart';

/// Repository for notification operations
class NotificationRepository extends BaseRepository {
  /// Send a notification
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await dio.post('/notifications', data: notification.toMap());
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Get all notifications for a user
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await dio.get('/notifications/user/$userId');
      return (response.data as List)
          .map((data) => NotificationModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await dio.put('/notifications/$notificationId/read');
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Remove FCM token for a user (used on logout)
  Future<void> removeFcmToken(String userId) async {
    try {
      await dio.post(
        '/notifications/remove-fcm-token',
        data: {'userId': userId},
      );
    } catch (e) {
      // Non-blocking, just log
      debugPrint('\x1B[31mError removing FCM token: $e\x1B[0m');
    }
  }

  /// Broadcast a message to the entire college (Students, Teachers, Parents)
  Future<Map<String, dynamic>> broadcastToCollege(String message) async {
    try {
      final response = await dio.post(
        '/notifications/broadcast',
        data: {'message': message},
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }
}
