import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/core/providers/socket_provider.dart';

/// User notifier for managing the list of all users
class UserNotifier extends AsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() async {
    final api = ref.watch(apiServiceProvider);
    return await api.getAllUsers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    final api = ref.read(apiServiceProvider);
    await api.updateUser(userId, data);
    await refresh();
  }

  Future<void> approveUser(String userId, String approverId) async {
    final api = ref.read(apiServiceProvider);
    await api.approveUser(userId, approverId);
    await refresh();
  }
}

/// Provider for the list of all users
final userListProvider = AsyncNotifierProvider<UserNotifier, List<UserModel>>(
  UserNotifier.new,
);

/// StreamProvider for all users (for backward compatibility)
final allUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final api = ref.watch(apiServiceProvider);
  final socket = ref.watch(socketServiceProvider);

  return Stream.multi((controller) async {
    Future<void> fetch() async {
      try {
        final users = await api.getAllUsers();
        if (!controller.isClosed) controller.add(users);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    await fetch();
    final sub = socket.userListUpdateStream.listen((_) => fetch());
    controller.onCancel = () => sub.cancel();
  });
});

/// StreamProvider for users filtered by role and college
final usersByRoleProvider =
    StreamProvider.family<List<UserModel>, ({UserRole role, String collegeId})>(
      (ref, arg) {
        final api = ref.watch(apiServiceProvider);
        final socket = ref.watch(socketServiceProvider);

        return Stream.multi((controller) async {
          Future<void> fetch() async {
            try {
              final allUsers = await api.getAllUsers();
              final filteredUsers = allUsers
                  .where(
                    (u) => u.role == arg.role && u.collegeId == arg.collegeId,
                  )
                  .toList();
              if (!controller.isClosed) controller.add(filteredUsers);
            } catch (e) {
              if (!controller.isClosed) controller.addError(e);
            }
          }

          await fetch();
          final subscription = socket.userListUpdateStream.listen(
            (_) => fetch(),
          );
          controller.onCancel = () => subscription.cancel();
        });
      },
    );

/// StreamProvider for pending approvals in a college
final pendingApprovalsProvider = StreamProvider.family<List<UserModel>, String>(
  (ref, collegeId) {
    final api = ref.watch(apiServiceProvider);
    final socket = ref.watch(socketServiceProvider);

    return Stream.multi((controller) async {
      Future<void> fetch() async {
        try {
          final allUsers = await api.getAllUsers();
          final filteredUsers = allUsers
              .where(
                (u) =>
                    u.collegeId == collegeId &&
                    u.needsManualApproval &&
                    !u.approved,
              )
              .toList();
          if (!controller.isClosed) controller.add(filteredUsers);
        } catch (e) {
          if (!controller.isClosed) controller.addError(e);
        }
      }

      await fetch();
      final subscription = socket.userListUpdateStream.listen((_) => fetch());
      controller.onCancel = () => subscription.cancel();
    });
  },
);





