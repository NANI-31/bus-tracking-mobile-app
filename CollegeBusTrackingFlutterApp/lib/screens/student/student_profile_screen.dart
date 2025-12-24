import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/app_drawer.dart';
import 'package:collegebus/services/theme_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/services/api_service.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:velocity_x/velocity_x.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  String? _updatingStop;

  Future<void> _updatePreferredStop(
    String stop,
    String userId,
    ApiService apiService,
    AuthService authService,
  ) async {
    setState(() => _updatingStop = stop);
    try {
      final updatedUser = await apiService.updateUser(userId, {
        'preferredStop': stop,
      });
      authService.updateCurrentUser(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferred stop updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating stop: $e')));
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
    final firestoreService = Provider.of<FirestoreService>(context);
    final apiService = Provider.of<ApiService>(context);
    final user = authService.currentUserModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: themeService.useBottomNavigation
              ? null
              : AppDrawer(user: user, authService: authService),
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 0,
          ),
          body: VStack([
            // Header Section
            VxBox(
                  child: VStack([
                    16.heightBox,
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child:
                          (user.fullName.isNotEmpty
                                  ? user.fullName.substring(0, 1).toUpperCase()
                                  : 'U')
                              .text
                              .size(36)
                              .bold
                              .color(Theme.of(context).primaryColor)
                              .make(),
                    ),
                    16.heightBox,
                    user.fullName.text
                        .size(24)
                        .bold
                        .color(Theme.of(context).colorScheme.onPrimary)
                        .make(),
                    8.heightBox,
                    user.email.text
                        .size(14)
                        .color(
                          Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.8),
                        )
                        .make(),
                  ], crossAlignment: CrossAxisAlignment.center),
                )
                .width(double.infinity)
                .color(Theme.of(context).primaryColor)
                .customRounded(
                  const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                )
                .make()
                .pOnly(bottom: 32),

            24.heightBox,

            // Details Section
            VStack([
              _buildProfileCard(
                context: context,
                title: 'Account Information',
                children: [
                  _buildProfileItem(
                    context: context,
                    icon: Icons.badge,
                    title: 'Role',
                    value: user.role.displayName,
                  ),
                  16.heightBox,
                  _buildProfileItem(
                    context: context,
                    icon: Icons.school,
                    title: 'College ID',
                    value: user.collegeId.isNotEmpty ? user.collegeId : 'N/A',
                  ),
                  16.heightBox,
                  _buildProfileItem(
                    context: context,
                    icon: Icons.phone,
                    title: 'Phone',
                    value: user.phoneNumber ?? 'Not provided',
                  ),
                ],
              ),

              24.heightBox,

              // Travel Preference Section
              _buildProfileCard(
                context: context,
                title: 'Travel Preference',
                children: [
                  8.heightBox,
                  StreamBuilder<List<RouteModel>>(
                    stream: firestoreService.getRoutesByCollege(user.collegeId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator().centered();
                      }

                      final stops = <String>{};
                      for (final route in snapshot.data!) {
                        stops.add(route.startPoint);
                        stops.add(route.endPoint);
                        stops.addAll(route.stopPoints);
                      }
                      final allStops = stops.toList()..sort();

                      return VStack([
                        'My Bus Stop'.text
                            .size(14)
                            .medium
                            .color(Theme.of(context).textTheme.bodySmall?.color)
                            .make(),
                        8.heightBox,
                        DropdownButtonFormField<String>(
                          value: allStops.contains(user.preferredStop)
                              ? user.preferredStop
                              : null,
                          hint: const Text('Select your stop'),
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                          items: allStops.map((stop) {
                            return DropdownMenuItem(
                              value: stop,
                              child: Text(
                                stop,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _updatingStop != null
                              ? null
                              : (value) {
                                  if (value != null) {
                                    _updatePreferredStop(
                                      value,
                                      user.id,
                                      apiService,
                                      authService,
                                    );
                                  }
                                },
                        ),
                        if (_updatingStop != null) ...[
                          8.heightBox,
                          const LinearProgressIndicator(),
                        ],
                      ]);
                    },
                  ),
                ],
              ),

              24.heightBox,

              // Settings Section
              _buildProfileCard(
                context: context,
                title: 'Settings',
                children: [
                  Consumer<ThemeService>(
                    builder: (context, themeService, _) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: 'Dark Mode'.text
                            .size(16)
                            .medium
                            .color(Theme.of(context).textTheme.bodyLarge?.color)
                            .make(),
                        secondary:
                            VxBox(
                                  child: Icon(
                                    themeService.isDarkMode
                                        ? Icons.dark_mode
                                        : Icons.light_mode,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                ).p12
                                .color(
                                  Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1),
                                )
                                .roundedFull
                                .make(),
                        value: themeService.isDarkMode,
                        onChanged: (value) {
                          themeService.toggleTheme(value);
                        },
                      );
                    },
                  ),
                  const Divider(),
                  Consumer<ThemeService>(
                    builder: (context, themeService, _) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: 'Bottom Navigation'.text
                            .size(16)
                            .medium
                            .color(Theme.of(context).textTheme.bodyLarge?.color)
                            .make(),
                        secondary:
                            VxBox(
                                  child: Icon(
                                    Icons.view_column_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                ).p12
                                .color(
                                  Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1),
                                )
                                .roundedFull
                                .make(),
                        value: themeService.useBottomNavigation,
                        onChanged: (value) {
                          if (value) {
                            themeService.toggleNavigationMode(true);
                            switch (user.role) {
                              case UserRole.busCoordinator:
                                context.go('/coordinator');
                                break;
                              case UserRole.driver:
                                context.go('/driver');
                                break;
                              case UserRole.teacher:
                                context.go('/teacher');
                                break;
                              case UserRole.admin:
                                context.go('/admin');
                                break;
                              default:
                                context.go('/student');
                            }
                          } else {
                            context.push('/student/profile');
                            themeService.toggleNavigationMode(false);
                          }
                        },
                      );
                    },
                  ),
                ],
              ),

              24.heightBox,

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authService.signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              32.heightBox,
            ]).pSymmetric(h: 16),
          ]).scrollVertical(),
        );
      },
    );
  }
}

Widget _buildProfileCard({
  required BuildContext context,
  required String title,
  required List<Widget> children,
}) {
  return VStack([
    title.text
        .size(18)
        .bold
        .color(
          Theme.of(context).textTheme.titleLarge?.color ??
              Theme.of(context).colorScheme.onSurface,
        )
        .make(),
    12.heightBox,
    VxBox(child: VStack(children)).p16
        .color(
          Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface,
        )
        .rounded
        .withShadow([
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ])
        .make(),
  ]);
}

Widget _buildProfileItem({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String value,
}) {
  return HStack([
    VxBox(child: Icon(icon, color: Theme.of(context).primaryColor, size: 20))
        .p12
        .color(Theme.of(context).primaryColor.withValues(alpha: 0.1))
        .roundedFull
        .make(),
    16.widthBox,
    VStack([
      title.text
          .size(12)
          .color(
            Theme.of(context).textTheme.bodyMedium?.color ??
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          )
          .make(),
      4.heightBox,
      value.text
          .size(16)
          .medium
          .color(
            Theme.of(context).textTheme.bodyLarge?.color ??
                Theme.of(context).colorScheme.onSurface,
          )
          .make(),
    ]).expand(),
  ]);
}
