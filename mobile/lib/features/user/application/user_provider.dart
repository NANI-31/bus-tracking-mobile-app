import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/providers/socket_provider.dart';

/// User notifier for managing the list of all users
class UserNotifier extends AsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() async {
    final repo = ref.watch(userRepositoryProvider);
    return await repo.getAllUsers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    final repo = ref.read(userRepositoryProvider);
    await repo.updateUser(userId, data);
    await refresh();
  }

  Future<void> approveUser(String userId, String approverId) async {
    final repo = ref.read(userRepositoryProvider);
    await repo.approveUser(userId, approverId);
    await refresh();
  }
}

/// Provider for the list of all users
final userListProvider = AsyncNotifierProvider<UserNotifier, List<UserModel>>(
  UserNotifier.new,
);

/// StreamProvider for all users (for backward compatibility)
final allUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  final socket = ref.watch(socketServiceProvider);

  return Stream.multi((controller) async {
    Future<void> fetch() async {
      try {
        final users = await repo.getAllUsers();
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

class UsersByRoleNotifier extends FamilyAsyncNotifier<List<UserModel>, ({UserRole role, String collegeId})> {
  @override
  Future<List<UserModel>> build(({UserRole role, String collegeId}) arg) async {
    final repo = ref.watch(userRepositoryProvider);
    final socket = ref.watch(socketServiceProvider);

    final sub = socket.userListUpdateStream.listen((_) async {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        final allUsers = await repo.getAllUsers();
        return allUsers
            .where((u) => u.role == arg.role && u.collegeId == arg.collegeId)
            .toList();
      });
    });

    ref.onDispose(() {
      sub.cancel();
    });

    final allUsers = await repo.getAllUsers();
    return allUsers
        .where((u) => u.role == arg.role && u.collegeId == arg.collegeId)
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepositoryProvider);
      final allUsers = await repo.getAllUsers();
      return allUsers
          .where((u) => u.role == arg.role && u.collegeId == arg.collegeId)
          .toList();
    });
  }
}

/// AsyncNotifierProvider for users filtered by role and college
final usersByRoleProvider = AsyncNotifierProvider.family<
    UsersByRoleNotifier,
    List<UserModel>,
    ({UserRole role, String collegeId})
>(UsersByRoleNotifier.new);

/// StreamProvider for pending approvals in a college
final pendingApprovalsProvider = StreamProvider.family<List<UserModel>, String>(
  (ref, collegeId) {
    final repo = ref.watch(userRepositoryProvider);
    final socket = ref.watch(socketServiceProvider);

    return Stream.multi((controller) async {
      Future<void> fetch() async {
        try {
          final allUsers = await repo.getAllUsers();
          final filteredUsers = allUsers
              .where(
                (u) =>
                    u.collegeId == collegeId &&
                    u.role == UserRole.driver &&
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
