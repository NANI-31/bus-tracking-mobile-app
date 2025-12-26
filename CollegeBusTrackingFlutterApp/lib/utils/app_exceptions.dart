class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({
    String message = 'Network error occurred. Please check your connection.',
    String? code,
  }) : super(message, code: code);
}

class AuthException extends AppException {
  AuthException({String message = 'Authentication failed.', String? code})
    : super(message, code: code);
}

class ServerException extends AppException {
  ServerException({
    String message = 'Server error occurred.',
    String? code,
    dynamic details,
  }) : super(message, code: code, details: details);
}

class ValidationException extends AppException {
  ValidationException({required String message, String? code})
    : super(message, code: code);
}
