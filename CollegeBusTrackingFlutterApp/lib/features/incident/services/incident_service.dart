import 'dart:async';
import 'package:collegebus/features/incident/domain/incident_model.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/core/services/api_service.dart';
import 'package:flutter/material.dart';

class IncidentService extends ChangeNotifier {
  ApiService _apiService;
  String? _lastError;

  String? get lastError => _lastError;

  IncidentService(this._apiService);

  void updateDependencies(ApiService api) {
    _apiService = api;
  }

  void clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  void _setError(dynamic e) {
    _lastError = e.toString();
    notifyListeners();
  }

  Future<Map<String, dynamic>> sendSOS({
    required String? busId,
    required String? routeId,
    required double lat,
    required double lng,
  }) async {
    try {
      final result = await _apiService.sendSOS(
        busId: busId,
        routeId: routeId,
        lat: lat,
        lng: lng,
      );
      clearError();
      return result;
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> resolveSos(String sosId) async {
    try {
      await _apiService.resolveSos(sosId);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<List<SosModel>> getActiveSos(String collegeId) async {
    try {
      final result = await _apiService.getActiveSos(collegeId);
      clearError();
      return result.map((data) => SosModel.fromMap(data)).toList();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> createIncident(IncidentModel incident) async {
    try {
      await _apiService.createIncident(incident);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }
}





