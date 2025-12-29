import 'package:dio/dio.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/utils/app_exceptions.dart';
import 'package:collegebus/services/persistence_service.dart';

/// Base repository with shared Dio instance and error handling.
/// All domain repositories should extend this class.
abstract class BaseRepository {
  static Dio? _sharedDio;

  /// Get the shared Dio instance (singleton pattern)
  Dio get dio {
    _sharedDio ??= _createDio();
    return _sharedDio!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
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

    return dio;
  }

  /// Unified error handling - converts Dio errors to typed AppExceptions
  AppException handleError(dynamic e) {
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
}
