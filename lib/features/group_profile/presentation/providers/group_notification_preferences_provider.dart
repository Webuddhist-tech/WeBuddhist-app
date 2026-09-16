import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_notification_preferences.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/usecases/update_group_notification_preferences_usecase.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which of the two toggles a request touched. Used to revert only that flag
/// on failure so a concurrent flip of the other toggle is never undone.
enum GroupNotificationToggle { chat, content }

@immutable
class GroupNotificationPreferencesState {
  final GroupNotificationPreferences preferences;

  /// True until the first read from the backend has settled, one way or the
  /// other. The sheet holds its switches back meanwhile so a default never
  /// flashes and then snaps to the stored value.
  final bool isLoading;

  /// The failure of the most recent save, cleared by the next successful one.
  /// Surfaced once by the sheet as a snackbar.
  final Failure? lastFailure;

  const GroupNotificationPreferencesState({
    required this.preferences,
    this.isLoading = false,
    this.lastFailure,
  });

  GroupNotificationPreferencesState copyWith({
    GroupNotificationPreferences? preferences,
    bool? isLoading,
    Failure? lastFailure,
    bool clearFailure = false,
  }) {
    return GroupNotificationPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      lastFailure: clearFailure ? null : (lastFailure ?? this.lastFailure),
    );
  }
}

/// Holds one group's push toggles and saves flips optimistically.
///
/// Fetched when the sheet opens. Every flip updates the UI at once and
/// sends a partial PUT; on failure only the flag that request changed is
/// reverted, and a response that has been overtaken by a newer flip of the
/// same flag is ignored so the screen never snaps back to a stale value.
class GroupNotificationPreferencesNotifier
    extends StateNotifier<GroupNotificationPreferencesState> {
  final String _groupId;
  final GroupProfileRepositoryInterface _repository;
  final UpdateGroupNotificationPreferencesUseCase _update;

  /// Per-toggle sequence numbers. A response only lands if no newer flip of
  /// that same toggle started after it.
  final Map<GroupNotificationToggle, int> _sequence = {
    GroupNotificationToggle.chat: 0,
    GroupNotificationToggle.content: 0,
  };

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
      // Not a member, or the backend is unreachable: fall back to the
      // defaults rather than blocking the sheet on an error. A save from
      // that state still reports its own failure.
      (_) => state = state.copyWith(isLoading: false),
      (preferences) {
        // A flip made while loading wins over the fetched snapshot.
        final flipped = _sequence.values.any((n) => n > 0);
        state = state.copyWith(
          preferences: flipped ? null : preferences,
          isLoading: false,
        );
      },
    );
  }

  Future<bool> setChat(bool enabled) =>
      _flip(GroupNotificationToggle.chat, enabled);

  Future<bool> setContent(bool enabled) =>
      _flip(GroupNotificationToggle.content, enabled);

  Future<bool> _flip(GroupNotificationToggle toggle, bool enabled) async {
    final previous = state.preferences;
    final isChat = toggle == GroupNotificationToggle.chat;
    if ((isChat ? previous.chat : previous.content) == enabled) return true;

    final sequence = _sequence[toggle] = (_sequence[toggle] ?? 0) + 1;
    state = state.copyWith(
      preferences: previous.copyWith(
        chat: isChat ? enabled : null,
        content: isChat ? null : enabled,
      ),
      clearFailure: true,
    );

    final result = await _update(
      UpdateGroupNotificationPreferencesParams(
        groupId: _groupId,
        chat: isChat ? enabled : null,
        content: isChat ? null : enabled,
      ),
    );
    if (!mounted) return false;
    // A newer flip of this toggle is in flight; let it settle the value.
    if (_sequence[toggle] != sequence) return result.isRight();

    return result.fold(
      (failure) {
        state = state.copyWith(
          preferences: state.preferences.copyWith(
            chat: isChat ? previous.chat : null,
            content: isChat ? null : previous.content,
          ),
          lastFailure: failure,
        );
        return false;
      },
      (saved) {
        // Only this toggle is authoritative here: the other one may have an
        // optimistic flip of its own still in flight.
        state = state.copyWith(
          preferences: state.preferences.copyWith(
            chat: isChat ? saved.chat : null,
            content: isChat ? null : saved.content,
          ),
        );
        return true;
      },
    );
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
