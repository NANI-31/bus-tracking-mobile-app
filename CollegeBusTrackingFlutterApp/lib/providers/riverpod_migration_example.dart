import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/providers/providers.dart';

/// Example ConsumerStatefulWidget showing how to migrate from Provider
///
/// BEFORE (Provider):
/// ```dart
/// class MyScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final auth = Provider.of<AuthService>(context);
///     return Text(auth.currentUserModel?.fullName ?? 'Guest');
///   }
/// }
/// ```
///
/// AFTER (Riverpod):
/// ```dart
/// class MyScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final authState = ref.watch(authProvider).value;
///     return Text(authState?.currentUser?.fullName ?? 'Guest');
///   }
/// }
/// ```

/// Example: Using ref.read for one-time actions (like button callbacks)
class RiverpodMigrationExample extends ConsumerWidget {
  const RiverpodMigrationExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch - rebuilds widget when state changes
    final authState = ref.watch(authProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Column(
      children: [
        // Display current user
        Text('User: ${authState.value?.currentUser?.fullName ?? 'Guest'}'),
        Text('Logged In: $isLoggedIn'),

        // Use ref.read in callbacks (doesn't rebuild widget)
        ElevatedButton(
          onPressed: () async {
            await ref.read(authProvider.notifier).signOut();
          },
          child: const Text('Logout'),
        ),

        ElevatedButton(
          onPressed: () async {
            final result = await ref
                .read(authProvider.notifier)
                .loginUser(email: 'test@example.com', password: 'password123');
            debugPrint('Login result: $result');
          },
          child: const Text('Login'),
        ),
      ],
    );
  }
}

/// Example: ConsumerStatefulWidget for more complex state
class RiverpodStatefulExample extends ConsumerStatefulWidget {
  const RiverpodStatefulExample({super.key});

  @override
  ConsumerState<RiverpodStatefulExample> createState() =>
      _RiverpodStatefulExampleState();
}

class _RiverpodStatefulExampleState
    extends ConsumerState<RiverpodStatefulExample> {
  @override
  void initState() {
    super.initState();
    // Access providers in initState via ref.read
    final authState = ref.read(authProvider).value;
    debugPrint('Initial user: ${authState?.currentUser?.fullName}');
  }

  @override
  Widget build(BuildContext context) {
    // Access providers in build via ref.watch
    // Note: BusService methods are async, so use FutureBuilder for data fetching
    final busService = ref.watch(busServiceProvider);

    // Example: Show loading state while BusService is available
    return Center(child: Text('BusService ready: ${busService.hashCode}'));
  }
}
