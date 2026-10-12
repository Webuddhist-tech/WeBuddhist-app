import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/notifications/data/datasource/notification_preferences_remote_datasource.dart';
import 'package:flutter_pecha/features/notifications/data/repositories/notification_preferences_repository_impl.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_preferences.dart';
import 'package:flutter_pecha/features/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:flutter_pecha/features/notifications/presentation/utils/notification_settings_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class NotificationPreferencesState {
  final NotificationPreferences preferences;

  /// True until the first read from the backend has settled, one way or the
  /// other. Switches are held back meanwhile so a default never flashes and
  /// then snaps to the stored value.
  final bool isLoading;

  /// Set when the stored values could not be read. Shown in place of the
  /// switches, with a retry, rather than presenting defaults as if they were
  /// the user's saved choices.
  final Failure? loadFailure;

  /// The failure of the most recent save, cleared by the next flip.
  /// Surfaced once as a snackbar.
  final Failure? lastFailure;

  const NotificationPreferencesState({
    required this.preferences,
    this.isLoading = false,
    this.loadFailure,
    this.lastFailure,
  });

  NotificationPreferencesState copyWith({
    NotificationPreferences? preferences,
    bool? isLoading,
    Failure? loadFailure,
    bool clearLoadFailure = false,
    Failure? lastFailure,
    bool clearFailure = false,
  }) {
    return NotificationPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      loadFailure: clearLoadFailure ? null : (loadFailure ?? this.loadFailure),
      lastFailure: clearFailure ? null : (lastFailure ?? this.lastFailure),
    );
  }
}

/// Holds the account-wide Connect switches and saves flips optimistically.
///
/// Same write discipline as `GroupNotificationPreferencesNotifier`: every
/// flip updates the UI at once and goes through a per-switch queue, so at
/// most one PATCH per switch is in flight and further taps only replace the
/// value the next PATCH carries. That keeps the backend's final row equal to
/// the switch the user last saw. On failure the switch falls back to the last
/// value the backend confirmed.
class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferencesState> {
  final NotificationPreferencesRepository _repository;

  /// Called once a flip has settled on the backend with a value different
  /// from where it started. A failed, reverted or undone flip is no change.
  final void Function(ConnectNotificationToggle toggle, bool enabled)? _onSaved;

  /// Called with true when the first write starts and with false once every
  /// queued write has been sent, so the provider can stay alive in between.
  final void Function(bool busy)? _onBusyChanged;

  /// Last value the backend confirmed per switch, the revert target.
  NotificationPreferences _persisted = NotificationPreferences.defaults;

  /// Value the next PATCH for a switch should carry, if one is waiting.
  final Map<ConnectNotificationToggle, bool> _pending = {};

  /// Completes when a switch's queue drains, with the last write's outcome.
  final Map<ConnectNotificationToggle, Completer<bool>> _draining = {};

  /// Switches the user has touched, so a late-arriving load snapshot only
  /// fills in the ones they have not.
  final Set<ConnectNotificationToggle> _touched = {};

  NotificationPreferencesNotifier({
    required NotificationPreferencesRepository repository,
    void Function(ConnectNotificationToggle toggle, bool enabled)? onSaved,
    void Function(bool busy)? onBusyChanged,
  }) : _repository = repository,
       _onSaved = onSaved,
       _onBusyChanged = onBusyChanged,
       super(
         const NotificationPreferencesState(
           preferences: NotificationPreferences.defaults,
           isLoading: true,
         ),
       ) {
    _load();
  }

  Future<void> _load() async {
    final result = await _repository.get();
    if (!mounted) return;
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, loadFailure: failure),
      (loaded) {
        var preferences = state.preferences;
        for (final toggle in ConnectNotificationToggle.values) {
          // A flip made while loading wins over the fetched snapshot.
          if (_touched.contains(toggle)) continue;
          final value = loaded.of(toggle);
          preferences = preferences.withValue(toggle, value);
          _persisted = _persisted.withValue(toggle, value);
        }
        state = state.copyWith(
          preferences: preferences,
          isLoading: false,
          clearLoadFailure: true,
        );
      },
    );
  }

  /// Reads the stored values again after a failed load.
  Future<void> retry() {
    if (state.isLoading) return Future.value();
    state = state.copyWith(isLoading: true, clearLoadFailure: true);
    return _load();
  }

  /// Flips [toggle] to [enabled]. Resolves to whether the backend ended up
  /// holding the value the user last chose.
  Future<bool> set(ConnectNotificationToggle toggle, bool enabled) {
    if (state.preferences.of(toggle) == enabled) {
      return _draining[toggle]?.future ?? Future.value(true);
    }

    _touched.add(toggle);
    state = state.copyWith(
      preferences: state.preferences.withValue(toggle, enabled),
      clearFailure: true,
    );
    _pending[toggle] = enabled;

    final running = _draining[toggle];
    if (running != null) return running.future;
    final completer = _draining[toggle] = Completer<bool>();
    if (_draining.length == 1) _onBusyChanged?.call(true);
    unawaited(_drain(toggle, completer));
    return completer.future;
  }

  /// Sends the queued value for [toggle], then any value queued meanwhile,
  /// one request at a time. Only the last response settles the switch; a
  /// response with a newer value already queued is superseded.
  Future<void> _drain(
    ConnectNotificationToggle toggle,
    Completer<bool> completer,
  ) async {
    final before = _persisted.of(toggle);
    var succeeded = true;
    while (_pending.containsKey(toggle)) {
      final enabled = _pending.remove(toggle) as bool;
      final result = await _repository.update({toggle: enabled});
      if (!mounted) {
        completer.complete(false);
        return;
      }

      // A success moved the backend even if a newer value is already queued
      // behind it, so the revert target follows it: if that newer write then
      // fails, the switch falls back to what the backend really holds. Only
      // this switch is taken from the response; another may have an
      // optimistic flip of its own still in flight.
      final confirmed = result.toOption().toNullable();
      if (confirmed != null) {
        _persisted = _persisted.withValue(toggle, confirmed.of(toggle));
      }

      // Superseded: the queued write settles the switch, not this response.
      if (_pending.containsKey(toggle)) continue;

      final settled = _persisted.of(toggle);
      state = state.copyWith(
        preferences: state.preferences.withValue(toggle, settled),
        lastFailure: result.fold((failure) => failure, (_) => null),
      );
      succeeded = result.isRight();
    }
    _draining.remove(toggle);
    final after = _persisted.of(toggle);
    if (after != before) _onSaved?.call(toggle, after);
    completer.complete(succeeded);
    if (_draining.isEmpty) _onBusyChanged?.call(false);
  }
}

final notificationPreferencesRemoteDatasourceProvider =
    Provider<NotificationPreferencesRemoteDatasource>((ref) {
      return NotificationPreferencesRemoteDatasource(
        dio: ref.watch(dioProvider),
      );
    });

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
      return NotificationPreferencesRepositoryImpl(
        remote: ref.watch(notificationPreferencesRemoteDatasourceProvider),
      );
    });

/// The account-wide Connect switches. Auto-disposed when the last screen or
/// sheet showing them closes, so the next one fetches fresh. Watch it only
/// for signed-in, non-guest users: the endpoint needs an account.
///
/// While a write is still queued the provider stays alive, so a switch
/// flipped just before its sheet closed still reaches the backend, and a
/// sheet reopened meanwhile shows the same state instead of a stale read.
final notificationPreferencesProvider = StateNotifierProvider.autoDispose<
  NotificationPreferencesNotifier,
  NotificationPreferencesState
>((ref) {
  final analytics = ref.watch(notificationSettingsAnalyticsProvider);
  KeepAliveLink? keepAlive;
  return NotificationPreferencesNotifier(
    repository: ref.watch(notificationPreferencesRepositoryProvider),
    onSaved:
        (toggle, enabled) => analytics.settingChanged(
          setting: _analyticsSetting(toggle),
          enabled: enabled,
        ),
    onBusyChanged: (busy) {
      if (busy) {
        keepAlive ??= ref.keepAlive();
      } else {
        keepAlive?.close();
        keepAlive = null;
      }
    },
  );
});

NotificationSetting _analyticsSetting(ConnectNotificationToggle toggle) =>
    switch (toggle) {
      ConnectNotificationToggle.groupPosts => NotificationSetting.groupPosts,
      ConnectNotificationToggle.groupChats => NotificationSetting.groupChats,
      ConnectNotificationToggle.prayerReceived =>
        NotificationSetting.prayerReceived,
      ConnectNotificationToggle.prayerRequest =>
        NotificationSetting.prayerRequest,
    };
