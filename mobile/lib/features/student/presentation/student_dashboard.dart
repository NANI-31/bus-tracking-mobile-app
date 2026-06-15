import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/core/services/persistence_service.dart';
import 'package:collegebus/features/notification/application/proximity_provider.dart';
import 'package:collegebus/features/notification/application/notification_provider.dart';
import 'package:collegebus/features/notification/services/fcm_service.dart';

// Import the new modules
import 'package:collegebus/features/student/application/map_navigation_provider.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  GoogleMapController? _mapController;

  LatLng? _currentLocation;
  int _bottomNavIndex = 0;
  Timer? _bannerDelayTimer;
  bool _showDisconnectedBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Restore/Enable Status Bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    _bottomNavIndex = PersistenceService.getBottomNavIndex();
    _getCurrentLocation();

    // Listen for user data to join socket room
    // This handles both initial load and re-auth scenarios
    ref.listenManual(currentUserProvider, (previous, next) {
      if (next?.collegeId != null && (previous?.collegeId != next?.collegeId)) {
        ref.read(socketServiceProvider).joinCollege(next!.collegeId);
      }
    });

    // Join socket room initially if user is already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      final collegeId = user?.collegeId;
      if (collegeId != null) {
        ref.read(socketServiceProvider).joinCollege(collegeId);
      }
      _checkPermissions(); // Request permissions after dashboard load
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reconnect socket when app comes back to foreground
      ref.read(socketServiceProvider).ensureConnected();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Cancel any pending banner timer when going to background
      _bannerDelayTimer?.cancel();
      if (mounted) {
        setState(() {
          _showDisconnectedBanner = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerDelayTimer?.cancel();
    super.dispose();
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
      ref.read(mapNavigationProvider.notifier).updateUserLocation(location);
    }
  }

  void _selectBus(BusModel bus) {
    final user = ref.read(currentUserProvider);
    final collegeId = user?.collegeId;
    RouteModel? activeRoute;
    if (collegeId != null) {
      final routes = ref.read(collegeRoutesProvider(collegeId)).value ?? [];
      final targetRouteId = bus.routeId ?? bus.defaultRouteId;
      activeRoute = routes.cast<RouteModel?>().firstWhere(
            (r) => r!.id == targetRouteId,
            orElse: () => null,
          );
    }
    ref.read(mapNavigationProvider.notifier).selectBus(bus, activeRoute);

    final repo = ref.read(busRepositoryProvider);
    repo.getBusLocation(bus.id).then((location) {
      if (location != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location.currentLocation, 16.0),
        );
      }
    });

    _onBottomNavChanged(1);
  }

  void _onBusNumberSelected(String? busNumber) {
    ref.read(mapNavigationProvider.notifier).updateFilters(
      selectedBusNumber: () => busNumber,
    );
  }

  void _onRouteTypeSelected(String? routeType) {
    ref.read(mapNavigationProvider.notifier).updateFilters(
      selectedRouteType: () => routeType,
    );
  }

  void _clearFilters() {
    ref.read(mapNavigationProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;
    
    // Selectively watch only the filter/selection parameters from mapNavigationProvider
    // to avoid rebuilding the entire dashboard on every continuous camera/zoom update.
    final selectedBus = ref.watch(mapNavigationProvider.select((s) => s.selectedBus));
    final selectedRouteType = ref.watch(mapNavigationProvider.select((s) => s.selectedRouteType));
    final selectedStop = ref.watch(mapNavigationProvider.select((s) => s.selectedStop));
    final selectedBusNumber = ref.watch(mapNavigationProvider.select((s) => s.selectedBusNumber));
    final activeRoute = ref.watch(mapNavigationProvider.select((s) => s.activeRoute));

    // Initialize proximity alerts listener
    ref.listen(proximityAlertProvider, (previous, next) {});

    // Watch providers
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final busesAsync = collegeId != null
        ? ref.watch(collegeBusesStreamProvider(collegeId))
        : const AsyncValue<List<BusModel>>.data([]);
    final routesAsync = collegeId != null
        ? ref.watch(collegeRoutesProvider(collegeId))
        : const AsyncValue<List<RouteModel>>.data([]);
    final liveLocationsAsync = collegeId != null
        ? ref.watch(collegeBusLocationsProvider(collegeId))
        : const AsyncValue<List<BusLocationModel>>.data([]);
    final liveLocations = liveLocationsAsync.value ?? [];
    final liveBusIds = liveLocations.map((loc) => loc.busId).toSet();

    final allBusesRaw = busesAsync.value ?? [];
    final routes = routesAsync.value ?? [];

    // Restore saved bus selection when buses list becomes available
    final savedBusId = user != null ? PersistenceService.getSelectedBusId(user.id) : null;
    if (savedBusId != null && selectedBus == null && busesAsync.hasValue) {
      BusModel? match;
      for (final b in allBusesRaw) {
        if (b.id == savedBusId) {
          match = b;
          break;
        }
      }
      if (match != null) {
        final targetRouteId = match.routeId ?? match.defaultRouteId;
        final activeRoute = targetRouteId != null
            ? routes.cast<RouteModel?>().firstWhere(
                  (r) => r!.id == targetRouteId,
                  orElse: () => null,
                )
            : null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(mapNavigationProvider.notifier).selectBus(match, activeRoute);
        });
      }
    }

    // Set default stop from preference if not set
    final preferredStop = user?.preferredStop;
    if (selectedStop == null && preferredStop != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mapNavigationProvider.notifier).updateFilters(
          selectedStop: () => preferredStop,
        );
      });
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
      final isLive = bus.status != 'not-running' || liveBusIds.contains(bus.id);
      return isLive && bus.assignmentStatus != 'unassigned';
    }).toList();

    if (selectedRouteType != null) {
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
        return route.routeType == selectedRouteType;
      }).toList();
    }
    if (selectedStop != null) {
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
        return route.startPoint.name == selectedStop ||
            route.endPoint.name == selectedStop ||
            route.stopPoints.any((s) => s.name == selectedStop);
      }).toList();
    }
    if (selectedBusNumber != null) {
      filteredBuses = filteredBuses
          .where((bus) => bus.busNumber == selectedBusNumber)
          .toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: null,
      body: Stack(
        children: [
          AnimatedIndexedStack(
            index: _bottomNavIndex,
            children: [
              StudentHomeScreen(
                isTab: true,
                onTrackLive: () => _onBottomNavChanged(1),
              ),
              StudentMapTab(
                currentLocation: _currentLocation,
                buses: selectedBus != null ? [selectedBus] : filteredBuses,
                selectedBus: selectedBus,
                selectedRouteType: selectedRouteType,
                allBuses: allBusesRaw,
                filteredBusesCount: filteredBuses.length,
                onMapCreated: (controller) => _mapController = controller,
                onRouteTypeSelected: _onRouteTypeSelected,
                onBusNumberSelected: _onBusNumberSelected,
                onClearFilters: _clearFilters,
                onBusSelected: (bus) {
                  RouteModel? activeRoute;
                  if (bus != null && collegeId != null) {
                    final routes = ref.read(collegeRoutesProvider(collegeId)).value ?? [];
                    final targetRouteId = bus.routeId ?? bus.defaultRouteId;
                    activeRoute = routes.cast<RouteModel?>().firstWhere(
                          (r) => r!.id == targetRouteId,
                          orElse: () => null,
                        );
                  }
                  ref.read(mapNavigationProvider.notifier).selectBus(bus, activeRoute);
                },
                activeRoute: activeRoute,
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
        activeColor: _getActiveColor(context),
        inactiveColor: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Theme.of(context).cardColor
            : Theme.of(context).colorScheme.primaryContainer,
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavChanged,
        items: [
          CurvedBottomNavItem(
            icon: _bottomNavIndex == 0 ? Icons.home : Icons.home_outlined,
            label: 'Home',
          ),
          CurvedBottomNavItem(
            icon: _bottomNavIndex == 1 ? Icons.map : Icons.map_outlined,
            label: 'Live Map',
          ),
          CurvedBottomNavItem(
            icon: _bottomNavIndex == 2
                ? Icons.calendar_month
                : Icons.calendar_month_outlined,
            label: 'Schedule',
          ),
          CurvedBottomNavItem(
            icon: _bottomNavIndex == 3
                ? Icons.notifications
                : Icons.notifications_none_outlined,
            label: 'Activity',
            badgeCount: unreadCount,
          ),
          CurvedBottomNavItem(
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

        // If connected, hide banner and cancel any pending timer
        if (isConnected && !isConnecting) {
          _bannerDelayTimer?.cancel();
          if (_showDisconnectedBanner) {
            _showDisconnectedBanner = false;
          }
          return const SizedBox.shrink();
        }

        // If just came back from background or briefly disconnected,
        // add a 3-second grace period before showing the banner
        if (!_showDisconnectedBanner && !isConnecting) {
          _bannerDelayTimer?.cancel();
          _bannerDelayTimer = Timer(const Duration(seconds: 3), () {
            if (mounted && !socketService.isConnected) {
              setState(() {
                _showDisconnectedBanner = true;
              });
            }
          });
          return const SizedBox.shrink();
        }

        // Show "Connecting..." immediately but "Disconnected" after grace period
        if (!isConnecting && !_showDisconnectedBanner) {
          return const SizedBox.shrink();
        }

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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isConnecting ? Colors.amber : Colors.red,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: (isConnecting ? Colors.amber : Colors.red)
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                isConnecting ? "Connecting..." : "Server Disconnected",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isConnecting ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getActiveColor(BuildContext context) {
    if (_bottomNavIndex == 0) return Theme.of(context).colorScheme.primary;
    if (_bottomNavIndex == 1) return Colors.teal.shade400;
    if (_bottomNavIndex == 2) return Colors.indigo.shade400;
    if (_bottomNavIndex == 3) return Colors.orange.shade400;
    if (_bottomNavIndex == 4) return Colors.purple.shade400;
    return Theme.of(context).colorScheme.primary;
  }
}

class AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  // Track which tab indexes have been visited at least once.
  // On revisit, we skip the slide-in animation so the tab appears
  // immediately without looking like a fake loading state.
  late Set<int> _visitedIndexes;

  @override
  void initState() {
    super.initState();
    _visitedIndexes = {widget.index}; // current tab is already "visited"
    _controllers = List.generate(
      widget.children.length,
      (i) => AnimationController(
        vsync: this,
        duration: widget.duration,
      ),
    );

    _animations = _controllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0), // Spring overshoot curve
      );
    }).toList();

    _controllers[widget.index].value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controllers[oldWidget.index].reverse();
      final isRevisit = _visitedIndexes.contains(widget.index);
      if (isRevisit) {
        // Jump straight to the final value — no entrance animation on revisit
        _controllers[widget.index].value = 1.0;
      } else {
        _visitedIndexes.add(widget.index);
        _controllers[widget.index].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.children.length, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            final val = _animations[i].value;
            if (val == 0.0 && widget.index != i) {
              return const SizedBox.shrink();
            }
            return IgnorePointer(
              ignoring: widget.index != i,
              child: Opacity(
                opacity: val.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.95 + (0.05 * val),
                  child: Transform.translate(
                    offset: Offset(0.0, 30.0 * (1.0 - val)),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: widget.children[i],
        );
      }),
    );
  }
}

// PulsatingDot class removed in favor of RiveSosIndicator
