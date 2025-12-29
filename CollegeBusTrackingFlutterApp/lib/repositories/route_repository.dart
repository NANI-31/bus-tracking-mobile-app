import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/repositories/base_repository.dart';

/// Repository for route operations
class RouteRepository extends BaseRepository {
  /// Get all routes for a college
  Future<List<RouteModel>> getRoutesByCollege(String collegeId) async {
    try {
      final response = await dio.get('/routes/college/$collegeId');
      return (response.data as List)
          .map((data) => RouteModel.fromMap(data, data['_id']))
          .toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Create a new route
  Future<RouteModel> createRoute(RouteModel route) async {
    try {
      final response = await dio.post('/routes', data: route.toMap());
      return RouteModel.fromMap(response.data, response.data['_id']);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Update route data
  Future<void> updateRoute(String routeId, Map<String, dynamic> data) async {
    try {
      await dio.put('/routes/$routeId', data: data);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Delete a route
  Future<void> deleteRoute(String routeId) async {
    try {
      await dio.delete('/routes/$routeId');
    } catch (e) {
      throw handleError(e);
    }
  }
}
