import 'dart:async';

import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_pecha/features/push_notifications/application/foreground_push_filter.dart';
import 'package:flutter_pecha/features/push_notifications/application/push_notification_service.dart';
import 'package:flutter_pecha/features/push_notifications/data/repositories/push_messaging_repository_impl.dart';
import 'package:flutter_pecha/features/push_notifications/domain/repositories/push_messaging_repository.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/push_message_navigator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushMessagingRepositoryProvider =
    Provider<PushMessagingRepository>((ref) {
  return PushMessagingRepositoryImpl(dio: ref.watch(dioProvider));
});

/// App-lifetime registry of what is on screen. Screens claim the pushes
/// they already render (see [ForegroundPushFilter]); the service consults it
/// before showing a foreground banner.
final foregroundPushFilterProvider = Provider<ForegroundPushFilter>(
  (ref) => ForegroundPushFilter(),
);

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(
    repository: ref.watch(pushMessagingRepositoryProvider),
    storage: ref.watch(localStorageServiceProvider),
    foregroundFilter: ref.watch(foregroundPushFilterProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Eagerly initializes FCM and feeds auth changes into the service so the
/// device token is registered once the user signs in. Watch for the app
/// lifetime (e.g. in `MyApp.build`).
final pushNotificationBootstrapProvider = Provider<void>((ref) {
  final service = ref.watch(pushNotificationServiceProvider);
  final navigator = ref.read(pushMessageNavigatorProvider);

  // Route notification taps from every app state through one navigator so
  // navigation stays consistent. Wire the callbacks BEFORE initialize() so a
  // terminated-state launch (handled inside initialize via getInitialMessage)
  // is routed too.
  //   • background / terminated taps  -> service.onOpenMessage
  //   • foreground taps               -> shared local-notifications callback,
  //     which NotificationService forwards here for push-shaped payloads.
  service.onOpenMessage = navigator.handle;
  NotificationService.setPushTapHandler(navigator.handleData);

  unawaited(service.initialize());

  void syncAuth() {
    final auth = ref.read(authProvider);
    if (auth.isLoading) return;
    service.onAuthChanged(loggedIn: auth.isLoggedIn && !auth.isGuest);
  }

  // Registration only needs the login state — the backend keys the device on
  // the JWT, so a single listener on auth is enough.
  ref.listen<AuthState>(authProvider, (_, __) => syncAuth(), fireImmediately: true);

  // Master is the global kill-switch: OFF unregisters the device so every
  // server push (chat, group content, reminders, routine, verse of the day)
  // stops; ON registers it again. The routine toggle only re-sends the
  // registration with the updated plan/series gate. The remaining toggles
  // (recitation/mala/timer) are local-only and ignored here.
  ref.listen<NotificationState>(
    notificationProvider,
    (prev, next) {
      final masterChanged =
          prev == null || prev.appMasterEnabled != next.appMasterEnabled;
      if (masterChanged) {
        service.setMasterEnabled(next.appMasterEnabled);
        return;
      }
      if (prev.appRoutineEnabled != next.appRoutineEnabled) {
        service.refreshRegistration();
      }
    },
    fireImmediately: true,
  );
});
