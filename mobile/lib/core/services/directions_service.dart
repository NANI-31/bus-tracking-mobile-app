import 'package:flutter/foundation.dart';
import 'package:collegebus/core/data/base_repository.dart';
import 'package:collegebus/core/services/directions_result.dart';
import 'package:collegebus/core/services/persistence_service.dart';
import 'package:collegebus/features/route/domain/route_model.dart';

/// Service to fetch and compute route directions.
/// For display: calls the backend GET /routes/{id}/directions (cached in memory & disk).
class DirectionsService extends BaseRepository {
  static final DirectionsService _instance = DirectionsService._internal();
  factory DirectionsService() => _instance;
  DirectionsService._internal();

  /// In-memory session cache keyed by route fingerprint (id + stop coordinates).
  final Map<String, DirectionsResult> _cache = {};

  void clearCache() {
    _cache.clear();
    PersistenceService.clearRouteDirectionsCache();
  }

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

  // ── Display path (cached via backend & disk storage fallback) ─────────────

  /// Fetch directions for a [RouteModel] from our secure backend API.
  /// Falls back to local device storage ([PersistenceService]) when offline.
  Future<DirectionsResult?> getDirectionsForRoute(RouteModel route) async {
    final key = _getCacheKey(route);

    // 1. Memory cache hit
    if (_cache.containsKey(key)) {
      debugPrint('[DirectionsService] Memory cache hit for route $key');
      return _cache[key];
    }

    // 2. Persistent disk cache hit (fast offline startup)
    final diskResult = PersistenceService.getRouteDirections(key);
    if (diskResult != null && diskResult.hasRoute) {
      debugPrint('[DirectionsService] Persistent disk cache hit for route $key');
      _cache[key] = diskResult;
    }

    try {
      debugPrint('[DirectionsService] Fetching from server for route ${route.id}');
      final response = await dio.get('/routes/${route.id}/directions');
      if (response.statusCode == 200 && response.data != null) {
        final result = DirectionsResult.fromMap(
            Map<String, dynamic>.from(response.data));
        _cache[key] = result;
        await PersistenceService.setRouteDirections(key, result);
        return result;
      }
    } catch (e) {
      debugPrint('[DirectionsService] Error fetching from server (offline fallback active): $e');
    }

    // Return disk cached result if offline / network error occurs
    return _cache[key] ?? diskResult;
  }
}

