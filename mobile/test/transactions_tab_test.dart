import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/super_admin/presentation/tabs/transactions_tab.dart';
import 'package:collegebus/features/payment/domain/transaction_model.dart';
import 'package:collegebus/features/super_admin/services/super_admin_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSuperAdminService extends Mock implements SuperAdminService {}

void main() {
  late MockSuperAdminService mockService;

  setUp(() {
    mockService = MockSuperAdminService();
    // Default mock behavior
    when(
      () => mockService.fetchTransactions(
        plan: any(named: 'plan'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [superAdminServiceProvider.overrideWith((ref) => mockService)],
      child: MaterialApp(
        home: Scaffold(body: TransactionsTab()),
      ),
    );
  }



  testWidgets('TransactionsTab shows filter panel when toggle is pressed', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Initially filter panel is not visible
    expect(find.text('Filter by Plan'), findsNothing);

    // Press filter toggle button
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    // Now filter panel should be visible
    expect(find.text('Filter by Plan'), findsOneWidget);
    expect(find.text('Filter by Date'), findsOneWidget);
  });

  testWidgets('TransactionsTab calls fetchTransactions when plan is selected', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Expand filters
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    // Tap on 'Monthly' chip
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();

    // Verify service method was called
    verify(
      () => mockService.fetchTransactions(
        plan: 'monthly',
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).called(1);
  });
}
