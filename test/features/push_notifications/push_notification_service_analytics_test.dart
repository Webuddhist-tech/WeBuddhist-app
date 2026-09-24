import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/entry_analytics.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/push_notifications/application/foreground_push_filter.dart';
import 'package:flutter_pecha/features/push_notifications/application/push_notification_service.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/domain/repositories/push_messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/analytics/recording_analytics_service.dart';

class _FakeRepository extends Fake implements PushMessagingRepository {
  bool willPrompt = true;
  bool grant = true;
  PushMessage? launchMessage;
  final opened = StreamController<PushMessage>.broadcast();

  @override
  Future<bool> willPromptForPermission() async => willPrompt;

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<PushMessage> get onForegroundMessage => const Stream.empty();

  @override
  Stream<PushMessage> get onMessageOpenedApp => opened.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => launchMessage;
}

class _FakeStorage extends Fake implements LocalStorageService {
  @override
  Future<T?> get<T>(String key) async => null;

  @override
  Future<bool> set<T>(String key, T value) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRepository repo;
  late RecordingAnalyticsService service;
  late PushNotificationService push;

  setUp(() {
    // Off Android the service skips the local-notifications channel setup,
    // which has no platform implementation under test.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    repo = _FakeRepository();
    service = RecordingAnalyticsService();
    push = PushNotificationService(
      repository: repo,
      storage: _FakeStorage(),
      foregroundFilter: ForegroundPushFilter(),
      analytics: EntryAnalytics(service),
    );
  });

  tearDown(() async {
    push.dispose();
    await repo.opened.close();
    debugDefaultTargetPlatformOverride = null;
  });

  test('a request the OS shows fires the prompt and then the answer', () async {
    repo.grant = false;

    await push.initialize();

    expect(service.eventNames, [
      AnalyticsEvents.notificationPermissionPrompted,
      AnalyticsEvents.notificationPermissionDenied,
    ]);
  });

  test('a request the OS answers silently fires nothing', () async {
    repo.willPrompt = false;

    await push.initialize();

    expect(service.events, isEmpty);
  });

  test(
    'taps say whether the app was in the background or terminated',
    () async {
      final states = <PushAppState>[];
      push.onOpenMessage = (_, state) => states.add(state);
      repo.launchMessage = const PushMessage(data: {'session_type': 'PLAN'});

      await push.initialize();
      repo.opened.add(const PushMessage(data: {'session_type': 'SERIES'}));
      await Future<void>.delayed(Duration.zero);

      expect(states, [PushAppState.terminated, PushAppState.background]);
    },
  );
}
