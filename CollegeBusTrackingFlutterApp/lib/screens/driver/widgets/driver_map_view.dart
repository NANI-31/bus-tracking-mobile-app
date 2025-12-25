import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverMapView extends StatelessWidget {
  final LatLng? currentLocation;
  final String? mapStyle;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Function(GoogleMapController)? onMapCreated;

  const DriverMapView({
    super.key,
    required this.currentLocation,
    this.mapStyle,
    required this.markers,
    required this.polylines,
    this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return const CircularProgressIndicator().centered();
    }

    return GoogleMap(
      onMapCreated: onMapCreated,
      style: mapStyle,
      initialCameraPosition: CameraPosition(
        target: currentLocation!,
        zoom: 16.0,
      ),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
    );
  }
}
