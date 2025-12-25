import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';

class StudentMapHelper {
  // Helper to get LatLng from RoutePoint with fallback for legacy data
  static LatLng _getPointLocation(RoutePoint point, LatLng? currentLocation) {
    if (point.lat != 0.0 && point.lng != 0.0) {
      return LatLng(point.lat, point.lng);
    }
    // Fallback if coordinates are missing (should not happen in prod with new data)
    return currentLocation ?? const LatLng(12.9716, 77.5946);
  }

  static Marker createBusMarker({
    required BusModel bus,
    required RouteModel route,
    required BusLocationModel? location,
    required LatLng? currentLocation,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final position =
        location?.currentLocation ??
        _getPointLocation(route.startPoint, currentLocation);

    return Marker(
      markerId: MarkerId('bus_${bus.id}'),
      position: position,
      infoWindow: InfoWindow(
        title:
            'Bus ${bus.busNumber} ${location != null ? "(Live)" : "(Not Live)"}',
        snippet:
            '${route.startPoint.name} → ${route.endPoint.name}\n${location != null ? 'Last updated: ${location.timestamp.toString().substring(11, 16)}' : 'Status: Offline'}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        isSelected
            ? BitmapDescriptor.hueRed
            : location != null
            ? BitmapDescriptor.hueGreen
            : BitmapDescriptor.hueRed,
      ),
      onTap: onTap,
    );
  }

  static Polyline createRoutePolyline({
    required BusModel bus,
    required RouteModel route,
    required LatLng? currentLocation,
  }) {
    final routePoints = <LatLng>[];

    routePoints.add(_getPointLocation(route.startPoint, currentLocation));

    for (final stop in route.stopPoints) {
      routePoints.add(_getPointLocation(stop, currentLocation));
    }

    routePoints.add(_getPointLocation(route.endPoint, currentLocation));

    return Polyline(
      polylineId: PolylineId('route_${bus.id}'),
      points: routePoints,
      color: Colors.blue,
      width: 4,
    );
  }

  static List<Marker> createStopMarkers({
    required BusModel bus,
    required RouteModel route,
    required LatLng? currentLocation,
  }) {
    final routePoints = <LatLng>[];
    final stopNames = <String>[];

    routePoints.add(_getPointLocation(route.startPoint, currentLocation));
    stopNames.add(route.startPoint.name);

    for (final stop in route.stopPoints) {
      routePoints.add(_getPointLocation(stop, currentLocation));
      stopNames.add(stop.name);
    }

    routePoints.add(_getPointLocation(route.endPoint, currentLocation));
    stopNames.add(route.endPoint.name);

    final markers = <Marker>[];

    for (int i = 0; i < routePoints.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('stop_${bus.id}_$i'),
          position: routePoints[i],
          infoWindow: InfoWindow(
            title: stopNames[i],
            snippet: i == 0
                ? 'Start Point'
                : i == routePoints.length - 1
                ? 'End Point'
                : 'Stop',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0
                ? BitmapDescriptor.hueGreen
                : i == routePoints.length - 1
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueYellow,
          ),
        ),
      );
    }
    return markers;
  }
}
