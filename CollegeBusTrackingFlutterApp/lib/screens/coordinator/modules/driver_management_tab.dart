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
  final Set<String> onlineDriverIds;
  final Function(UserModel) onApprove;
  final Function(UserModel) onReject;
  final Function(UserModel)? onEditDriver;
  final Function(BusModel)? onTrack;

  const DriverManagementTab({
    super.key,
    required this.pendingApprovals,
    required this.allDrivers,
    required this.buses,
    required this.onlineDriverIds,
    required this.onApprove,
    required this.onReject,
    this.onEditDriver,
    this.onTrack,
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

    final isOnline = onlineDriverIds.contains(driver.id);
    final canTrack =
        bus != null && bus.isActive; // Trackable if bus exists and is active

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
      child: isApproval
          ? ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: _buildAvatar(context, driver, isOnline),
              title: driver.fullName.text.semiBold.size(16).make(),
              subtitle: _buildDriverStatusBadge(
                context,
                status,
              ).pOnly(top: 8).objectTopLeft(),
              trailing: HStack([
                IconButton(
                  icon: Icon(Icons.check, color: AppColors.success),
                  onPressed: () => onApprove(driver),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.error),
                  onPressed: () => onReject(driver),
                ),
              ]),
            )
          : ExpansionTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20,
              ),
              leading: _buildAvatar(context, driver, isOnline),
              title: driver.fullName.text.semiBold.size(16).make(),
              subtitle: _buildDriverStatusBadge(context, status).pOnly(top: 8),
              children: [
                Divider(
                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                ),
                12.heightBox,
                HStack([
                  ElevatedButton.icon(
                    onPressed: () {
                      onEditDriver?.call(driver);
                    },
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      foregroundColor: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ).expand(),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverHistoryScreen(driver: driver),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history, size: 20),
                    label: const Text('History'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      foregroundColor: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ).expand(),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient:
                          (bus != null &&
                              bus.isActive &&
                              bus.status != 'not-running')
                          ? const LinearGradient(
                              colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade200,
                                Colors.grey.shade300,
                              ],
                            ),
                      boxShadow:
                          (bus != null &&
                              bus.isActive &&
                              bus.status != 'not-running')
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2E3192).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (bus != null &&
                            bus.isActive &&
                            bus.status != 'not-running') {
                          onTrack?.call(bus);
                        } else {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Driver Not Active'),
                              content: const Text(
                                'The driver has not started location sharing yet.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        Icons.location_searching,
                        size: 20,
                        color:
                            (bus != null &&
                                bus.isActive &&
                                bus.status != 'not-running')
                            ? Colors.white
                            : Colors.grey.shade400,
                      ),
                      label: const Text('Track'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.transparent,
                        foregroundColor:
                            (bus != null &&
                                bus.isActive &&
                                bus.status != 'not-running')
                            ? Colors.white
                            : Colors.grey.shade400,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ).expand(),
                ], alignment: MainAxisAlignment.spaceEvenly),
              ],
            ),
    );
  }

  Widget _buildAvatar(BuildContext context, UserModel driver, bool isOnline) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isOnline
                  ? Colors.greenAccent
                  : Colors.grey.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: (driver.fullName.isNotEmpty ? driver.fullName[0] : '?').text
                .size(20)
                .color(Theme.of(context).primaryColor)
                .bold
                .make(),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDriverStatusBadge(BuildContext context, String status) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    Color color;
    String label;

    switch (status) {
      case 'accepted':
        color = const Color(0xFF00C853); // Bright Green
        label = l10n.accepted;
        break;
      case 'assigned':
      case 'pending':
        color = const Color(0xFFFFAB00); // Amber
        label = l10n.assigned;
        break;
      case 'rejected':
        color = const Color(0xFFFF1744); // Red Accent
        label = l10n.rejected;
        break;
      default:
        color = Colors.grey;
        label = l10n.unassigned;
    }

    return HStack([
          VxBox().size(6, 6).color(color).roundedFull.make(),
          8.widthBox,
          label.text.size(12).semiBold.color(color.withOpacity(0.9)).make(),
        ])
        .pSymmetric(h: 12, v: 6)
        .box
        .color(color.withOpacity(0.08))
        .border(color: color.withOpacity(0.2))
        .withRounded(value: 50)
        .make();
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return VStack(
      [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 48,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
        ),
        24.heightBox,
        message.text.size(16).color(AppColors.textSecondary).make(),
      ],
      alignment: MainAxisAlignment.center,
      crossAlignment: CrossAxisAlignment.center,
    ).centered();
  }
}
