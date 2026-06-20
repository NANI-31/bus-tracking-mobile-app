import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/core/services/map_tile_cache_service.dart';
import 'dart:io';

class CommonMapView extends ConsumerStatefulWidget {
  final LatLng? currentLocation;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final String? mapStyle;
  final Function(GoogleMapController)? onMapCreated;
  final double initialZoom;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final VoidCallback? onCameraMoveStarted;
  final Function(CameraPosition)? onCameraMove;
  final VoidCallback? onCameraIdle;
  final bool useTileCache;
  final double bottomPadding;

  const CommonMapView({
    super.key,
    this.currentLocation,
    this.markers = const {},
    this.polylines = const {},
    this.mapStyle,
    this.onMapCreated,
    this.initialZoom = 25.0,
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = true,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.useTileCache = false,
    this.bottomPadding = 0.0,
  });

  @override
  ConsumerState<CommonMapView> createState() => _CommonMapViewState();
}

class _CommonMapViewState extends ConsumerState<CommonMapView> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    if (widget.currentLocation == null) {
      return const CircularProgressIndicator().centered();
    }

    final autoMapStyle = ref.watch(mapStyleProvider).value;

    final bool isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Text('Map View (Test Mode)')),
      );
    }

    return Stack(
      children: [
        RepaintBoundary(
          child: GoogleMap(
            onMapCreated: (controller) {
              _controller = controller;
              if (widget.onMapCreated != null) {
                widget.onMapCreated!(controller);
              }
            },
            initialCameraPosition: CameraPosition(
              target: widget.currentLocation!,
              zoom: widget.initialZoom,
            ),
            markers: widget.markers,
            polylines: widget.polylines,
            myLocationEnabled: widget.myLocationEnabled,
            myLocationButtonEnabled: false, // Disabling built-in button
            zoomControlsEnabled: false, // Disabling built-in zoom controls
            onCameraMoveStarted: widget.onCameraMoveStarted,
            onCameraMove: widget.onCameraMove,
            onCameraIdle: widget.onCameraIdle,
            mapType: MapType.normal,
            padding: EdgeInsets.only(bottom: widget.bottomPadding),
            style: widget.mapStyle ?? autoMapStyle,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            tileOverlays: widget.useTileCache
                ? {
                    TileOverlay(
                      tileOverlayId: const TileOverlayId('cached_tiles'),
                      tileProvider: CachedTileProvider(),
                    ),
                  }
                : {},
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ),
        ),

        // Custom My Location Button at Bottom Right
        if (widget.myLocationButtonEnabled)
          Positioned(
            bottom: 24 + widget.bottomPadding,
            right: 16,
            child: RepaintBoundary(
              child: FloatingActionButton.small(
                heroTag: 'my_location_btn',
                onPressed: () {
                  if (_controller != null && widget.currentLocation != null) {
                    _controller!.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        widget.currentLocation!,
                        widget.initialZoom,
                      ),
                    );
                  }
                },
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: Icon(
                  Icons.my_location_rounded,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
