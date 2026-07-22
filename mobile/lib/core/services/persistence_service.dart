import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:collegebus/core/services/directions_result.dart';
import 'package:collegebus/core/services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static const String _keyUserId = 'user_id';
  static const String _keyIsSharingLocation = 'is_sharing_location';
  static const String _keySelectedBusId = 'selected_bus_id';
  static const String _keyBottomNavIndex = 'bottom_nav_index';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Cache tokens synchronously from secure storage during initialization
    _cachedToken = await SecureStorageService.getAuthToken();
    _cachedRefreshToken = await SecureStorageService.getRefreshToken();
  }

  // Auth (Migrated to SecureStorage with Synchronous Cache)
  static String? _cachedToken;
  static String? _cachedRefreshToken;

  static String? getAuthToken() => _cachedToken;

  static Future<void> setAuthToken(String token) async {
    _cachedToken = token;
    await SecureStorageService.setAuthToken(token);
  }

  static Future<void> removeAuthToken() async {
    _cachedToken = null;
    await SecureStorageService.clearAuthToken();
  }

  static String? getRefreshToken() => _cachedRefreshToken;

  static Future<void> setRefreshToken(String token) async {
    _cachedRefreshToken = token;
    await SecureStorageService.setRefreshToken(token);
  }

  static Future<void> removeRefreshToken() async {
    _cachedRefreshToken = null;
    await SecureStorageService.clearRefreshToken();
  }

  static String? getUserId() => _prefs?.getString(_keyUserId);
  static Future<void> setUserId(String userId) =>
      _prefs!.setString(_keyUserId, userId);
  static Future<void> removeUserId() => _prefs!.remove(_keyUserId);

  // Sharing State
  static bool getIsSharingLocation() =>
      _prefs?.getBool(_keyIsSharingLocation) ?? false;
  static Future<void> setIsSharingLocation(bool isSharing) =>
      _prefs!.setBool(_keyIsSharingLocation, isSharing);

  // Dashboard Preferences
  static String? getSelectedBusId([String? userId]) {
    final suffix = userId != null ? '_$userId' : '';
    return _prefs?.getString('$_keySelectedBusId$suffix');
  }

  static Future<void> setSelectedBusId(String busId, [String? userId]) {
    final suffix = userId != null ? '_$userId' : '';
    return _prefs!.setString('$_keySelectedBusId$suffix', busId);
  }

  static Future<void> removeSelectedBusId([String? userId]) {
    if (userId != null) {
      _prefs!.remove(_keySelectedBusId); // Also clear old global format
      return _prefs!.remove('${_keySelectedBusId}_$userId');
    }
    return _prefs!.remove(_keySelectedBusId);
  }

  static int getBottomNavIndex() => _prefs?.getInt(_keyBottomNavIndex) ?? 0;
  static Future<void> setBottomNavIndex(int index) =>
      _prefs!.setInt(_keyBottomNavIndex, index);

  // Generic key-value helpers for double/float types (lat, lng, zoom, sheet extent)
  static double? getDouble(String key) => _prefs?.getDouble(key);
  static Future<void> setDouble(String key, double value) =>
      _prefs!.setDouble(key, value);

  // Generic key for driver selections (bus_number, route_id)
  static String? getString(String key) => _prefs?.getString(key);
  static Future<void> setString(String key, String value) =>
      _prefs!.setString(key, value);
  static bool? getBool(String key) => _prefs?.getBool(key);
  static Future<void> setBool(String key, bool value) =>
      _prefs!.setBool(key, value);
  static Future<void> remove(String key) => _prefs!.remove(key);


  // Persistent Route Directions Cache (Offline Fallback)
  static const String _keyRouteDirectionsPrefix = 'route_directions_';

  static DirectionsResult? getRouteDirections(String key) {
    try {
      final jsonStr = _prefs?.getString('$_keyRouteDirectionsPrefix$key');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return DirectionsResult.fromMap(map);
      }
    } catch (e) {
      debugPrint('[PersistenceService] Error reading cached route directions: $e');
    }
    return null;
  }

  static Future<void> setRouteDirections(String key, DirectionsResult result) async {
    try {
      final jsonStr = jsonEncode(result.toMap());
      await _prefs?.setString('$_keyRouteDirectionsPrefix$key', jsonStr);
    } catch (e) {
      debugPrint('[PersistenceService] Error saving route directions: $e');
    }
  }

  static Future<void> clearRouteDirectionsCache() async {
    try {
      final keys = _prefs?.getKeys().where((k) => k.startsWith(_keyRouteDirectionsPrefix)).toList() ?? [];
      for (final k in keys) {
        await _prefs?.remove(k);
      }
    } catch (e) {
      debugPrint('[PersistenceService] Error clearing route directions cache: $e');
    }
  }
}

