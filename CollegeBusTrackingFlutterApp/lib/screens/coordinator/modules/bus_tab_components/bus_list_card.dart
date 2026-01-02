import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/user_model.dart';

class BusListCard extends StatelessWidget {
  final String busNumber;
  final bool isOfficial;
  final BusModel assignedBus;
  final UserModel? assignedDriver;
  final VoidCallback onTap;
  final VoidCallback onHistory;
  final VoidCallback onEdit;
  final VoidCallback onEditDriver;
  final VoidCallback onDelete;

  const BusListCard({
    super.key,
    required this.busNumber,
    required this.isOfficial,
    required this.assignedBus,
    required this.assignedDriver,
    required this.onTap,
    required this.onHistory,
    required this.onEdit,
    required this.onEditDriver,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAssigned = assignedBus.id.isNotEmpty;
    final hasDriver = isAssigned && assignedBus.driverId.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isAssigned
              ? AppColors.success
              : (isOfficial ? AppColors.warning : Colors.grey),
          child: Icon(Icons.directions_bus, color: AppColors.onPrimary),
        ),
        title: busNumber.text.semiBold.make(),
        subtitle:
            (hasDriver
                    ? (assignedDriver != null
                          ? 'Assigned -> ${assignedDriver!.fullName}'
                          : 'None')
                    : 'None')
                .text
                .color(hasDriver ? AppColors.success : AppColors.warning)
                .medium
                .make(),
        trailing: HStack([
          if (hasDriver)
            IconButton(
              icon: const Icon(Icons.history, color: Colors.blueGrey),
              onPressed: onHistory,
              tooltip: 'View History',
            ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.blue),
            onPressed: onEditDriver,
            tooltip: 'Edit Driver Name',
          ),
          if (isOfficial) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
              tooltip: 'Edit Bus Number',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ]),
      ),
    );
  }
}
