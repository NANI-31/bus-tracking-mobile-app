import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/super_admin/application/super_admin_provider.dart';
import 'package:collegebus/core/presentation/widgets/shared_transactions_tab.dart';

class TransactionsTab extends ConsumerWidget {
  const TransactionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(superAdminServiceProvider);
    
    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(child: Text('Error: $error')),
      data: (state) {
        return SharedTransactionsTab(
          transactions: state.transactions,
          isLoading: asyncState.isLoading,
          hasMore: state.transactionsHasMore,
          onLoadMore: () {
            ref.read(superAdminServiceProvider.notifier).fetchTransactions(isLoadMore: true);
          },
          onFilterChanged: (plan, dateRange) {
            ref.read(superAdminServiceProvider.notifier).fetchTransactions(
              plan: plan,
              startDate: dateRange?.start,
              endDate: dateRange?.end,
              isLoadMore: false,
            );
          },
        );
      },
    );
  }
}
