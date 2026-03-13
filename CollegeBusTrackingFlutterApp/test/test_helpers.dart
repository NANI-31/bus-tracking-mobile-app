import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:collegebus/core/services/theme_service.dart';
import 'package:collegebus/core/providers/service_providers.dart';
import 'package:collegebus/features/college/application/college_provider.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mocks the platform views channel to prevent MissingPluginException
/// when widgets like GoogleMap are used in widget tests.
void mockPlatformViews() {
  const MethodChannel channel = MethodChannel('flutter/platform_views');
  
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'create':
        return 0;
      case 'init':
      case 'update':
      case 'dispose':
        return null;
      default:
        return null;
    }
  });
}

/// A stable mock for ThemeNotifier that avoids SharedPreferences
class MockThemeNotifier extends ThemeNotifier {
  @override
  ThemeState build() => const ThemeState();
}

/// A stable mock for LocaleNotifier extends LocaleNotifier
class MockLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('en');
}

/// A stable mock for CollegeNotifier
class MockCollegeNotifier extends CollegeNotifier {
  @override
  Future<List<CollegeModel>> build() async => [
    CollegeModel(
      id: 'college_123',
      name: 'Test College',
      allowedDomains: ['test.edu'],
      createdBy: 'admin_1',
      createdAt: DateTime.now(),
    ),
  ];
}
