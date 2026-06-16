import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/features/user/application/user_provider.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;
import 'bus_tab_components/bus_search_bar.dart';
import 'bus_tab_components/bus_list_card.dart';
import 'bus_tab_components/bus_empty_state.dart';
import 'package:collegebus/shared/widgets/shimmer_skeletons.dart';

import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';

class BusNumbersTab extends ConsumerStatefulWidget {
  const BusNumbersTab({super.key});

  @override
  ConsumerState<BusNumbersTab> createState() => _BusNumbersTabState();
}

class _BusNumbersTabState extends ConsumerState<BusNumbersTab>
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

                if (busNumber.isEmpty) return;

                final user = ref.read(currentUserProvider);
                final collegeId = user?.collegeId;

                if (collegeId != null) {
                  await ref
                      .read(collegeRepositoryProvider)
                      .addBusNumber(collegeId, busNumber);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  // Refresh is automatic
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;

    if (collegeId == null) return const SizedBox.shrink();

    final busNumbersAsync = ref.watch(busNumbersProvider(collegeId));
    final busesAsync = ref.watch(allCollegeBusesStreamProvider(collegeId));
    final allDriversAsync = ref.watch(
      usersByRoleProvider((
        role: UserRole.driver,
        collegeId: collegeId,
      )),
    );

    if (busNumbersAsync.isLoading || busesAsync.isLoading || allDriversAsync.isLoading) {
      return const BusListSkeleton();
    }

    if (busNumbersAsync.hasError || busesAsync.hasError || allDriversAsync.hasError) {
      final error = busNumbersAsync.error ?? busesAsync.error ?? allDriversAsync.error;
      return Center(child: Text('Error loading buses: $error'));
    }

    final busNumbers = busNumbersAsync.value ?? [];
    final buses = busesAsync.value ?? [];
    final allDrivers = allDriversAsync.value ?? [];

    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest, // Semantic color token
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    isScrollable: false,
                    labelColor: Colors.white,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                      _buildBusList('all', busNumbers, buses, allDrivers),
                      _buildBusList('free', busNumbers, buses, allDrivers),
                      _buildBusList('running', busNumbers, buses, allDrivers),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: CurvedBottomNavBar.clearance(context) + AppSizes.paddingMedium,
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

  Widget _buildBusList(
    String category,
    List<String> busNumbers,
    List<BusModel> buses,
    List<UserModel> allDrivers,
  ) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    // 1. Get all base numbers
    final Set<String> allNumbers = busNumbers.toSet();
    for (final bus in buses) {
      allNumbers.add(bus.busNumber);
    }
    List<String> displayNumbers = allNumbers.toList()..sort();

    // 2. Filter by category
    if (category == 'free') {
      displayNumbers = displayNumbers.where((busNumber) {
        final assignedBus = buses.firstWhere(
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
        final assignedBus = buses.firstWhere(
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
        bottom: 16,
        top: 8,
      ),
      itemCount: displayNumbers.length + 1,
      itemBuilder: (context, index) {
        if (index == displayNumbers.length) {
          return const BottomNavSpacer();
        }
        final busNumber = displayNumbers[index];
        final isOfficial = busNumbers.contains(busNumber);
        final assignedBus = buses.firstWhere(
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
            assignedDriver = allDrivers.firstWhere(
              (d) => d.id == assignedBus.driverId,
            );
          } catch (_) {
            assignedDriver = null;
          }
        }

        return BusListCard(
          key: ValueKey(busNumber),
          busNumber: busNumber,
          isOfficial: isOfficial,
          assignedBus: assignedBus,
          assignedDriver: assignedDriver,
          onTap: () async {
            await context.push('/coordinator/assign-driver/$busNumber');
          },
          onHistory: () {
            _focusNode.unfocus();
            context.push(
              '/coordinator/assignment-history/${assignedBus.id}/$busNumber',
            );
          },
          onEdit: () async {
            _focusNode.unfocus();
            await context.push(
              '/coordinator/edit-bus/$busNumber',
              extra: isAssigned ? assignedBus : null,
            );
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
              final user = ref.read(currentUserProvider);
              final collegeId = user?.collegeId;

              if (collegeId != null) {
                // If there is an associated Bus document (even if unassigned), delete it too
                if (isAssigned) {
                  await ref
                      .read(busRepositoryProvider)
                      .deleteBus(assignedBus.id);
                }

                await ref
                    .read(collegeRepositoryProvider)
                    .removeBusNumber(collegeId, busNumber);
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
