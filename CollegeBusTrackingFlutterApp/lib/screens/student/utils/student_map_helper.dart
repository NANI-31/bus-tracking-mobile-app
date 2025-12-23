import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';

class StudentMapHelper {
  static LatLng getMockCoordinateForLocation(
    String location,
    LatLng? currentLocation,
  ) {
    final mockCoords = {
      'Central Station': const LatLng(12.9716, 77.5946),
      'City Center': const LatLng(12.9726, 77.5956),
      'Shopping Mall': const LatLng(12.9736, 77.5966),
      'Hospital': const LatLng(12.9746, 77.5976),
      'University Campus': const LatLng(12.9756, 77.5986),
      'Airport': const LatLng(12.9766, 77.5996),
      'Hotel District': const LatLng(12.9776, 77.6006),
      'Business Park': const LatLng(12.9786, 77.6016),
      'Suburban Area': const LatLng(12.9796, 77.6026),
      'Residential Area': const LatLng(12.9806, 77.6036),
      'Park': const LatLng(12.9816, 77.6046),
    };

    return mockCoords[location] ??
        currentLocation ??
        const LatLng(12.9716, 77.5946);
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
        getMockCoordinateForLocation(route.startPoint, currentLocation);

    return Marker(
      markerId: MarkerId('bus_${bus.id}'),
      position: position,
      infoWindow: InfoWindow(
        title:
            'Bus ${bus.busNumber} ${location != null ? "(Live)" : "(Not Live)"}',
        snippet:
            '${route.startPoint} → ${route.endPoint}\n${location != null ? 'Last updated: ${location.timestamp.toString().substring(11, 16)}' : 'Status: Offline'}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        isSelected
            ? BitmapDescriptor.hueRed
            : location != null
            ? BitmapDescriptor.hueGreen
            : BitmapDescriptor.hueOrange,
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
    final startCoord = getMockCoordinateForLocation(
      route.startPoint,
      currentLocation,
    );
    routePoints.add(startCoord);

    for (final stop in route.stopPoints) {
      routePoints.add(getMockCoordinateForLocation(stop, currentLocation));
    }

    final endCoord = getMockCoordinateForLocation(
      route.endPoint,
      currentLocation,
    );
    routePoints.add(endCoord);

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
    final startCoord = getMockCoordinateForLocation(
      route.startPoint,
      currentLocation,
    );
    routePoints.add(startCoord);

    for (final stop in route.stopPoints) {
      routePoints.add(getMockCoordinateForLocation(stop, currentLocation));
    }

    final endCoord = getMockCoordinateForLocation(
      route.endPoint,
      currentLocation,
    );
    routePoints.add(endCoord);

    final markers = <Marker>[];

    for (int i = 0; i < routePoints.length; i++) {
      final stopName = i == 0
          ? route.startPoint
          : i == routePoints.length - 1
          ? route.endPoint
          : route.stopPoints[i - 1];

      markers.add(
        Marker(
          markerId: MarkerId('stop_${bus.id}_$i'),
          position: routePoints[i],
          infoWindow: InfoWindow(
            title: stopName,
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
