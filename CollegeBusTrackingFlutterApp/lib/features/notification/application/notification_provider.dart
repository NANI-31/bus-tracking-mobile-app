import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/notification/domain/notification_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';

// Import the existing repository provider if it exists, otherwise define it here.
// Actually, earlier we saw notificationRepositoryProvider is defined in auth_provider.dart!
// Wait, yes, `final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository());` in auth_provider.dart.

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
      NotificationsNotifier.new,
    );

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return [];
    }

    final repo = ref.read(notificationRepositoryProvider);
    return await repo.getUserNotifications(user.id);
  }

  Future<void> refreshNotifications({bool silent = false}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (!silent) {
      state = const AsyncValue.loading();
    }
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final notifications = await repo.getUserNotifications(user.id);
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      if (!silent) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final previousState = state;

    // Optimistic Update First
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.map((n) {
          if (n.id == notificationId) {
            return NotificationModel(
              id: n.id,
              senderId: n.senderId,
              receiverId: n.receiverId,
              message: n.message,
              type: n.type,
              timestamp: n.timestamp,
              isRead: true,
              data: n.data,
            );
          }
          return n;
        }).toList(),
      );
    }

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markNotificationAsRead(notificationId);
    } catch (e) {
      // Revert handle error
      state = previousState;
    }
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final previousState = state;

    // Optimistic Update First
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.map((n) {
          return NotificationModel(
            id: n.id,
            senderId: n.senderId,
            receiverId: n.receiverId,
            message: n.message,
            type: n.type,
            timestamp: n.timestamp,
            isRead: true,
            data: n.data,
          );
        }).toList(),
      );
    }

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAllNotificationsAsRead(user.id);
    } catch (e) {
      // Revert handle error
      state = previousState;
    }
  }
}

// Derived provider for unread count
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final asyncNotifications = ref.watch(notificationsProvider);
  return asyncNotifications.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
