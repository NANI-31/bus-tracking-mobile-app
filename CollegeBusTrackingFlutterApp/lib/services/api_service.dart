import 'package:dio/dio.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/schedule_model.dart';
import 'package:collegebus/models/notification_model.dart';
import 'package:collegebus/utils/constants.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // User Operations
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('/auth/register', data: userData);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await _dio.post(
        '/auth/send-otp',
        data: {'email': email},
      );
      return {'success': true, 'message': response.data['message']};
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response!.data['message'] ?? 'Error sending OTP',
        };
      }
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      return {'success': true, 'message': response.data['message']};
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response!.data['message'] ?? 'Error verifying OTP',
        };
      }
      return {'success': false, 'message': 'Network error occurred'};
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
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response!.data['message'] ?? 'Error resetting password',
        };
      }
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return UserModel.fromMap(response.data, userId);
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _dio.get('/users');
      return (response.data as List)
          .map((data) => UserModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      print('Error fetching all users: $e');
      return [];
    }
  }

  Future<UserModel> createUser(UserModel user) async {
    try {
      final response = await _dio.post('/users', data: user.toMap());
      return UserModel.fromMap(response.data, response.data['_id']);
    } catch (e) {
      throw Exception('Error creating user: $e');
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
      print('Error fetching buses: $e');
      return [];
    }
  }

  Future<BusModel> createBus(BusModel bus) async {
    try {
      final response = await _dio.post('/buses', data: bus.toMap());
      return BusModel.fromMap(response.data, response.data['_id']);
    } catch (e) {
      throw Exception('Error creating bus: $e');
    }
  }

  Future<void> updateBus(String busId, Map<String, dynamic> data) async {
    try {
      await _dio.put('/buses/$busId', data: data);
    } catch (e) {
      throw Exception('Error updating bus: $e');
    }
  }

  Future<void> deleteBus(String busId) async {
    try {
      await _dio.delete('/buses/$busId');
    } catch (e) {
      throw Exception('Error deleting bus: $e');
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
      print('Error updating location: $e');
    }
  }

  Future<BusLocationModel?> getBusLocation(String busId) async {
    try {
      final response = await _dio.get('/buses/$busId/location');
      return BusLocationModel.fromMap(response.data, busId);
    } catch (e) {
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
      print('Error fetching college bus locations: $e');
      return [];
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
      print('Error fetching colleges: $e');
      return [];
    }
  }

  Future<CollegeModel> createCollege(CollegeModel college) async {
    try {
      final response = await _dio.post('/colleges', data: college.toMap());
      return CollegeModel.fromMap(response.data, response.data['_id']);
    } catch (e) {
      throw Exception('Error creating college: $e');
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
      print('Error fetching routes: $e');
      return [];
    }
  }

  Future<RouteModel> createRoute(RouteModel route) async {
    try {
      final response = await _dio.post('/routes', data: route.toMap());
      return RouteModel.fromMap(response.data, response.data['_id']);
    } catch (e) {
      throw Exception('Error creating route: $e');
    }
  }

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) async {
    try {
      await _dio.put('/routes/$routeId', data: data);
    } catch (e) {
      throw Exception('Error updating route: $e');
    }
  }

  Future<void> deleteRoute(String routeId) async {
    try {
      await _dio.delete('/routes/$routeId');
    } catch (e) {
      throw Exception('Error deleting route: $e');
    }
  }

  // Schedule Operations
  Future<List<ScheduleModel>> getSchedulesByRoute(String routeId) async {
    try {
      final response = await _dio.get('/schedules/route/$routeId');
      return (response.data as List)
          .map((data) => ScheduleModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      print('Error fetching schedules: $e');
      return [];
    }
  }

  Future<List<ScheduleModel>> getSchedulesByCollege(String collegeId) async {
    try {
      final response = await _dio.get('/schedules/college/$collegeId');
      return (response.data as List)
          .map((data) => ScheduleModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      print('Error fetching college schedules: $e');
      return [];
    }
  }

  Future<ScheduleModel> createSchedule(ScheduleModel schedule) async {
    try {
      final response = await _dio.post('/schedules', data: schedule.toMap());
      return ScheduleModel.fromMap(response.data, response.data['_id']);
    } catch (e) {
      throw Exception('Error creating schedule: $e');
    }
  }

  Future<void> updateSchedule(
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _dio.put('/schedules/$scheduleId', data: data);
    } catch (e) {
      throw Exception('Error updating schedule: $e');
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _dio.delete('/schedules/$scheduleId');
    } catch (e) {
      throw Exception('Error deleting schedule: $e');
    }
  }

  // Notification Operations
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await _dio.get('/notifications/user/$userId');
      return (response.data as List)
          .map((data) => NotificationModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _dio.post('/notifications', data: notification.toMap());
    } catch (e) {
      throw Exception('Error sending notification: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _dio.put('/notifications/$notificationId/read');
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // General Updates
  Future<UserModel> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/users/$userId', data: data);
      return UserModel.fromMap(response.data, userId);
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  Future<void> verifyEmail(String userId) async {
    try {
      await _dio.put('/users/$userId/verify-email');
    } catch (e) {
      print('Error verifying email via API: $e');
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

  Future<void> rejectUser(String userId, String approverId) async {
    await updateUser(userId, {
      'approved': false,
      'needsManualApproval': false,
      'approverId': approverId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Bus Number Operations
  Future<void> addBusNumber(String collegeId, String busNumber) async {
    try {
      await _dio.post(
        '/bus-numbers',
        data: {'collegeId': collegeId, 'busNumber': busNumber},
      );
    } catch (e) {
      throw Exception('Error adding bus number: $e');
    }
  }

  Future<List<String>> getBusNumbers(String collegeId) async {
    try {
      final response = await _dio.get('/bus-numbers/$collegeId');
      return (response.data as List).map((e) => e.toString()).toList();
    } catch (e) {
      print('Error fetching bus numbers: $e');
      return [];
    }
  }

  Future<void> removeBusNumber(String collegeId, String busNumber) async {
    try {
      await _dio.delete('/bus-numbers/$collegeId/$busNumber');
    } catch (e) {
      throw Exception('Error removing bus number: $e');
    }
  }
}
