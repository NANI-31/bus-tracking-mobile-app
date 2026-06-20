import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:intl/intl.dart';
import 'package:collegebus/shared/widgets/shimmer_skeletons.dart';

class AssignmentHistoryScreen extends ConsumerWidget {
  final String busId;
  final String busNumber;

  const AssignmentHistoryScreen({
    super.key,
    required this.busId,
    required this.busNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(busAssignmentLogsProvider(busId));

    return Scaffold(
      appBar: AppBar(title: 'Assignment History - $busNumber'.text.make()),
      body: logsAsync.when(
        loading: () => const BusListSkeleton(),
        error: (err, stack) =>
            err.toString().text.color(AppColors.error).make().centered(),
        data: (logs) {
          if (logs.isEmpty) {
            return 'No assignment history found for this bus'.text.gray500
                .make()
                .centered();
          }

          return ListView.builder(
            itemCount: logs.length,
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: VStack([
                  HStack([
                    _getStatusBadge(log.status),
                    const Spacer(),
                    DateFormat('MMM dd, yyyy')
                        .format(log.assignedAt.toLocal())
                        .text
                        .size(12)
                        .gray500
                        .make(),
                  ]).pOnly(bottom: 8),

                  HStack([
                    const Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.blueGrey,
                    ).pOnly(right: 8),
                    'Driver: '.text.bold.make(),
                    (log.driverName ?? 'Unknown Driver').text.make(),
                  ]),

                  if (log.routeName != null)
                    HStack([
                      const Icon(
                        Icons.route,
                        size: 16,
                        color: Colors.blueGrey,
                      ).pOnly(right: 8),
                      'Route: '.text.bold.make(),
                      log.routeName!.text.make(),
                    ]).pOnly(top: 4),

                  const Divider().pSymmetric(v: 8),

                  VStack([
                    _buildTimeRow('Assigned', log.assignedAt),
                    if (log.acceptedAt != null)
                      _buildTimeRow('Accepted', log.acceptedAt!),
                    if (log.completedAt != null)
                      _buildTimeRow(
                        log.status == 'rejected' ? 'Rejected' : 'Completed',
                        log.completedAt!,
                      ),
                  ]),
                ]).p(16),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimeRow(String label, DateTime time) {
    return HStack([
      label.text.size(12).gray600.make(),
      const Spacer(),
      DateFormat('hh:mm a').format(time.toLocal()).text.size(12).bold.make(),
    ]);
  }

  Widget _getStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'accepted':
        color = AppColors.success;
        break;
      case 'pending':
        color = AppColors.warning;
        break;
      case 'rejected':
        color = AppColors.error;
        break;
      default:
        color = AppColors.primary;
    }

    return status
        .toUpperCase()
        .text
        .white
        .size(10)
        .bold
        .make()
        .pSymmetric(h: 8, v: 4)
        .box
        .color(color)
        .roundedSM
        .make();
  }
}
