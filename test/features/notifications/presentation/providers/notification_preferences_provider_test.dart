import 'dart:async';

import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_preferences.dart';
import 'package:flutter_pecha/features/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

/// Records update calls and lets each one be held open so the test controls
/// the order in which responses land. Starts as a user who never touched a
/// switch.
class _FakeRepository implements NotificationPreferencesRepository {
  NotificationPreferences server = NotificationPreferences.defaults;
  Failure? getFailure;
  Failure? updateFailure;
  int getCalls = 0;
  final List<Map<ConnectNotificationToggle, bool>> updates = [];
  final List<Completer<void>> holds = [];
  Completer<void>? getHold;

  @override
  Future<Either<Failure, NotificationPreferences>> get() async {
    getCalls++;
    final hold = getHold;
    if (hold != null) await hold.future;
    final failure = getFailure;
    if (failure != null) return Left(failure);
    return Right(server);
  }

  @override
  Future<Either<Failure, NotificationPreferences>> update(
    Map<ConnectNotificationToggle, bool> changes,
  ) async {
    updates.add(changes);
    final hold = Completer<void>();
    holds.add(hold);
    await hold.future;
    final failure = updateFailure;
    if (failure != null) return Left(failure);
    for (final MapEntry(key: toggle, value: enabled) in changes.entries) {
      server = server.withValue(toggle, enabled);
    }
    return Right(server);
  }

  /// Lets the [index]th update call return.
  void release(int index) => holds[index].complete();
}

/// A signed-in session the test can end.
class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth() : super(const AuthState(isLoggedIn: true));

  void signOut() => state = const AuthState(isLoggedIn: false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container(_FakeRepository repository, {_Auth? auth}) {
  final container = ProviderContainer(
    overrides: [
      notificationPreferencesRepositoryProvider.overrideWithValue(repository),
      analyticsServiceProvider.overrideWithValue(RecordingAnalyticsService()),
      authProvider.overrideWith((ref) => auth ?? _Auth()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _Harness {
  _Harness(this.repository, {bool track = false}) {
    notifier = NotificationPreferencesNotifier(
      repository: repository,
      onSaved: track ? (toggle, enabled) => saved.add((toggle, enabled)) : null,
    );
  }

  final _FakeRepository repository;
  late final NotificationPreferencesNotifier notifier;
  final List<(ConnectNotificationToggle, bool)> saved = [];
}

const _groupChats = ConnectNotificationToggle.groupChats;
const _prayerRequest = ConnectNotificationToggle.prayerRequest;

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('loading', () {
    test(
      'starts loading with defaults, then shows the stored values',
      () async {
        final repo =
            _FakeRepository()
              ..server = NotificationPreferences.defaults.copyWith(
                groupChats: true,
                groupPosts: false,
              );
        final notifier = _Harness(repo).notifier;
        expect(notifier.state.isLoading, isTrue);
        expect(notifier.state.preferences, NotificationPreferences.defaults);

        await _settle();
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.loadFailure, isNull);
        expect(notifier.state.preferences, repo.server);
      },
    );

    test('a failed load is reported, never shown as saved values', () async {
      final repo = _FakeRepository()..getFailure = const NetworkFailure('off');
      final notifier = _Harness(repo).notifier;
      await _settle();
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.loadFailure, isA<NetworkFailure>());
      expect(notifier.state.lastFailure, isNull);
    });

    test('retry reads again and clears the load failure', () async {
      final repo =
          _FakeRepository()
            ..getFailure = const NetworkFailure('off')
            ..server = NotificationPreferences.defaults.copyWith(
              prayerRequest: true,
            );
      final notifier = _Harness(repo).notifier;
      await _settle();
      expect(notifier.state.loadFailure, isNotNull);

      repo.getFailure = null;
      final retry = notifier.retry();
      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.loadFailure, isNull);
      await retry;

      expect(repo.getCalls, 2);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.preferences.prayerRequest, isTrue);
    });

    test('a flip made while loading wins over the snapshot', () async {
      final repo =
          _FakeRepository()
            ..getHold = Completer<void>()
            ..server = NotificationPreferences.defaults.copyWith(
              groupPosts: false,
            );
      final notifier = _Harness(repo).notifier;

      final flip = notifier.set(_groupChats, true);
      repo.release(0);
      expect(await flip, isTrue);

      repo.getHold!.complete();
      await _settle();
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.preferences.groupChats, isTrue);
      expect(notifier.state.preferences.groupPosts, isFalse);
    });
  });

  group('flipping', () {
    test('flips optimistically and sends only that switch', () async {
      final repo = _FakeRepository();
      final notifier = _Harness(repo).notifier;
      await _settle();

      final flip = notifier.set(_prayerRequest, true);
      expect(notifier.state.preferences.prayerRequest, isTrue);
      expect(repo.updates, [
        {_prayerRequest: true},
      ]);

      repo.release(0);
      expect(await flip, isTrue);
      expect(repo.server.prayerRequest, isTrue);
      expect(
        notifier.state.preferences,
        NotificationPreferences.defaults.copyWith(prayerRequest: true),
      );
    });

    test('flipping to the current value is a no-op', () async {
      final repo = _FakeRepository();
      final notifier = _Harness(repo).notifier;
      await _settle();
      for (final toggle in ConnectNotificationToggle.values) {
        expect(
          await notifier.set(
            toggle,
            NotificationPreferences.defaults.of(toggle),
          ),
          isTrue,
        );
      }
      expect(repo.updates, isEmpty);
    });

    test('a failed save reverts and reports the failure', () async {
      final repo = _FakeRepository()..updateFailure = const NetworkFailure('x');
      final notifier = _Harness(repo).notifier;
      await _settle();

      final flip = notifier.set(_groupChats, true);
      repo.release(0);
      expect(await flip, isFalse);
      expect(notifier.state.preferences, NotificationPreferences.defaults);
      expect(notifier.state.lastFailure, isA<NetworkFailure>());
    });

    test('the next flip clears the reported failure', () async {
      final repo = _FakeRepository()..updateFailure = const NetworkFailure('x');
      final notifier = _Harness(repo).notifier;
      await _settle();

      final failed = notifier.set(_groupChats, true);
      repo.release(0);
      await failed;
      expect(notifier.state.lastFailure, isNotNull);

      repo.updateFailure = null;
      final flip = notifier.set(_groupChats, true);
      expect(notifier.state.lastFailure, isNull);
      repo.release(1);
      expect(await flip, isTrue);
    });

    test(
      'a failed flip does not undo another switch in flight',
      () async {
        final repo = _FakeRepository();
        final notifier = _Harness(repo).notifier;
        await _settle();

        final chats = notifier.set(_groupChats, true);
        final prayers = notifier.set(_prayerRequest, true);
        expect(repo.updates, hasLength(2));

        repo.updateFailure = const NetworkFailure('x');
        repo.release(0);
        expect(await chats, isFalse);
        expect(notifier.state.preferences.groupChats, isFalse);
        expect(notifier.state.preferences.prayerRequest, isTrue);

        repo.updateFailure = null;
        repo.release(1);
        expect(await prayers, isTrue);
        expect(notifier.state.preferences.prayerRequest, isTrue);
      },
    );
  });

  group('rapid taps', () {
    test('one request at a time, and the last value wins', () async {
      final repo = _FakeRepository();
      final notifier = _Harness(repo).notifier;
      await _settle();

      final first = notifier.set(_groupChats, true);
      final second = notifier.set(_groupChats, false);
      final third = notifier.set(_groupChats, true);
      expect(repo.updates, hasLength(1), reason: 'only one in flight');
      expect(notifier.state.preferences.groupChats, isTrue);

      repo.release(0);
      await _settle();
      expect(repo.updates, [
        {_groupChats: true},
        {_groupChats: true},
      ], reason: 'the queued value replaced the one in between');
      expect(notifier.state.preferences.groupChats, isTrue);

      repo.release(1);
      expect(await Future.wait([first, second, third]), [true, true, true]);
      expect(repo.server.groupChats, isTrue);
    });

    test('a superseded response does not move the switch', () async {
      final repo = _FakeRepository();
      final notifier = _Harness(repo).notifier;
      await _settle();

      final on = notifier.set(_groupChats, true);
      notifier.set(_groupChats, false);
      repo.release(0);
      await _settle();
      expect(
        notifier.state.preferences.groupChats,
        isFalse,
        reason: 'the response to the first tap must not flash it back on',
      );

      repo.release(1);
      expect(await on, isTrue);
      expect(notifier.state.preferences.groupChats, isFalse);
      expect(repo.server.groupChats, isFalse);
    });

    test('a failed last write falls back to what the backend holds', () async {
      final repo = _FakeRepository();
      final notifier = _Harness(repo).notifier;
      await _settle();

      final flip = notifier.set(_groupChats, true);
      notifier.set(_groupChats, false);
      repo.release(0);
      await _settle();

      repo.updateFailure = const NetworkFailure('x');
      repo.release(1);
      expect(await flip, isFalse);
      expect(
        notifier.state.preferences.groupChats,
        isTrue,
        reason: 'the first write landed, so the backend holds on',
      );
    });
  });

  group('saved callback', () {
    test(
      'fires once with the settled value after a confirmed change',
      () async {
        final repo = _FakeRepository();
        final harness = _Harness(repo, track: true);
        await _settle();

        final flip = harness.notifier.set(_prayerRequest, true);
        expect(harness.saved, isEmpty, reason: 'not before the backend agrees');
        repo.release(0);
        await flip;
        expect(harness.saved, [(_prayerRequest, true)]);
      },
    );

    test('does not fire for a failed save', () async {
      final repo = _FakeRepository()..updateFailure = const NetworkFailure('x');
      final harness = _Harness(repo, track: true);
      await _settle();

      final flip = harness.notifier.set(_prayerRequest, true);
      repo.release(0);
      await flip;
      expect(harness.saved, isEmpty);
    });

    test('the provider reports a confirmed flip to analytics', () async {
      final repo = _FakeRepository();
      final analytics = RecordingAnalyticsService();
      final container = ProviderContainer(
        overrides: [
          notificationPreferencesRepositoryProvider.overrideWithValue(repo),
          analyticsServiceProvider.overrideWithValue(analytics),
          authProvider.overrideWith((ref) => _Auth()),
        ],
      );
      addTearDown(container.dispose);
      // autoDispose: hold a listener so the notifier outlives the reads.
      final sub = container.listen(notificationPreferencesProvider, (_, _) {});
      addTearDown(sub.close);
      await _settle();

      final flip = container
          .read(notificationPreferencesProvider.notifier)
          .set(_prayerRequest, true);
      repo.release(0);
      await flip;

      expect(analytics.eventNames, [
        AnalyticsEvents.notificationSettingChanged,
      ]);
      expect(analytics.events.single.properties, {
        'setting': 'prayerRequest',
        'enabled': true,
      });
    });

    test('a write queued when the sheet closes still reaches the backend, '
        'then the provider lets go', () async {
      final repo = _FakeRepository();
      final container = _container(repo);
      final sub = container.listen(notificationPreferencesProvider, (_, _) {});
      await _settle();

      final notifier = container.read(notificationPreferencesProvider.notifier);
      final flip = notifier.set(_prayerRequest, true);
      notifier.set(_prayerRequest, false);

      // The sheet closes while the first PATCH is still out.
      sub.close();
      await _settle();
      expect(container.exists(notificationPreferencesProvider), isTrue);

      repo.release(0);
      await _settle();
      expect(repo.updates, [
        {_prayerRequest: true},
        {_prayerRequest: false},
      ], reason: 'the queued value is sent, not dropped');

      repo.release(1);
      expect(await flip, isTrue);
      expect(repo.server.prayerRequest, isFalse);

      await _settle();
      expect(
        container.exists(notificationPreferencesProvider),
        isFalse,
        reason: 'nothing left to send and nobody listening',
      );
    });

    test('signing out drops a write still queued, so it never goes out '
        'as the next account', () async {
      final repo = _FakeRepository();
      final auth = _Auth();
      final container = _container(repo, auth: auth);
      final sub = container.listen(notificationPreferencesProvider, (_, _) {});
      await _settle();

      final notifier = container.read(notificationPreferencesProvider.notifier);
      final flip = notifier.set(_prayerRequest, true);
      notifier.set(_prayerRequest, false);
      sub.close();
      await _settle();

      // Sign-out starts while the first PATCH is still out.
      auth.signOut();
      repo.release(0);
      await _settle();

      expect(repo.updates, [
        {_prayerRequest: true},
      ], reason: 'the queued value is dropped');
      expect(await flip, isFalse);
      expect(container.exists(notificationPreferencesProvider), isFalse);
    });

    test('does not fire when quick taps end where they started', () async {
      final repo = _FakeRepository();
      final harness = _Harness(repo, track: true);
      await _settle();

      final flip = harness.notifier.set(_groupChats, true);
      harness.notifier.set(_groupChats, false);
      repo.release(0);
      await _settle();
      repo.release(1);
      await flip;
      expect(harness.saved, isEmpty);
    });
  });
}
