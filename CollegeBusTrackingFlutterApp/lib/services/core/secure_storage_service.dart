import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:collegebus/utils/app_logger.dart';

/// SecureStorageService - Provides encrypted storage for sensitive data.
/// Uses flutter_secure_storage for Android Keystore / iOS Keychain integration.
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys for driver-specific data
  static const String _keyDriverBusId = 'secure_driver_bus_id';
  static const String _keyDriverBusNumber = 'secure_driver_bus_number';
  static const String _keyDriverRouteId = 'secure_driver_route_id';
  static const String _keyAuthToken = 'secure_auth_token';

  // ============== Driver Data ==============

  /// Save driver's assigned bus ID (encrypted)
  static Future<void> setDriverBusId(String busId) async {
    try {
      await _storage.write(key: _keyDriverBusId, value: busId);
    } catch (e) {
      AppLogger.e('[SecureStorage] Failed to save bus ID: $e');
    }
  }

  /// Get driver's assigned bus ID
  static Future<String?> getDriverBusId() async {
    try {
      return await _storage.read(key: _keyDriverBusId);
    } catch (e) {
      AppLogger.e('[SecureStorage] Failed to read bus ID: $e');
      return null;
    }
  }

  /// Save driver's bus number (encrypted)
  static Future<void> setDriverBusNumber(String busNumber) async {
    try {
      await _storage.write(key: _keyDriverBusNumber, value: busNumber);
    } catch (e) {
      AppLogger.e('[SecureStorage] Failed to save bus number: $e');
    }
  }

  /// Get driver's bus number
  static Future<String?> getDriverBusNumber() async {
    try {
      return await _storage.read(key: _keyDriverBusNumber);
    } catch (e) {
      AppLogger.e('[SecureStorage] Failed to read bus number: $e');
      return null;
    }
  }

  /// Save driver's route ID (encrypted)
  static Future<void> setDriverRouteId(String routeId) async {
    try {
      await _storage.write(key: _keyDriverRouteId, value: routeId);
    } catch (e) {
      AppLogger.e('[SecureStorage] Failed to save route ID: $e');
    }
  }

  /// Get driver's route ID
  static Future<String?> getDriverRouteId() async {
    try {
      return await _storage.read(key: _keyDriverRouteId);
    } catch (e) {
      AppLogger.e('[SecureStorage] Failed to read route ID: $e');
      return null;
    }
  }

  /// Clear all driver data (on logout or assignment removal)
  static Future<void> clearDriverData() async {
    try {
      await _storage.delete(key: _keyDriverBusId);
      await _storage.delete(key: _keyDriverBusNumber);
      await _storage.delete(key: _keyDriverRouteId);
      AppLogger.i('[SecureStorage] Driver data cleared');
    } catch (e) {
      AppLogger.e('[SecureStorage] Failed to clear driver data: $e');
    }
  }

  // ============== Auth Token ==============

  /// Save auth token (encrypted)
  static Future<void> setAuthToken(String token) async {
    try {
      await _storage.write(key: _keyAuthToken, value: token);
    } catch (e) {
      AppLogger.e('[SecureStorage] Failed to save auth token: $e');
    }
  }

  /// Get auth token
  static Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _keyAuthToken);
    } catch (e) {
      AppLogger.e('[SecureStorage] Failed to read auth token: $e');
      return null;
    }
  }

  /// Clear auth token (on logout)
  static Future<void> clearAuthToken() async {
    try {
      await _storage.delete(key: _keyAuthToken);
      AppLogger.i('[SecureStorage] Auth token cleared');
    } catch (e) {
      AppLogger.e('[SecureStorage] Failed to clear auth token: $e');
    }
  }

  // ============== Clear All ==============

  /// Clear all secure storage data (complete reset)
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.i('[SecureStorage] All secure data cleared');
    } catch (e) {
      AppLogger.e('[SecureStorage] Failed to clear all data: $e');
    }
  }
}
