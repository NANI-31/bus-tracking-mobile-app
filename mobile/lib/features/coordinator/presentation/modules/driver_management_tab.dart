import 'dart:math' as math;
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
import 'package:collegebus/shared/widgets/shimmer_skeletons.dart';
import 'package:collegebus/features/coordinator/presentation/widgets/coordinator_list_layout.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'bubble_tab_selector.dart';

class DriverManagementTab extends ConsumerWidget {
  final Function(UserModel)? onEditDriver;
  final Function(BusModel)? onTrack;

  const DriverManagementTab({super.key, this.onEditDriver, this.onTrack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final collegeId = user?.collegeId;

    if (collegeId == null) return const SizedBox.shrink();

    final allDriversAsync = ref.watch(
      usersByRoleProvider((
        role: UserRole.driver,
        collegeId: collegeId,
      )),
    );
    final busesAsync = ref.watch(collegeBusesStreamProvider(collegeId));
    final onlineDriverIdsAsync = ref.watch(onlineDriversProvider(collegeId));

    final allDrivers = allDriversAsync.value ?? [];
    final buses = busesAsync.value ?? [];
    final onlineDriverIds = onlineDriverIdsAsync.value ?? {};
    final isLoading = allDriversAsync.isLoading || busesAsync.isLoading;

    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          BubbleTabSelector(
            icons: const [
              Icons.people_outline,
              Icons.assignment_ind_outlined,
              Icons.check_circle_outline,
              Icons.assignment_turned_in_outlined,
            ],
            labels: [
              l10n.all,
              l10n.assigned,
              l10n.accepted,
              'Teachers',
            ],
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                DriverStatusList(
                  status: 'all',
                  allDrivers: allDrivers,
                  buses: buses,
                  onlineDriverIds: onlineDriverIds,
                  isLoading: isLoading,
                  onTrack: onTrack,
                  onEditDriver: onEditDriver,
                ),
                DriverStatusList(
                  status: 'assigned',
                  allDrivers: allDrivers,
                  buses: buses,
                  onlineDriverIds: onlineDriverIds,
                  isLoading: isLoading,
                  onTrack: onTrack,
                  onEditDriver: onEditDriver,
                ),
                DriverStatusList(
                  status: 'accepted',
                  allDrivers: allDrivers,
                  buses: buses,
                  onlineDriverIds: onlineDriverIds,
                  isLoading: isLoading,
                  onTrack: onTrack,
                  onEditDriver: onEditDriver,
                ),
                const TeacherOverrideRequestsSubtab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DriverStatusList extends ConsumerStatefulWidget {
  final String status;
  final List<UserModel> allDrivers;
  final List<BusModel> buses;
  final Set<String> onlineDriverIds;
  final bool isLoading;
  final Function(BusModel)? onTrack;
  final Function(UserModel)? onEditDriver;

  const DriverStatusList({
    super.key,
    required this.status,
    required this.allDrivers,
    required this.buses,
    required this.onlineDriverIds,
    required this.isLoading,
    this.onTrack,
    this.onEditDriver,
  });

  @override
  ConsumerState<DriverStatusList> createState() => _DriverStatusListState();
}

class _DriverStatusListState extends ConsumerState<DriverStatusList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Mandatory for KeepAlive

    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    List<UserModel> filteredDrivers = [];

    if (widget.status == 'all') {
      filteredDrivers = widget.allDrivers;
    } else if (widget.status == 'assigned') {
      // All drivers who have ANY non-unassigned assignment status
      final assignedBusDriverIds = widget.buses
          .where((b) => b.assignmentStatus != 'unassigned')
          .map((b) => b.driverId)
          .toSet();
      filteredDrivers = widget.allDrivers
          .where((d) => assignedBusDriverIds.contains(d.id))
          .toList();
    } else if (widget.status == 'accepted') {
      // Drivers with specific assignment status
      final targetBusDriverIds = widget.buses
          .where((b) => b.assignmentStatus == 'accepted')
          .map((b) => b.driverId)
          .toSet();
      filteredDrivers = widget.allDrivers
          .where((d) => targetBusDriverIds.contains(d.id))
          .toList();
    }

    if (widget.isLoading && filteredDrivers.isEmpty) {
      return const DriverListSkeleton();
    }

    if (filteredDrivers.isEmpty) {
      return _buildEmptyState(
        context,
        l10n.noDriversInCategory,
        Icons.people_outline,
      );
    }

    return CoordinatorListLayout<UserModel>(
      pageStorageKey: PageStorageKey<String>('driver_list_${widget.status}'),
      items: filteredDrivers,
      onRefresh: () async {
        final user = ref.read(currentUserProvider);
        if (user?.collegeId != null) {
          ref.invalidate(usersByRoleProvider);
          ref.invalidate(collegeBusesStreamProvider);
          ref.invalidate(onlineDriversProvider);
          await Future.delayed(const Duration(milliseconds: 600));
        }
      },
      emptyState: _buildEmptyState(
        context,
        l10n.noDriversInCategory,
        Icons.people_outline,
      ),
      itemBuilder: (context, driver, itemIndex) {
        BusModel? bus;
        try {
          bus = widget.buses.firstWhere((b) => b.driverId == driver.id);
        } catch (_) {
          bus = null;
        }
        return DriverCard(
          driver: driver,
          ref: ref,
          isApproval: false,
          bus: bus,
          onlineDriverIds: widget.onlineDriverIds,
          onEditDriver: widget.onEditDriver,
          onTrack: widget.onTrack,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSizes.paddingLarge),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: VStack(
          [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            16.heightBox,
            message.text
                .size(15)
                .medium
                .color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))
                .center
                .make(),
          ],
          alignment: MainAxisAlignment.center,
          crossAlignment: CrossAxisAlignment.center,
        ),
      ),
    );
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
      curve: const Cubic(0.34, 1.56, 0.64, 1.0),
      reverseCurve: Curves.easeOut,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
        reverseCurve: Curves.easeOut,
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
    final avatarWidget = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isOnline
              ? const Color(0xFF00C6E6)
              : Colors.grey.withValues(alpha: 0.2),
          width: 2.0,
        ),
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF00C6E6), Color(0xFF0097B2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: (driver.fullName.isNotEmpty ? driver.fullName[0].toUpperCase() : '?')
              .text
              .size(20)
              .color(Colors.white)
              .bold
              .make(),
        ),
      ),
    );

    return Stack(
      children: [
        if (isOnline)
          OnlineAvatarAura(child: avatarWidget)
        else
          avatarWidget,
        if (isOnline)
          const Positioned(
            bottom: 2,
            right: 2,
            child: OnlineStatusDot(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String status = 'unassigned';
    if (widget.bus != null) {
      status = widget.bus!.assignmentStatus;
    }

    final isOnline = widget.onlineDriverIds.contains(widget.driver.id);

    final Color cardBorderColor;
    final List<Color> cardGradientColors;
    final List<BoxShadow> cardShadows;

    if (isOnline) {
      if (isDark) {
        cardBorderColor = const Color(0xFF00C6E6).withValues(alpha: 0.45);
        cardGradientColors = [
          const Color(0xFF0A2E3D), // Deep Navy-Teal
          const Color(0xFF05161F), // Darker Navy
        ];
        cardShadows = [
          BoxShadow(
            color: const Color(0xFF00C6E6).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ];
      } else {
        cardBorderColor = const Color(0xFF0097B2).withValues(alpha: 0.35);
        cardGradientColors = [
          const Color(0xFFE0F7FA), // Fresh Ice-Teal
          const Color(0xFFF0FDFD), // Very light soft blue-green
        ];
        cardShadows = [
          BoxShadow(
            color: const Color(0xFF0097B2).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
      }
    } else {
      if (isDark) {
        cardBorderColor = const Color(0xFF334155).withValues(alpha: 0.35); // Slate border
        cardGradientColors = [
          const Color(0xFF1E293B), // Slate Grey-Blue
          const Color(0xFF0F172A), // Dark Slate/Navy
        ];
        cardShadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ];
      } else {
        cardBorderColor = const Color(0xFFE2E8F0); // Light Slate border
        cardGradientColors = [
          Colors.white,
          const Color(0xFFF8FAFC), // Off-white/slate-tinted
        ];
        cardShadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cardBorderColor,
          width: 1.5,
        ),
        boxShadow: cardShadows,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardGradientColors,
        ),
      ),
      child: widget.isApproval
          ? ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: widget.bus != null
                  ? Hero(
                      tag: 'bus_marker_${widget.bus!.id}',
                      child: _buildAvatar(context, widget.driver, isOnline),
                    )
                  : _buildAvatar(context, widget.driver, isOnline),
              title: widget.driver.fullName.text.semiBold.size(16).make(),
              subtitle: _buildDriverStatusBadge(
                context,
                status,
              ).pOnly(top: 8).objectTopLeft(),
              trailing: HStack([
                GestureDetector(
                  onTap: () {
                    final approverId = widget.ref.read(currentUserProvider)?.id;
                    if (approverId != null) {
                      widget.ref
                          .read(userRepositoryProvider)
                          .approveUser(widget.driver.id, approverId);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 14, color: Colors.green.shade700),
                        4.widthBox,
                        'Approve'.text.bold.size(11).color(Colors.green.shade700).make(),
                      ],
                    ),
                  ),
                ),
                12.widthBox,
                GestureDetector(
                  onTap: () => widget.ref.read(userRepositoryProvider).deleteUser(widget.driver.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded, size: 14, color: Colors.red.shade700),
                        4.widthBox,
                        'Reject'.text.bold.size(11).color(Colors.red.shade700).make(),
                      ],
                    ),
                  ),
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
                        widget.bus != null
                            ? Hero(
                                tag: 'bus_marker_${widget.bus!.id}',
                                child: _buildAvatar(context, widget.driver, isOnline),
                              )
                            : _buildAvatar(context, widget.driver, isOnline),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          color: isDark
                              ? (isOnline
                                  ? const Color(0xFF00C6E6).withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.08))
                              : (isOnline
                                  ? const Color(0xFF0097B2).withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.06)),
                        ),
                        12.heightBox,
                        
                        // Contact Info Section
                        VStack([
                          if (widget.driver.phoneNumber != null)
                            HStack([
                              const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                              8.widthBox,
                              widget.driver.phoneNumber!.text.size(13).medium.color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)).make(),
                            ]).pOnly(bottom: 6),
                          HStack([
                            const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                            8.widthBox,
                            widget.driver.email.text.size(13).medium.color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)).make(),
                          ]).pOnly(bottom: 6),
                          if (widget.bus != null)
                            HStack([
                              const Icon(Icons.directions_bus_outlined, size: 16, color: Color(0xFF00C6E6)),
                              8.widthBox,
                              'Bus Number: '.text.size(13).color(Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)).make(),
                              widget.bus!.busNumber.text.size(13).bold.color(const Color(0xFF00C6E6)).make(),
                              if (widget.bus!.capacity != null) ...[
                                8.widthBox,
                                '(${widget.bus!.capacity} capacity)'.text.size(12).color(Colors.grey.shade500).make(),
                              ],
                            ]).pOnly(bottom: 6),
                        ]).pSymmetric(v: 4),
                        
                        16.heightBox,
                        
                        // Action Buttons Row
                        HStack([
                          ElevatedButton.icon(
                            onPressed: () {
                              widget.onEditDriver?.call(widget.driver);
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: isDark
                                  ? (isOnline
                                      ? const Color(0xFF00C6E6).withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.05))
                                  : (isOnline
                                      ? const Color(0xFF0097B2).withValues(alpha: 0.06)
                                      : Colors.grey.shade100),
                              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isDark
                                      ? (isOnline
                                          ? const Color(0xFF00C6E6).withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.08))
                                      : (isOnline
                                          ? const Color(0xFF0097B2).withValues(alpha: 0.15)
                                          : Theme.of(context).dividerColor.withValues(alpha: 0.1)),
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
                            icon: const Icon(Icons.history_outlined, size: 18),
                            label: const Text('History'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: isDark
                                  ? (isOnline
                                      ? const Color(0xFF00C6E6).withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.05))
                                  : (isOnline
                                      ? const Color(0xFF0097B2).withValues(alpha: 0.06)
                                      : Colors.grey.shade100),
                              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isDark
                                      ? (isOnline
                                          ? const Color(0xFF00C6E6).withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.08))
                                      : (isOnline
                                          ? const Color(0xFF0097B2).withValues(alpha: 0.15)
                                          : Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                                ),
                              ),
                            ),
                          ).expand(),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: (widget.bus != null &&
                                      widget.bus!.isActive &&
                                      widget.bus!.status != 'not-running')
                                  ? const LinearGradient(
                                      colors: [Color(0xFF00C6E6), Color(0xFF0097B2)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: (widget.bus != null &&
                                      widget.bus!.isActive &&
                                      widget.bus!.status != 'not-running')
                                  ? null
                                  : (isDark
                                      ? (isOnline
                                          ? const Color(0xFF00C6E6).withValues(alpha: 0.05)
                                          : Colors.white.withValues(alpha: 0.04))
                                      : Colors.grey.shade200),
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
                                Icons.location_searching_rounded,
                                size: 18,
                                color: (widget.bus != null &&
                                        widget.bus!.isActive &&
                                        widget.bus!.status != 'not-running')
                                    ? Colors.white
                                    : Colors.grey.shade400,
                              ),
                              label: const Text('Track'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.transparent,
                                foregroundColor: (widget.bus != null &&
                                        widget.bus!.isActive &&
                                        widget.bus!.status != 'not-running')
                                    ? Colors.white
                                    : Colors.grey.shade400,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
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


class OnlineStatusDot extends StatefulWidget {
  const OnlineStatusDot({super.key});

  @override
  State<OnlineStatusDot> createState() => _OnlineStatusDotState();
}

class _OnlineStatusDotState extends State<OnlineStatusDot> with SingleTickerProviderStateMixin {
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
        final double scale = 1.0 + (_controller.value * 1.5);
        final double opacity = (1.0 - _controller.value).clamp(0.0, 1.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: opacity * 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class AnimatedTabIcon extends StatefulWidget {
  final IconData icon;
  final int index;

  const AnimatedTabIcon({
    super.key,
    required this.icon,
    required this.index,
  });

  @override
  State<AnimatedTabIcon> createState() => _AnimatedTabIconState();
}

class _AnimatedTabIconState extends State<AnimatedTabIcon>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
        reverseCurve: Curves.easeOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.15 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
        reverseCurve: Curves.easeOut,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = DefaultTabController.of(context);
    if (newController != _tabController) {
      _tabController?.removeListener(_handleTabChange);
      _tabController = newController;
      _tabController?.addListener(_handleTabChange);
      if (_tabController != null) {
        if (_tabController!.index == widget.index) {
          _controller.value = 1.0;
        } else {
          _controller.value = 0.0;
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController == null) return;
    final isSelected = _tabController!.index == widget.index;
    if (isSelected) {
      if (_controller.status != AnimationStatus.completed &&
          _controller.status != AnimationStatus.forward) {
        _controller.forward();
      }
    } else {
      if (_controller.status != AnimationStatus.dismissed &&
          _controller.status != AnimationStatus.reverse) {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: child,
          ),
        );
      },
      child: Icon(
        widget.icon,
        size: 20,
      ),
    );
  }
}

class OnlineAvatarAura extends StatefulWidget {
  final Widget child;
  const OnlineAvatarAura({super.key, required this.child});

  @override
  State<OnlineAvatarAura> createState() => _OnlineAvatarAuraState();
}

class _OnlineAvatarAuraState extends State<OnlineAvatarAura> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 4.0, end: 18.0).animate(
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C6E6).withValues(alpha: 0.22),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value * 0.35,
              ),
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.12),
                blurRadius: _glowAnimation.value * 1.5,
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class TeacherOverrideRequestsSubtab extends ConsumerStatefulWidget {
  const TeacherOverrideRequestsSubtab({super.key});

  @override
  ConsumerState<TeacherOverrideRequestsSubtab> createState() =>
      _TeacherOverrideRequestsSubtabState();
}

class _TeacherOverrideRequestsSubtabState
    extends ConsumerState<TeacherOverrideRequestsSubtab> {
  bool _isProcessing = false;

  Future<void> _handleRequest(String requestId, String status) async {
    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(busRepositoryProvider);
      await repo.handleTeacherOverrideRequest(requestId, status);
      ref.invalidate(teacherOverrideRequestsProvider);
      if (mounted) {
        SuccessModal.show(
          context: context,
          title: status == 'approved' ? 'Request Approved' : 'Request Rejected',
          message: status == 'approved'
              ? 'Teacher is now authorized to broadcast locations.'
              : 'Teacher override request has been rejected.',
          primaryActionText: 'OK',
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(
          context: context,
          error: 'Action failed: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(teacherOverrideRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          err.toString().text.color(AppColors.error).make().centered(),
      data: (requests) {
        if (requests.isEmpty) {
          return VStack([
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey,
            ).pOnly(bottom: 16),
            'No pending teacher tracking requests'.text.gray500.make(),
          ]).centered();
        }

        return ListView.builder(
          itemCount: requests.length,
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          itemBuilder: (context, index) {
            final reqMap = requests[index];
            final requestId = reqMap['_id'] as String;
            final teacher = reqMap['teacherId'] as Map<String, dynamic>? ?? {};
            final bus = reqMap['busId'] as Map<String, dynamic>? ?? {};
            final teacherName = teacher['fullName'] as String? ?? 'Teacher';
            final teacherEmail = teacher['email'] as String? ?? '';
            final busNumber = bus['busNumber'] as String? ?? 'N/A';

            return Card(
              margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: VStack([
                HStack([
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: 'Bus $busNumber'.text.bold.color(AppColors.primary).make(),
                  ),
                  const Spacer(),
                  'Pending'.text.amber500.bold.make(),
                ]).pOnly(bottom: 12),

                HStack([
                  const Icon(Icons.person, color: Colors.blueGrey, size: 20).pOnly(right: 8),
                  VStack([
                    teacherName.text.bold.lg.make(),
                    if (teacherEmail.isNotEmpty)
                      teacherEmail.text.size(12).gray500.make(),
                  ]).expand(),
                ]),

                const Divider().pSymmetric(v: 12),

                if (_isProcessing)
                  const CircularProgressIndicator().centered().pOnly(bottom: 8)
                else
                  HStack([
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _handleRequest(requestId, 'rejected'),
                        child: 'Reject'.text.bold.make(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _handleRequest(requestId, 'approved'),
                        child: 'Approve'.text.bold.make(),
                      ),
                    ),
                  ]),
              ]).p(16),
            );
          },
        );
      },
    );
  }
}


