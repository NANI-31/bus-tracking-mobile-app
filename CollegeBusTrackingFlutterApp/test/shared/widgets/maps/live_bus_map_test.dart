import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:collegebus/shared/widgets/maps/live_bus_map.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/widgets/common/common_map_view.dart';
import 'package:collegebus/features/bus/services/location_service.dart';
import 'package:collegebus/features/college/application/college_provider.dart';
import '../../../test_helpers.dart';

class MockUserModel extends Mock implements UserModel {}
class MockBusLocationModel extends Mock implements BusLocationModel {}
class MockLocationService extends Mock implements LocationService {}

void main() {
  late MockUserModel mockUser;
  late MockLocationService mockLocationService;
  
  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
    mockPlatformViews();
  });

  setUp(() {
    mockUser = MockUserModel();
    mockLocationService = MockLocationService();
    when(() => mockUser.collegeId).thenReturn('college_123');
    when(() => mockUser.id).thenReturn('user_123');
    when(() => mockLocationService.getCurrentLocation())
        .thenAnswer((_) async => const LatLng(17.385, 78.4867));
  });

  Widget createWidgetUnderTest({
    required List<BusModel> buses,
    Stream<List<BusLocationModel>>? locationStream,
  }) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(mockUser),
        locationServiceProvider.overrideWithValue(mockLocationService),
        if (locationStream != null)
          collegeBusLocationsProvider('college_123').overrideWith((ref) => locationStream),
        mapStyleProvider.overrideWith((ref) => Future.value('[]')),
        themeServiceProvider.overrideWith(() => MockThemeNotifier()),
        localeServiceProvider.overrideWith(() => MockLocaleNotifier()),
        collegeServiceProvider.overrideWith(() => MockCollegeNotifier()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: LiveBusMap(
            buses: buses,
            showUserLocation: false,
          ),
        ),
      ),
    );
  }

  testWidgets('LiveBusMap renders CommonMapView when location is initialized', (WidgetTester tester) async {
    final buses = [
      BusModel(
        id: 'bus_1',
        busNumber: '101',
        driverId: 'driver_1',
        collegeId: 'college_123',
        status: 'on-time',
        assignmentStatus: 'accepted',
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(createWidgetUnderTest(
      buses: buses,
      locationStream: Stream.value([]),
    ));

    // Initially might show loader
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for Future to complete and rebuild
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // Verify CommonMapView
    expect(find.byType(CommonMapView), findsOneWidget);
  });

  testWidgets('LiveBusMap rebuilds markers when location updates arrive', (WidgetTester tester) async {
    final buses = [
      BusModel(
        id: 'bus_1',
        busNumber: '101',
        driverId: 'driver_1',
        collegeId: 'college_123',
        status: 'on-time',
        assignmentStatus: 'accepted',
        createdAt: DateTime.now(),
      ),
    ];

    final locationUpdate = BusLocationModel(
      busId: 'bus_1',
      currentLocation: const LatLng(17.385, 78.4867),
      timestamp: DateTime.now(),
      heading: 90.0,
    );

    final streamController = StreamController<List<BusLocationModel>>();

    await tester.pumpWidget(createWidgetUnderTest(
      buses: buses,
      locationStream: streamController.stream,
    ));

    await tester.pumpAndSettle();

    // Push location update
    await tester.runAsync(() async {
      streamController.add([locationUpdate]);
      
      // Wait for Riverpod and listener
      await Future.delayed(const Duration(milliseconds: 100));
    });

    // Advance enough frames to let animation and setState execute
    await tester.pump(); 
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify CommonMapView updated its markers.
    final commonMapViewFinder = find.byType(CommonMapView);
    expect(commonMapViewFinder, findsOneWidget);
    
    final commonMapView = tester.widget<CommonMapView>(commonMapViewFinder);
    expect(commonMapView.markers.length, 1);
    expect(commonMapView.markers.first.markerId.value, 'bus_1');

    await streamController.close();
  });
}
