import 'package:flutter/foundation.dart';
import 'package:collegebus/core/data/base_repository.dart';
import 'package:collegebus/core/services/directions_result.dart';
import 'package:collegebus/features/route/domain/route_model.dart';

/// Service to fetch route directions. Calls the backend server which handles
/// fetching from Google and caching in MongoDB + Redis.
class DirectionsService extends BaseRepository {
  static final DirectionsService _instance = DirectionsService._internal();
  factory DirectionsService() => _instance;
  DirectionsService._internal();

  /// In-memory session cache keyed by routeId (to avoid even server network requests).
  final Map<String, DirectionsResult> _cache = {};

  /// Clear the cache (e.g., on logout or memory pressure).
  void clearCache() => _cache.clear();

  /// Check if a route is already cached.
  bool isCached(String routeId) => _cache.containsKey(routeId);

  /// Get cached result (returns null if not cached).
  DirectionsResult? getCached(String routeId) => _cache[routeId];

  /// Fetch directions for a [RouteModel] from our secure backend API.
  Future<DirectionsResult?> getDirectionsForRoute(RouteModel route) async {
    // 1. Check in-memory session cache
    if (_cache.containsKey(route.id)) {
      debugPrint('[DirectionsService] Memory cache hit for route ${route.id}');
      return _cache[route.id];
    }

    // 2. Fetch from backend route directions endpoint
    try {
      debugPrint('[DirectionsService] Fetching directions from server for route ${route.id}');
      
      final response = await dio.get('/routes/${route.id}/directions');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = Map<String, dynamic>.from(response.data);
        final result = DirectionsResult.fromMap(data);
        
        // Save in session cache
        _cache[route.id] = result;
        return result;
      }
      
      debugPrint('[DirectionsService] Server returned non-200 or empty data');
      return null;
    } catch (e) {
      debugPrint('[DirectionsService] Error fetching directions from server: $e');
      return null;
    }
  }
}
