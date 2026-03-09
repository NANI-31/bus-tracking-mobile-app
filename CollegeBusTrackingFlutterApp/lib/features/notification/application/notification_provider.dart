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
            return n.copyWith(isRead: true);
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
          return n.copyWith(isRead: true);
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

  Future<void> deleteNotification(String notificationId) async {
    final previousState = state;

    // Optimistic Update: Remove from list
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.where((n) => n.id != notificationId).toList(),
      );
    }

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.deleteNotification(notificationId);
    } catch (e) {
      // Revert on error
      state = previousState;
      rethrow;
    }
  }

  /// Local sync: remove a notification by ID (from socket)
  void deleteNotificationLocal(String notificationId) {
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.where((n) => n.id != notificationId).toList(),
      );
    }
  }

  /// Local sync: remove all notifications sharing a voiceKey (from socket retraction)
  void removeNotificationsByVoiceKey(String voiceKey) {
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.where((n) {
          // If it's a voice notification, check the voiceKey in data
          if (n.type == 'VOICE_NOTIFICATION' &&
              n.data?['voiceKey'] == voiceKey) {
            return false;
          }
          return true;
        }).toList(),
      );
    }
  }

  /// Local sync: remove all notifications sharing a groupId (from socket retraction)
  void removeNotificationsByGroupId(String groupId) {
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.where((n) => n.groupId != groupId).toList(),
      );
    }
  }

  /// Local sync: mark a single notification as read (from socket)
  void markAsReadLocal(String notificationId) {
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList(),
      );
    }
  }

  /// Local sync: mark all notifications as read (from socket)
  void markAllAsReadLocal() {
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.map((n) => n.copyWith(isRead: true)).toList(),
      );
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
