// map_marker_cache.dart
//
// In-memory LRU cache for custom map marker BitmapDescriptors.
// Eliminates redundant canvas-draw + image-decode calls during active
// tracking sessions when GPS location bursts arrive at high frequency.
//
// Usage:
//   final icon = await MapMarkerCache.getStartMarker(color: startColor);
//
// The cache is keyed on (markerType, color.toARGB32()). When the same
// color is requested again the cached descriptor is returned immediately
// with zero async overhead. When the number of unique entries exceeds
// [_maxEntries] the oldest entry is evicted (FIFO within the LinkedHashMap).

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/core/utils/map_marker_helper.dart';

class MapMarkerCache {
  MapMarkerCache._(); // prevent instantiation

  /// Maximum number of distinct (type, color) entries kept in memory.
  /// 24 entries cover all stop-type × theme-color combinations with headroom.
  static const int _maxEntries = 24;

  /// Insertion-ordered map so oldest entries can be evicted efficiently.
  static final _cache = <String, BitmapDescriptor>{};

  // ─── Public API ──────────────────────────────────────────────────────────

  static Future<BitmapDescriptor> getStartMarker({
    required Color color,
  }) => _get('start', color, () => MapMarkerHelper.getStartMarker(color: color));

  static Future<BitmapDescriptor> getStopMarker({
    required Color color,
  }) => _get('stop', color, () => MapMarkerHelper.getStopMarker(color: color));

  static Future<BitmapDescriptor> getEndMarker({
    required Color color,
  }) => _get('end', color, () => MapMarkerHelper.getEndMarker(color: color));

  static Future<BitmapDescriptor> getBusMarker() =>
      _getByKey('bus', MapMarkerHelper.createBusMarker);

  /// Remove all cached descriptors (call on theme change or low-memory).
  static void clear() => _cache.clear();

  // ─── Internal helpers ─────────────────────────────────────────────────────

  static Future<BitmapDescriptor> _get(
    String type,
    Color color,
    Future<BitmapDescriptor> Function() factory,
  ) {
    final key = _colorKey(type, color);
    return _getByKey(key, factory);
  }

  static Future<BitmapDescriptor> _getByKey(
    String key,
    Future<BitmapDescriptor> Function() factory,
  ) async {
    final cached = _cache[key];
    if (cached != null) return cached;

    final descriptor = await factory();
    _insert(key, descriptor);
    return descriptor;
  }

  static void _insert(String key, BitmapDescriptor descriptor) {
    if (_cache.length >= _maxEntries) {
      // Evict the oldest insertion (first key in LinkedHashMap iteration order)
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = descriptor;
  }

  static String _colorKey(String type, Color color) =>
      '$type#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
}
