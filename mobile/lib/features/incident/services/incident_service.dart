import 'dart:async';
import 'package:collegebus/features/incident/domain/incident_model.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/core/data/repositories.dart';
import 'package:flutter/material.dart';

class IncidentService extends ChangeNotifier {
  IncidentRepository _incidentRepo;
  String? _lastError;

  String? get lastError => _lastError;

  IncidentService(this._incidentRepo);

  void updateDependencies(IncidentRepository repo) {
    _incidentRepo = repo;
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
      final result = await _incidentRepo.sendSOS(
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
      await _incidentRepo.resolveSos(sosId);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<List<SosModel>> getActiveSos(String collegeId) async {
    try {
      final result = await _incidentRepo.getActiveSos(collegeId);
      clearError();
      return result.map((data) => SosModel.fromMap(data)).toList();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<void> createIncident(IncidentModel incident) async {
    try {
      await _incidentRepo.createIncident(incident);
      clearError();
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }
}
