import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/providers/auth_provider.dart';
import 'package:collegebus/providers/bus_provider.dart';
import 'package:collegebus/providers/route_provider.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/widgets/app_drawer.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:go_router/go_router.dart';

// New standalone widgets
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
    final userName = user?.fullName.split(' ').first ?? 'Student';

    if (user == null || user.collegeId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final busesAsync = ref.watch(collegeBusesStreamProvider(user.collegeId));
    final routesAsync = ref.watch(collegeRoutesProvider(user.collegeId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: isTab ? null : AppDrawer(user: user),
      appBar: isTab
          ? null
          : AppBar(
              title: const Text('Home'),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/notifications'),
                ),
              ],
            ),
      body: busesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading buses: $err')),
        data: (buses) => routesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Error loading routes: $err')),
          data: (routes) {
            RouteModel? assignedRoute;
            BusModel? assignedBus;

            if (user.routeId != null) {
              final matchingRoutes = routes.where((r) => r.id == user.routeId);
              assignedRoute = matchingRoutes.isNotEmpty
                  ? matchingRoutes.first
                  : null;

              final matchingBuses = buses.where(
                (b) => b.routeId == user.routeId,
              );
              assignedBus = matchingBuses.isNotEmpty
                  ? matchingBuses.first
                  : null;
            }

            return RefreshIndicator(
              onRefresh: () async {
                // Socket handles updates
              },
              child: VStack([
                16.heightBox,
                WelcomeSection(userName: userName),
                16.heightBox,
                BusStatusCard(
                  bus: assignedBus,
                  userStop: user.preferredStop ?? user.stopName,
                  stopLocation: user.stopLocation,
                ),
                20.heightBox,
                RouteCard(
                  route: assignedRoute,
                  userStop: user.preferredStop ?? user.stopName,
                ),
                16.heightBox,
                TrackBusButton(
                  onTap: () {
                    if (onTrackLive != null) {
                      onTrackLive!();
                    } else {
                      context.go('/student');
                    }
                  },
                ),
                16.heightBox,
                HStack([
                  const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                  8.widthBox,
                  "Live location updates every 30 seconds".text
                      .size(13)
                      .color(
                        Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      )
                      .make(),
                ], alignment: MainAxisAlignment.center).centered(),
                20.heightBox,
              ]).pSymmetric(h: 20).scrollVertical(),
            );
          },
        ),
      ),
    );
  }
}
