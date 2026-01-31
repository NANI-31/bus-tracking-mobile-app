import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/services/api_service.dart';

/// Provider for ApiService - singleton instance
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
