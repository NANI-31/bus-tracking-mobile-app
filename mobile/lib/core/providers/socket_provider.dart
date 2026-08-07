import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/services/socket_service.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/notification/application/notification_provider.dart';
import 'package:collegebus/shared/widgets/global_connectivity_banner.dart';
import 'package:collegebus/shared/widgets/session_expiry_dialog.dart';
import 'package:collegebus/core/utils/app_logger.dart';


/// SocketService provider - depends on auth token for initialization
final socketServiceProvider = ChangeNotifierProvider<SocketService>((ref) {
  SocketService.onSuppressBanner = GlobalConnectivityBanner.suppress;
  SocketService.onSessionExpired = () {
    SessionExpiryDialog.show(
      onConfirm: () {
        ref.read(authProvider.notifier).signOut();
      },
    );
  };
  final socketService = SocketService();



  // Initial setup: read current token without watching
  final token = ref.read(authProvider).value?.token;
  if (token != null) {
    socketService.init(AppConstants.baseUrl, token: token);
  }

  // Listen for token changes to update connection
  // We specify fireImmediately: false because we handled initial state above
  ref.listen(authProvider.select((state) => state.value?.token), (
    previous,
    next,
  ) {
    if (previous != next) {
      socketService.updateAuth(next, url: AppConstants.baseUrl);
    }
  });

  // Inject HTTP Fallback
  socketService.onFallbackUpdate = (data) async {
    final repo = ref.read(busRepositoryProvider);
    final busId = data['busId'] as String;
    final location = data['location'] as Map<String, dynamic>;
    final lat = location['lat'] as double;
    final lng = location['lng'] as double;
    final speed = (data['speed'] ?? 0.0) as double;
    final heading = (data['heading'] ?? 0.0) as double;

    await repo.updateBusLocation(busId, lat, lng, speed, heading);
  };

  // Notification Synchronization
  socketService.notificationStream.listen((data) {
    AppLogger.i('[socketServiceProvider] New notification received via socket');
    ref.read(notificationsProvider.notifier).refreshNotifications(silent: true);
  });

  socketService.notificationDeletedStream.listen((data) {
    AppLogger.i('[socketServiceProvider] Notification deleted via socket');
    final voiceKey = data['voiceKey'] as String?;
    final groupId = data['groupId'] as String?;
    final notificationId = data['id'] as String?;

    if (voiceKey != null) {
      // It's a voice retraction
      ref
          .read(notificationsProvider.notifier)
          .removeNotificationsByVoiceKey(voiceKey);
    } else if (groupId != null) {
      // It's a text broadcast retraction
      ref
          .read(notificationsProvider.notifier)
          .removeNotificationsByGroupId(groupId);
    } else if (notificationId != null) {
      ref
          .read(notificationsProvider.notifier)
          .deleteNotificationLocal(notificationId);
    }
  });

  socketService.notificationReadStream.listen((data) {
    AppLogger.i('[socketServiceProvider] Notification mark as read via socket');
    final id = data['id'] as String;
    ref.read(notificationsProvider.notifier).markAsReadLocal(id);
  });

  socketService.notificationReadAllStream.listen((data) {
    AppLogger.i(
      '[socketServiceProvider] All notifications mark as read via socket',
    );
    ref.read(notificationsProvider.notifier).markAllAsReadLocal();
  });

  return socketService;
});
