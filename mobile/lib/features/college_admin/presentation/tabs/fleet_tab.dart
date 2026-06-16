import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/college_admin/application/college_admin_provider.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/core/utils/app_logger.dart';

class FleetTab extends ConsumerStatefulWidget {
  const FleetTab({super.key});

  @override
  ConsumerState<FleetTab> createState() => _FleetTabState();
}

class _FleetTabState extends ConsumerState<FleetTab> {
  String _searchQuery = '';
  final Set<String> _selectedStatuses = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddBusDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AddBusDialog(),
    );
  }

  void _confirmDeleteBus(String busId, String busNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Bus $busNumber'),
        content: const Text(
          'Are you sure you want to remove this bus from the fleet? This action cannot be undone.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(collegeAdminServiceProvider.notifier).deleteBus(busId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Bus $busNumber removed successfully.')),
                  );
                }
              } catch (e) {
                AppLogger.e('Failed to delete bus: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to remove bus: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(collegeAdminServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF00C6E6) : const Color(0xFF0097B2);

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (state) {
        final buses = state.collegeBuses;

        // Filtering
        final filteredBuses = buses.where((bus) {
          final matchesSearch = bus.busNumber.toLowerCase().contains(_searchQuery.toLowerCase());
          if (_selectedStatuses.isNotEmpty) {
            bool matchesAnyStatus = false;
            for (final status in _selectedStatuses) {
              if (status == 'active' && (bus.status == 'on-time' || bus.status == 'active')) {
                matchesAnyStatus = true;
              } else if (bus.status == status) {
                matchesAnyStatus = true;
              }
            }
            if (!matchesAnyStatus) return false;
          }
          return matchesSearch;
        }).toList();

        // Statistics
        final totalBuses = buses.length;
        final activeBuses = buses.where((b) => b.status == 'on-time' || b.status == 'active').length;
        final totalCapacity = buses.fold<int>(0, (sum, b) => sum + (b.capacity ?? 40));

        // Screen width check for responsive columns
        final screenWidth = MediaQuery.of(context).size.width;
        final int crossAxisCount = screenWidth > 600 ? 2 : 1;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            onRefresh: () async {
              if (state.college?.id != null) {
                await ref.read(collegeAdminServiceProvider.notifier).loadCollegeDashboard(state.college!.id);
              }
            },
            color: primaryColor,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // Header block
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Control Center: Fleet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Monitor, deploy, and maintain transit buses.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openAddBusDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Bus', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search & Filters Panel
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [Colors.white, const Color(0xFFF8FAFC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search bus number...',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: 20,
                                  color: isDark ? const Color(0xFF00C6E6) : const Color(0xFF0097B2),
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            _searchQuery = '';
                                            _searchController.clear();
                                          });
                                        },
                                      )
                                    : null,
                                isDense: true,
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                    : Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16)),
                                  borderSide: BorderSide(
                                    color: Color(0xFF00C6E6),
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() => _searchQuery = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Filter trigger button
                          GestureDetector(
                            onTap: () async {
                              final result = await showModalBottomSheet<Set<String>>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => _FleetFilterBottomSheet(
                                  initialSelectedStatuses: _selectedStatuses,
                                ),
                              );

                              if (result != null) {
                                setState(() {
                                  _selectedStatuses.clear();
                                  _selectedStatuses.addAll(result);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: _selectedStatuses.isNotEmpty
                                    ? (isDark
                                        ? const Color(0xFF00C6E6).withValues(alpha: 0.15)
                                        : const Color(0xFF0097B2).withValues(alpha: 0.08))
                                    : (isDark
                                        ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                        : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedStatuses.isNotEmpty
                                      ? (isDark
                                          ? const Color(0xFF00C6E6).withValues(alpha: 0.4)
                                          : const Color(0xFF0097B2).withValues(alpha: 0.2))
                                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                                ),
                              ),
                              child: Badge(
                                isLabelVisible: _selectedStatuses.isNotEmpty,
                                label: Text(
                                  '${_selectedStatuses.length}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: Colors.red,
                                alignment: const Alignment(1.3, -1.3),
                                child: Icon(
                                  Icons.filter_list_rounded,
                                  size: 20,
                                  color: _selectedStatuses.isNotEmpty
                                      ? (isDark ? const Color(0xFF00C6E6) : const Color(0xFF0097B2))
                                      : (isDark ? Colors.white60 : Colors.black54),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Dismissible Filter Chips Display
                      if (_selectedStatuses.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Filters: ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ..._selectedStatuses.map((status) => Padding(
                                      padding: const EdgeInsets.only(right: 6.0),
                                      child: _buildActiveFilterChip(
                                        label: status == 'active'
                                            ? 'Active'
                                            : status == 'delayed'
                                                ? 'Delayed'
                                                : 'Not Running',
                                        onClear: () {
                                          setState(() => _selectedStatuses.remove(status));
                                        },
                                        isDark: isDark,
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Analytics Stats Grid
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: screenWidth > 600 ? 2.2 : 1.0,
                  children: [
                    _buildStatCard(
                      'TOTAL FLEET',
                      totalBuses.toString(),
                      Icons.directions_bus_outlined,
                      primaryColor.withValues(alpha: 0.12),
                      primaryColor,
                      isDark,
                    ),
                    _buildStatCard(
                      'IN-SERVICE',
                      activeBuses.toString(),
                      Icons.check_circle_outline_rounded,
                      const Color(0xFF10B981).withValues(alpha: 0.12),
                      const Color(0xFF10B981),
                      isDark,
                    ),
                    _buildStatCard(
                      'CAPACITY',
                      '$totalCapacity Seats',
                      Icons.bar_chart_rounded,
                      const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      const Color(0xFF8B5CF6),
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Fleet List Grid
                filteredBuses.isEmpty
                    ? _buildEmptyState(isDark)
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 175,
                        ),
                        itemCount: filteredBuses.length,
                        itemBuilder: (context, index) {
                          final bus = filteredBuses[index];
                          return _buildBusCard(bus, isDark, primaryColor);
                        },
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgOpacityColor,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgOpacityColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(BusModel bus, bool isDark, Color primaryColor) {
    final bool isOnline = bus.status == 'on-time' || bus.status == 'active';
    final bool isDelayed = bus.status == 'delayed';

    final Color statusColor = isOnline
        ? const Color(0xFF10B981)
        : isDelayed
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    final String statusText = bus.status.replaceAll('-', ' ').toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 6,
              child: Container(color: statusColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                            ),
                            child: Icon(Icons.directions_bus_outlined, color: primaryColor, size: 24),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: LiveStatusDot(color: statusColor),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _confirmDeleteBus(bus.id, bus.busNumber),
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bus ${bus.busNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Vehicle ID: ${bus.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  const Divider(height: 12, thickness: 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Occupancy: ${bus.capacity ?? 40} Seats',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onClear,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded, size: 13, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 64,
            color: isDark ? Colors.white10 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Fleet Vehicles Matched',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria or register a new bus to the fleet.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
                _selectedStatuses.clear();
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset All Filters', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveStatusDot extends StatefulWidget {
  final Color color;
  const LiveStatusDot({super.key, required this.color});

  @override
  State<LiveStatusDot> createState() => _LiveStatusDotState();
}

class _LiveStatusDotState extends State<LiveStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14 + (10 * _controller.value),
              height: 14 + (10 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.25 * (1.0 - _controller.value)),
              ),
            ),
            Container(
              width: 10 + (4 * _controller.value),
              height: 10 + (4 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.4 * (1.0 - _controller.value)),
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AddBusDialog extends ConsumerStatefulWidget {
  const _AddBusDialog();

  @override
  ConsumerState<_AddBusDialog> createState() => _AddBusDialogState();
}

class _AddBusDialogState extends ConsumerState<_AddBusDialog> {
  final _formKey = GlobalKey<FormState>();
  final _busNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _busNumberController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final collegeId = ref.read(currentUserProvider)?.collegeId ?? '';

    final newBus = BusModel(
      id: '',
      busNumber: _busNumberController.text.trim(),
      capacity: int.parse(_capacityController.text.trim()),
      driverId: '',
      collegeId: collegeId,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(collegeAdminServiceProvider.notifier).addBus(newBus);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bus ${newBus.busNumber} added successfully.')),
        );
      }
    } catch (e) {
      AppLogger.e('Failed to add bus: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add bus: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF00C6E6) : const Color(0xFF0097B2);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Add New Bus', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _busNumberController,
              decoration: InputDecoration(
                labelText: 'Bus Number',
                hintText: 'e.g. BUS-402',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Bus number is required.';
                }
                if (!RegExp(r'^[A-Z0-9-]{3,10}$', caseSensitive: false).hasMatch(val.trim())) {
                  return 'Must be 3-10 alphanumeric characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Capacity (Seats)',
                hintText: 'e.g. 40',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Capacity is required.';
                }
                final seats = int.tryParse(val.trim());
                if (seats == null || seats <= 0 || seats > 120) {
                  return 'Must be between 1 and 120 seats.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add Bus', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _FleetFilterBottomSheet extends StatefulWidget {
  final Set<String> initialSelectedStatuses;

  const _FleetFilterBottomSheet({
    required this.initialSelectedStatuses,
  });

  @override
  State<_FleetFilterBottomSheet> createState() => _FleetFilterBottomSheetState();
}

class _FleetFilterBottomSheetState extends State<_FleetFilterBottomSheet> {
  final Set<String> _tempSelectedStatuses = {};

  @override
  void initState() {
    super.initState();
    _tempSelectedStatuses.addAll(widget.initialSelectedStatuses);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.46,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F28) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _tempSelectedStatuses.clear();
                    });
                  },
                  child: Text(
                    'Reset All',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 120,
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeftTabTile(
                        title: 'Status',
                        isDark: isDark,
                        badgeCount: _tempSelectedStatuses.length,
                      ),
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade200,
                ),
                Expanded(
                  child: _buildStatusOptionsList(isDark),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C6E6), Color(0xFF0097B2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0097B2).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, _tempSelectedStatuses);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftTabTile({
    required String title,
    required bool isDark,
    required int badgeCount,
  }) {
    final Color activeColor = isDark
        ? const Color(0xFF00C6E6)
        : const Color(0xFF0097B2);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 18,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: activeColor,
                fontSize: 14,
              ),
            ),
          ),
          if (badgeCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusOptionsList(bool isDark) {
    final statuses = [
      {'label': 'All Statuses', 'value': null},
      {'label': 'Active', 'value': 'active'},
      {'label': 'Delayed', 'value': 'delayed'},
      {'label': 'Not Running', 'value': 'not-running'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final statusObj = statuses[index];
        final val = statusObj['value'];
        final label = statusObj['label'] ?? '';
        
        final bool isSelected = val == null 
            ? _tempSelectedStatuses.isEmpty 
            : _tempSelectedStatuses.contains(val);

        return CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? (isDark ? const Color(0xFF00C6E6) : const Color(0xFF0097B2))
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          value: isSelected,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: isDark ? const Color(0xFF00C6E6) : const Color(0xFF0097B2),
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onChanged: (bool? checked) {
            setState(() {
              if (val == null) {
                _tempSelectedStatuses.clear();
              } else {
                if (checked == true) {
                  _tempSelectedStatuses.add(val);
                } else {
                  _tempSelectedStatuses.remove(val);
                }
              }
            });
          },
        );
      },
    );
  }
}
