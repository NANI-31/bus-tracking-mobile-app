import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/features/payment/presentation/screens/payment_screen.dart';

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
    if (user == null || user.collegeId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final busesAsync = ref.watch(collegeBusesStreamProvider(user.collegeId));
    final routesAsync = ref.watch(collegeRoutesProvider(user.collegeId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: null,
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
        error: (err, stack) {
          // Use last known data or empty list during error
          final lastBuses = busesAsync.valueOrNull ?? [];
          final lastRoutes = routesAsync.valueOrNull ?? [];
          return _buildMainHomeUI(context, ref, user, lastBuses, lastRoutes);
        },
        data: (buses) => routesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            // Use last known routes or empty list during error
            final lastRoutes = routesAsync.valueOrNull ?? [];
            return _buildMainHomeUI(context, ref, user, buses, lastRoutes);
          },
          data: (routes) => _buildMainHomeUI(context, ref, user, buses, routes),
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

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(collegeBusesStreamProvider(user.collegeId));
          ref.invalidate(collegeRoutesProvider(user.collegeId));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              if (!user.hasActivePremium)
                _buildPremiumUpsell(context)
              else if (user.premiumUntil != null)
                _buildPremiumStatus(context, user, user.premiumUntil!),
              const SizedBox(height: 16),
              WelcomeSection(userName: userName),
              const SizedBox(height: 16),
              BusStatusCard(
                bus: assignedBus,
                userStop: user.preferredStop ?? user.stopName,
                stopLocation: user.stopLocation,
              ),
              const SizedBox(height: 20),
              RouteCard(
                route: assignedRoute,
                userStop: user.preferredStop ?? user.stopName,
              ),
              const SizedBox(height: 16),
              _buildPremiumInsights(context, user.hasActivePremium),
              const SizedBox(height: 20),
              TrackBusButton(
                onTap: () {
                  if (onTrackLive != null) {
                    onTrackLive!();
                  } else {
                    context.go('/student');
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                  const SizedBox(width: 8.0),
                  Text(
                    "Live location updates every 30 seconds",
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumUpsell(BuildContext context) {
    return VxBox(
      child: HStack([
        const Icon(
          Icons.workspace_premium_rounded,
          color: Colors.amber,
          size: 32,
        ),
        16.widthBox,
        VStack([
          "Upgrade to Premium".text.white.bold.size(16).make(),
          "Live alerts & advanced bus insights".text.white.size(12).make(),
        ]).expand(),
        ElevatedButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PaymentScreen())),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 32),
          ),
          child: "Get Now".text.bold.make(),
        ),
      ]),
    ).indigo600.roundedLg.p16.shadowLg.make();
  }

  Widget _buildPremiumStatus(
    BuildContext context,
    dynamic user,
    DateTime expiry,
  ) {
    final daysLeft = expiry.difference(DateTime.now()).inDays;
    return VxBox(
      child: HStack([
        const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 24),
        12.widthBox,
        "${user.planDisplayName} Active • $daysLeft days left".text.white.bold
            .size(12)
            .make(),
      ]),
    ).roundedFull.px16.py8.make();
  }

  Widget _buildPremiumInsights(BuildContext context, bool isPremium) {
    // Only full premium users get full insights. Trial users see locked message.
    return VxBox(
          child: VStack([
            HStack([
              const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
              8.widthBox,
              "Trip Insights".text.bold.size(16).make(),
              const Spacer(),
              if (!isPremium)
                const Icon(Icons.lock_rounded, color: Colors.grey, size: 16),
            ]),
            12.heightBox,
            if (isPremium)
              HStack([
                _buildInsightItem("Bus Load", "Low", Icons.people_outline),
                16.widthBox,
                _buildInsightItem("ETA Sync", "98%", Icons.speed),
              ])
            else
              "Upgrade to Premium to see live load and speed insights".text
                  .color(Colors.grey)
                  .italic
                  .make(),
          ]),
        )
        .color(Colors.white.withValues(alpha: 0.05))
        .roundedLg
        .p16
        .border(color: Colors.white.withValues(alpha: 0.1))
        .make();
  }

  Widget _buildInsightItem(String label, String value, IconData icon) {
    return VStack([
      HStack([
        Icon(icon, size: 14, color: Colors.amber),
        4.widthBox,
        label.text.size(12).color(Colors.grey).make(),
      ]),
      4.heightBox,
      value.text.bold.size(14).make(),
    ]);
  }
}
