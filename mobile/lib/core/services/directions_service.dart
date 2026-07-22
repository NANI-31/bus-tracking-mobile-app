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

  /// In-memory session cache keyed by route fingerprint (id + stop coordinates).
  final Map<String, DirectionsResult> _cache = {};

  void clearCache() => _cache.clear();

  String _getCacheKey(RouteModel route) {
    final buffer = StringBuffer(route.id);
    buffer.write('|${route.startPoint.lat},${route.startPoint.lng}');
    for (final s in route.stopPoints) {
      buffer.write('|${s.lat},${s.lng}');
    }
    buffer.write('|${route.endPoint.lat},${route.endPoint.lng}');
    return buffer.toString();
  }

  bool isCached(String routeId) => _cache.keys.any((k) => k.startsWith(routeId));
  DirectionsResult? getCached(String routeId) {
    for (final entry in _cache.entries) {
      if (entry.key.startsWith(routeId)) return entry.value;
    }
    return null;
  }

  // ── Display path (cached via backend) ─────────────────────────────────────

  /// Fetch directions for a [RouteModel] from our secure backend API.
  Future<DirectionsResult?> getDirectionsForRoute(RouteModel route) async {
    final key = _getCacheKey(route);
    if (_cache.containsKey(key)) {
      debugPrint('[DirectionsService] Memory cache hit for route $key');
      return _cache[key];
    }

    try {
      debugPrint('[DirectionsService] Fetching from server for route ${route.id}');
      final response = await dio.get('/routes/${route.id}/directions');
      if (response.statusCode == 200 && response.data != null) {
        final result = DirectionsResult.fromMap(
            Map<String, dynamic>.from(response.data));
        _cache[key] = result;
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('[DirectionsService] Error fetching from server: $e');
      return null;
    }
  }

}
