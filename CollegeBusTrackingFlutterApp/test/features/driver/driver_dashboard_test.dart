import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:collegebus/features/driver/presentation/driver_dashboard.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/core/services/socket_service.dart';
import 'package:collegebus/features/bus/services/location_service.dart';
import 'package:collegebus/features/bus/data/bus_repository.dart';
import 'package:collegebus/features/route/data/route_repository.dart';
import 'package:collegebus/features/college/application/college_provider.dart';
import 'package:collegebus/l10n/driver/app_localizations.dart';
import 'package:collegebus/l10n/common/app_localizations.dart';
import 'package:collegebus/core/constants/constants.dart';
import '../../test_helpers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MockUserModel extends Mock implements UserModel {}
class MockSocketService extends Mock implements SocketService {}
class MockLocationService extends Mock implements LocationService {}
class MockBusRepository extends Mock implements BusRepository {}
class MockRouteRepository extends Mock implements RouteRepository {}

void main() {
  late MockUserModel mockUser;
  late MockSocketService mockSocketService;
  late MockLocationService mockLocationService;
  late MockBusRepository mockBusRepository;
  late MockRouteRepository mockRouteRepository;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    mockPlatformViews();
  });

  setUp(() {
    mockUser = MockUserModel();
    mockSocketService = MockSocketService();
    mockLocationService = MockLocationService();
    mockBusRepository = MockBusRepository();
    mockRouteRepository = MockRouteRepository();

    when(() => mockUser.id).thenReturn('driver_123');
    when(() => mockUser.fullName).thenReturn('Test Driver');
    when(() => mockUser.collegeId).thenReturn('college_123');
    when(() => mockUser.role).thenReturn(UserRole.driver);
    when(() => mockUser.isPremium).thenReturn(false);
    when(() => mockUser.hasActivePremium).thenReturn(false);
    when(() => mockUser.email).thenReturn('driver@test.com');
    when(() => mockUser.language).thenReturn('en');

    when(() => mockSocketService.isConnected).thenReturn(true);
    when(() => mockSocketService.isConnecting).thenReturn(false);
    when(() => mockSocketService.joinCollege(any())).thenReturn(null);
    when(() => mockSocketService.ensureConnected()).thenReturn(null);

    when(() => mockLocationService.getCurrentLocation())
        .thenAnswer((_) async => const LatLng(17.385, 78.4867));
    when(() => mockLocationService.checkLocationPermission())
        .thenAnswer((_) async => true);
    
    // Mocking streams
    when(() => mockSocketService.busListUpdateStream).thenAnswer((_) => const Stream.empty());
    when(() => mockSocketService.busUpdateStream).thenAnswer((_) => const Stream.empty());
    when(() => mockSocketService.notificationStream).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(mockUser),
        socketServiceProvider.overrideWith((ref) => mockSocketService),
        locationServiceProvider.overrideWithValue(mockLocationService),
        busRepositoryProvider.overrideWithValue(mockBusRepository),
        routeRepositoryProvider.overrideWithValue(mockRouteRepository),
        collegeServiceProvider.overrideWith(() => MockCollegeNotifier()),
        themeServiceProvider.overrideWith(() => MockThemeNotifier()),
        // Override the family providers
        driverBusProvider('driver_123').overrideWith((ref) => Stream.value(null)),
        collegeRoutesProvider('college_123').overrideWith((ref) => Stream.value([])),
        busNumbersProvider('college_123').overrideWith((ref) => Stream.value([])),
        localeServiceProvider.overrideWith(() => MockLocaleNotifier()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          ...DriverLocalizations.localizationsDelegates,
          ...CommonLocalizations.localizationsDelegates,
        ],
        supportedLocales: [
          ...DriverLocalizations.supportedLocales,
          ...CommonLocalizations.supportedLocales,
        ],
        home: DriverDashboard(),
      ),
    );
  }

  testWidgets('DriverDashboard renders welcome message and setup tab initially', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Initial build
    await tester.pump(const Duration(milliseconds: 100)); // Wait for any async init

    expect(find.textContaining('Welcome, Test Driver'), findsOneWidget);
    expect(find.text('Bus Setup'), findsOneWidget);
  });

  testWidgets('DriverDashboard shows bus assignment card when bus is assigned', (WidgetTester tester) async {
    final myBus = BusModel(
      id: 'bus_1',
      busNumber: '555',
      driverId: 'driver_123',
      collegeId: 'college_123',
      assignmentStatus: 'pending',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(mockUser),
        socketServiceProvider.overrideWith((ref) => mockSocketService),
        locationServiceProvider.overrideWithValue(mockLocationService),
        busRepositoryProvider.overrideWithValue(mockBusRepository),
        routeRepositoryProvider.overrideWithValue(mockRouteRepository),
        collegeServiceProvider.overrideWith(() => MockCollegeNotifier()),
        themeServiceProvider.overrideWith(() => MockThemeNotifier()),
        driverBusProvider('driver_123').overrideWith((ref) => Stream.value(myBus)),
        collegeRoutesProvider('college_123').overrideWith((ref) => Stream.value([])),
        busNumbersProvider('college_123').overrideWith((ref) => Stream.value(['555'])),
        localeServiceProvider.overrideWith(() => MockLocaleNotifier()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          ...DriverLocalizations.localizationsDelegates,
          ...CommonLocalizations.localizationsDelegates,
        ],
        supportedLocales: [
          ...DriverLocalizations.supportedLocales,
          ...CommonLocalizations.supportedLocales,
        ],
        home: DriverDashboard(),
      ),
    ));

    await tester.pump(); // Initial build
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('New Trip Assignment'), findsOneWidget);
    expect(find.text('555'), findsOneWidget);
    expect(find.text('START TRIP'), findsOneWidget); 
    expect(find.text('Decline'), findsOneWidget);
  });
}
