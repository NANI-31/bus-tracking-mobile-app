import 'dart:async';
import 'package:dio/dio.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/utils/app_exceptions.dart';
import 'package:collegebus/core/services/persistence_service.dart';

/// Base repository with shared Dio instance and error handling.
/// All domain repositories should extend this class.
abstract class BaseRepository {
  static Dio? _sharedDio;

  /// Get the shared Dio instance (singleton pattern)
  Dio get dio {
    _sharedDio ??= _createDio();
    return _sharedDio!;
  }

  /// Global callback to handle 401 errors (e.g., force logout)
  static void Function()? onUnauthorized;

  /// Callback triggered when an access token is silently refreshed via HTTP 401 interceptor.
  static void Function(String newToken)? onTokenRefreshed;

  /// Mutex lock for concurrent HTTP 401 token refresh requests
  static Completer<String?>? _refreshCompleter;

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
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            final isLogoutRequest = e.requestOptions.path.contains(
              'auth/logout',
            );
            final isRefreshRequest = e.requestOptions.path.contains(
              'auth/refresh-token',
            );

            if (!isLogoutRequest && !isRefreshRequest) {
              // 1. Check if token was already refreshed by a concurrent request while this was in flight
              final currentToken = PersistenceService.getAuthToken();
              final requestAuthHeader =
                  e.requestOptions.headers['Authorization'];
              if (currentToken != null &&
                  requestAuthHeader != null &&
                  requestAuthHeader != 'Bearer $currentToken') {
                try {
                  final opts = e.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $currentToken';
                  final retryResponse = await dio.fetch(opts);
                  return handler.resolve(retryResponse);
                } on DioException catch (retryError) {
                  return handler.reject(retryError);
                } catch (retryError) {
                  return handler.reject(
                    DioException(
                      requestOptions: e.requestOptions,
                      error: retryError,
                    ),
                  );
                }
              }

              // 2. If a refresh is already in progress, wait for the shared Completer
              final inFlightCompleter = _refreshCompleter;
              if (inFlightCompleter != null) {
                try {
                  final newToken = await inFlightCompleter.future;
                  if (newToken != null) {
                    final opts = e.requestOptions;
                    opts.headers['Authorization'] = 'Bearer $newToken';
                    final retryResponse = await dio.fetch(opts);
                    return handler.resolve(retryResponse);
                  } else {
                    return handler.next(e);
                  }
                } on DioException catch (retryError) {
                  return handler.reject(retryError);
                } catch (retryError) {
                  return handler.next(e);
                }
              }

              // 3. First request: acquire lock and execute silent token refresh
              final refreshToken = PersistenceService.getRefreshToken();
              if (refreshToken != null && refreshToken.isNotEmpty) {
                final completer = Completer<String?>();
                _refreshCompleter = completer;

                try {
                  // Attempt to refresh token using a separate Dio instance to avoid interceptor loops
                  final refreshDio = Dio(
                    BaseOptions(
                      baseUrl: AppConstants.apiBaseUrl,
                      connectTimeout: const Duration(seconds: 15),
                      receiveTimeout: const Duration(seconds: 15),
                    ),
                  );
                  final response = await refreshDio.post(
                    '/auth/refresh-token',
                    data: {'refreshToken': refreshToken},
                  );

                  if (response.data != null &&
                      response.data['success'] == true) {
                    final newToken =
                        (response.data['accessToken'] ?? response.data['token'])
                            as String?;
                    if (newToken != null && newToken.isNotEmpty) {
                      await PersistenceService.setAuthToken(newToken);
                      onTokenRefreshed?.call(newToken);

                      // Unlock waiting requests immediately with the new token
                      completer.complete(newToken);

                      // Retry the original request with the new token
                      try {
                        final opts = e.requestOptions;
                        opts.headers['Authorization'] = 'Bearer $newToken';
                        final retryResponse = await dio.fetch(opts);
                        return handler.resolve(retryResponse);
                      } on DioException catch (retryError) {
                        return handler.reject(retryError);
                      } catch (retryError) {
                        return handler.reject(
                          DioException(
                            requestOptions: e.requestOptions,
                            error: retryError,
                          ),
                        );
                      }
                    }
                  }

                  // If server response didn't contain new token, fail refresh
                  completer.complete(null);
                  await PersistenceService.removeAuthToken();
                  await PersistenceService.removeRefreshToken();
                  onUnauthorized?.call();
                  return handler.next(e);
                } catch (refreshError) {
                  // If refresh fails, clear everything and force logout
                  completer.complete(null);
                  await PersistenceService.removeAuthToken();
                  await PersistenceService.removeRefreshToken();
                  onUnauthorized?.call();
                  return handler.next(e);
                } finally {
                  _refreshCompleter = null;
                }
              }
            }

            // Fallback for unauthorized without refresh capability
            if (!isLogoutRequest && PersistenceService.getAuthToken() != null) {
              onUnauthorized?.call();
            }
          }
          return handler.next(e);
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
