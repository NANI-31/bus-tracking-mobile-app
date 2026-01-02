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
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;

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

  void _showRenameBusNumberDialog(BuildContext context, String oldBusNumber) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    final TextEditingController busNumberController = TextEditingController(
      text: oldBusNumber,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Bus Number'),
          content: TextField(
            controller: busNumberController,
            decoration: InputDecoration(
              labelText: l10n.busNumber,
              hintText: l10n.enterBusNumber,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final newBusNumber = busNumberController.text.trim();
                if (newBusNumber.isEmpty || newBusNumber == oldBusNumber)
                  return;

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
                  await firestoreService.renameBusNumber(
                    collegeId,
                    oldBusNumber,
                    newBusNumber,
                  );
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  widget.onRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bus renamed to $newBusNumber'),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  );
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  void _showCreateBusNumberDialog(BuildContext context) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    final TextEditingController busNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addBusNumber),
          content: TextField(
            controller: busNumberController,
            decoration: InputDecoration(
              labelText: l10n.busNumber,
              hintText: l10n.enterBusNumber,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
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
                      content: Text(l10n.busAddedSuccess(busNumber)),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  );
                }
              },
              child: Text(l10n.add),
            ),
          ],
        );
      },
    );
  }

  void _showEditDriverNameDialog(BuildContext context, UserModel driver) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    final TextEditingController nameController = TextEditingController(
      text: driver.fullName,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Driver Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Enter driver name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty || newName == driver.fullName) return;

                final firestoreService = Provider.of<DataService>(
                  context,
                  listen: false,
                );

                try {
                  await firestoreService.updateUser(driver.id, {
                    'fullName': newName,
                  });
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  widget.onRefresh(); // Refresh list to show new name
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Driver name updated to $newName')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update name: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get l10n
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            VStack([
              // Search Bar Component
              BusSearchBar(
                controller: _searchController,
                focusNode: _focusNode,
                hintText: l10n.search,
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

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMedium,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF2C3E50,
                  ), // Dark background for the capsule
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  isScrollable: false,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade400,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    Tab(text: l10n.all),
                    Tab(text: l10n.free),
                    Tab(text: l10n.running),
                  ],
                ).p4(),
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    _buildBusList('all'),
                    _buildBusList('free'),
                    _buildBusList('running'),
                  ],
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
      ),
    );
  }

  Widget _buildBusList(String category) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    // 1. Get all base numbers
    final Set<String> allNumbers = widget.busNumbers.toSet();
    for (final bus in widget.buses) {
      allNumbers.add(bus.busNumber);
    }
    List<String> displayNumbers = allNumbers.toList()..sort();

    // 2. Filter by category
    if (category == 'free') {
      displayNumbers = displayNumbers.where((busNumber) {
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
        final hasDriver = isAssigned && assignedBus.driverId.isNotEmpty;
        // Free if not assigned OR assigned but status is unassigned
        return !hasDriver || assignedBus.assignmentStatus == 'unassigned';
      }).toList();
    } else if (category == 'running') {
      displayNumbers = displayNumbers.where((busNumber) {
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
        final hasDriver = isAssigned && assignedBus.driverId.isNotEmpty;
        // Running if assigned AND status is NOT unassigned
        return hasDriver && assignedBus.assignmentStatus != 'unassigned';
      }).toList();
    }

    // 3. Filter by search query
    if (_searchQuery.isNotEmpty) {
      displayNumbers = displayNumbers
          .where(
            (number) =>
                number.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // 4. Return list or empty state
    if (displayNumbers.isEmpty) {
      return BusEmptyState(
        isSearching: _searchQuery.isNotEmpty,
        searchQuery: _searchQuery,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: AppSizes.paddingMedium,
        right: AppSizes.paddingMedium,
        bottom: 80,
        top: 8,
      ),
      itemCount: displayNumbers.length,
      itemBuilder: (context, index) {
        final busNumber = displayNumbers[index];
        final isOfficial = widget.busNumbers.contains(busNumber);
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
        final hasDriver = isAssigned && assignedBus.driverId.isNotEmpty;

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
            await context.push('/coordinator/assign-driver/$busNumber');
            widget.onRefresh();
          },
          onHistory: () {
            _focusNode.unfocus();
            context.push(
              '/coordinator/assignment-history/${assignedBus.id}/$busNumber',
            );
          },
          onEdit: () => _showRenameBusNumberDialog(context, busNumber),
          onEditDriver: () {
            if (assignedDriver != null) {
              _showEditDriverNameDialog(context, assignedDriver);
            }
          },
          onDelete: () async {
            // Allow delete if NOT assigned OR (assigned but status is unassigned)
            final canDelete =
                !isAssigned ||
                (isAssigned && assignedBus.assignmentStatus == 'unassigned');

            if (!canDelete) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.cannotDeleteAssigned),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }

            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.deleteBusNumber),
                content: Text(l10n.deleteConfirmation(busNumber)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: Text(l10n.delete),
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
              final collegeId = authService.currentUserModel?.collegeId;

              if (collegeId != null) {
                // If there is an associated Bus document (even if unassigned), delete it too
                if (isAssigned) {
                  await firestoreService.deleteBus(assignedBus.id);
                }

                await firestoreService.removeBusNumber(collegeId, busNumber);
                widget.onRefresh();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.busDeletedSuccess(busNumber)),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}
