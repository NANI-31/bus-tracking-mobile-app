import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/college_admin/application/college_admin_provider.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/core/utils/map_marker_helper.dart';

class MapCluster {
  final String id;
  LatLng center;
  final List<BusModel> buses;
  final bool isCluster;

  MapCluster({
    required this.id,
    required this.center,
    required this.buses,
    required this.isCluster,
  });
}

class LiveTrackingTab extends ConsumerStatefulWidget {
  const LiveTrackingTab({super.key});

  @override
  ConsumerState<LiveTrackingTab> createState() => _LiveTrackingTabState();
}

class _LiveTrackingTabState extends ConsumerState<LiveTrackingTab> {
  GoogleMapController? _mapController;
  BusModel? _selectedBus;
  String _searchTerm = '';
  double _zoom = 5.0;
  Set<Marker> _markers = {};
  BitmapDescriptor? _busIcon;
  final Map<int, BitmapDescriptor> _clusterIconCache = {};
  bool _isDisposed = false;
  String _lastStateKey = '';

  @override
  void initState() {
    super.initState();
    _loadBusIcon();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadBusIcon() async {
    try {
      final icon = await MapMarkerHelper.createBusMarker();
      if (!_isDisposed && mounted) {
        setState(() {
          _busIcon = icon;
        });
      }
    } catch (_) {}
  }

  Future<BitmapDescriptor> _createClusterMarkerIcon(int count) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double size = count > 10 ? 90.0 : 70.0;
    
    final paint = Paint()
      ..color = const Color(0xFF0097B2) // Upasthit Deep Teal
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 3, paint);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 3, borderPaint);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$count',
        style: TextStyle(
          fontSize: size * 0.35,
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
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _getClusterIcon(int count) async {
    if (_clusterIconCache.containsKey(count)) {
      return _clusterIconCache[count]!;
    }
    final icon = await _createClusterMarkerIcon(count);
    _clusterIconCache[count] = icon;
    return icon;
  }

  List<MapCluster> _getClusters(
    List<BusModel> buses,
    Map<String, BusLocationModel> locations,
    double zoom,
  ) {
    if (zoom >= 12.0) {
      return buses.map((bus) {
        final loc = locations[bus.id];
        return MapCluster(
          id: 'single-${bus.id}',
          center: loc?.currentLocation ?? const LatLng(0, 0),
          buses: [bus],
          isCluster: false,
        );
      }).where((c) => c.center.latitude != 0.0).toList();
    }

    final double threshold = 1.2 / math.pow(2, zoom);
    final List<MapCluster> clusters = [];

    for (var bus in buses) {
      final loc = locations[bus.id];
      if (loc == null) continue;
      final lat = loc.currentLocation.latitude;
      final lng = loc.currentLocation.longitude;

      MapCluster? foundCluster;
      for (var c in clusters) {
        final latDiff = (c.center.latitude - lat).abs();
        final lngDiff = (c.center.longitude - lng).abs();
        if (latDiff < threshold && lngDiff < threshold) {
          foundCluster = c;
          break;
        }
      }

      if (foundCluster != null) {
        foundCluster.buses.add(bus);
        final count = foundCluster.buses.length;
        foundCluster.center = LatLng(
          (foundCluster.center.latitude * (count - 1) + lat) / count,
          (foundCluster.center.longitude * (count - 1) + lng) / count,
        );
      } else {
        clusters.add(MapCluster(
          id: 'cluster-${bus.id}',
          center: LatLng(lat, lng),
          buses: [bus],
          isCluster: true,
        ));
      }
    }

    return clusters.map((c) {
      if (c.buses.length == 1) {
        return MapCluster(
          id: 'single-${c.buses.first.id}',
          center: locations[c.buses.first.id]!.currentLocation,
          buses: c.buses,
          isCluster: false,
        );
      }
      return c;
    }).toList();
  }

  Map<String, String> _getBusStatus(BusModel bus, BusLocationModel? loc) {
    if (loc == null) {
      return {'label': 'Not Running', 'color': 'grey'};
    }
    final diffInMinutes = DateTime.now().difference(loc.timestamp).inMinutes.abs();
    if (diffInMinutes > 5) {
      return {'label': 'Not Running', 'color': 'grey'};
    }
    if ((loc.speed ?? 0) > 2) {
      if (bus.delay > 10) {
        return {'label': 'Delayed', 'color': 'red'};
      }
      return {'label': 'On Time', 'color': 'green'};
    }
    return {'label': 'Stationary', 'color': 'amber'};
  }

  Color _getStatusColor(String? colorName) {
    switch (colorName) {
      case 'green':
        return const Color(0xFF10B981); // Emerald
      case 'red':
        return const Color(0xFFEF4444); // Rose
      case 'amber':
        return const Color(0xFFF59E0B); // Amber
      default:
        return Colors.grey;
    }
  }

  void _rebuildMarkers(List<BusModel> buses, List<BusLocationModel> locations, String forKey) async {
    final Set<Marker> newMarkers = {};
    final locationMap = {for (var loc in locations) loc.busId: loc};
    final clusters = _getClusters(buses, locationMap, _zoom);

    for (final cluster in clusters) {
      if (cluster.isCluster) {
        final icon = await _getClusterIcon(cluster.buses.length);
        newMarkers.add(Marker(
          markerId: MarkerId(cluster.id),
          position: cluster.center,
          icon: icon,
          onTap: () {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(cluster.center, _zoom + 3.0),
            );
          },
        ));
      } else {
        final bus = cluster.buses.first;
        final loc = locationMap[bus.id];
        if (loc != null) {
          final status = _getBusStatus(bus, loc);
          newMarkers.add(Marker(
            markerId: MarkerId(bus.id),
            position: loc.currentLocation,
            rotation: loc.heading ?? 0.0,
            icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: 'Bus ${bus.busNumber}',
              snippet: '${status['label']} • ${(loc.speed ?? 0).toStringAsFixed(1)} km/h',
            ),
            onTap: () {
              setState(() {
                _selectedBus = bus;
              });
            },
          ));
        }
      }
    }

    if (!_isDisposed && mounted && forKey == _lastStateKey) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _zoomToFitBuses(List<BusLocationModel> locations) {
    if (_mapController == null || locations.isEmpty) return;

    double minLat = locations.first.currentLocation.latitude;
    double maxLat = locations.first.currentLocation.latitude;
    double minLng = locations.first.currentLocation.longitude;
    double maxLng = locations.first.currentLocation.longitude;

    for (var loc in locations) {
      if (loc.currentLocation.latitude < minLat) minLat = loc.currentLocation.latitude;
      if (loc.currentLocation.latitude > maxLat) maxLat = loc.currentLocation.latitude;
      if (loc.currentLocation.longitude < minLng) minLng = loc.currentLocation.longitude;
      if (loc.currentLocation.longitude > maxLng) maxLng = loc.currentLocation.longitude;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;
    final primaryColor = isDark ? const Color(0xFF00C6E6) : const Color(0xFF0097B2);

    final authUser = ref.watch(currentUserProvider);
    final collegeId = authUser?.collegeId ?? '';

    final collegeAdminState = ref.watch(collegeAdminServiceProvider).valueOrNull;
    final collegeName = collegeAdminState?.college?.name ?? 'My College';

    final busesAsync = ref.watch(busListProvider);
    final locationsAsync = ref.watch(globalBusLocationsProvider);
    final socket = ref.watch(socketServiceProvider);

    return busesAsync.when(
      data: (buses) {
        return locationsAsync.when(
          data: (locations) {
            // Apply Filters (restrict to admin's college only)
            final filteredBuses = buses.where((b) {
              final matchCollege = b.collegeId == collegeId;
              final matchSearch = _searchTerm.isEmpty || b.busNumber.toLowerCase().contains(_searchTerm.toLowerCase());
              return matchCollege && matchSearch;
            }).toList();

            final locationMap = {for (var loc in locations) loc.busId: loc};
            final activeBuses = filteredBuses.where((b) => locationMap.containsKey(b.id)).toList();

            // Dynamic rebuild markers with key change verification to prevent infinite build loops
            final stateKey = '${_zoom}_${collegeId}_${_searchTerm}_${filteredBuses.map((b) {
              final loc = locationMap[b.id];
              return '${b.id}_${loc?.currentLocation.latitude}_${loc?.currentLocation.longitude}_${loc?.heading}';
            }).join('|')}';

            if (stateKey != _lastStateKey) {
              _lastStateKey = stateKey;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _rebuildMarkers(filteredBuses, locations, stateKey);
              });
            }

            // Handle map centering to selected bus
            if (_selectedBus != null && locationMap.containsKey(_selectedBus!.id)) {
              final loc = locationMap[_selectedBus!.id]!;
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(loc.currentLocation),
              );
            }

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  // Connection Alert Banner
                  if (!socket.isConnected)
                    Container(
                      width: double.infinity,
                      color: Colors.amber.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Connection Lost — Showing Last Cached Location. Reconnecting...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Top Info Bar (shows the College Name instead of College Dropdown)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.school_rounded, color: primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                collegeName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Live Fleet Tracking',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main split panel or stacked content
                  Expanded(
                    child: Row(
                      children: [
                        // Map panel
                        Expanded(
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: const CameraPosition(
                                  target: LatLng(20.5937, 78.9629),
                                  zoom: 5.0,
                                ),
                                markers: _markers,
                                zoomControlsEnabled: true,
                                mapToolbarEnabled: false,
                                myLocationButtonEnabled: false,
                                onMapCreated: (controller) => _mapController = controller,
                                onCameraMove: (position) {
                                  if (_zoom != position.zoom) {
                                    setState(() {
                                      _zoom = position.zoom;
                                    });
                                  }
                                },
                              ),
                              
                              // Zoom fit fleet FAB
                              Positioned(
                                top: 16,
                                right: 16,
                                child: FloatingActionButton.small(
                                  onPressed: () {
                                    final activeLocations = locations
                                        .where((l) => filteredBuses.any((b) => b.id == l.busId))
                                        .toList();
                                    _zoomToFitBuses(activeLocations);
                                  },
                                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  foregroundColor: isDark ? Colors.white : Colors.black87,
                                  child: const Icon(Icons.zoom_out_map),
                                ),
                              ),

                              // Mobile Selected Bus Info Bottomsheet card
                              if (!isWide && _selectedBus != null)
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  right: 16,
                                  child: _buildSelectedBusCard(
                                    _selectedBus!,
                                    locationMap[_selectedBus!.id],
                                    collegeName,
                                    isDark,
                                    primaryColor,
                                    () => setState(() => _selectedBus = null),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Sidebar list for wide layouts
                        if (isWide)
                          Container(
                            width: 300,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              border: Border(
                                left: BorderSide(
                                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                                ),
                              ),
                            ),
                            child: _buildSidebarList(
                              activeBuses,
                              locationMap,
                              collegeName,
                              isDark,
                              primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Mobile list panel toggle button
                  if (!isWide)
                    Container(
                      width: double.infinity,
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) {
                              return Container(
                                height: MediaQuery.of(context).size.height * 0.6,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                child: _buildSidebarList(
                                  activeBuses,
                                  locationMap,
                                  collegeName,
                                  isDark,
                                  primaryColor,
                                ),
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.list_alt_rounded),
                        label: Text('Active Fleet List (${activeBuses.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Locations Error: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Buses Error: $err')),
    );
  }

  Widget _buildSidebarList(
    List<BusModel> activeBuses,
    Map<String, BusLocationModel> locationMap,
    String collegeName,
    bool isDark,
    Color primaryColor,
  ) {
    return Column(
      children: [
        // Sidebar header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.directions_bus_rounded, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Active Fleet (${activeBuses.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),

        // Search Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            onChanged: (val) {
              setState(() {
                _searchTerm = val;
              });
            },
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search bus number...',
              prefixIcon: const Icon(Icons.search, size: 16),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        const Divider(height: 1),

        // Scrollable List
        Expanded(
          child: activeBuses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_rounded, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        'No active buses detected.',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: activeBuses.length,
                  separatorBuilder: (context, idx) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final bus = activeBuses[index];
                    final loc = locationMap[bus.id];
                    final status = _getBusStatus(bus, loc);
                    final isSelected = _selectedBus?.id == bus.id;

                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      color: isSelected
                          ? primaryColor.withOpacity(isDark ? 0.08 : 0.04)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? primaryColor.withOpacity(0.4)
                              : (isDark ? Colors.white10 : Colors.grey.shade200),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBus = bus;
                          });
                          if (loc != null) {
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(loc.currentLocation, 15.0),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bus ${bus.busNumber}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        collegeName,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isDark ? Colors.white38 : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status['color']).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status['label']!.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(status['color']),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.bolt, size: 12, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(loc?.speed ?? 0).toStringAsFixed(1)} km/h',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.access_time_filled_rounded, size: 12, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${bus.delay}m delay',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Selected bus bottom details panel for wide layouts
        if (_selectedBus != null)
          _buildSelectedBusCard(
            _selectedBus!,
            locationMap[_selectedBus!.id],
            collegeName,
            isDark,
            primaryColor,
            () => setState(() => _selectedBus = null),
          ),
      ],
    );
  }

  Widget _buildSelectedBusCard(
    BusModel bus,
    BusLocationModel? loc,
    String collegeName,
    bool isDark,
    Color primaryColor,
    VoidCallback onClose,
  ) {
    final status = _getBusStatus(bus, loc);

    return Card(
      elevation: 6,
      margin: EdgeInsets.zero,
      color: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'System Details',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'College',
              collegeName,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status', style: TextStyle(color: Colors.white60, fontSize: 11)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status['color']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(status['color']).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status['label']!.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status['color']),
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Bus Number', bus.busNumber, valueColor: primaryColor),
            const SizedBox(height: 8),
            _buildDetailRow('Speed', '${(loc?.speed ?? 0).toStringAsFixed(1)} km/h'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contacting fleet coordinator...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Contact Coordinator', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
