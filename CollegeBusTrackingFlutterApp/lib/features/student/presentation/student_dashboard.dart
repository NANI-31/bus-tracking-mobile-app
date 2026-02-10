import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/services/persistence_service.dart';
import 'package:collegebus/features/notification/application/proximity_provider.dart';
import 'package:collegebus/features/notification/services/fcm_service.dart';

// Import the new modules
import 'tabs/student_map_tab.dart';
import 'student_notifications_screen.dart';
import 'package:collegebus/features/user/presentation/screens/profile_screen.dart';
import 'student_home_screen.dart';
import 'bus_schedule_screen.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;

  BusModel? _selectedBus;
  LatLng? _currentLocation;
  String? _selectedStop;
  String? _selectedBusNumber;
  String? _selectedRouteType;
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Restore/Enable Status Bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    _bottomNavIndex = PersistenceService.getBottomNavIndex();
    _getCurrentLocation();

    // Join socket room
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      final collegeId = user?.collegeId;
      if (collegeId != null) {
        ref.read(socketServiceProvider).joinCollege(collegeId);
      }
      _checkPermissions(); // Request permissions after dashboard load
    });
  }

  void _onBottomNavChanged(int index) {
    if (mounted) {
      setState(() {
        _bottomNavIndex = index;
      });
      PersistenceService.setBottomNavIndex(index);
    }
  }

  Future<void> _checkPermissions() async {
    // 1. Request Notification Permission
    await FCMService().requestPermission();

    // 2. Request Location Permission
    final locationService = ref.read(locationServiceProvider);
    await locationService.requestLocationPermission();

    // 3. Refresh location now that permission might be granted
    await _getCurrentLocation();

    // 4. Refresh FCM Token (in case it was waiting for permission)
    final user = ref.read(currentUserProvider);
    if (user != null) {
      debugPrint('Refreshing FCM token after permissions...');
      // We can trigger a token refresh by calling register again or logic in AuthProvider
      // For now, let's just log it. The FCMService listener handles refresh.
    }
  }

  Future<void> _getCurrentLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final location = await locationService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() => _currentLocation = location);
    }
  }

  void _selectBus(BusModel bus) {
    if (mounted) setState(() => _selectedBus = bus);
    final api = ref.read(apiServiceProvider);
    api.getBusLocation(bus.id).then((location) {
      if (location != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location.currentLocation, 16.0),
        );
      }
    });

    _onBottomNavChanged(1);
  }

  void _onBusNumberSelected(String? busNumber) {
    if (mounted) {
      setState(() {
        _selectedBusNumber = busNumber;
      });
    }
  }

  void _onRouteTypeSelected(String? routeType) {
    if (mounted) {
      setState(() {
        _selectedRouteType = routeType;
      });
    }
  }

  void _clearFilters() {
    if (mounted) {
      setState(() {
        _selectedStop = null;
        _selectedBusNumber = null;
        _selectedRouteType = null;
        _selectedBus = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;

    // Initialize proximity alerts listener
    ref.listen(proximityAlertProvider, (previous, next) {});

    // Watch providers
    final busesAsync = collegeId != null
        ? ref.watch(collegeBusesStreamProvider(collegeId))
        : const AsyncValue<List<BusModel>>.data([]);
    final routesAsync = collegeId != null
        ? ref.watch(collegeRoutesProvider(collegeId))
        : const AsyncValue<List<RouteModel>>.data([]);

    final allBusesRaw = busesAsync.value ?? [];
    final routes = routesAsync.value ?? [];

    // Set default stop from preference if not set
    final preferredStop = user?.preferredStop;
    if (_selectedStop == null && preferredStop != null) {
      _selectedStop = preferredStop;
    }

    // Compute filter options
    final stopsSet = <String>{};
    for (final bus in allBusesRaw) {
      final route = routes.firstWhere(
        (r) => r.id == bus.routeId,
        orElse: () => RouteModel(
          id: '',
          routeName: 'N/A',
          routeType: '',
          startPoint: RoutePoint(name: '', lat: 0, lng: 0),
          endPoint: RoutePoint(name: '', lat: 0, lng: 0),
          stopPoints: [],
          collegeId: '',
          createdBy: '',
          isActive: false,
          createdAt: DateTime.now(),
        ),
      );
      stopsSet.add(route.startPoint.name);
      stopsSet.add(route.endPoint.name);
      stopsSet.addAll(route.stopPoints.map((s) => s.name));
    }
    // Apply filters
    var filteredBuses = allBusesRaw.where((bus) {
      return bus.status != 'not-running' && bus.assignmentStatus == 'accepted';
    }).toList();

    if (_selectedRouteType != null) {
      filteredBuses = filteredBuses.where((bus) {
        final route = routes.firstWhere(
          (r) => r.id == bus.routeId,
          orElse: () => RouteModel(
            id: '',
            routeName: '',
            routeType: '',
            startPoint: RoutePoint(name: '', lat: 0, lng: 0),
            endPoint: RoutePoint(name: '', lat: 0, lng: 0),
            stopPoints: [],
            collegeId: '',
            createdBy: '',
            isActive: false,
            createdAt: DateTime.now(),
          ),
        );
        return route.routeType == _selectedRouteType;
      }).toList();
    }
    if (_selectedStop != null) {
      filteredBuses = filteredBuses.where((bus) {
        final route = routes.firstWhere(
          (r) => r.id == bus.routeId,
          orElse: () => RouteModel(
            id: '',
            routeName: '',
            routeType: '',
            startPoint: RoutePoint(name: '', lat: 0, lng: 0),
            endPoint: RoutePoint(name: '', lat: 0, lng: 0),
            stopPoints: [],
            collegeId: '',
            createdBy: '',
            isActive: false,
            createdAt: DateTime.now(),
          ),
        );
        return route.startPoint.name == _selectedStop ||
            route.endPoint.name == _selectedStop ||
            route.stopPoints.any((s) => s.name == _selectedStop);
      }).toList();
    }
    if (_selectedBusNumber != null) {
      filteredBuses = filteredBuses
          .where((bus) => bus.busNumber == _selectedBusNumber)
          .toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: null,
      body: Stack(
        children: [
          IndexedStack(
            index: _bottomNavIndex,
            children: [
              StudentHomeScreen(
                isTab: true,
                onTrackLive: () => _onBottomNavChanged(1),
              ),
              StudentMapTab(
                currentLocation: _currentLocation,
                buses: _selectedBus != null ? [_selectedBus!] : [],
                selectedBus: _selectedBus,
                selectedRouteType: _selectedRouteType,
                allBuses: allBusesRaw,
                filteredBusesCount: filteredBuses.length,
                onMapCreated: (controller) => _mapController = controller,
                onRouteTypeSelected: _onRouteTypeSelected,
                onBusNumberSelected: _onBusNumberSelected,
                onClearFilters: _clearFilters,
                onBusSelected: (bus) {
                  if (mounted) setState(() => _selectedBus = bus);
                },
              ),
              BusScheduleScreen(
                isTab: true,
                onBusSelected: (bus) => _selectBus(bus),
              ),
              StudentNotificationsScreen(),
              const ProfileScreen(),
            ],
          ),
          // Global Connectivity Banner
          _buildConnectivityBanner(),
        ],
      ),
      bottomNavigationBar: CurvedBottomNavBar(
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Theme.of(context).cardColor
            : Theme.of(context).colorScheme.primaryContainer,
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavChanged,
        items: [
          CurvedBottomNavIcon(
            icon: _bottomNavIndex == 0 ? Icons.home : Icons.home_outlined,
            label: 'Home',
          ),
          CurvedBottomNavIcon(
            icon: _bottomNavIndex == 1 ? Icons.map : Icons.map_outlined,
            label: 'Live Map',
          ),
          CurvedBottomNavIcon(
            icon: _bottomNavIndex == 2
                ? Icons.calendar_month
                : Icons.calendar_month_outlined,
            label: 'Schedule',
          ),
          CurvedBottomNavIcon(
            icon: _bottomNavIndex == 3
                ? Icons.notifications
                : Icons.notifications_none_outlined,
            label: 'Activity',
            badgeCount: 3,
          ),
          CurvedBottomNavIcon(
            icon: _bottomNavIndex == 4 ? Icons.person : Icons.person_outline,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityBanner() {
    return Consumer(
      builder: (context, ref, child) {
        final socketService = ref.watch(socketServiceProvider);
        final isConnected = socketService.isConnected;
        final isConnecting = socketService.isConnecting;

        if (isConnected && !isConnecting) return const SizedBox.shrink();

        final color = isConnecting ? Colors.amber : Colors.redAccent;

        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 20,
          right: 20,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * -20),
                  child: child,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.7),
                        color.withValues(alpha: 0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulsatingDot(),
                      const SizedBox(width: 12),
                      Text(
                        isConnecting ? "Connecting..." : "Server Disconnected",
                        style: TextStyle(
                          color: isConnecting ? Colors.black87 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PulsatingDot extends StatefulWidget {
  const PulsatingDot({super.key});

  @override
  State<PulsatingDot> createState() => _PulsatingDotState();
}

class _PulsatingDotState extends State<PulsatingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: child);
      },
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 4,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
