// teacher_override_tab.dart
//
// Extracted from teacher_dashboard.dart.
// Renders the "Override" tab — lets a teacher select a bus, request/manage
// a coordinator-approved override, and view the real-time fleet status list.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';

import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/user/domain/user_model.dart';

class TeacherOverrideTab extends ConsumerWidget {
  const TeacherOverrideTab({
    super.key,
    required this.user,
    required this.selectedBusId,
    required this.isTracking,
    required this.isRequesting,
    required this.isDark,
    required this.onSelectBus,
    required this.onStartTracking,
    required this.onStopTracking,
    required this.onSubmitRequest,
    required this.onCancelOverride,
    required this.onOpenLiveTracking,
  });

  final UserModel user;
  final String? selectedBusId;
  final bool isTracking;
  final bool isRequesting;
  final bool isDark;
  final void Function(String? busId) onSelectBus;
  final VoidCallback onStartTracking;
  final VoidCallback onStopTracking;
  final VoidCallback onSubmitRequest;
  final VoidCallback onCancelOverride;
  final VoidCallback onOpenLiveTracking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busesAsync = ref.watch(collegeBusesStreamProvider(user.collegeId));
    final pendingRequestsAsync = ref.watch(teacherOverrideRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: 'Driver Keypad Override'.text.bold.make(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: busesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          final errStr = err.toString();
          final isRateLimit = errStr.contains("Too many requests") || errStr.contains("429");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isRateLimit ? Icons.timer_outlined : Icons.error_outline,
                    color: AppColors.error,
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  (isRateLimit
                          ? "Server is busy updating permissions. Please tap retry in a moment."
                          : "Error loading fleet: $errStr")
                      .text
                      .center
                      .color(AppColors.error)
                      .make(),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(collegeBusesStreamProvider(user.collegeId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        },
        data: (buses) {
          String? activeOverrideId;
          for (final b in buses) {
            if (b.trackingTeacherId == user.id) {
              activeOverrideId = b.id;
              break;
            }
          }

          final effectiveSelectedId = selectedBusId ?? activeOverrideId;


          final selectedBus = effectiveSelectedId != null
              ? buses.cast<dynamic>().firstWhere(
                  (b) => b.id == effectiveSelectedId,
                  orElse: () => null,
                )
              : null;

          final pendingRequests = pendingRequestsAsync.valueOrNull ?? [];
          final hasPendingRequest =
              effectiveSelectedId != null &&
              pendingRequests.any(
                (r) =>
                    r['busId'] == effectiveSelectedId ||
                    (r['busId'] is Map &&
                        r['busId']['_id'] == effectiveSelectedId),
              );

          final isApproved =
              selectedBus != null && selectedBus.trackingTeacherId == user.id;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: VStack([
              'Select Bus to Override'.text.lg.bold.make().pOnly(bottom: 8),
              DropdownButtonFormField<String>(
                initialValue: effectiveSelectedId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                hint: 'Choose a vehicle'.text.make(),
                items: buses.map((bus) {
                  final statusSuffix = bus.assignmentStatus == 'accepted'
                      ? ' (Active)'
                      : bus.assignmentStatus == 'pending'
                          ? ' (Pending)'
                          : ' (Available)';
                  return DropdownMenuItem<String>(
                    value: bus.id,
                    child: 'Bus ${bus.busNumber}$statusSuffix'.text.make(),
                  );
                }).toList(),
                onChanged: isTracking ? null : (busId) => onSelectBus(busId),
              ),
              const SizedBox(height: 24),

              if (selectedBus != null) ...[
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: VStack([
                    HStack([
                      const Icon(Icons.info_outline, color: Colors.blueGrey),
                      const SizedBox(width: 12),
                      'Status'.text.bold.lg.make(),
                    ]).pOnly(bottom: 8),

                    if (isApproved)
                      'Approved & Authorized'.text.green600.bold.make()
                    else if (hasPendingRequest)
                      'Request Pending Coordinator Approval'.text.amber500.bold
                          .make()
                    else
                      'No active override authorization'.text.gray500.make(),
                  ]).p(16),
                ),
                const SizedBox(height: 24),

                if (isApproved) ...[
                  if (isTracking) ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onOpenLiveTracking,
                      child: 'Open Live Tracking'.text.bold.make(),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onStopTracking,
                      child: 'Pause Tracking'.text.bold.make(),
                    ),
                  ] else ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onStartTracking,
                      child: 'Start Override Tracking'.text.bold.make(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade300),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isTracking ? null : onCancelOverride,
                    child: 'End Override Session'.text.bold.make(),
                  ),
                ] else ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (isRequesting || hasPendingRequest)
                        ? null
                        : onSubmitRequest,
                    child: isRequesting
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          ).centered()
                        : 'Request Override Authorization'.text.bold.make(),
                  ),
                ],
              ],

              const SizedBox(height: 32),
              'College Fleet Live Status'.text.lg.bold.make().pOnly(bottom: 12),
              if (buses.isEmpty)
                'No buses registered in this college.'.text.gray500
                    .make()
                    .centered()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: buses.length,
                  itemBuilder: (context, index) {
                    final bus = buses[index];
                    final isLive = ref
                        .watch(studentLiveBusIdsProvider(user.collegeId))
                        .contains(bus.id);
                    final isAssigned = bus.driverId.isNotEmpty;
                    final isCurrentOverride = bus.trackingTeacherId == user.id;

                    Color statusColor = Colors.grey;
                    String statusLabel = 'Offline';
                    String statusSubtitle = 'Unassigned & Offline';

                    // Show trip direction if the bus has an active assignment.
                    final tripType = bus.tripType;
                    final directionTag = tripType != null
                        ? ' \u2014 ${tripType.toUpperCase()}'
                        : '';

                    if (isCurrentOverride) {
                      statusColor = Colors.green;
                      statusLabel = 'Override Active';
                      statusSubtitle = 'You are broadcasting location$directionTag';
                    } else if (isLive) {
                      statusColor = Colors.green;
                      statusLabel = 'Live';
                      statusSubtitle = 'Currently broadcasting live$directionTag';
                    } else if (isAssigned) {
                      statusColor = Colors.amber.shade700;
                      statusLabel = 'Assigned';
                      statusSubtitle = 'Assigned (Driver Offline)$directionTag';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isCurrentOverride
                              ? Colors.green.shade400
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_bus,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        title: 'Bus ${bus.busNumber}'.text.bold.make(),
                        subtitle: statusSubtitle.text.size(12).gray500.make(),
                        trailing: HStack([
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          statusLabel.text
                              .color(statusColor)
                              .bold
                              .size(12)
                              .make(),
                        ]),
                        onTap: isTracking ? null : () => onSelectBus(bus.id),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 80),
            ]),
          );
        },
      ),
    );
  }
}
