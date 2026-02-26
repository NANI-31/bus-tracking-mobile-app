import 'package:flutter/foundation.dart';
import 'package:collegebus/features/notification/domain/notification_model.dart';
import 'package:collegebus/core/data/base_repository.dart';
import 'package:dio/dio.dart' as dio_lib;

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

  /// Mark all user notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await dio.put('/notifications/user/$userId/read-all');
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

  /// Send a voice notification
  Future<Map<String, dynamic>> sendVoiceNotification({
    required String receiverId,
    required String filePath,
    String? message,
  }) async {
    try {
      final formData = dio_lib.FormData.fromMap({
        'receiverId': receiverId,
        'message': message ?? 'New voice message',
        'audio': await dio_lib.MultipartFile.fromFile(
          filePath,
          filename: 'voice_message.mp3',
        ),
      });

      final response = await dio.post(
        '/notifications/voice',
        data: formData,
        options: dio_lib.Options(contentType: 'multipart/form-data'),
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await dio.delete('/notifications/$notificationId');
    } catch (e) {
      throw handleError(e);
    }
  }
}
