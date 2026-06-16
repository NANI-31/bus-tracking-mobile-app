import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:collegebus/features/super_admin/application/super_admin_provider.dart';

class PaymentsTab extends ConsumerStatefulWidget {
  const PaymentsTab({super.key});

  @override
  ConsumerState<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends ConsumerState<PaymentsTab> {
  String _searchQuery = '';
  String? _selectedPlan;
  String? _selectedCollegeId;
  DateTimeRange? _selectedDateRange;
  bool _isFilterExpanded = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(superAdminServiceProvider).valueOrNull;
    if (state == null) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final isLoading = ref.read(superAdminServiceProvider).isLoading;
      if (!isLoading && state.transactionsHasMore) {
        ref.read(superAdminServiceProvider.notifier).fetchTransactions(
              plan: _selectedPlan,
              collegeId: _selectedCollegeId,
              startDate: _selectedDateRange?.start,
              endDate: _selectedDateRange?.end,
              isLoadMore: true,
            );
      }
    }
  }

  void _applyFilters() {
    ref.read(superAdminServiceProvider.notifier).fetchTransactions(
          plan: _selectedPlan,
          collegeId: _selectedCollegeId,
          startDate: _selectedDateRange?.start,
          endDate: _selectedDateRange?.end,
          isLoadMore: false,
        );
  }

  void _resetFilters() {
    setState(() {
      _selectedPlan = null;
      _selectedCollegeId = null;
      _selectedDateRange = null;
      _searchQuery = '';
    });
    _applyFilters();
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Colors.deepPurple,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Colors.deepPurple,
                    onPrimary: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        _selectedDateRange = range;
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncState = ref.watch(superAdminServiceProvider);

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(child: Text('Error: $error')),
      data: (state) {
        final colleges = state.colleges;
        
        // Client-side search filtering on userName, userEmail, or orderId/paymentId
        final filteredTransactions = state.transactions.where((tx) {
          if (_searchQuery.isEmpty) return true;
          final query = _searchQuery.toLowerCase();
          return tx.userName.toLowerCase().contains(query) ||
              tx.userEmail.toLowerCase().contains(query) ||
              tx.orderId.toLowerCase().contains(query) ||
              tx.paymentId.toLowerCase().contains(query);
        }).toList();

        final hasActiveFilters = _selectedPlan != null ||
            _selectedCollegeId != null ||
            _selectedDateRange != null;

        return Column(
          children: [
            // Header Card matching web client
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.public,
                            color: Color(0xFF1E90FF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Global Revenue & Subscriptions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Monitor across ${colleges.length} colleges',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Filter Toggle Chip Button
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isFilterExpanded = !_isFilterExpanded;
                            });
                          },
                          icon: Icon(
                            _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                            size: 16,
                            color: hasActiveFilters ? const Color(0xFF1E90FF) : null,
                          ),
                          label: Row(
                            children: [
                              const Text('Filters', style: TextStyle(fontSize: 12)),
                              if (hasActiveFilters) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E90FF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: hasActiveFilters
                                  ? const Color(0xFF1E90FF)
                                  : (isDark ? Colors.white24 : Colors.grey.shade300),
                            ),
                            backgroundColor: hasActiveFilters
                                ? const Color(0xFF1E90FF).withValues(alpha: 0.08)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Search Text Field
                        Expanded(
                          child: TextField(
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Search user, order...',
                              prefixIcon: const Icon(Icons.search, size: 16),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expanded Filter Panel
            if (_isFilterExpanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subscription Plan Selector
                      const Text(
                        'Subscription Plan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedPlan,
                            hint: const Text('All Plans', style: TextStyle(fontSize: 12)),
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('All Plans', style: TextStyle(fontSize: 12)),
                              ),
                              DropdownMenuItem(
                                value: 'monthly',
                                child: Text('Monthly', style: TextStyle(fontSize: 12)),
                              ),
                              DropdownMenuItem(
                                value: 'semester',
                                child: Text('Semester', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedPlan = val;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // College Selector
                      const Text(
                        'College',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCollegeId,
                            hint: const Text('All Colleges', style: TextStyle(fontSize: 12)),
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Colleges', style: TextStyle(fontSize: 12)),
                              ),
                              ...colleges.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name, style: const TextStyle(fontSize: 12)),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedCollegeId = val;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date Range picker
                      const Text(
                        'Date Filter',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDateRange,
                              icon: const Icon(Icons.date_range, size: 16),
                              label: Text(
                                _selectedDateRange == null
                                    ? 'Select Range'
                                    : '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                          if (hasActiveFilters) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _resetFilters,
                              child: const Text(
                                'Reset All',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Transactions List
            Expanded(
              child: filteredTransactions.isEmpty && !asyncState.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: isDark ? Colors.white10 : Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions found',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters or search query',
                            style: TextStyle(
                              color: isDark ? Colors.white30 : Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredTransactions.length + (state.transactionsHasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= filteredTransactions.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final tx = filteredTransactions[index];
                        final isSemester = tx.plan.toLowerCase() == 'semester';
                        final collegeName = colleges.firstWhereOrNull((c) => c.id == tx.collegeId)?.name ?? 'N/A';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                            ),
                          ),
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User information row
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          tx.userName.isNotEmpty ? tx.userName[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isDark ? Colors.white : Colors.blueGrey.shade800,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'College: $collegeName',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.white38 : Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Status tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: const Text(
                                        'CAPTURED',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),

                                // Subscription Plan and Amount row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'PLAN TYPE',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isSemester
                                                ? Colors.purple.withValues(alpha: 0.15)
                                                : Colors.blue.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            tx.plan.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isSemester ? Colors.purple : Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'AMOUNT',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${tx.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Date details
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'TRANSACTION DATE',
                                          style: TextStyle(fontSize: 9, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('dd MMM, yyyy HH:mm').format(tx.createdAt.toLocal()),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'PREMIUM UNTIL',
                                          style: TextStyle(fontSize: 9, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('dd MMM, yyyy').format(tx.premiumUntil.toLocal()),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Monospace Order and Payment IDs
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order ID: ${tx.orderId}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Payment ID: ${tx.paymentId}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
