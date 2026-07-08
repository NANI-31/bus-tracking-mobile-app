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

import 'package:collegebus/features/notification/services/notification_service.dart';

// Import the new modules
import 'package:collegebus/features/student/application/map_navigation_provider.dart';
import 'tabs/student_map_tab.dart';
import 'student_notifications_screen.dart';
import 'package:collegebus/features/user/presentation/screens/profile_screen.dart';
import 'student_home_screen.dart';
import 'bus_schedule_screen.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';
import 'package:collegebus/core/constants/constants.dart';

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

  /// Tracks which tabs have been visited (and thus mounted).
  /// P0.3 fix: Tabs are lazily built — only mounted on first visit.
  /// This prevents Google Maps + schedule streams from initializing at startup.
  final Set<int> _visitedTabs = {};

  /// Key for the [RepaintBoundary] wrapping the main content.
  /// Passed to [CurvedBottomNavBar] so the liquid-glass lens shader can
  /// sample the real pixels rendered behind the navigation bar.
  final GlobalKey _backgroundKey = GlobalKey();

  /// P2.1 fix: Guard to ensure bus-from-prefs restoration only runs once,
  /// not on every build triggered by socket events.
  bool _busRestoredFromPrefs = false;

  /// Subscription to the socket stop_reached stream.
  /// Shows an in-app banner when the student's tracked bus arrives at a stop.
  StreamSubscription<Map<String, dynamic>>? _stopReachedSub;

  /// Active stop arrival in-app toast overlay.
  OverlayEntry? _activeStopArrivalOverlay;

  /// Tracks the current app lifecycle state to determine whether to show
  /// an in-app toast or background system notification.
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;


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
    // Seed the visited set with whichever tab was last open
    _visitedTabs.add(_bottomNavIndex);

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
      _subscribeToStopArrivals(); // Start listening for stop_reached events
    });
  }

  /// Listen to the socket stop_reached stream and show a banner/notification whenever
  /// the bus the student is currently tracking arrives at a stop.
  ///
  /// Filters by [selectedBus.id] so only events for the tracked bus appear.
  void _subscribeToStopArrivals() {
    final socketService = ref.read(socketServiceProvider);
    _stopReachedSub = socketService.stopReachedStream.listen((data) {
      if (!mounted) return;

      // Only show the banner for the bus the student is currently tracking.
      final selectedBus =
          ref.read(mapNavigationProvider.select((s) => s.selectedBus));
      if (selectedBus == null || data['busId'] != selectedBus.id) return;

      final stopName = data['stopName'] as String? ?? 'a stop';
      final busNumber = selectedBus.busNumber;

      if (_lifecycleState == AppLifecycleState.resumed) {
        // App is open (foreground) -> Show custom swipe-dismissible top toast
        _showStopArrivalToast(
          busNumber: busNumber,
          stopName: stopName,
        );
      } else {
        // App is in background -> Send system status bar notification
        NotificationService.showStopArrivalAlert(
          busNumber: busNumber,
          stopName: stopName,
        );
      }
    });
  }

  /// Displays a premium in-app toast for stop arrival.
  /// This toast is overlay-based, placed below the status bar, and is swipeable.
  void _showStopArrivalToast({
    required String busNumber,
    required String stopName,
  }) {
    if (!mounted) return;

    // Remove any active overlay first to prevent overlaps
    _activeStopArrivalOverlay?.remove();
    _activeStopArrivalOverlay = null;

    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: SwipeDismissibleToast(
              onDismissed: () {
                if (_activeStopArrivalOverlay == entry) {
                  entry.remove();
                  _activeStopArrivalOverlay = null;
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0097B2), Color(0xFF0076A3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0097B2).withValues(alpha: 0.35),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Bus Icon with background container
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_bus_filled_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Notification details text
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bus $busNumber has arrived!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Now at: $stopName',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Swipe left, right, or up to dismiss',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action button (View)
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        if (_activeStopArrivalOverlay == entry) {
                          entry.remove();
                          _activeStopArrivalOverlay = null;
                        }
                        // Navigate to map tab
                        _onBottomNavChanged(1);
                      },
                      child: const Text(
                        'View',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    _activeStopArrivalOverlay = entry;
    overlay.insert(entry);
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      // Reconnect socket when app comes back to foreground
      ref.read(socketServiceProvider).ensureConnected();
    }
  }

  @override
  void dispose() {
    _activeStopArrivalOverlay?.remove();
    _activeStopArrivalOverlay = null;
    _stopReachedSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  void _onBottomNavChanged(int index) {
    if (mounted) {
      setState(() {
        _bottomNavIndex = index;
        // Mark this tab as visited so it gets built on the first switch.
        _visitedTabs.add(index);
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
    if (bus.assignmentStatus != 'accepted') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bus ${bus.busNumber} is not active yet (pending driver acceptance).',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final user = ref.read(currentUserProvider);
    final collegeId = user?.collegeId;
    RouteModel? activeRoute;
    if (collegeId != null) {
      final routes = ref.read(collegeRoutesProvider(collegeId)).valueOrNull ?? [];
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
    ref
        .read(mapNavigationProvider.notifier)
        .updateFilters(selectedBusNumber: () => busNumber);
  }

  void _onRouteTypeSelected(String? routeType) {
    ref
        .read(mapNavigationProvider.notifier)
        .updateFilters(selectedRouteType: () => routeType);
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
    final selectedBus = ref.watch(
      mapNavigationProvider.select((s) => s.selectedBus),
    );
    final selectedRouteType = ref.watch(
      mapNavigationProvider.select((s) => s.selectedRouteType),
    );
    final selectedStop = ref.watch(
      mapNavigationProvider.select((s) => s.selectedStop),
    );
    final selectedBusNumber = ref.watch(
      mapNavigationProvider.select((s) => s.selectedBusNumber),
    );
    final activeRoute = ref.watch(
      mapNavigationProvider.select((s) => s.activeRoute),
    );

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
    // P1.1 perf fix: Watch the pre-computed live bus IDs provider instead of
    // the raw collegeBusLocationsProvider. This ensures build() only runs when
    // the SET of live buses changes, not on every GPS coordinate update.
    final liveBusIds = collegeId != null
        ? ref.watch(studentLiveBusIdsProvider(collegeId))
        : const <String>{};

    final allBusesRaw = busesAsync.valueOrNull ?? [];
    final routes = routesAsync.valueOrNull ?? [];

    // Restore saved bus selection when buses list becomes available.
    // P2.1 fix: guarded by _busRestoredFromPrefs so this runs at most once
    // instead of on every build triggered by socket location updates.
    if (!_busRestoredFromPrefs) {
      final savedBusId = user != null
          ? PersistenceService.getSelectedBusId(user.id)
          : null;
      if (savedBusId != null && selectedBus == null && busesAsync.hasValue) {
        _busRestoredFromPrefs = true; // prevent re-entry
        BusModel? match;
        for (final b in allBusesRaw) {
          if (b.id == savedBusId) {
            match = b;
            break;
          }
        }
        if (match != null) {
          if (match.assignmentStatus == 'accepted') {
            final targetRouteId = match.routeId ?? match.defaultRouteId;
            final restoredRoute = targetRouteId != null
                ? routes.cast<RouteModel?>().firstWhere(
                    (r) => r!.id == targetRouteId,
                    orElse: () => null,
                  )
                : null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(mapNavigationProvider.notifier)
                  .selectBus(match, restoredRoute);
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              PersistenceService.removeSelectedBusId(user?.id);
            });
          }
        }
      }
    }

    // Set default stop from preference if not set — guarded, runs once
    final preferredStop = user?.preferredStop;
    if (selectedStop == null && preferredStop != null && !_busRestoredFromPrefs) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(mapNavigationProvider.notifier)
            .updateFilters(selectedStop: () => preferredStop);
      });
    }

    // P1.1 perf fix: Removed O(N×M) stopsSet loop. Stop filter options are
    // computed inside BusScheduleScreen which has its own data access.
    // Apply live tracking filter — only buses actively broadcasting GPS.
    var filteredBuses = allBusesRaw.where((bus) {
      // Only show buses whose driver is ACTIVELY broadcasting GPS.
      // bus.status updates on DB assignment (not on broadcast start),
      // so we rely solely on liveBusIds from the socket as the gate.
      return liveBusIds.contains(bus.id) && bus.assignmentStatus == 'accepted';
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

    final isWide = context.isTabletLayout || context.isDesktopLayout;

    final mainBody = Stack(
      children: [
        // Main content – wrapped in RepaintBoundary so the nav bar's
        // liquid-glass shader can capture the pixels behind it.
        // ColoredBox ensures the captured image is always opaque; without it
        // transparent tab areas (list gaps, short pages) appear black.
        RepaintBoundary(
          key: _backgroundKey,
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            // P0.3 fix: Lazy IndexedStack — only mount a tab after first visit.
            // Unvisited tabs render a lightweight SizedBox.shrink() placeholder.
            // Once visited, the real widget stays mounted (state preserved).
            // This avoids initialising Google Maps, socket streams, and
            // multiple BackdropFilter trees for all 5 tabs at startup.
            child: IndexedStack(
              index: _bottomNavIndex,
              children: [
                // Tab 0 — Home
                _visitedTabs.contains(0)
                    ? StudentHomeScreen(
                        isTab: true,
                        onTrackLive: () => _onBottomNavChanged(1),
                      )
                    : const SizedBox.shrink(),
                // Tab 1 — Live Map
                _visitedTabs.contains(1)
                    ? StudentMapTab(
                        currentLocation: _currentLocation,
                        buses:
                            selectedBus != null &&
                                    selectedBus.assignmentStatus == 'accepted' &&
                                    liveBusIds.contains(selectedBus.id)
                                ? [selectedBus]
                                : const [],
                        selectedBus:
                            selectedBus != null &&
                                    selectedBus.assignmentStatus == 'accepted'
                                ? selectedBus
                                : null,
                        selectedRouteType: selectedRouteType,
                        allBuses: allBusesRaw,
                        filteredBusesCount: selectedBus != null &&
                                selectedBus.assignmentStatus == 'accepted' &&
                                liveBusIds.contains(selectedBus.id)
                            ? 1
                            : 0,
                        onMapCreated: (controller) => _mapController = controller,
                        onRouteTypeSelected: _onRouteTypeSelected,
                        onBusNumberSelected: _onBusNumberSelected,
                        onClearFilters: _clearFilters,
                        onBusSelected: (bus) {
                          if (bus != null && bus.assignmentStatus != 'accepted') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Bus ${bus.busNumber} is not active yet (pending driver acceptance).',
                                ),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          RouteModel? activeRoute;
                          if (bus != null && collegeId != null) {
                            final routes =
                                ref.read(collegeRoutesProvider(collegeId)).valueOrNull ?? [];
                            final targetRouteId = bus.routeId ?? bus.defaultRouteId;
                            activeRoute = routes.cast<RouteModel?>().firstWhere(
                              (r) => r!.id == targetRouteId,
                              orElse: () => null,
                            );
                          }
                          ref
                              .read(mapNavigationProvider.notifier)
                              .selectBus(bus, activeRoute);
                        },
                        activeRoute:
                            selectedBus != null &&
                                    selectedBus.assignmentStatus == 'accepted'
                                ? activeRoute
                                : null,
                      )
                    : const SizedBox.shrink(),
                // Tab 2 — Schedule
                _visitedTabs.contains(2)
                    ? BusScheduleScreen(
                        isTab: true,
                        onBusSelected: (bus) => _selectBus(bus),
                      )
                    : const SizedBox.shrink(),
                // Tab 3 — Notifications
                _visitedTabs.contains(3)
                    ? StudentNotificationsScreen()
                    : const SizedBox.shrink(),
                // Tab 4 — Profile
                _visitedTabs.contains(4)
                    ? const ProfileScreen()
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),

        // Global Connectivity Banner is now handled by MaterialApp builder
        const SizedBox.shrink(),
        if (!isWide)
          Align(
            alignment: Alignment.bottomCenter,
            child: CurvedBottomNavBar(
              activeColor: _getActiveColor(context),
              activeColors: [
                const Color(0xFF00C6E6), // Turkish Blue / Turquoise
                Colors.teal.shade400,
                Colors.indigo.shade400,
                Colors.orange.shade400,
                Colors.purple.shade400,
              ],
              inactiveColor: Theme.of(context).colorScheme.secondary,
              backgroundColor: Theme.of(context).brightness == Brightness.light
                  ? Theme.of(context).cardColor
                  : Theme.of(context).colorScheme.primaryContainer,
              currentIndex: _bottomNavIndex,
              onTap: _onBottomNavChanged,
              backgroundKey: _backgroundKey,
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
                  icon: _bottomNavIndex == 4
                      ? Icons.person
                      : Icons.person_outline,
                  label: 'Profile',
                ),
              ],
            ),
          ),
      ],
    );

    if (isWide) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _bottomNavIndex,
              onDestinationSelected: _onBottomNavChanged,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).brightness == Brightness.light
                  ? Theme.of(context).cardColor
                  : Theme.of(context).colorScheme.primaryContainer,
              selectedIconTheme: IconThemeData(color: _getActiveColor(context)),
              selectedLabelTextStyle: TextStyle(
                color: _getActiveColor(context),
                fontWeight: FontWeight.bold,
              ),
              unselectedIconTheme: const IconThemeData(color: Colors.grey),
              unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
              destinations: [
                NavigationRailDestination(
                  icon: Icon(
                    _bottomNavIndex == 0 ? Icons.home : Icons.home_outlined,
                  ),
                  label: const Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(
                    _bottomNavIndex == 1 ? Icons.map : Icons.map_outlined,
                  ),
                  label: const Text('Live Map'),
                ),
                NavigationRailDestination(
                  icon: Icon(
                    _bottomNavIndex == 2
                        ? Icons.calendar_month
                        : Icons.calendar_month_outlined,
                  ),
                  label: const Text('Schedule'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text(unreadCount.toString()),
                    isLabelVisible: unreadCount > 0,
                    child: Icon(
                      _bottomNavIndex == 3
                          ? Icons.notifications
                          : Icons.notifications_none_outlined,
                    ),
                  ),
                  label: const Text('Activity'),
                ),
                NavigationRailDestination(
                  icon: Icon(
                    _bottomNavIndex == 4 ? Icons.person : Icons.person_outline,
                  ),
                  label: const Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: mainBody,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: mainBody,
    );
  }



  Color _getActiveColor(BuildContext context) {
    if (_bottomNavIndex == 0) return const Color(0xFF00C6E6); // Turkish Blue / Turquoise
    if (_bottomNavIndex == 1) return Colors.teal.shade400;
    if (_bottomNavIndex == 2) return Colors.indigo.shade400;
    if (_bottomNavIndex == 3) return Colors.orange.shade400;
    if (_bottomNavIndex == 4) return Colors.purple.shade400;
    return const Color(0xFF00C6E6);
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
    this.duration = const Duration(milliseconds: 320), // Snappier, premium transition speed
  });

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (i) => AnimationController(vsync: this, duration: widget.duration),
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
      _controllers[widget.index].forward(from: 0.0); // Animate always for seamless visual flow
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
        final isActive = widget.index == i;
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            final val = _animations[i].value;
            // CRITICAL: Use Offstage instead of SizedBox.shrink() so the
            // child widget is NEVER unmounted. Unmounting destroys state
            // (e.g. LiveBusMapState._centerLocation, AnimationControllers)
            // which causes the map skeleton and route animations to replay
            // every time the user returns to this tab.
            return Offstage(
              offstage: !isActive && val == 0.0,
              child: IgnorePointer(
                ignoring: !isActive,
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.96 + (0.04 * val), // Snug, premium minor scale transition
                    child: Transform.translate(
                      offset: Offset(0.0, 12.0 * (1.0 - val)), // Light 12px float lift
                      child: child,
                    ),
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


class SwipeDismissibleToast extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismissed;

  const SwipeDismissibleToast({
    super.key,
    required this.child,
    required this.onDismissed,
  });

  @override
  State<SwipeDismissibleToast> createState() => _SwipeDismissibleToastState();
}

class _SwipeDismissibleToastState extends State<SwipeDismissibleToast>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: _opacity,
      child: Transform.translate(
        offset: _dragOffset,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _dragOffset += details.delta;
              // Fade out slightly as user drags further away
              final double distance = _dragOffset.dx.abs().clamp(0.0, 150.0) +
                  _dragOffset.dy.abs().clamp(0.0, 150.0);
              _opacity = (1.0 - (distance / 300.0)).clamp(0.2, 1.0);
            });
          },
          onPanEnd: (details) {
            final double velocityX = details.velocity.pixelsPerSecond.dx;
            final double velocityY = details.velocity.pixelsPerSecond.dy;

            // Dismiss if swiped left, right, or up
            final bool dismissedLeft = _dragOffset.dx < -100 || velocityX < -800;
            final bool dismissedRight = _dragOffset.dx > 100 || velocityX > 800;
            final bool dismissedUp = _dragOffset.dy < -80 || velocityY < -600;

            if (dismissedLeft || dismissedRight || dismissedUp) {
              setState(() {
                _opacity = 0.0;
                // Translate off-screen in the main drag direction
                if (dismissedUp && _dragOffset.dy.abs() > _dragOffset.dx.abs()) {
                  _dragOffset = Offset(_dragOffset.dx, -400);
                } else if (_dragOffset.dx > 0) {
                  _dragOffset = Offset(500, _dragOffset.dy);
                } else {
                  _dragOffset = Offset(-500, _dragOffset.dy);
                }
              });
              Future.delayed(const Duration(milliseconds: 150), widget.onDismissed);
            } else {
              // Snap back
              setState(() {
                _dragOffset = Offset.zero;
                _opacity = 1.0;
              });
            }
          },
          child: widget.child,
        ),
      ),
    );
  }
}

