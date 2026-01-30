import 'dart:async';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/services/api/api_service.dart';
import 'package:collegebus/services/api/socket_service.dart';
import 'package:flutter/material.dart';

class CollegeService extends ChangeNotifier {
  ApiService _apiService;
  // SocketService might be needed if colleges list updates via socket (not implemented in DataService but good to have ref)

  String? _lastError;
  String? get lastError => _lastError;

  List<CollegeModel>? _cachedColleges;

  CollegeService(
    this._apiService,
  ); // SocketService removed as not used in DataService for College ops

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

  Future<CollegeModel?> getCollege(String collegeId) async {
    if (_cachedColleges != null) {
      try {
        return _cachedColleges!.firstWhere((c) => c.id == collegeId);
      } catch (_) {}
    }
    try {
      final colleges = await _apiService.getAllColleges();
      return colleges.firstWhere((c) => c.id == collegeId);
    } catch (e) {
      return null;
    }
  }

  Stream<List<CollegeModel>> getAllColleges({bool forceRefresh = false}) {
    if (!forceRefresh && _cachedColleges != null) {
      return Stream.value(_cachedColleges!);
    }
    return Stream.fromFuture(
      _apiService
          .getAllColleges()
          .then((colleges) {
            _cachedColleges = colleges;
            clearError();
            return colleges;
          })
          .catchError((e) {
            _setError(e);
            throw e;
          }),
    );
  }
}
