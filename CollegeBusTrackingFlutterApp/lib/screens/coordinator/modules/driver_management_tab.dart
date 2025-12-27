import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/screens/coordinator/modules/driver_history_screen.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;

class DriverManagementTab extends StatelessWidget {
  final List<UserModel> pendingApprovals;
  final List<UserModel> allDrivers;
  final List<BusModel> buses;
  final Function(UserModel) onApprove;
  final Function(UserModel) onReject;

  const DriverManagementTab({
    super.key,
    required this.pendingApprovals,
    required this.allDrivers,
    required this.buses,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    return DefaultTabController(
      length: 4,
      child: VStack([
        Container(
          margin: const EdgeInsets.all(AppSizes.paddingMedium),
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50), // Dark background for the capsule
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
            isScrollable: false, // Fit all in one view
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade400,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppColors.primary, // Active pill color
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
              Tab(text: l10n.assigned),
              Tab(text: l10n.accepted),
              Tab(text: l10n.approvals),
            ],
          ).p4(), // Padding inside the capsule
        ),
        Expanded(
          child: TabBarView(
            children: [
              _buildDriversByStatus(context, 'all'),
              _buildDriversByStatus(context, 'assigned'),
              _buildDriversByStatus(context, 'accepted'),
              _buildPendingApprovals(context),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildPendingApprovals(BuildContext context) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    if (pendingApprovals.isEmpty) {
      return _buildEmptyState(
        context,
        l10n.noPendingApprovals,
        Icons.check_circle_outline,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: pendingApprovals.length,
      itemBuilder: (context, index) {
        final driver = pendingApprovals[index];
        return _buildDriverCard(context, driver, isApproval: true);
      },
    );
  }

  Widget _buildDriversByStatus(BuildContext context, String status) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    List<UserModel> filteredDrivers = [];

    if (status == 'all') {
      filteredDrivers = allDrivers;
    } else if (status == 'assigned') {
      // All drivers who have ANY non-unassigned assignment status
      final assignedBusDriverIds = buses
          .where((b) => b.assignmentStatus != 'unassigned')
          .map((b) => b.driverId)
          .toSet();
      filteredDrivers = allDrivers
          .where((d) => assignedBusDriverIds.contains(d.id))
          .toList();
    } else if (status == 'accepted') {
      // Drivers with specific assignment status
      final targetBusDriverIds = buses
          .where((b) => b.assignmentStatus == 'accepted')
          .map((b) => b.driverId)
          .toSet();
      filteredDrivers = allDrivers
          .where((d) => targetBusDriverIds.contains(d.id))
          .toList();
    }

    if (filteredDrivers.isEmpty) {
      return _buildEmptyState(
        context,
        l10n.noDriversInCategory,
        Icons.people_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: filteredDrivers.length,
      itemBuilder: (context, index) {
        final driver = filteredDrivers[index];
        BusModel? bus;
        try {
          bus = buses.firstWhere((b) => b.driverId == driver.id);
        } catch (_) {
          bus = null;
        }
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween(begin: 50.0, end: 0.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: Opacity(
                opacity: (1 - value / 50.0).clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: _buildDriverCard(context, driver, bus: bus),
        );
      },
    );
  }

  Widget _buildDriverCard(
    BuildContext context,
    UserModel driver, {
    bool isApproval = false,
    BusModel? bus,
  }) {
    String status = 'unassigned';
    if (bus != null) {
      status = bus.assignmentStatus;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: (driver.fullName.isNotEmpty ? driver.fullName[0] : '?')
              .text
              .white
              .bold
              .make(),
        ),
        title: driver.fullName.text.semiBold.make(),
        subtitle: !isApproval
            ? _buildDriverStatusBadge(
                context,
                status,
              ).pOnly(top: 4).objectTopLeft()
            : null,
        trailing: isApproval
            ? HStack([
                IconButton(
                  icon: Icon(Icons.check, color: AppColors.success),
                  onPressed: () => onApprove(driver),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.error),
                  onPressed: () => onReject(driver),
                ),
              ])
            : IconButton(
                tooltip: 'View History',
                icon: const Icon(Icons.history, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverHistoryScreen(driver: driver),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDriverStatusBadge(BuildContext context, String status) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    Color color;
    String label;

    switch (status) {
      case 'accepted':
        color = const Color(0xFF4CAF50); // Green
        label = l10n.accepted;
        break;
      case 'assigned':
        color = const Color(0xFFE67E22); // Orange
        label = l10n.assigned;
        break;
      case 'rejected':
        color = const Color(0xFFE74C3C); // Red
        label = l10n.rejected;
        break;
      default:
        color = Colors.grey;
        label = l10n.unassigned;
    }

    return HStack([
          VxBox().size(8, 8).color(color).roundedFull.make(),
          8.widthBox,
          label.text.size(12).bold.color(color.withValues(alpha: 0.9)).make(),
        ])
        .pSymmetric(h: 12, v: 6)
        .box
        .color(color.withValues(alpha: 0.1))
        .rounded
        .make();
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return VStack(
      [
        Icon(
          icon,
          size: 64,
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
        AppSizes.paddingMedium.heightBox,
        message.text
            .size(18)
            .color(AppColors.textSecondary.withValues(alpha: 0.5))
            .make(),
      ],
      alignment: MainAxisAlignment.center,
      crossAlignment: CrossAxisAlignment.center,
    ).centered();
  }
}
