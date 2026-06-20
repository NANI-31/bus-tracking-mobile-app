import 'package:flutter/foundation.dart';
import 'package:collegebus/core/data/base_repository.dart';
import 'package:collegebus/core/services/directions_result.dart';
import 'package:collegebus/features/route/domain/route_model.dart';

/// Service to fetch and compute route directions.
/// For display: calls the backend GET /routes/{id}/directions (cached).
class DirectionsService extends BaseRepository {
  static final DirectionsService _instance = DirectionsService._internal();
  factory DirectionsService() => _instance;
  DirectionsService._internal();

  /// In-memory session cache keyed by routeId.
  final Map<String, DirectionsResult> _cache = {};

  void clearCache() => _cache.clear();
  bool isCached(String routeId) => _cache.containsKey(routeId);
  DirectionsResult? getCached(String routeId) => _cache[routeId];

  // ── Display path (cached via backend) ─────────────────────────────────────

  /// Fetch directions for a [RouteModel] from our secure backend API.
  Future<DirectionsResult?> getDirectionsForRoute(RouteModel route) async {
    if (_cache.containsKey(route.id)) {
      debugPrint('[DirectionsService] Memory cache hit for route ${route.id}');
      return _cache[route.id];
    }

    try {
      debugPrint('[DirectionsService] Fetching from server for route ${route.id}');
      final response = await dio.get('/routes/${route.id}/directions');
      if (response.statusCode == 200 && response.data != null) {
        final result = DirectionsResult.fromMap(
            Map<String, dynamic>.from(response.data));
        _cache[route.id] = result;
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('[DirectionsService] Error fetching from server: $e');
      return null;
    }
  }
}
