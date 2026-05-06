import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collegebus/features/payment/domain/transaction_model.dart';
import 'package:collegebus/features/admin/application/admin_provider.dart';
import 'package:collegebus/features/super_admin/services/super_admin_service.dart';
import 'package:collegebus/core/constants/constants.dart';
// import 'package:velocity_x/velocity_x.dart'; // Removing unused import

class TransactionsTab extends ConsumerStatefulWidget {
  final List<TransactionModel> transactions;

  const TransactionsTab({super.key, required this.transactions});

  @override
  ConsumerState<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<TransactionsTab> {
  String? _selectedPlan;
  DateTimeRange? _selectedDateRange;
  bool _isFilterExpanded = false;

  @override
  Widget build(BuildContext context) {
    final saService = ref.watch(superAdminServiceProvider);

    return Column(
      children: [
        _buildFilterHeader(saService),
        if (_isFilterExpanded) _buildFilterPanel(saService),
        Expanded(
          child: saService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildTransactionList(widget.transactions),
        ),
      ],
    );
  }

  Widget _buildFilterHeader(SuperAdminService saService) {
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
                '${widget.transactions.length} Transactions',
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

  Widget _buildFilterPanel(SuperAdminService saService) {
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
              _buildFilterChip('All', null, saService),
              const SizedBox(width: 8),
              _buildFilterChip('Monthly', 'monthly', saService),
              const SizedBox(width: 8),
              _buildFilterChip('Semester', 'semester', saService),
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
                  onPressed: () => _pickDateRange(saService),
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
                    _fetchData(saService);
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
    SuperAdminService saService,
  ) {
    final isSelected = _selectedPlan == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPlan = value);
          _fetchData(saService);
        }
      },
    );
  }

  Future<void> _pickDateRange(SuperAdminService saService) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
    );

    if (range != null) {
      setState(() => _selectedDateRange = range);
      _fetchData(saService);
    }
  }

  void _fetchData(SuperAdminService saService) {
    saService.fetchTransactions(
      plan: _selectedPlan,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );
  }

  Widget _buildTransactionList(List<TransactionModel> transactions) {
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
            Text(
              'No transactions match your filters',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedPlan = null;
                  _selectedDateRange = null;
                });
                _fetchData(ref.read(superAdminServiceProvider));
              },
              child: const Text('Clear All Filters'),
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
                          fontSize: 14,
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
                            'MMM dd, yyyy HH:mm',
                          ).format(transaction.createdAt.toLocal()),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Valid Until',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy',
                          ).format(transaction.premiumUntil.toLocal()),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Order ID: ${transaction.orderId}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
