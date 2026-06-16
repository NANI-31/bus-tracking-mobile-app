import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final userTransactionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.read(paymentRepositoryProvider);
  return await repo.getTransactions();
});

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(userTransactionsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter logic
    final query = _searchController.text.toLowerCase();
    final transactions = transactionsAsync.value ?? [];
    final filteredTransactions = transactions.where((tx) {
      final paymentId = (tx['paymentId'] ?? '').toString().toLowerCase();
      final plan = (tx['plan'] ?? '').toString().toLowerCase();
      return paymentId.contains(query) || plan.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Search Payment ID or Plan...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text("Transaction History"),
        backgroundColor: isDark ? Colors.transparent : theme.primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
            tooltip: _isSearching ? "Close Search" : "Search",
          ),
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            onPressed: () => _exportToCSV(context, filteredTransactions),
            tooltip: "Export to CSV",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          return ref.refresh(userTransactionsProvider);
        },
        child: transactionsAsync.when(
          data: (_) {
            // Ignore original list, use state filtered list
            if (filteredTransactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 80,
                      color: theme.disabledColor.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No transactions found",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.disabledColor,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTransactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = filteredTransactions[index];
                final date = DateTime.parse(tx['createdAt']).toLocal();
                final amount = tx['amount'];
                final status = (tx['status'] ?? 'captured').toString();
                final plan = (tx['plan'] ?? 'monthly').toString();
                final paymentId = tx['paymentId'] ?? 'N/A';
                final method = (tx['paymentMethod'] ?? 'upi').toString();

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
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
                              color: _getStatusColor(
                                status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(status),
                                  size: 12,
                                  color: _getStatusColor(status),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.disabledColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "₹$amount",
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                "${plan == 'monthly' || plan == 'trial' ? 'Trial' : 'Semester'} Plan",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getPaymentMethodIcon(method),
                              color: theme.primaryColor,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: theme.dividerColor.withValues(alpha: 0.05),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Payment ID",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.disabledColor,
                                  ),
                                ),
                                Text(
                                  paymentId,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (status.toLowerCase() == 'captured' ||
                              status.toLowerCase() == 'success')
                            ElevatedButton(
                              onPressed: () =>
                                  _showRefundDialog(context, ref, tx['_id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: Colors.red,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                visualDensity: VisualDensity.compact,
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text("Refund"),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => _buildSkeletonCard(theme),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text("Error: $err", textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(userTransactionsProvider),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportToCSV(
    BuildContext context,
    List<dynamic> transactions,
  ) async {
    if (transactions.isEmpty) return;

    List<List<dynamic>> rows = [];
    rows.add(["Date", "Amount", "Plan", "Status", "Payment ID"]);

    for (var tx in transactions) {
      rows.add([
        tx['createdAt'],
        tx['amount'],
        tx['plan'],
        tx['status'],
        tx['paymentId'],
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/transactions.csv";
    final file = File(path);
    await file.writeAsString(csv);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'Transaction History',
      ),
    );
  }

  Future<void> _showRefundDialog(
    BuildContext context,
    WidgetRef ref,
    String transactionId,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Request Refund"),
        content: const Text(
          "Are you sure you want to request a refund for this transaction?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repo = ref.read(paymentRepositoryProvider);
                await repo.requestRefund(
                  transactionId,
                  "User requested via app",
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Refund request submitted")),
                  );
                  return ref.refresh(userTransactionsProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("Request"),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'captured':
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
      case 'refund_requested':
        return Colors.orange;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'captured':
      case 'success':
        return Icons.check_circle_rounded;
      case 'failed':
        return Icons.cancel_rounded;
      case 'pending':
      case 'refund_requested':
        return Icons.pending_rounded;
      case 'refunded':
        return Icons.keyboard_return_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return Icons.credit_card_rounded;
      case 'upi':
        return Icons.account_balance_rounded;
      case 'netbanking':
        return Icons.account_balance_wallet_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'emi':
        return Icons.calendar_month_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  Widget _buildSkeletonCard(ThemeData theme) {
    final baseColor = theme.dividerColor.withValues(alpha: 0.1);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: 100,
                height: 16,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 24,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
