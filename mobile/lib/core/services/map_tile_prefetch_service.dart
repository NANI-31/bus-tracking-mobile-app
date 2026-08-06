import 'dart:math' as math;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/core/utils/app_logger.dart';

/// Pre-warms the Google Maps tile cache for an area around [center].
///
/// Fetches a grid of OSM-compatible tile URLs at the given [zoomLevel] so that
/// the map renders instantly on the next cold start or on weak networks.
///
/// Zoom level guidelines:
///   - 14 → neighbourhood (~1 km)
///   - 15 → streets (~500 m)   ← default
///   - 16 → blocks  (~250 m)
class MapTilePrefetchService {
  /// OSM tile URL template (same as the existing [CachedTileProvider]).
  static const _urlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Prefetches a [gridRadius]×[gridRadius] square of tiles around [center]
  /// at [zoomLevel]. Default grid is 3×3 (9 tiles) at zoom 15.
  ///
  /// Tiles are fetched via [DefaultCacheManager] so they are available to
  /// the [CachedTileProvider] used by [CommonMapView].
  static Future<void> prefetchArea(
    LatLng center, {
    int zoomLevel = 15,
    int gridRadius = 1,
  }) async {
    try {
      final tile = _latLngToTile(center.latitude, center.longitude, zoomLevel);
      final tileX = tile[0];
      final tileY = tile[1];

      final futures = <Future<void>>[];
      for (int dx = -gridRadius; dx <= gridRadius; dx++) {
        for (int dy = -gridRadius; dy <= gridRadius; dy++) {
          final x = tileX + dx;
          final y = tileY + dy;
          final url = _urlTemplate
              .replaceAll('{z}', zoomLevel.toString())
              .replaceAll('{x}', x.toString())
              .replaceAll('{y}', y.toString());
          futures.add(_fetchAndCache(url));
        }
      }

      await Future.wait(futures, eagerError: false);
      AppLogger.i(
        '[MapTilePrefetch] Prefetched ${futures.length} tiles '
        'around (${center.latitude.toStringAsFixed(4)}, '
        '${center.longitude.toStringAsFixed(4)}) at zoom $zoomLevel',
      );
    } catch (e) {
      // Non-fatal — failure just means the map fetches tiles on demand.
      AppLogger.w('[MapTilePrefetch] Prefetch failed: $e');
    }
  }

  static Future<void> _fetchAndCache(String url) async {
    try {
      await DefaultCacheManager().getSingleFile(url);
    } catch (_) {
      // Ignore individual tile failures.
    }
  }

  /// Converts WGS-84 [lat]/[lng] to OSM tile XY at [zoom].
  static List<int> _latLngToTile(double lat, double lng, int zoom) {
    final n = math.pow(2, zoom);
    final x = ((lng + 180.0) / 360.0 * n).floor();
    final latRad = lat * math.pi / 180.0;
    final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) /
                math.pi) /
            2.0 *
            n)
        .floor();
    return [x, y];
  }
}
