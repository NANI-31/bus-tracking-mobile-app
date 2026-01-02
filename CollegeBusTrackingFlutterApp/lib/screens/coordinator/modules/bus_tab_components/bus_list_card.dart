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

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: isAssigned
                ? AppColors.success.withOpacity(0.1)
                : (isOfficial
                      ? AppColors.warning.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1)),
            child: Icon(
              Icons.directions_bus,
              color: isAssigned
                  ? AppColors.success
                  : (isOfficial ? AppColors.warning : Colors.grey),
            ),
          ),
          title: busNumber.text.semiBold.size(16).make(),
          subtitle:
              (hasDriver
                      ? (assignedDriver != null
                            ? 'Assigned -> ${assignedDriver!.fullName}'
                            : 'None')
                      : 'None')
                  .text
                  .color(hasDriver ? AppColors.success : AppColors.warning)
                  .medium
                  .make()
                  .pOnly(top: 4),
          children: [
            Divider(
              color: Theme.of(context).dividerColor.withOpacity(0.05),
              indent: 20,
              endIndent: 20,
            ),
            12.heightBox,
            HStack([
              // Tracking / Assign button (onTap equivalent)
              _buildActionButton(
                context,
                icon: Icons.assignment_ind_outlined,
                label: 'Assign',
                color: Colors.blue,
                onPressed: onTap,
              ).expand(),
              12.widthBox,

              if (hasDriver) ...[
                _buildActionButton(
                  context,
                  icon: Icons.history,
                  label: 'History',
                  color: Colors.blueGrey,
                  onPressed: onHistory,
                ).expand(),
                12.widthBox,
              ],

              _buildActionButton(
                context,
                icon: Icons.person_outline,
                label: 'Driver',
                color: Colors.indigo,
                onPressed: onEditDriver,
              ).expand(),
            ]).pSymmetric(h: 20),
            12.heightBox,
            if (isOfficial)
              HStack([
                _buildActionButton(
                  context,
                  icon: Icons.edit_outlined,
                  label: 'Rename',
                  color: Colors.orange,
                  onPressed: onEdit,
                ).expand(),
                12.widthBox,
                _buildActionButton(
                  context,
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppColors.error,
                  onPressed: onDelete,
                ).expand(),
              ]).pSymmetric(h: 20),
            16.heightBox,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: color.withOpacity(0.08),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
      ),
    );
  }
}
