import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collegebus/features/payment/domain/transaction_model.dart';
import 'package:collegebus/features/college_admin/services/college_admin_service.dart';
import 'package:collegebus/features/admin/application/admin_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';

class CollegeAdminTransactionsTab extends ConsumerStatefulWidget {
  const CollegeAdminTransactionsTab({super.key});

  @override
  ConsumerState<CollegeAdminTransactionsTab> createState() =>
      _CollegeAdminTransactionsTabState();
}

class _CollegeAdminTransactionsTabState
    extends ConsumerState<CollegeAdminTransactionsTab> {
  String? _selectedPlan;
  DateTimeRange? _selectedDateRange;
  bool _isFilterExpanded = false;

  @override
  Widget build(BuildContext context) {
    final caService = ref.watch(collegeAdminServiceProvider);
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId ?? '';

    return Column(
      children: [
        _buildFilterHeader(caService),
        if (_isFilterExpanded) _buildFilterPanel(caService, collegeId),
        Expanded(
          child: caService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildTransactionList(
                  caService.transactions,
                  caService,
                  collegeId,
                ),
        ),
      ],
    );
  }

  Widget _buildFilterHeader(CollegeAdminService caService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${caService.transactions.length} Subscriptions',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
              color: (_selectedPlan != null || _selectedDateRange != null)
                  ? AppColors.primary
                  : Colors.grey,
            ),
            onPressed: () =>
                setState(() => _isFilterExpanded = !_isFilterExpanded),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(CollegeAdminService caService, String collegeId) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Plan',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFilterChip('All', null, caService, collegeId),
              const SizedBox(width: 8),
              _buildFilterChip('Monthly', 'monthly', caService, collegeId),
              const SizedBox(width: 8),
              _buildFilterChip('Semester', 'semester', caService, collegeId),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Filter by Date',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDateRange(caService, collegeId),
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Select Range'
                        : '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (_selectedDateRange != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() => _selectedDateRange = null);
                    _fetchData(caService, collegeId);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? value,
    CollegeAdminService caService,
    String collegeId,
  ) {
    final isSelected = _selectedPlan == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPlan = value);
          _fetchData(caService, collegeId);
        }
      },
    );
  }

  Future<void> _pickDateRange(
    CollegeAdminService caService,
    String collegeId,
  ) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
    );

    if (range != null) {
      setState(() => _selectedDateRange = range);
      _fetchData(caService, collegeId);
    }
  }

  void _fetchData(CollegeAdminService caService, String collegeId) {
    caService.fetchTransactions(
      collegeId: collegeId,
      plan: _selectedPlan,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );
  }

  Widget _buildTransactionList(
    List<TransactionModel> transactions,
    CollegeAdminService caService,
    String collegeId,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No subscriptions found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (_selectedPlan != null || _selectedDateRange != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedPlan = null;
                    _selectedDateRange = null;
                  });
                  _fetchData(caService, collegeId);
                },
                child: const Text('Clear Filters'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isSemester = transaction.plan == 'semester';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSemester
                            ? Colors.amber.shade100
                            : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        transaction.plan.toUpperCase(),
                        style: TextStyle(
                          color: isSemester
                              ? Colors.amber.shade900
                              : Colors.blue.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '₹${transaction.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                if (transaction.userEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        transaction.userEmail,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy',
                          ).format(transaction.createdAt),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Valid Until',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy',
                          ).format(transaction.premiumUntil),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
