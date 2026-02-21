import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CachedTileProvider implements TileProvider {
  final String urlPattern;
  final int tileSize;

  CachedTileProvider({
    this.urlPattern = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    this.tileSize = 256,
  });

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null) return TileProvider.noTile;

    final url = urlPattern
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString())
        .replaceAll('{z}', zoom.toString());

    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      final Uint8List bytes = await file.readAsBytes();
      return Tile(tileSize, tileSize, bytes);
    } catch (e) {
      return TileProvider.noTile;
    }
  }
}
