import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/features/payment/presentation/screens/payment_screen.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/notification/application/notification_provider.dart';

import 'widgets/home/student_skeletons.dart';
import 'package:collegebus/shared/widgets/skeleton_transition.dart';
import 'package:collegebus/shared/widgets/navigation/curved_bottom_nav_bar.dart';
import 'widgets/home/welcome_section.dart';
import 'widgets/home/bus_status_card.dart';
import 'widgets/home/route_card.dart';
import 'widgets/home/track_button.dart';

class StudentHomeScreen extends ConsumerWidget {
  final bool isTab;
  final VoidCallback? onTrackLive;

  const StudentHomeScreen({super.key, this.isTab = false, this.onTrackLive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.collegeId.isEmpty) {
      return const Scaffold(body: StudentHomeSkeleton());
    }

    final busesAsync = ref.watch(collegeBusesStreamProvider(user.collegeId));
    final routesAsync = ref.watch(collegeRoutesProvider(user.collegeId));
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12181F) : const Color(0xFFF5F7FA),
      drawer: null,
      appBar: isTab
          ? null
          : AppBar(
              title: const Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              elevation: 0,
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => context.push('/notifications'),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF12181F), const Color(0xFF1A232E)]
                : [const Color(0xFFF5F7FA), const Color(0xFFEBF0F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SkeletonTransition(
          isLoading: busesAsync.isLoading || routesAsync.isLoading,
          skeleton: const StudentHomeSkeleton(),
          child: (busesAsync.isLoading || routesAsync.isLoading)
              ? const SizedBox.shrink()
              : busesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) {
                    final lastBuses = busesAsync.valueOrNull ?? [];
                    final lastRoutes = routesAsync.valueOrNull ?? [];
                    return _buildMainHomeUI(context, ref, user, lastBuses, lastRoutes);
                  },
                  data: (buses) => routesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (err, stack) {
                      final lastRoutes = routesAsync.valueOrNull ?? [];
                      return _buildMainHomeUI(context, ref, user, buses, lastRoutes);
                    },
                    data: (routes) => _buildMainHomeUI(context, ref, user, buses, routes),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMainHomeUI(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    List<BusModel> buses,
    List<RouteModel> routes,
  ) {
    final userName = user?.fullName.split(' ').first ?? 'Student';
    RouteModel? assignedRoute;
    BusModel? assignedBus;

    if (user.routeId != null) {
      final matchingRoutes = routes.where((r) => r.id == user.routeId);
      assignedRoute = matchingRoutes.isNotEmpty ? matchingRoutes.first : null;

      final matchingBuses = buses.where((b) => b.routeId == user.routeId);
      assignedBus = matchingBuses.isNotEmpty ? matchingBuses.first : null;
    }

    final isWide = context.isTabletLayout || context.isDesktopLayout;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(collegeBusesStreamProvider(user.collegeId));
          ref.invalidate(collegeRoutesProvider(user.collegeId));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Greeting, Vehicle Status, Insights, CTA)
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WelcomeSection(userName: userName, isPremium: user.hasActivePremium),
                          const SizedBox(height: 24),
                          if (!user.hasActivePremium) ...[
                            _buildPremiumUpsell(context),
                            const SizedBox(height: 24),
                          ],
                          BusStatusCard(
                            bus: assignedBus,
                            userStop: user.preferredStop ?? user.stopName,
                            stopLocation: user.stopLocation,
                          ),
                          const SizedBox(height: 24),
                          _buildPremiumInsights(context, user.hasActivePremium),
                          const SizedBox(height: 24),
                          TrackBusButton(
                            onTap: () {
                              if (onTrackLive != null) {
                                onTrackLive!();
                              } else {
                                context.go('/student');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column (Route Details)
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RouteCard(
                            route: assignedRoute,
                            userStop: user.preferredStop ?? user.stopName,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                // Mobile layout
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WelcomeSection(userName: userName, isPremium: user.hasActivePremium),
                    const SizedBox(height: 24),
                    if (!user.hasActivePremium) ...[
                      _buildPremiumUpsell(context),
                      const SizedBox(height: 24),
                    ],
                    BusStatusCard(
                      bus: assignedBus,
                      userStop: user.preferredStop ?? user.stopName,
                      stopLocation: user.stopLocation,
                    ),
                    const SizedBox(height: 24),
                    RouteCard(
                      route: assignedRoute,
                      userStop: user.preferredStop ?? user.stopName,
                    ),
                    const SizedBox(height: 24),
                    _buildPremiumInsights(context, user.hasActivePremium),
                    const SizedBox(height: 28),
                    TrackBusButton(
                      onTap: () {
                        if (onTrackLive != null) {
                          onTrackLive!();
                        } else {
                          context.go('/student');
                        }
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Live location updates every 30 seconds",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              BottomNavSpacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumUpsell(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF3F51B5).withValues(alpha: 0.8), const Color(0xFF1A237E).withValues(alpha: 0.8)]
              : [const Color(0xFF5C6BC0), const Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F51B5).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.amberAccent,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Upgrade to Premium",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Live alerts & advanced bus insights",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaymentScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3949AB),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Get Now",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInsights(BuildContext context, bool isPremium) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.05),
          width: 1.0,
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.amberAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.amberAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Trip Insights",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (!isPremium)
                Icon(
                  Icons.lock_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isPremium)
            Row(
              children: [
                Expanded(child: _buildInsightItem(context, "Bus Load", "Low", Icons.people_outline)),
                const SizedBox(width: 16),
                Expanded(child: _buildInsightItem(context, "ETA Sync", "98%", Icons.speed)),
              ],
            )
          else
            Text(
              "Upgrade to Premium to see live load and speed insights",
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.amberAccent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
