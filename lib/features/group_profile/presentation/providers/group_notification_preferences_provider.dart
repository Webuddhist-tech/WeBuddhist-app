import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_notification_preferences.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/usecases/update_group_notification_preferences_usecase.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One of the two switches the sheet shows.
enum GroupNotificationToggle { chat, content }

extension on GroupNotificationToggle {
  bool of(GroupNotificationPreferences preferences) => switch (this) {
    GroupNotificationToggle.chat => preferences.chat,
    GroupNotificationToggle.content => preferences.content,
  };

  GroupNotificationPreferences apply(
    GroupNotificationPreferences preferences,
    bool enabled,
  ) => switch (this) {
    GroupNotificationToggle.chat => preferences.copyWith(chat: enabled),
    GroupNotificationToggle.content => preferences.copyWith(content: enabled),
  };
}

@immutable
class GroupNotificationPreferencesState {
  final GroupNotificationPreferences preferences;

  /// True until the first read from the backend has settled, one way or the
  /// other. The sheet holds its switches back meanwhile so a default never
  /// flashes and then snaps to the stored value.
  final bool isLoading;

  /// Set when the stored values could not be read. The sheet shows this in
  /// place of the switches, with a retry, rather than presenting defaults
  /// as if they were the user's saved choices.
  final Failure? loadFailure;

  /// The failure of the most recent save, cleared by the next successful one.
  /// Surfaced once by the sheet as a snackbar.
  final Failure? lastFailure;

  const GroupNotificationPreferencesState({
    required this.preferences,
    this.isLoading = false,
    this.loadFailure,
    this.lastFailure,
  });

  GroupNotificationPreferencesState copyWith({
    GroupNotificationPreferences? preferences,
    bool? isLoading,
    Failure? loadFailure,
    bool clearLoadFailure = false,
    Failure? lastFailure,
    bool clearFailure = false,
  }) {
    return GroupNotificationPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      loadFailure: clearLoadFailure ? null : (loadFailure ?? this.loadFailure),
      lastFailure: clearFailure ? null : (lastFailure ?? this.lastFailure),
    );
  }
}

/// Holds one group's push toggles and saves flips optimistically.
///
/// Fetched when the sheet opens. Every flip updates the UI at once and is
/// written through a per-toggle queue: at most one PATCH per toggle is in
/// flight, and further taps only replace the value the next PATCH will
/// carry. That keeps the backend's final row equal to the switch the user
/// last saw, which concurrent requests cannot guarantee since the earlier
/// one may land last. On failure the toggle falls back to the last value the
/// backend confirmed.
class GroupNotificationPreferencesNotifier
    extends StateNotifier<GroupNotificationPreferencesState> {
  final String _groupId;
  final GroupProfileRepositoryInterface _repository;
  final UpdateGroupNotificationPreferencesUseCase _update;

  /// Last value the backend confirmed per toggle, the revert target.
  GroupNotificationPreferences _persisted = GroupNotificationPreferences.allOn;

  /// Value the next PATCH for a toggle should carry, if one is waiting.
  final Map<GroupNotificationToggle, bool> _pending = {};

  /// Completes when a toggle's queue drains, with the last write's outcome.
  final Map<GroupNotificationToggle, Completer<bool>> _draining = {};

  /// Toggles the user has touched, so a late-arriving load snapshot only
  /// fills in the ones they have not.
  final Set<GroupNotificationToggle> _touched = {};

  GroupNotificationPreferencesNotifier({
    required String groupId,
    required GroupProfileRepositoryInterface repository,
    required UpdateGroupNotificationPreferencesUseCase update,
  }) : _groupId = groupId,
       _repository = repository,
       _update = update,
       super(
         const GroupNotificationPreferencesState(
           preferences: GroupNotificationPreferences.allOn,
           isLoading: true,
         ),
       ) {
    _load();
  }

  Future<void> _load() async {
    final result = await _repository.getGroupNotificationPreferences(_groupId);
    if (!mounted) return;
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, loadFailure: failure),
      (loaded) {
        var preferences = state.preferences;
        for (final toggle in GroupNotificationToggle.values) {
          // A flip made while loading wins over the fetched snapshot.
          if (_touched.contains(toggle)) continue;
          final value = toggle.of(loaded);
          preferences = toggle.apply(preferences, value);
          _persisted = toggle.apply(_persisted, value);
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

  Future<bool> setChat(bool enabled) =>
      _flip(GroupNotificationToggle.chat, enabled);

  Future<bool> setContent(bool enabled) =>
      _flip(GroupNotificationToggle.content, enabled);

  Future<bool> _flip(GroupNotificationToggle toggle, bool enabled) {
    if (toggle.of(state.preferences) == enabled) {
      return _draining[toggle]?.future ?? Future.value(true);
    }

    _touched.add(toggle);
    state = state.copyWith(
      preferences: toggle.apply(state.preferences, enabled),
      clearFailure: true,
    );
    _pending[toggle] = enabled;

    final running = _draining[toggle];
    if (running != null) return running.future;
    final completer = _draining[toggle] = Completer<bool>();
    unawaited(_drain(toggle, completer));
    return completer.future;
  }

  /// Sends the queued value for [toggle], then any value queued meanwhile,
  /// one request at a time. Only the last response settles the switch; a
  /// response with a newer value already queued is superseded.
  Future<void> _drain(
    GroupNotificationToggle toggle,
    Completer<bool> completer,
  ) async {
    var succeeded = true;
    while (_pending.containsKey(toggle)) {
      final enabled = _pending.remove(toggle) as bool;
      final result = await _update(
        UpdateGroupNotificationPreferencesParams(
          groupId: _groupId,
          chat: toggle == GroupNotificationToggle.chat ? enabled : null,
          content: toggle == GroupNotificationToggle.content ? enabled : null,
        ),
      );
      if (!mounted) {
        completer.complete(false);
        return;
      }
      if (_pending.containsKey(toggle)) continue;

      succeeded = result.fold(
        (failure) {
          state = state.copyWith(
            preferences: toggle.apply(state.preferences, toggle.of(_persisted)),
            lastFailure: failure,
          );
          return false;
        },
        (saved) {
          // Only this toggle is authoritative here: the other one may have
          // an optimistic flip of its own still in flight.
          final value = toggle.of(saved);
          _persisted = toggle.apply(_persisted, value);
          state = state.copyWith(
            preferences: toggle.apply(state.preferences, value),
          );
          return true;
        },
      );
    }
    _draining.remove(toggle);
    completer.complete(succeeded);
  }
}

final updateGroupNotificationPreferencesUseCaseProvider =
    Provider<UpdateGroupNotificationPreferencesUseCase>((ref) {
      return UpdateGroupNotificationPreferencesUseCase(
        ref.watch(groupProfileRepositoryProvider),
      );
    });

/// Push toggles for [groupId]. Auto-disposed when the sheet closes, so the
/// next open fetches fresh.
final groupNotificationPreferencesProvider = StateNotifierProvider.autoDispose
    .family<
      GroupNotificationPreferencesNotifier,
      GroupNotificationPreferencesState,
      String
    >((ref, groupId) {
      return GroupNotificationPreferencesNotifier(
        groupId: groupId,
        repository: ref.watch(groupProfileRepositoryProvider),
        update: ref.watch(updateGroupNotificationPreferencesUseCaseProvider),
      );
    });
