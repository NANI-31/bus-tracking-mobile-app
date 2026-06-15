import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/coordinator/presentation/modules/driver_history_screen.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/user/application/user_provider.dart';
import 'package:collegebus/features/sos/application/sos_provider.dart';
import 'package:collegebus/core/providers/repository_providers.dart';

class DriverManagementTab extends ConsumerWidget {
  final Function(UserModel)? onEditDriver;
  final Function(BusModel)? onTrack;

  const DriverManagementTab({super.key, this.onEditDriver, this.onTrack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;

    if (collegeId == null) return const SizedBox.shrink();

    final pendingApprovals =
        ref.watch(pendingApprovalsProvider(collegeId)).value ?? [];
    final allDrivers =
        ref
            .watch(
              usersByRoleProvider((
                role: UserRole.driver,
                collegeId: collegeId,
              )),
            )
            .value ??
        [];
    final buses = ref.watch(collegeBusesStreamProvider(collegeId)).value ?? [];
    final onlineDriverIds =
        ref.watch(onlineDriversProvider(collegeId)).value ?? {};

    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(AppSizes.paddingMedium),
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
              isScrollable: false, // Fit all in one view
              labelColor: Colors.white,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                _buildDriversByStatus(
                  context,
                  ref,
                  'all',
                  allDrivers,
                  buses,
                  onlineDriverIds,
                ),
                _buildDriversByStatus(
                  context,
                  ref,
                  'assigned',
                  allDrivers,
                  buses,
                  onlineDriverIds,
                ),
                _buildDriversByStatus(
                  context,
                  ref,
                  'accepted',
                  allDrivers,
                  buses,
                  onlineDriverIds,
                ),
                _buildPendingApprovals(context, ref, pendingApprovals),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovals(
    BuildContext context,
    WidgetRef ref,
    List<UserModel> pendingApprovals,
  ) {
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
        return DriverCard(
          driver: driver,
          ref: ref,
          isApproval: true,
          onEditDriver: onEditDriver,
          onTrack: onTrack,
        );
      },
    );
  }

  Widget _buildDriversByStatus(
    BuildContext context,
    WidgetRef ref,
    String status,
    List<UserModel> allDrivers,
    List<BusModel> buses,
    Set<String> onlineDriverIds,
  ) {
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
          child: DriverCard(
            driver: driver,
            ref: ref,
            isApproval: false,
            bus: bus,
            onlineDriverIds: onlineDriverIds,
            onEditDriver: onEditDriver,
            onTrack: onTrack,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return VStack(
      [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 48,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ),
        ),
        24.heightBox,
        message.text
            .size(16)
            .color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))
            .make(),
      ],
      alignment: MainAxisAlignment.center,
      crossAlignment: CrossAxisAlignment.center,
    ).centered();
  }
}

class DriverCard extends StatefulWidget {
  final UserModel driver;
  final bool isApproval;
  final BusModel? bus;
  final Set<String> onlineDriverIds;
  final Function(UserModel)? onEditDriver;
  final Function(BusModel)? onTrack;
  final WidgetRef ref;

  const DriverCard({
    super.key,
    required this.driver,
    required this.ref,
    this.isApproval = false,
    this.bus,
    this.onlineDriverIds = const {},
    this.onEditDriver,
    this.onTrack,
  });

  @override
  State<DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<DriverCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInOut,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
        HapticFeedback.lightImpact();
      } else {
        _controller.reverse();
      }
    });
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
                  : Colors.grey.withValues(alpha: 0.2),
              width: 2.0,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                border: Border.all(color: Colors.white, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.4),
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
        color = const Color(0xFF00C853);
        label = l10n.accepted;
        break;
      case 'assigned':
      case 'pending':
        color = const Color(0xFFFFAB00);
        label = l10n.assigned;
        break;
      case 'rejected':
        color = const Color(0xFFFF1744);
        label = l10n.rejected;
        break;
      default:
        color = Colors.grey;
        label = l10n.unassigned;
    }

    return HStack([
      VxBox().size(6, 6).color(color).roundedFull.make(),
      8.widthBox,
      label.text
          .size(12)
          .semiBold
          .color(color.withValues(alpha: 0.9))
          .make(),
    ])
        .pSymmetric(h: 12, v: 6)
        .box
        .color(color.withValues(alpha: 0.08))
        .border(color: color.withValues(alpha: 0.2))
        .withRounded(value: 50)
        .make();
  }

  @override
  Widget build(BuildContext context) {
    String status = 'unassigned';
    if (widget.bus != null) {
      status = widget.bus!.assignmentStatus;
    }

    final isOnline = widget.onlineDriverIds.contains(widget.driver.id);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: widget.isApproval
          ? ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: _buildAvatar(context, widget.driver, isOnline),
              title: widget.driver.fullName.text.semiBold.size(16).make(),
              subtitle: _buildDriverStatusBadge(
                context,
                status,
              ).pOnly(top: 8).objectTopLeft(),
              trailing: HStack([
                IconButton(
                  icon: Icon(Icons.check, color: AppColors.success),
                  onPressed: () {
                    final approverId = widget.ref.read(currentUserProvider)?.id;
                    if (approverId != null) {
                      widget.ref
                          .read(userRepositoryProvider)
                          .approveUser(widget.driver.id, approverId);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.error),
                  onPressed: () =>
                      widget.ref.read(userRepositoryProvider).deleteUser(widget.driver.id),
                ),
              ]),
            )
          : Column(
              children: [
                InkWell(
                  onTap: _toggleExpanded,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        _buildAvatar(context, widget.driver, isOnline),
                        16.widthBox,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              widget.driver.fullName.text.semiBold.size(16).make(),
                              8.heightBox,
                              _buildDriverStatusBadge(context, status),
                            ],
                          ),
                        ),
                        RotationTransition(
                          turns: _rotateAnimation,
                          child: Icon(
                            Icons.expand_more,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  axisAlignment: 1.0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                    child: Column(
                      children: [
                        Divider(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                        ),
                        12.heightBox,
                        HStack([
                          ElevatedButton.icon(
                            onPressed: () {
                              widget.onEditDriver?.call(widget.driver);
                            },
                            icon: const Icon(Icons.edit, size: 20),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
                                  builder: (_) => DriverHistoryScreen(driver: widget.driver),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history, size: 20),
                            label: const Text('History'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                          ).expand(),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: (widget.bus != null &&
                                      widget.bus!.isActive &&
                                      widget.bus!.status != 'not-running')
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
                              boxShadow: (widget.bus != null &&
                                      widget.bus!.isActive &&
                                      widget.bus!.status != 'not-running')
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF2E3192).withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (widget.bus != null &&
                                    widget.bus!.isActive &&
                                    widget.bus!.status != 'not-running') {
                                  widget.onTrack?.call(widget.bus!);
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
                                color: (widget.bus != null &&
                                        widget.bus!.isActive &&
                                        widget.bus!.status != 'not-running')
                                    ? Colors.white
                                    : Colors.grey.shade400,
                              ),
                              label: const Text('Track'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.transparent,
                                foregroundColor: (widget.bus != null &&
                                        widget.bus!.isActive &&
                                        widget.bus!.status != 'not-running')
                                    ? Colors.white
                                    : Colors.grey.shade400,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ).expand(),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
