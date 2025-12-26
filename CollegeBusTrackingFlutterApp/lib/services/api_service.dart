import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/schedule_model.dart';
import 'package:collegebus/models/notification_model.dart';
import 'package:collegebus/models/assignment_log_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/utils/app_exceptions.dart';
import 'package:collegebus/services/persistence_service.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = PersistenceService.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  AppException _handleError(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return NetworkException(message: 'Connection timed out');
      }
      if (e.response != null) {
        final data = e.response!.data;
        final message = data is Map
            ? (data['message'] ?? 'Server error')
            : 'Server error';
        if (e.response!.statusCode == 401 || e.response!.statusCode == 403) {
          return AuthException(message: message);
        }
        return ServerException(
          message: message,
          code: e.response!.statusCode.toString(),
        );
      }
      return NetworkException();
    }
    return AppException(e.toString());
  }

  // User Operations
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('/auth/register', data: userData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await _dio.post(
        '/auth/send-otp',
        data: {'email': email},
      );
      return {'success': true, 'message': response.data['message']};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      return {'success': true, 'message': response.data['message']};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {'email': email, 'newPassword': newPassword},
      );
      return {'success': true, 'message': response.data['message']};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return UserModel.fromMap(response.data, userId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _dio.get('/users');
      return (response.data as List)
          .map((data) => UserModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Bus Operations
  Future<List<BusModel>> getAllBuses() async {
    try {
      final response = await _dio.get('/buses');
      return (response.data as List)
          .map((data) => BusModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BusModel> createBus(BusModel bus) async {
    try {
      final response = await _dio.post('/buses', data: bus.toMap());
      return BusModel.fromMap(response.data, response.data['_id']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateBus(String busId, Map<String, dynamic> data) async {
    try {
      await _dio.put('/buses/$busId', data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteBus(String busId) async {
    try {
      await _dio.delete('/buses/$busId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Location Operations
  Future<void> updateBusLocation(
    String busId,
    double lat,
    double lng,
    double speed,
    double heading,
  ) async {
    try {
      await _dio.post(
        '/buses/location',
        data: {
          'busId': busId,
          'currentLocation': {'lat': lat, 'lng': lng},
          'speed': speed,
          'heading': heading,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BusLocationModel?> getBusLocation(String busId) async {
    try {
      final response = await _dio.get('/buses/$busId/location');
      return BusLocationModel.fromMap(response.data, busId);
    } catch (e) {
      // Location might not exist yet, so we return null instead of throwing for this specific one
      return null;
    }
  }

  Future<List<BusLocationModel>> getCollegeBusLocations(
    String collegeId,
  ) async {
    try {
      final response = await _dio.get('/buses/college/$collegeId/locations');
      return (response.data as List)
          .map((data) => BusLocationModel.fromMap(data, data['busId']))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // College Operations
  Future<List<CollegeModel>> getAllColleges() async {
    try {
      final response = await _dio.get('/colleges');
      return (response.data as List)
          .map((data) => CollegeModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Route Operations
  Future<List<RouteModel>> getRoutesByCollege(String collegeId) async {
    try {
      final response = await _dio.get('/routes/college/$collegeId');
      return (response.data as List)
          .map((data) => RouteModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<RouteModel> createRoute(RouteModel route) async {
    try {
      final response = await _dio.post('/routes', data: route.toMap());
      return RouteModel.fromMap(response.data, response.data['_id']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) async {
    try {
      await _dio.put('/routes/$routeId', data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteRoute(String routeId) async {
    try {
      await _dio.delete('/routes/$routeId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Schedule Operations
  Future<ScheduleModel> createSchedule(ScheduleModel schedule) async {
    try {
      final response = await _dio.post('/schedules', data: schedule.toMap());
      return ScheduleModel.fromMap(response.data, response.data['_id']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ScheduleModel>> getSchedulesByCollege(String collegeId) async {
    try {
      final response = await _dio.get('/schedules/college/$collegeId');
      return (response.data as List)
          .map((data) => ScheduleModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _dio.put('/schedules/$scheduleId', data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _dio.delete('/schedules/$scheduleId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Notification Operations
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _dio.post('/notifications', data: notification.toMap());
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await _dio.get('/notifications/user/$userId');
      return (response.data as List)
          .map((data) => NotificationModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _dio.put('/notifications/$notificationId/read');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removeFcmToken(String userId) async {
    try {
      await _dio.post(
        '/notifications/remove-fcm-token',
        data: {'userId': userId},
      );
    } catch (e) {
      // Create a warning but don't blocking flow
      debugPrint('Error removing FCM token: $e');
    }
  }

  // General Updates
  Future<UserModel> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/users/$userId', data: data);
      return UserModel.fromMap(response.data, userId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> approveUser(String userId, String approverId) async {
    await updateUser(userId, {
      'approved': true,
      'needsManualApproval': false,
      'approverId': approverId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Bus Number Operations
  Future<void> addBusNumber(String collegeId, String busNumber) async {
    try {
      await _dio.post(
        '/colleges/bus-numbers',
        data: {'collegeId': collegeId, 'busNumber': busNumber},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<String>> getBusNumbers(String collegeId) async {
    try {
      final response = await _dio.get('/colleges/$collegeId/bus-numbers');
      return (response.data as List).map((e) => e.toString()).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removeBusNumber(String collegeId, String busNumber) async {
    try {
      await _dio.delete('/colleges/$collegeId/bus-numbers/$busNumber');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Assignment Log Operations
  Future<List<AssignmentLogModel>> getAssignmentLogsByBus(String busId) async {
    try {
      final response = await _dio.get('/assignments/bus/$busId');
      return (response.data as List)
          .map((data) => AssignmentLogModel.fromMap(data))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<AssignmentLogModel>> getAssignmentLogsByDriver(
    String driverId,
  ) async {
    try {
      final response = await _dio.get('/assignments/driver/$driverId');
      return (response.data as List)
          .map((data) => AssignmentLogModel.fromMap(data))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
}
