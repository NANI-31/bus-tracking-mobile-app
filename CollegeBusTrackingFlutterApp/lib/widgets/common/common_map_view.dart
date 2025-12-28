import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class CommonMapView extends StatelessWidget {
  final LatLng? currentLocation;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final String? mapStyle;
  final Function(GoogleMapController)? onMapCreated;
  final double initialZoom;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;

  const CommonMapView({
    super.key,
    required this.currentLocation,
    required this.markers,
    required this.polylines,
    this.mapStyle,
    this.onMapCreated,
    this.initialZoom = 14.0,
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return const CircularProgressIndicator().centered();
    }

    return GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: CameraPosition(
        target: currentLocation!,
        zoom: initialZoom,
      ),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      mapType: MapType.normal,
      style: mapStyle,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }
}
