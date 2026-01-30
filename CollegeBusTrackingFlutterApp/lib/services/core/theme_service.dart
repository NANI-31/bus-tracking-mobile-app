import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';
  static const String _navKey = 'use_bottom_nav';
  bool _isDarkMode = false;
  bool _useBottomNavigation = false;

  bool get isDarkMode => _isDarkMode;
  bool get useBottomNavigation => _useBottomNavigation;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _useBottomNavigation = prefs.getBool(_navKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
    notifyListeners();
  }

  Future<void> toggleNavigationMode(bool useBottom) async {
    _useBottomNavigation = useBottom;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_navKey, useBottom);
    notifyListeners();
  }
}
