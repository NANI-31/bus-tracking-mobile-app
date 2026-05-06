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
  static String? getSelectedBusId() => _prefs?.getString(_keySelectedBusId);
  static Future<void> setSelectedBusId(String busId) =>
      _prefs!.setString(_keySelectedBusId, busId);
  static Future<void> removeSelectedBusId() =>
      _prefs!.remove(_keySelectedBusId);

  static int getBottomNavIndex() => _prefs?.getInt(_keyBottomNavIndex) ?? 0;
  static Future<void> setBottomNavIndex(int index) =>
      _prefs!.setInt(_keyBottomNavIndex, index);

  // Generic key for driver selections (bus_number, route_id)
  static String? getString(String key) => _prefs?.getString(key);
  static Future<void> setString(String key, String value) =>
      _prefs!.setString(key, value);
  static Future<void> remove(String key) => _prefs!.remove(key);
}
