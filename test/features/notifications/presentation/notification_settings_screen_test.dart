import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_notification_settings_sheet.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_preferences.dart';
import 'package:flutter_pecha/features/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_preferences_provider.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_pecha/features/notifications/presentation/widgets/notification_switch_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Answers at once and records what the screen asked for.
class _FakeRepository implements NotificationPreferencesRepository {
  NotificationPreferences server = NotificationPreferences.defaults;
  Failure? getFailure;
  int getCalls = 0;
  final List<Map<ConnectNotificationToggle, bool>> updates = [];

  @override
  Future<Either<Failure, NotificationPreferences>> get() async {
    getCalls++;
    final failure = getFailure;
    return failure != null ? Left(failure) : Right(server);
  }

  @override
  Future<Either<Failure, NotificationPreferences>> update(
    Map<ConnectNotificationToggle, bool> changes,
  ) async {
    updates.add(changes);
    for (final MapEntry(key: toggle, value: enabled) in changes.entries) {
      server = server.withValue(toggle, enabled);
    }
    return Right(server);
  }
}

/// Pins the local flags without touching SharedPreferences or the OS, and
/// records which Practice toggle the screen called.
class _FakeNotificationNotifier extends NotificationNotifier {
  _FakeNotificationNotifier(Ref ref, NotificationState initial)
    : super(NotificationService(), ref) {
    state = initial;
  }

  final List<String> calls = [];

  @override
  Future<void> refreshStatus({bool initial = false}) async {}

  @override
  Future<NotificationToggleResult> toggleMaster(bool enable) =>
      _record('master', enable);

  Future<NotificationToggleResult> _record(String name, bool enable) async {
    calls.add('$name:$enable');
    return NotificationToggleResult.success;
  }

  @override
  Future<NotificationToggleResult> toggleRoutine(bool enable) =>
      _record('routine', enable);

  @override
  Future<NotificationToggleResult> toggleRecitation(bool enable) =>
      _record('recitation', enable);

  @override
  Future<NotificationToggleResult> togglePractice(bool enable) =>
      _record('practice', enable);

  @override
  Future<NotificationToggleResult> toggleTimer(bool enable) =>
      _record('timer', enable);
}

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _en = lookupAppLocalizations(const Locale('en'));

const _signedIn = AuthState(isLoggedIn: true);
const _guest = AuthState(isLoggedIn: true, isGuest: true);
const _allOn = NotificationState(hasSystemPermission: true);

class _Harness {
  final _FakeRepository repository = _FakeRepository();
  late _FakeNotificationNotifier notifications;

  Future<void> pump(
    WidgetTester tester, {
    required Widget home,
    AuthState auth = _signedIn,
    NotificationState notificationState = _allOn,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationPreferencesRepositoryProvider.overrideWithValue(
            repository,
          ),
          notificationProvider.overrideWith(
            (ref) =>
                notifications = _FakeNotificationNotifier(
                  ref,
                  notificationState,
                ),
          ),
          authProvider.overrideWith((ref) => _Auth(auth)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

NotificationSwitchRow _row(WidgetTester tester, String label) {
  return tester.widget<NotificationSwitchRow>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(NotificationSwitchRow),
    ),
  );
}

Future<void> _tapRow(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  group('NotificationSettingsScreen', () {
    testWidgets('shows Practice and Connect with the stored values', (
      tester,
    ) async {
      final h = _Harness();
      h.repository.server = NotificationPreferences.defaults.copyWith(
        groupChats: true,
      );
      await h.pump(tester, home: const NotificationSettingsScreen());

      expect(find.text(_en.group_notifications_title), findsOneWidget);
      expect(find.text(_en.notification_allow_subtitle_on), findsOneWidget);
      expect(find.text(_en.notification_section_practice), findsOneWidget);
      expect(find.text(_en.notification_section_connect), findsOneWidget);
      expect(h.repository.getCalls, 1);

      expect(_row(tester, _en.notification_row_plans).value, isTrue);
      expect(_row(tester, _en.notification_row_group_posts).value, isTrue);
      expect(_row(tester, _en.notification_row_group_chats).value, isTrue);
      expect(
        _row(tester, _en.notification_row_my_prayer_requests).value,
        isTrue,
      );
      expect(
        _row(tester, _en.notification_row_others_prayer_requests).value,
        isFalse,
      );
    });

    testWidgets('each Practice row drives its own local toggle', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, home: const NotificationSettingsScreen());

      await _tapRow(tester, _en.notification_row_plans);
      await _tapRow(tester, _en.notification_row_chants);
      await _tapRow(tester, _en.notification_row_mala);
      await _tapRow(tester, _en.notification_row_timer);

      expect(h.notifications.calls, [
        'routine:false',
        'recitation:false',
        'practice:false',
        'timer:false',
      ]);
      expect(h.repository.updates, isEmpty);
    });

    testWidgets('each Connect row saves its own type to the server', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, home: const NotificationSettingsScreen());

      await _tapRow(tester, _en.notification_row_group_posts);
      await _tapRow(tester, _en.notification_row_group_chats);
      await _tapRow(tester, _en.notification_row_my_prayer_requests);
      await _tapRow(tester, _en.notification_row_others_prayer_requests);

      expect(h.repository.updates, [
        {ConnectNotificationToggle.groupPosts: false},
        {ConnectNotificationToggle.groupChats: true},
        {ConnectNotificationToggle.prayerReceived: false},
        {ConnectNotificationToggle.prayerRequest: true},
      ]);
      expect(_row(tester, _en.notification_row_group_chats).value, isTrue);
      expect(h.notifications.calls, isEmpty);
    });

    testWidgets('master off greys every row out and saves nothing', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(
        tester,
        home: const NotificationSettingsScreen(),
        notificationState: const NotificationState(
          appMasterEnabled: false,
          hasSystemPermission: true,
        ),
      );

      expect(find.text(_en.notification_allow_subtitle_off), findsOneWidget);
      for (final label in [
        _en.notification_row_plans,
        _en.notification_row_group_posts,
        _en.notification_row_my_prayer_requests,
      ]) {
        expect(_row(tester, label).enabled, isFalse, reason: label);
        expect(_row(tester, label).value, isFalse, reason: label);
      }

      await _tapRow(tester, _en.notification_row_group_posts);
      await _tapRow(tester, _en.notification_row_plans);
      expect(h.repository.updates, isEmpty);
      expect(h.notifications.calls, isEmpty);
    });

    testWidgets('missing OS permission greys the rows too', (tester) async {
      final h = _Harness();
      await h.pump(
        tester,
        home: const NotificationSettingsScreen(),
        notificationState: const NotificationState(),
      );

      expect(
        find.text(_en.notification_allow_subtitle_disabled),
        findsOneWidget,
      );
      expect(_row(tester, _en.notification_row_group_chats).enabled, isFalse);
    });

    testWidgets('"Tap to grant in Settings" opens Settings, master stays on', (
      tester,
    ) async {
      final opened = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (call) async {
          opened.add(call.method);
          return true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          null,
        ),
      );

      final h = _Harness();
      await h.pump(
        tester,
        home: const NotificationSettingsScreen(),
        notificationState: const NotificationState(),
      );

      await tester.tap(find.text(_en.notification_allow_subtitle_disabled));
      await tester.pumpAndSettle();
      expect(opened, ['openAppSettings']);
      expect(h.notifications.calls, isEmpty);
    });

    testWidgets('with permission granted the card flips master', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, home: const NotificationSettingsScreen());

      await tester.tap(find.text(_en.notification_allow_title));
      await tester.pumpAndSettle();
      expect(h.notifications.calls, ['master:false']);
    });

    testWidgets('a guest sees no Connect section and nothing is fetched', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(
        tester,
        home: const NotificationSettingsScreen(),
        auth: _guest,
      );

      expect(find.text(_en.notification_section_practice), findsOneWidget);
      expect(find.text(_en.notification_section_connect), findsNothing);
      expect(find.text(_en.notification_row_group_posts), findsNothing);
      expect(h.repository.getCalls, 0);
    });

    testWidgets('a failed load offers a retry instead of defaults', (
      tester,
    ) async {
      final h = _Harness();
      h.repository.getFailure = const NetworkFailure('offline');
      await h.pump(tester, home: const NotificationSettingsScreen());

      expect(find.text(_en.group_notifications_load_failed), findsOneWidget);
      expect(find.text(_en.notification_row_group_posts), findsNothing);

      h.repository.getFailure = null;
      await tester.tap(find.text(_en.retry));
      await tester.pumpAndSettle();
      expect(find.text(_en.notification_row_group_posts), findsOneWidget);
    });
  });

  group('PrayerNotificationSettingsSheet', () {
    testWidgets('shows the two prayer switches and saves each type', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(
        tester,
        home: const Scaffold(body: PrayerNotificationSettingsSheet()),
      );

      expect(find.text(_en.group_notifications_title), findsOneWidget);
      expect(find.byType(NotificationSwitchRow), findsNWidgets(2));
      expect(
        _row(tester, _en.notification_row_my_prayer_requests).value,
        isTrue,
      );
      expect(
        _row(tester, _en.notification_row_others_prayer_requests).value,
        isFalse,
      );

      await _tapRow(tester, _en.notification_row_others_prayer_requests);
      expect(h.repository.updates, [
        {ConnectNotificationToggle.prayerRequest: true},
      ]);
      expect(
        _row(tester, _en.notification_row_others_prayer_requests).value,
        isTrue,
      );
    });

    testWidgets('master off greys both and says why', (tester) async {
      final h = _Harness();
      await h.pump(
        tester,
        home: const Scaffold(body: PrayerNotificationSettingsSheet()),
        notificationState: const NotificationState(
          appMasterEnabled: false,
          hasSystemPermission: true,
        ),
      );

      expect(find.text(_en.group_notifications_master_off), findsOneWidget);
      expect(
        _row(tester, _en.notification_row_my_prayer_requests).enabled,
        isFalse,
      );
      await _tapRow(tester, _en.notification_row_my_prayer_requests);
      expect(h.repository.updates, isEmpty);
    });

    testWidgets('missing OS permission greys both, like the settings screen', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(
        tester,
        home: const Scaffold(body: PrayerNotificationSettingsSheet()),
        notificationState: const NotificationState(),
      );

      expect(
        _row(tester, _en.notification_row_others_prayer_requests).enabled,
        isFalse,
      );
      expect(find.text(_en.group_notifications_master_off), findsOneWidget);
    });
  });
}
