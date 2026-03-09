import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/features/user/application/user_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/core/providers/socket_provider.dart';

class EditBusScreen extends ConsumerStatefulWidget {
  final String busNumber;
  final BusModel? bus;
  final bool isBusEditable;

  const EditBusScreen({
    super.key,
    required this.busNumber,
    this.bus,
    this.isBusEditable = true,
  });

  @override
  ConsumerState<EditBusScreen> createState() => _EditBusScreenState();
}

class _EditBusScreenState extends ConsumerState<EditBusScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _busNumberController;
  String? _selectedDefaultRouteId;
  String? _selectedDriverId;
  bool _isSaving = false;
  bool _isRemovingDriver = false;

  @override
  void initState() {
    super.initState();
    _busNumberController = TextEditingController(text: widget.busNumber);
    _selectedDefaultRouteId = widget.bus?.defaultRouteId;
    _selectedDriverId = widget.bus?.driverId;
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final authState = ref.read(authProvider).value;
      final collegeId = authState?.currentUser?.collegeId;
      if (collegeId == null) throw 'College context missing';

      final newBusNumber = _busNumberController.text.trim();

      // Update bus name and route
      await api.updateBusDetails(
        collegeId,
        widget.busNumber,
        newBusNumber: newBusNumber != widget.busNumber ? newBusNumber : null,
        defaultRouteId: _selectedDefaultRouteId != widget.bus?.defaultRouteId
            ? _selectedDefaultRouteId
            : null,
      );

      // Update driver assignment if changed
      if (_selectedDriverId != widget.bus?.driverId && widget.bus != null) {
        if (_selectedDriverId != null && _selectedDriverId!.isNotEmpty) {
          await api.assignDriverToBus(
            busNumber: widget.busNumber,
            driverId: _selectedDriverId!,
            collegeId: collegeId,
          );
        }
      }

      // Notify socket for real-time synchronization
      ref.read(socketServiceProvider).sendBusListUpdate();

      if (mounted) {
        SuccessModal.show(
          context: context,
          title: 'Bus Updated',
          message: 'Bus details have been updated successfully.',
          primaryActionText: 'OK',
          onPrimaryAction: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(context: context, error: e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleRemoveDriver() async {
    if (widget.bus == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Driver'),
        content: const Text(
          'Are you sure you want to remove the assigned driver from this bus?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRemovingDriver = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.rejectBusAssignment(widget.bus!.id);

      // Notify socket for real-time synchronization
      ref.read(socketServiceProvider).sendBusListUpdate();

      if (mounted) {
        SuccessModal.show(
          context: context,
          title: 'Driver Removed',
          message: 'The driver has been removed from this bus.',
          primaryActionText: 'OK',
          onPrimaryAction: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(context: context, error: e);
      }
    } finally {
      if (mounted) setState(() => _isRemovingDriver = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).value;
    final collegeId = authState?.currentUser?.collegeId;

    final routesAsync = collegeId != null
        ? ref.watch(collegeRoutesProvider(collegeId))
        : const AsyncValue<List<RouteModel>>.data([]);

    final driversAsync = collegeId != null
        ? ref.watch(
            usersByRoleProvider((role: UserRole.driver, collegeId: collegeId)),
          )
        : const AsyncValue<List<UserModel>>.data([]);

    final buses = collegeId != null
        ? (ref.watch(allCollegeBusesStreamProvider(collegeId)).value ?? [])
        : <BusModel>[];

    // Build a map: driverId -> busNumber (for drivers assigned to other buses)
    final Map<String, String> driverToBusMap = {};
    for (final bus in buses) {
      if (bus.driverId.isNotEmpty) {
        driverToBusMap[bus.driverId] = bus.busNumber;
      }
    }

    final hasDriver = widget.bus != null && widget.bus!.driverId.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Bus'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: 'Error: $err'.text.make()),
        data: (routes) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Section 1: Bus Details ──
                _buildSectionHeader(
                  context,
                  icon: Icons.directions_bus_outlined,
                  title: 'Bus Details',
                  subtitle: 'Modify the bus identifier and default route.',
                ),
                const SizedBox(height: 20),

                // Bus Number Field
                TextFormField(
                  controller: _busNumberController,
                  enabled: widget.isBusEditable,
                  decoration: InputDecoration(
                    labelText: 'Bus Number / Name',
                    hintText: 'e.g. BUS-01',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.directions_bus_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a bus number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Default Route Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedDefaultRouteId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Default Route',
                    hintText: 'Select a default route',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.route_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No Default Route'),
                    ),
                    ...routes.map((route) {
                      return DropdownMenuItem<String>(
                        value: route.id,
                        child: Text(route.displayName),
                      );
                    }),
                  ],
                  onChanged: widget.isBusEditable
                      ? (value) {
                          setState(() {
                            _selectedDefaultRouteId = value;
                          });
                        }
                      : null,
                ),
                const SizedBox(height: 32),

                // ── Section 2: Driver Management ──
                _buildSectionHeader(
                  context,
                  icon: Icons.person_outline,
                  title: 'Driver Management',
                  subtitle: hasDriver
                      ? 'Change or remove the assigned driver.'
                      : 'Assign a driver to this bus.',
                ),
                const SizedBox(height: 20),

                // Driver Dropdown
                driversAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading drivers: $err'),
                  data: (drivers) {
                    // Validate that selectedDriverId exists in the list
                    final validDriverIds = drivers.map((d) => d.id).toSet();
                    final currentValue =
                        validDriverIds.contains(_selectedDriverId)
                        ? _selectedDriverId
                        : null;

                    return DropdownButtonFormField<String>(
                      initialValue: currentValue,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Assigned Driver',
                        hintText: 'Select a driver',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person_search_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Driver Assigned'),
                        ),
                        ...drivers.map((driver) {
                          final assignedBusNumber = driverToBusMap[driver.id];
                          final isAssignedToThisBus =
                              assignedBusNumber == widget.busNumber;
                          final isAssignedToOther =
                              assignedBusNumber != null && !isAssignedToThisBus;

                          return DropdownMenuItem<String>(
                            value: driver.id,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    driver.fullName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isAssignedToOther
                                          ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5)
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isAssignedToThisBus)
                                  _buildBadge('This Bus', Colors.orange)
                                else if (isAssignedToOther)
                                  _buildBadge(
                                    assignedBusNumber,
                                    AppColors.error,
                                  )
                                else
                                  _buildBadge('Available', AppColors.success),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDriverId = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Remove Driver Button (only shown when a driver is assigned)
                if (hasDriver)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isRemovingDriver ? null : _handleRemoveDriver,
                      icon: _isRemovingDriver
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_remove_outlined),
                      label: Text(
                        _isRemovingDriver
                            ? 'Removing...'
                            : 'Remove Current Driver',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),

                // ── Save Button ──
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title.text.bold.xl.make(),
              const SizedBox(height: 2),
              subtitle.text
                  .color(
                    Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  )
                  .sm
                  .make(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
