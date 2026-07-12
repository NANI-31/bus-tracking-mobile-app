// ignore_for_file: deprecated_member_use
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/core/providers/socket_provider.dart';
import 'package:collegebus/shared/widgets/shimmer_skeletons.dart';

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
      final collegeRepo = ref.read(collegeRepositoryProvider);
      final busRepo = ref.read(busRepositoryProvider);
      final authState = ref.read(authProvider).value;
      final collegeId = authState?.currentUser?.collegeId;
      if (collegeId == null) throw 'College context missing';

      final newBusNumber = _busNumberController.text.trim();

      // Update bus name and route
      await collegeRepo.updateBusDetails(
        collegeId: collegeId,
        oldBusNumber: widget.busNumber,
        newBusNumber: newBusNumber != widget.busNumber ? newBusNumber : null,
        details: _selectedDefaultRouteId != widget.bus?.defaultRouteId
            ? {'defaultRouteId': _selectedDefaultRouteId}
            : null,
      );

      // Update driver assignment if changed
      if (_selectedDriverId != widget.bus?.driverId && widget.bus != null) {
        if (_selectedDriverId != null && _selectedDriverId!.isNotEmpty) {
          await busRepo.assignDriverToBus(
            busId: widget.bus!.id,
            driverId: _selectedDriverId!,
            routeId: _selectedDefaultRouteId,
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
          onPrimaryAction: () {
            if (context.mounted) {
              context.pop();
            }
          },
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

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Confirm Remove Driver',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim1,
            curve: const Cubic(0.34, 1.56, 0.64, 1.0),
          ),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (dialogContext, anim1, anim2) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_remove_outlined,
                        color: AppColors.error,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Remove Driver',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Are you sure you want to remove the assigned driver from this bus?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Remove',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isRemovingDriver = true);
    try {
      final busRepo = ref.read(busRepositoryProvider);
      await busRepo.rejectBusAssignment(widget.bus!.id);

      // Notify socket for real-time synchronization
      ref.read(socketServiceProvider).sendBusListUpdate();

      if (mounted) {
        SuccessModal.show(
          context: context,
          title: 'Driver Removed',
          message: 'The driver has been removed from this bus.',
          primaryActionText: 'OK',
          onPrimaryAction: () {
            if (context.mounted) {
              context.pop();
            }
          },
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

    // Build a map: driverId -> busNumber
    final Map<String, String> driverToBusMap = {};
    for (final bus in buses) {
      if (bus.driverId.isNotEmpty) {
        driverToBusMap[bus.driverId] = bus.busNumber;
      }
    }

    final hasDriver = widget.bus != null && widget.bus!.driverId.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Bus Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFF0097B2), const Color(0xFF00C6E6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: routesAsync.when(
        loading: () => const BusListSkeleton(),
        error: (err, stack) => Center(child: 'Error: $err'.text.make()),
        data: (routes) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card 1: Bus Details
                Card(
                  elevation: 0,
                  color: context.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.06,
                      ),
                      width: 1.2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader(
                          context,
                          icon: Icons.directions_bus_outlined,
                          title: 'Bus Details',
                          subtitle:
                              'Modify the bus identifier and default route.',
                        ),
                        const SizedBox(height: 24),

                        // Bus Number Field
                        TextFormField(
                          controller: _busNumberController,
                          enabled: widget.isBusEditable,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Bus Number / Name',
                            labelStyle: TextStyle(
                              color: context.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                            hintText: 'e.g. BUS-01',
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.black.withValues(alpha: 0.015),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.directions_bus_outlined,
                              color: primaryColor.withValues(alpha: 0.7),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a bus number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Custom Expandable Route Selector with Vector Timeline
                        RouteSelectorWidget(
                          routes: routes,
                          selectedRouteId: _selectedDefaultRouteId,
                          isEditable: widget.isBusEditable,
                          onChanged: (value) {
                            setState(() {
                              _selectedDefaultRouteId = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card 2: Driver Management
                Card(
                  elevation: 0,
                  color: context.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.06,
                      ),
                      width: 1.2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader(
                          context,
                          icon: Icons.person_outline,
                          title: 'Driver Management',
                          subtitle: hasDriver
                              ? 'Change or remove the assigned driver.'
                              : 'Assign a driver to this bus.',
                        ),
                        const SizedBox(height: 24),

                        // Driver Dropdown
                        driversAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, _) =>
                              Text('Error loading drivers: $err'),
                          data: (drivers) {
                            final validDriverIds = drivers
                                .map((d) => d.id)
                                .toSet();
                            final currentValue =
                                validDriverIds.contains(_selectedDriverId)
                                ? _selectedDriverId
                                : null;

                            return DropdownButtonFormField<String>(
                              initialValue: currentValue,
                              isExpanded: true,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.colorScheme.onSurface,
                              ),
                              dropdownColor: context.cardColor,
                              decoration: InputDecoration(
                                labelText: 'Assigned Driver',
                                labelStyle: TextStyle(
                                  color: context.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                                hintText: 'Select a driver',
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.02)
                                    : Colors.black.withValues(alpha: 0.015),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: context.colorScheme.onSurface
                                        .withValues(alpha: 0.08),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: context.colorScheme.onSurface
                                        .withValues(alpha: 0.08),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.person_search_outlined,
                                  color: primaryColor.withValues(alpha: 0.7),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('No Driver Assigned'),
                                ),
                                ...drivers.map((driver) {
                                  final assignedBusNumber =
                                      driverToBusMap[driver.id];
                                  final isAssignedToThisBus =
                                      assignedBusNumber == widget.busNumber;
                                  final isAssignedToOther =
                                      assignedBusNumber != null &&
                                      !isAssignedToThisBus;

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
                                          _buildBadge(
                                            'Available',
                                            AppColors.success,
                                          ),
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

                        // Remove Driver Button
                        if (hasDriver)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _isRemovingDriver
                                  ? null
                                  : _handleRemoveDriver,
                              icon: _isRemovingDriver
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.person_remove_outlined),
                              label: Text(
                                _isRemovingDriver
                                    ? 'Removing...'
                                    : 'Remove Current Driver',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(
                                  color: AppColors.error.withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27),
                    gradient: LinearGradient(
                      colors: _isSaving
                          ? [Colors.grey, Colors.grey]
                          : (isDark
                                ? [
                                    const Color(0xFF00E5FF),
                                    const Color(0xFF0097B2),
                                  ]
                                : [
                                    const Color(0xFF0097B2),
                                    const Color(0xFF00C6E6),
                                  ]),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      if (!_isSaving)
                        BoxShadow(
                          color:
                              (isDark
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFF0097B2))
                                  .withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 24),
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

class RouteSelectorWidget extends StatefulWidget {
  final List<RouteModel> routes;
  final String? selectedRouteId;
  final ValueChanged<String?> onChanged;
  final bool isEditable;

  const RouteSelectorWidget({
    super.key,
    required this.routes,
    required this.selectedRouteId,
    required this.onChanged,
    required this.isEditable,
  });

  @override
  State<RouteSelectorWidget> createState() => _RouteSelectorWidgetState();
}

class _RouteSelectorWidgetState extends State<RouteSelectorWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Find the currently selected route
    RouteModel? selectedRoute;
    for (final r in widget.routes) {
      if (r.id == widget.selectedRouteId) {
        selectedRoute = r;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Selector Header Card
        InkWell(
          onTap: widget.isEditable
              ? () => setState(() => _isExpanded = !_isExpanded)
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.015),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isExpanded
                    ? primaryColor
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.08),
                width: _isExpanded ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.route_outlined,
                  color: primaryColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default Route',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedRoute != null
                            ? selectedRoute.displayName
                            : 'No Default Route',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isEditable)
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),

        // 2. Expanded Route List Panel
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black26
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.06),
                    ),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount:
                        widget.routes.length +
                        1, // +1 for "No default route" option
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return RadioListTile<String?>(
                          title: const Text(
                            'No Default Route',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          value: null,
                          groupValue: widget.selectedRouteId,
                          activeColor: primaryColor,
                          onChanged: (val) {
                            widget.onChanged(val);
                            setState(() => _isExpanded = false);
                          },
                        );
                      }

                      final route = widget.routes[index - 1];
                      final isSelected = widget.selectedRouteId == route.id;
                      final routeColor = _parseHexColor(
                        route.color,
                        primaryColor,
                      );

                      return _RouteListTile(
                        route: route,
                        isSelected: isSelected,
                        routeColor: routeColor,
                        allRoutes: widget.routes,
                        initiallyExpanded: isSelected,
                        onSelect: () {
                          widget.onChanged(route.id);
                          setState(() => _isExpanded = false);
                        },
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // 3. Mini Vector Timeline
        if (selectedRoute != null) ...[
          const SizedBox(height: 16),
          Text(
            'Active Route Preview',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          TransitTimelineView(
            route: selectedRoute,
            routeColor: _parseHexColor(selectedRoute.color, primaryColor),
            allRoutes: widget.routes,
          ),
        ],
      ],
    );
  }

  Color _parseHexColor(String hex, Color fallback) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}

class _RouteListTile extends StatefulWidget {
  final RouteModel route;
  final bool isSelected;
  final Color routeColor;
  final VoidCallback onSelect;
  final List<RouteModel> allRoutes;
  final bool initiallyExpanded;

  const _RouteListTile({
    required this.route,
    required this.isSelected,
    required this.routeColor,
    required this.onSelect,
    required this.allRoutes,
    this.initiallyExpanded = false,
  });

  @override
  State<_RouteListTile> createState() => _RouteListTileState();
}

class _RouteListTileState extends State<_RouteListTile> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: widget.isSelected
          ? widget.routeColor.withValues(alpha: 0.04)
          : Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.isSelected
              ? widget.routeColor.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          width: widget.isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              widget.route.routeName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: widget.isSelected ? widget.routeColor : null,
              ),
            ),
            subtitle: Text(
              '${widget.route.routeType.toUpperCase()} • ${widget.route.stopPoints.length + 2} stops',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            leading: Radio<String?>(
              value: widget.route.id,
              groupValue: widget.isSelected ? widget.route.id : null,
              activeColor: widget.routeColor,
              onChanged: (_) => widget.onSelect(),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: widget.routeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.routeColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      top: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(height: 16),
                        TransitTimelineView(
                          route: widget.route,
                          routeColor: widget.routeColor,
                          allRoutes: widget.allRoutes,
                        ),
                        const SizedBox(height: 12),
                        if (!widget.isSelected)
                          ElevatedButton.icon(
                            onPressed: widget.onSelect,
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text(
                              'Use This Route',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.routeColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class TransitTimelineView extends StatefulWidget {
  final RouteModel route;
  final Color routeColor;
  final List<RouteModel> allRoutes;

  const TransitTimelineView({
    super.key,
    required this.route,
    required this.routeColor,
    required this.allRoutes,
  });

  @override
  State<TransitTimelineView> createState() => _TransitTimelineViewState();
}

class _TransitTimelineViewState extends State<TransitTimelineView>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int? _expandedNodeIndex;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void didUpdateWidget(covariant TransitTimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.id != widget.route.id) {
      _fadeController.forward(from: 0.0);
      _expandedNodeIndex = null;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  List<String> _getTransferRoutes(RoutePoint point) {
    final List<String> transferring = [];
    final name = point.name.trim().toLowerCase();
    if (name.isEmpty) return transferring;

    for (final other in widget.allRoutes) {
      if (other.id == widget.route.id) continue;
      final otherPoints = [
        other.startPoint,
        ...other.stopPoints,
        other.endPoint,
      ];
      for (final op in otherPoints) {
        if (op.name.trim().toLowerCase() == name) {
          transferring.add(other.routeName);
          break;
        }
      }
    }
    return transferring;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allPoints = [
      widget.route.startPoint,
      ...widget.route.stopPoints,
      widget.route.endPoint,
    ];

    // Compute estimate metrics
    final int duration =
        widget.route.directions?.totalDurationMin ?? (allPoints.length * 5);
    final double distance =
        widget.route.directions?.totalDistanceKm ?? (allPoints.length * 1.2);
    final double avgSpeed = duration > 0 ? (distance / (duration / 60.0)) : 0.0;
    final double stopInterval = allPoints.length > 1
        ? duration / (allPoints.length - 1)
        : 0.0;

    final String durationText = '$duration mins';
    final String distanceText = '${distance.toStringAsFixed(1)} km';
    final String speedText = '${avgSpeed.toStringAsFixed(1)} km/h';
    final String intervalText = '${stopInterval.toStringAsFixed(1)} m/stop';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Info Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: widget.routeColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.routeColor.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricItem(
                    Icons.timer_outlined,
                    'Duration',
                    durationText,
                    widget.routeColor,
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: widget.routeColor.withValues(alpha: 0.2),
                  ),
                  _buildMetricItem(
                    Icons.map_outlined,
                    'Distance',
                    distanceText,
                    widget.routeColor,
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: widget.routeColor.withValues(alpha: 0.2),
                  ),
                  _buildMetricItem(
                    Icons.speed_outlined,
                    'Avg Speed',
                    speedText,
                    widget.routeColor,
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: widget.routeColor.withValues(alpha: 0.2),
                  ),
                  _buildMetricItem(
                    Icons.av_timer_outlined,
                    'Interval',
                    intervalText,
                    widget.routeColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Vertical Timeline
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              children: List.generate(allPoints.length, (i) {
                final isStart = i == 0;
                final isEnd = i == allPoints.length - 1;
                final point = allPoints[i];
                final transfers = _getTransferRoutes(point);
                final isExpandedNode = _expandedNodeIndex == i;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline nodes and connectors
                    Column(
                      children: [
                        // Upper Connector Line
                        Container(
                          width: 2,
                          height: 16,
                          color: isStart
                              ? Colors.transparent
                              : widget.routeColor,
                        ),
                        // Node bullet
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _expandedNodeIndex = isExpandedNode ? null : i;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isExpandedNode ? 20 : 16,
                            height: isExpandedNode ? 20 : 16,
                            decoration: BoxDecoration(
                              color: isStart
                                  ? const Color(
                                      0xFFFF9100,
                                    ) // Vibrant orange start node
                                  : (isEnd
                                        ? const Color(0xFF00E676)
                                        : widget.routeColor), // Green end node
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isStart
                                              ? const Color(0xFFFF9100)
                                              : (isEnd
                                                    ? const Color(0xFF00E676)
                                                    : widget.routeColor))
                                          .withValues(
                                            alpha: isExpandedNode ? 0.6 : 0.4,
                                          ),
                                  blurRadius: isExpandedNode ? 6 : 4,
                                  spreadRadius: isExpandedNode ? 2 : 1,
                                ),
                              ],
                            ),
                            child: isExpandedNode
                                ? const Center(
                                    child: Icon(
                                      Icons.gps_fixed,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        // Lower Connector Line
                        Container(
                          width: 2,
                          height: 16,
                          color: isEnd ? Colors.transparent : widget.routeColor,
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Stop Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _expandedNodeIndex = isExpandedNode ? null : i;
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    point.name.isEmpty
                                        ? 'Unnamed Stop'
                                        : point.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: (isStart || isEnd)
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                                if (transfers.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.blue.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.swap_horiz,
                                          size: 10,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Transfer',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isStart)
                            const Text(
                              'ORIGIN / START POINT',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF9100),
                                letterSpacing: 0.5,
                              ),
                            )
                          else if (isEnd)
                            const Text(
                              'DESTINATION / END POINT',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00E676),
                                letterSpacing: 0.5,
                              ),
                            ),

                          // Transfer routes names pill list
                          if (transfers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Shared with: ${transfers.join(", ")}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                          // Stop coordinates expandable details bubble
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: isExpandedNode
                                ? Container(
                                    margin: const EdgeInsets.only(
                                      top: 6,
                                      bottom: 4,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: widget.routeColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: widget.routeColor.withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: widget.routeColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Lat: ${point.lat.toStringAsFixed(6)}  •  Lng: ${point.lng.toStringAsFixed(6)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
