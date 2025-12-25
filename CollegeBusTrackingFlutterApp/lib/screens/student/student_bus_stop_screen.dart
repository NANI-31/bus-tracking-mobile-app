import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:provider/provider.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/services/api_service.dart';
import 'package:collegebus/models/route_model.dart';

class StudentBusStopScreen extends StatefulWidget {
  const StudentBusStopScreen({super.key});

  @override
  State<StudentBusStopScreen> createState() => _StudentBusStopScreenState();
}

class _StudentBusStopScreenState extends State<StudentBusStopScreen> {
  String _searchQuery = "";
  String? _updatingStop;

  Future<void> _updatePreferredStop(
    String stopName,
    String routeId,
    String? stopId,
    double lat,
    double lng,
    String userId,
    ApiService apiService,
    AuthService authService,
    String routeName,
  ) async {
    // Unique ID for the updating state (stopName + routeId)
    final uniqueId = '$stopName-$routeId';
    setState(() => _updatingStop = uniqueId);
    try {
      final updatedUser = await apiService.updateUser(userId, {
        'preferredStop': stopName,
        'routeId': routeId,
        'stopId': stopId ?? stopName, // Use name as ID if explicit ID missing
        'stopName': stopName,
        'stopLocation': {'lat': lat, 'lng': lng},
      });
      authService.updateCurrentUser(updatedUser);
      if (mounted) {
        VxToast.show(context, msg: 'Stop updated to $stopName ($routeName)');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        VxToast.show(context, msg: 'Error updating stop: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _updatingStop = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<DataService>(context);
    final apiService = Provider.of<ApiService>(context);
    final user = authService.currentUserModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: 'Select Bus Stop'.text.bold.make(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: VStack([
        // Header Section
        VxBox(
              child: VStack([
                'Where will you board?'.text.white.extraBold.size(24).make(),
                8.heightBox,
                'Select your stop and route to receive arrival alerts.'.text
                    .color(Colors.white.withValues(alpha: 0.7))
                    .make(),
                24.heightBox,
                TextField(
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search stop or route...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ]),
            )
            .width(double.infinity)
            .p24
            .color(Theme.of(context).primaryColor)
            .customRounded(
              const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            )
            .make(),

        // Stops List
        StreamBuilder<List<RouteModel>>(
          stream: firestoreService.getRoutesByCollege(user.collegeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator().centered().expand();
            }

            // Build a list of all stops with their route context
            final stopOptions = <Map<String, dynamic>>[];

            if (snapshot.hasData) {
              for (final route in snapshot.data!) {
                // Start Point
                stopOptions.add({
                  'name': route.startPoint.name,
                  'lat': route.startPoint.lat,
                  'lng': route.startPoint.lng,
                  'type': 'Start Point',
                  'routeId': route.id,
                  'routeName': route.routeName,
                });

                // End Point
                stopOptions.add({
                  'name': route.endPoint.name,
                  'lat': route.endPoint.lat,
                  'lng': route.endPoint.lng,
                  'type': 'End Point',
                  'routeId': route.id,
                  'routeName': route.routeName,
                });

                // Intermediate Points
                for (final point in route.stopPoints) {
                  stopOptions.add({
                    'name': point.name,
                    'lat': point.lat,
                    'lng': point.lng,
                    'type': 'Intermediate',
                    'routeId': route.id,
                    'routeName': route.routeName,
                  });
                }
              }
            }

            final filteredOptions = stopOptions.where((option) {
              final search = _searchQuery.toLowerCase();
              final name = (option['name'] as String).toLowerCase();
              final route = (option['routeName'] as String).toLowerCase();
              return name.contains(search) || route.contains(search);
            }).toList();

            // Sort by name
            filteredOptions.sort(
              (a, b) => (a['name'] as String).compareTo(b['name'] as String),
            );

            if (filteredOptions.isEmpty) {
              return [
                const Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
                16.heightBox,
                'No stops found'.text.gray500.make(),
              ].vStack().centered().expand();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOptions.length,
              itemBuilder: (context, index) {
                final option = filteredOptions[index];
                final name = option['name'] as String;
                final routeId = option['routeId'] as String;
                final routeName = option['routeName'] as String;

                // Unique check: matches stop AND route
                final isSelected =
                    user.preferredStop == name && user.routeId == routeId;
                final uniqueId = '$name-$routeId';
                final isUpdating = _updatingStop == uniqueId;

                return _buildStopItem(
                  context: context,
                  stopName: name,
                  routeName: routeName,
                  isSelected: isSelected,
                  isUpdating: isUpdating,
                  onTap: () => _updatePreferredStop(
                    name,
                    routeId,
                    null, // implicit ID
                    option['lat'] as double,
                    option['lng'] as double,
                    user.id,
                    apiService,
                    authService,
                    routeName,
                  ),
                );
              },
            ).expand();
          },
        ),
      ]),
    );
  }

  Widget _buildStopItem({
    required BuildContext context,
    required String stopName,
    required String routeName,
    required bool isSelected,
    required bool isUpdating,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSelected || isUpdating ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        (isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey)
                            .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    size: 24,
                  ),
                ),
                16.widthBox,
                VStack([
                  stopName.text.bold
                      .size(16)
                      .color(isSelected ? Theme.of(context).primaryColor : null)
                      .make(),
                  4.heightBox,
                  'Route: $routeName'.text.size(12).gray500.make(),
                ]).expand(),
                if (isUpdating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
