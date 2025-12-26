import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'bus_tab_components/bus_search_bar.dart';
import 'bus_tab_components/bus_list_card.dart';
import 'bus_tab_components/bus_empty_state.dart';

class BusNumbersTab extends StatefulWidget {
  final List<String> busNumbers;
  final List<BusModel> buses;
  final Function() onRefresh;
  final List<UserModel> allDrivers;

  const BusNumbersTab({
    super.key,
    required this.busNumbers,
    required this.buses,
    required this.onRefresh,
    required this.allDrivers,
  });

  @override
  State<BusNumbersTab> createState() => _BusNumbersTabState();
}

class _BusNumbersTabState extends State<BusNumbersTab>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    final bottomInset = View.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0.0;

    if (_isKeyboardVisible && !isKeyboardOpen) {
      _focusNode.unfocus();
    }

    _isKeyboardVisible = isKeyboardOpen;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _showCreateBusNumberDialog(BuildContext context) {
    final TextEditingController busNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Bus Number'),
          content: TextField(
            controller: busNumberController,
            decoration: const InputDecoration(
              labelText: 'Bus Number',
              hintText: 'e.g., KA-01-AB-1234',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final busNumber = busNumberController.text.trim();
                if (busNumber.isEmpty) return;

                final authService = Provider.of<AuthService>(
                  context,
                  listen: false,
                );
                final firestoreService = Provider.of<DataService>(
                  context,
                  listen: false,
                );
                final collegeId = authService.currentUserModel?.collegeId;

                if (collegeId != null) {
                  await firestoreService.addBusNumber(collegeId, busNumber);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  widget.onRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bus number $busNumber added successfully'),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  List<String> get _allDisplayNumbers {
    final Set<String> numbers = widget.busNumbers.toSet();
    for (final bus in widget.buses) {
      numbers.add(bus.busNumber);
    }
    final sorted = numbers.toList();
    sorted.sort();

    if (_searchQuery.isEmpty) {
      return sorted;
    }

    return sorted
        .where(
          (number) => number.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayNumbers = _allDisplayNumbers;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          VStack([
            // Search Bar Component
            BusSearchBar(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              onClear: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              searchQuery: _searchQuery,
            ),

            Expanded(
              child: displayNumbers.isEmpty
                  ? BusEmptyState(
                      isSearching: _searchQuery.isNotEmpty,
                      searchQuery: _searchQuery,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: AppSizes.paddingMedium,
                        right: AppSizes.paddingMedium,
                        bottom: 80, // Add padding for FAB
                        top: 8,
                      ),
                      itemCount: displayNumbers.length,
                      itemBuilder: (context, index) {
                        final busNumber = displayNumbers[index];
                        final isOfficial = widget.busNumbers.contains(
                          busNumber,
                        );
                        final assignedBus = widget.buses.firstWhere(
                          (bus) => bus.busNumber == busNumber,
                          orElse: () => BusModel(
                            id: '',
                            busNumber: '',
                            driverId: '',
                            collegeId: '',
                            isActive: false,
                            createdAt: DateTime.now(),
                          ),
                        );
                        final isAssigned = assignedBus.id.isNotEmpty;

                        final hasDriver =
                            isAssigned && assignedBus.driverId.isNotEmpty;

                        UserModel? assignedDriver;
                        if (hasDriver) {
                          try {
                            assignedDriver = widget.allDrivers.firstWhere(
                              (d) => d.id == assignedBus.driverId,
                            );
                          } catch (_) {
                            assignedDriver = null;
                          }
                        }

                        return BusListCard(
                          busNumber: busNumber,
                          isOfficial: isOfficial,
                          assignedBus: assignedBus,
                          assignedDriver: assignedDriver,
                          onTap: () async {
                            await context.push(
                              '/coordinator/assign-driver/$busNumber',
                            );
                            widget.onRefresh();
                          },
                          onHistory: () {
                            _focusNode.unfocus();
                            context.push(
                              '/coordinator/assignment-history/${assignedBus.id}/$busNumber',
                            );
                          },
                          onDelete: () async {
                            if (isAssigned) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Cannot delete assigned bus number',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Bus Number'),
                                content: Text(
                                  'Are you sure you want to delete $busNumber?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              if (!context.mounted) return;
                              final authService = Provider.of<AuthService>(
                                context,
                                listen: false,
                              );
                              final firestoreService = Provider.of<DataService>(
                                context,
                                listen: false,
                              );
                              final collegeId =
                                  authService.currentUserModel?.collegeId;

                              if (collegeId != null) {
                                await firestoreService.removeBusNumber(
                                  collegeId,
                                  busNumber,
                                );
                                widget.onRefresh();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Bus number $busNumber deleted',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
            ),
          ]),
          Positioned(
            bottom: AppSizes.paddingMedium,
            right: AppSizes.paddingMedium,
            child: FloatingActionButton(
              onPressed: () => _showCreateBusNumberDialog(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
