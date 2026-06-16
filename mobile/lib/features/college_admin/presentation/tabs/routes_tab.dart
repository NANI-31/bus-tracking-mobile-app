import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/utils/app_logger.dart';

Color _parseHexColor(String hex) {
  try {
    final hexVal = hex.replaceAll('#', '').trim();
    if (hexVal.length == 6) {
      return Color(int.parse('FF$hexVal', radix: 16));
    } else if (hexVal.length == 8) {
      return Color(int.parse(hexVal, radix: 16));
    }
  } catch (_) {}
  return const Color(0xFF0097B2);
}

String _colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  var p = 0.017453292519943295;
  var c = math.cos;
  var a = 0.5 - c((lat2 - lat1) * p)/2 + 
        c(lat1 * p) * c(lat2 * p) * 
        (1 - c((lon2 - lon1) * p))/2;
  return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
}

class RoutesTab extends ConsumerStatefulWidget {
  const RoutesTab({super.key});

  @override
  ConsumerState<RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends ConsumerState<RoutesTab> {
  String _searchQuery = '';
  RouteModel? _selectedRoute;
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  bool _showStats = false;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<BitmapDescriptor> _createMarkerIcon(String text, Color bgColor, {double size = 70}) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    final paint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 3, paint);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 3, borderPaint);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
    
    final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _getMarkerIcon(String text, Color bgColor) async {
    final key = '${text}_${bgColor.toARGB32()}';
    if (_markerIconCache.containsKey(key)) {
      return _markerIconCache[key]!;
    }
    final icon = await _createMarkerIcon(text, bgColor);
    _markerIconCache[key] = icon;
    return icon;
  }

  Future<Set<Marker>> _buildMarkers(RouteModel route) async {
    final Set<Marker> markers = {};
    if (route.stopPoints.isEmpty) return markers;

    final Color routeColor = _parseHexColor(route.color);

    // Start Marker
    final startIcon = await _getMarkerIcon('S', const Color(0xFF10B981));
    markers.add(Marker(
      markerId: MarkerId('start-${route.id}'),
      position: LatLng(route.startPoint.lat, route.startPoint.lng),
      icon: startIcon,
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(
        title: 'Start: ${route.startPoint.name}',
      ),
    ));

    // Intermediate Markers
    for (int i = 1; i < route.stopPoints.length - 1; i++) {
      final stop = route.stopPoints[i];
      final stopIcon = await _getMarkerIcon('$i', routeColor);
      markers.add(Marker(
        markerId: MarkerId('stop-${route.id}-$i'),
        position: LatLng(stop.lat, stop.lng),
        icon: stopIcon,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: 'Stop #$i: ${stop.name}',
        ),
      ));
    }

    // End Marker
    if (route.stopPoints.length > 1) {
      final endIcon = await _getMarkerIcon('E', const Color(0xFFEF4444));
      markers.add(Marker(
        markerId: MarkerId('end-${route.id}'),
        position: LatLng(route.endPoint.lat, route.endPoint.lng),
        icon: endIcon,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: 'Terminus: ${route.endPoint.name}',
        ),
      ));
    }

    return markers;
  }

  void _zoomToFitRoute(RouteModel route) {
    if (_mapController == null || route.stopPoints.isEmpty) return;

    double minLat = route.stopPoints.first.lat;
    double maxLat = route.stopPoints.first.lat;
    double minLng = route.stopPoints.first.lng;
    double maxLng = route.stopPoints.first.lng;

    for (var stop in route.stopPoints) {
      if (stop.lat < minLat) minLat = stop.lat;
      if (stop.lat > maxLat) maxLat = stop.lat;
      if (stop.lng < minLng) minLng = stop.lng;
      if (stop.lng > maxLng) maxLng = stop.lng;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0,
      ),
    );
  }

  List<Map<String, dynamic>> _computeElevationData(List<RoutePoint> stops) {
    return List.generate(stops.length, (index) {
      final stop = stops[index];
      final latFactor = math.sin((stop.lat * 15).abs()) * 120;
      final lngFactor = math.cos((stop.lng * 15).abs()) * 90;
      final mockElevation = (45 + latFactor + lngFactor + (index * 7) % 20).roundToDouble();
      
      double distanceKm = 0.0;
      double slopePercentage = 0.0;
      double slopeAngle = 0.0;
      double elevationChange = 0.0;
      
      if (index > 0) {
        final prev = stops[index - 1];
        distanceKm = _calculateDistance(prev.lat, prev.lng, stop.lat, stop.lng);
        final prevLatFactor = math.sin((prev.lat * 15).abs()) * 120;
        final prevLngFactor = math.cos((prev.lng * 15).abs()) * 90;
        final prevElevation = (45 + prevLatFactor + prevLngFactor + ((index - 1) * 7) % 20).roundToDouble();
        
        elevationChange = mockElevation - prevElevation;
        final distanceMeters = distanceKm * 1000;
        if (distanceMeters > 0) {
          slopePercentage = (elevationChange / distanceMeters) * 100;
          slopeAngle = math.atan(elevationChange / distanceMeters) * (180 / math.pi);
        }
      }
      
      return {
        'index': index,
        'name': stop.name,
        'elevation': mockElevation,
        'distanceKm': distanceKm,
        'elevationChange': elevationChange,
        'slopePercentage': slopePercentage,
        'slopeAngle': slopeAngle,
      };
    });
  }

  void _openRouteFormDialog({RouteModel? route}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RouteFormDialog(route: route),
    );
  }

  void _confirmDeleteRoute(RouteModel route) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${route.routeName}'),
        content: const Text(
          'Are you sure you want to delete this route? This action cannot be undone and will affect associated schedules.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(routeMutatorProvider.notifier).deleteRoute(route.id);
                final authUser = ref.read(currentUserProvider);
                if (authUser != null) {
                  ref.invalidate(collegeRoutesProvider(authUser.collegeId));
                }
                setState(() {
                  if (_selectedRoute?.id == route.id) {
                    _selectedRoute = null;
                  }
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Route deleted successfully.')),
                  );
                }
              } catch (e) {
                AppLogger.e('Failed to delete route: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete route: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.turkishBlue : AppColors.deepTeal;

    final authUser = ref.watch(currentUserProvider);
    final collegeId = authUser?.collegeId ?? '';

    final routesAsync = ref.watch(collegeRoutesProvider(collegeId));

    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading routes: $err')),
      data: (routes) {
        // Apply search filter
        final filteredRoutes = routes.where((route) {
          final matchesName = route.routeName.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesStops = route.stopPoints.any(
            (stop) => stop.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          );
          return matchesName || matchesStops;
        }).toList();

        // Calculate statistics
        final totalRoutes = routes.length;
        final totalStops = routes.fold<int>(0, (sum, r) => sum + r.stopPoints.length);
        final avgStops = totalRoutes > 0 ? (totalStops / totalRoutes).toStringAsFixed(1) : '0';

        // Auto select first route if none selected
        if (_selectedRoute == null && filteredRoutes.isNotEmpty) {
          _selectedRoute = filteredRoutes.first;
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isWide = screenWidth > 900;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Header block
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Control Center: Routes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Configure transit lines, pathways, and stop points.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openRouteFormDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Route', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar & Stats toggle
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search transit line or stop...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: primaryColor,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          isDense: true,
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                              : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showStats = !_showStats;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: _showStats
                              ? (isDark
                                  ? primaryColor.withValues(alpha: 0.15)
                                  : primaryColor.withValues(alpha: 0.08))
                              : (isDark
                                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _showStats
                                ? (isDark
                                    ? primaryColor.withValues(alpha: 0.4)
                                    : primaryColor.withValues(alpha: 0.2))
                                : (isDark ? Colors.white10 : Colors.grey.shade200),
                          ),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: _showStats
                              ? primaryColor
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: isWide ? 2.5 : 1.0,
                        children: [
                          _buildStatCard(
                            'TOTAL LINES',
                            totalRoutes.toString(),
                            Icons.route_outlined,
                            primaryColor.withValues(alpha: 0.12),
                            primaryColor,
                            isDark,
                          ),
                          _buildStatCard(
                            'CONFIG STATIONS',
                            totalStops.toString(),
                            Icons.place_outlined,
                            const Color(0xFF10B981).withValues(alpha: 0.12),
                            const Color(0xFF10B981),
                            isDark,
                          ),
                          _buildStatCard(
                            'AVG STOPS / LINE',
                            avgStops,
                            Icons.show_chart_rounded,
                            const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                            const Color(0xFF8B5CF6),
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                  crossFadeState: _showStats ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
                const SizedBox(height: 16),

                // Dual-Pane or Single-Pane Content
                Expanded(
                  child: filteredRoutes.isEmpty
                      ? _buildEmptyState(isDark)
                      : isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Pane: Routes list
                                Expanded(
                                  flex: 2,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: filteredRoutes.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, idx) {
                                      final route = filteredRoutes[idx];
                                      return _buildRouteCard(route, isDark, primaryColor, true);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Right Pane: Map preview + Elevation chart
                                Expanded(
                                  flex: 3,
                                  child: _selectedRoute != null
                                      ? _buildRouteVisualsPane(_selectedRoute!, isDark, primaryColor)
                                      : const SizedBox(),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: filteredRoutes.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, idx) {
                                final route = filteredRoutes[idx];
                                return _buildRouteCard(route, isDark, primaryColor, false);
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgOpacityColor,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgOpacityColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(RouteModel route, bool isDark, Color primaryColor, bool isWide) {
    final routeColor = _parseHexColor(route.color);
    final isSelected = _selectedRoute?.id == route.id;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? routeColor
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRoute = route;
          });
          if (!isWide) {
            // Mobile: Tap to open visual detail overlay
            _showMobileVisualsOverlay(route, isDark, primaryColor);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: routeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            route.routeName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _openRouteFormDialog(route: route),
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _confirmDeleteRoute(route),
                        icon: Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.white54 : Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Start: ${route.startPoint.name}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.flag_outlined, size: 14, color: isDark ? Colors.white54 : Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Terminus: ${route.endPoint.name}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${route.stopPoints.length} configured stops',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: routeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      route.routeType.toUpperCase(),
                      style: TextStyle(
                        color: routeColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMobileVisualsOverlay(RouteModel route, bool isDark, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.gunmetal : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Pull Handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.routeName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${route.stopPoints.length} Stops • ${route.routeType.toUpperCase()}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 600,
                          child: _buildRouteVisualsPane(route, isDark, primaryColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRouteVisualsPane(RouteModel route, bool isDark, Color primaryColor) {
    final routeColor = _parseHexColor(route.color);
    final points = route.stopPoints.map((s) => LatLng(s.lat, s.lng)).toList();
    final elevationData = _computeElevationData(route.stopPoints);

    // Calculate total distance
    double totalDistance = 0.0;
    for (int i = 1; i < points.length; i++) {
      totalDistance += _calculateDistance(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: routeColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Map Panel
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  FutureBuilder<Set<Marker>>(
                    future: _buildMarkers(route),
                    builder: (context, snapshot) {
                      return GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: points.isNotEmpty ? points.first : const LatLng(20.5937, 78.9629),
                          zoom: 12.0,
                        ),
                        markers: snapshot.data ?? {},
                        polylines: {
                          Polyline(
                            polylineId: PolylineId('route-path-${route.id}'),
                            points: points,
                            color: routeColor,
                            width: 5,
                            geodesic: true,
                          ),
                        },
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          if (points.isNotEmpty) {
                            // Delay slightly to allow map construction
                            Future.delayed(const Duration(milliseconds: 300), () {
                              _zoomToFitRoute(route);
                            });
                          }
                        },
                      );
                    },
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Live Pathway Preview',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          Text(
                            '${totalDistance.toStringAsFixed(1)} km transit',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: routeColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Elevation Profile Chart Panel
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.terrain_rounded, size: 16, color: Colors.grey),
                            SizedBox(width: 6),
                            Text(
                              'Elevation Profile (Spatial Depth)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),
                        if (elevationData.isNotEmpty)
                          Text(
                            'Min: ${elevationData.map((d) => d['elevation'] as double).reduce(math.min).toStringAsFixed(0)}m | Max: ${elevationData.map((d) => d['elevation'] as double).reduce(math.max).toStringAsFixed(0)}m',
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) => isDark ? const Color(0xFF1E293B) : Colors.white,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final data = elevationData[spot.x.toInt()];
                                  final isClimb = data['elevationChange'] > 0;
                                  final name = data['name'];
                                  final elevation = data['elevation'];
                                  final slopeAngle = data['slopeAngle'].toStringAsFixed(1);
                                  final elevationChange = data['elevationChange'].abs().toStringAsFixed(0);
                                  
                                  String changeText = "";
                                  if (data['elevationChange'] != 0) {
                                    changeText = isClimb ? "\n▲ Climb: ${elevationChange}m ($slopeAngle°)" : "\n▼ Descent: ${elevationChange}m ($slopeAngle°)";
                                  } else {
                                    changeText = "\nStart Station";
                                  }
                                  
                                  return LineTooltipItem(
                                    "$name\nAlt: ${elevation.toStringAsFixed(0)}m$changeText",
                                    TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(elevationData.length, (idx) {
                                return FlSpot(idx.toDouble(), elevationData[idx]['elevation']);
                              }),
                              isCurved: true,
                              barWidth: 3,
                              color: routeColor,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                  radius: 4,
                                  color: routeColor,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: routeColor.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 32),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.route_outlined,
              size: 64,
              color: isDark ? Colors.white10 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Transit Lines Matched',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adjust your search filter or add a new transit line.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Filter', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteFormDialog extends ConsumerStatefulWidget {
  final RouteModel? route;
  const _RouteFormDialog({this.route});

  @override
  ConsumerState<_RouteFormDialog> createState() => _RouteFormDialogState();
}

class _RouteFormDialogState extends ConsumerState<_RouteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _routeType = 'pickup';
  Color _selectedColor = AppColors.turkishBlue;
  bool _isSaving = false;

  final List<RoutePoint> _stops = [];

  final List<Color> _colorOptions = [
    AppColors.turkishBlue,
    AppColors.deepTeal,
    const Color(0xFF10B981), // Green
    const Color(0xFFEF4444), // Red
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFFFC107), // Yellow
    const Color(0xFFEC4899), // Pink
  ];

  @override
  void initState() {
    super.initState();
    if (widget.route != null) {
      _nameController.text = widget.route!.routeName;
      _routeType = widget.route!.routeType;
      _selectedColor = _parseHexColor(widget.route!.color);
      _stops.addAll(widget.route!.stopPoints);
    } else {
      // Add two default stops to get started
      _stops.add(RoutePoint(name: 'Start Location', lat: 20.5937, lng: 78.9629));
      _stops.add(RoutePoint(name: 'Terminus Location', lat: 20.6200, lng: 78.9900));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addStopField() {
    setState(() {
      final lastStop = _stops.last;
      _stops.add(RoutePoint(
        name: 'New Stop #${_stops.length + 1}',
        lat: lastStop.lat + 0.005,
        lng: lastStop.lng + 0.005,
      ));
    });
  }

  void _removeStopField(int index) {
    if (_stops.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A route requires at least 2 stops.')),
      );
      return;
    }
    setState(() {
      _stops.removeAt(index);
    });
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_stops.length < 2) return;

    setState(() {
      _isSaving = true;
    });

    final authUser = ref.read(currentUserProvider);
    final collegeId = authUser?.collegeId ?? '';
    final userId = authUser?.id ?? '';

    final routeData = RouteModel(
      id: widget.route?.id ?? '',
      routeName: _nameController.text,
      routeType: _routeType,
      startPoint: _stops.first,
      endPoint: _stops.last,
      stopPoints: _stops,
      collegeId: collegeId,
      createdBy: widget.route?.createdBy ?? userId,
      createdAt: widget.route?.createdAt ?? DateTime.now(),
      color: _colorToHex(_selectedColor),
    );

    try {
      if (widget.route != null) {
        // Edit Mode
        await ref.read(routeMutatorProvider.notifier).updateRoute(
          widget.route!.id,
          routeData.toMap(),
        );
      } else {
        // Create Mode
        await ref.read(routeMutatorProvider.notifier).createRoute(routeData);
      }
      
      ref.invalidate(collegeRoutesProvider(collegeId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route saved successfully.')),
        );
      }
    } catch (e) {
      AppLogger.e('Error saving route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.route != null ? 'Edit Route' : 'Add Route';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route Name
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Route Name',
                          hintText: 'e.g. Route A, Campus Express',
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a route name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Route Type
                      const Text(
                        'Route Type',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      RadioGroup<String>(
                        groupValue: _routeType,
                        onChanged: (val) {
                          if (val != null) setState(() => _routeType = val);
                        },
                        child: Row(
                          children: const [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Pickup', style: TextStyle(fontSize: 13)),
                                value: 'pickup',
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Drop', style: TextStyle(fontSize: 13)),
                                value: 'drop',
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Color Palette selection
                      const Text(
                        'Route Palette Highlight Color',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _colorOptions.map((color) {
                            final isSel = _selectedColor.toARGB32() == color.toARGB32();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: const SizedBox.shrink(),
                                labelPadding: EdgeInsets.zero,
                                avatar: isSel
                                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                                    : null,
                                selected: isSel,
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedColor = color);
                                },
                                shape: const CircleBorder(),
                                selectedColor: color,
                                backgroundColor: color.withValues(alpha: 0.5),
                                showCheckmark: false,
                                padding: const EdgeInsets.all(8),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stops section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transit Stops (Sequence Builder)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _addStopField,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Stop', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const Text(
                        'Drag items using the reorder handles to rearrange the stop sequence.',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ReorderableListView.builder(
                          itemCount: _stops.length,
                          onReorder: (oldIdx, newIdx) {
                            setState(() {
                              if (newIdx > oldIdx) newIdx -= 1;
                              final item = _stops.removeAt(oldIdx);
                              _stops.insert(newIdx, item);
                            });
                          },
                          itemBuilder: (context, idx) {
                            final stop = _stops[idx];
                            return _StopBuilderCard(
                              key: ValueKey('stop-builder-$idx-${stop.hashCode}'),
                              index: idx,
                              isStart: idx == 0,
                              isEnd: idx == _stops.length - 1,
                              stop: stop,
                              onRemove: () => _removeStopField(idx),
                              onChanged: (updatedStop) {
                                setState(() {
                                  _stops[idx] = updatedStop;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveRoute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopBuilderCard extends StatefulWidget {
  final int index;
  final bool isStart;
  final bool isEnd;
  final RoutePoint stop;
  final VoidCallback onRemove;
  final ValueChanged<RoutePoint> onChanged;

  const _StopBuilderCard({
    required super.key,
    required this.index,
    required this.isStart,
    required this.isEnd,
    required this.stop,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_StopBuilderCard> createState() => _StopBuilderCardState();
}

class _StopBuilderCardState extends State<_StopBuilderCard> {
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.stop.name;
    _latController.text = widget.stop.lat.toString();
    _lngController.text = widget.stop.lng.toString();
  }

  @override
  void didUpdateWidget(covariant _StopBuilderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stop.name != widget.stop.name) {
      _nameController.text = widget.stop.name;
    }
    if (oldWidget.stop.lat != widget.stop.lat) {
      _latController.text = widget.stop.lat.toString();
    }
    if (oldWidget.stop.lng != widget.stop.lng) {
      _lngController.text = widget.stop.lng.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _triggerChange() {
    final lat = double.tryParse(_latController.text) ?? 0.0;
    final lng = double.tryParse(_lngController.text) ?? 0.0;
    widget.onChanged(RoutePoint(
      name: _nameController.text,
      lat: lat,
      lng: lng,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = widget.isStart
        ? const Color(0xFF10B981) // Start Green
        : widget.isEnd
            ? const Color(0xFFEF4444) // End Red
            : AppColors.turkishBlue;

    final String badgeLabel = widget.isStart
        ? 'S'
        : widget.isEnd
            ? 'E'
            : '${widget.index}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              badgeLabel,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Stop Name',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (_) => _triggerChange(),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        style: const TextStyle(fontSize: 9, fontFamily: 'monospace'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Latitude',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 2),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (_) => _triggerChange(),
                        validator: (val) => double.tryParse(val ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        style: const TextStyle(fontSize: 9, fontFamily: 'monospace'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Longitude',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 2),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (_) => _triggerChange(),
                        validator: (val) => double.tryParse(val ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onRemove,
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
