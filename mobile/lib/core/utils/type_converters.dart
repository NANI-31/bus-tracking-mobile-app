import 'package:flutter/material.dart';

bool parseBool(dynamic value, [bool defaultValue = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return defaultValue;
}

DateTime parseDateTime(dynamic value, [DateTime? defaultValue]) {
  if (value == null) return defaultValue ?? DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? defaultValue ?? DateTime.now();
  }
  return defaultValue ?? DateTime.now();
}

Color parseHexColor(dynamic value, [Color defaultColor = const Color(0xFF0097B2)]) {
  if (value == null) return defaultColor;
  if (value is Color) return value;
  if (value is! String) return defaultColor;
  final clean = value.replaceAll('#', '').trim();
  if (clean.isEmpty) return defaultColor;
  try {
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    } else if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    } else if (clean.length == 3) {
      final r = clean[0];
      final g = clean[1];
      final b = clean[2];
      return Color(int.parse('FF$r$r$g$g$b$b', radix: 16));
    }
  } catch (_) {
    return defaultColor;
  }
  return defaultColor;
}
