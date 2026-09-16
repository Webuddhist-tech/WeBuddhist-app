import 'dart:async';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_notification_preferences.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/domain/usecases/update_group_notification_preferences_usecase.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_notification_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Records update calls and lets each one be held open so the test controls
/// the order in which responses land.
class _FakeRepository extends Fake implements GroupProfileRepositoryInterface {
  GroupNotificationPreferences server = GroupNotificationPreferences.allOn;
  Failure? getFailure;
  Failure? updateFailure;
  final List<({bool? chat, bool? content})> updates = [];
  final List<Completer<void>> holds = [];
  Completer<void>? getHold;

  @override
  Future<Either<Failure, GroupNotificationPreferences>>
  getGroupNotificationPreferences(String groupId) async {
    final hold = getHold;
    if (hold != null) await hold.future;
    final failure = getFailure;
    if (failure != null) return Left(failure);
    return Right(server);
  }

  @override
  Future<Either<Failure, GroupNotificationPreferences>>
  updateGroupNotificationPreferences(
    String groupId, {
    bool? chat,
    bool? content,
  }) async {
    updates.add((chat: chat, content: content));
    final hold = Completer<void>();
    holds.add(hold);
    await hold.future;
    final failure = updateFailure;
    if (failure != null) return Left(failure);
    server = server.copyWith(chat: chat, content: content);
    return Right(server);
  }

  /// Lets the [index]th update call return.
  void release(int index) => holds[index].complete();
}

GroupNotificationPreferencesNotifier _notifier(_FakeRepository repository) {
  return GroupNotificationPreferencesNotifier(
    groupId: 'grp-1',
    repository: repository,
    update: UpdateGroupNotificationPreferencesUseCase(repository),
  );
}

void main() {
  group('GroupNotificationPreferencesNotifier', () {
    test(
      'starts loading with defaults, then shows the stored values',
      () async {
        final repo =
            _FakeRepository()
              ..server = const GroupNotificationPreferences(
                chat: true,
                content: false,
              );
        final notifier = _notifier(repo);
        expect(notifier.state.isLoading, isTrue);
        expect(notifier.state.preferences, GroupNotificationPreferences.allOn);

        await Future<void>.delayed(Duration.zero);
        expect(notifier.state.isLoading, isFalse);
        expect(
          notifier.state.preferences,
          const GroupNotificationPreferences(chat: true, content: false),
        );
      },
    );

    test('keeps defaults and stops loading when the fetch fails', () async {
      final repo = _FakeRepository()..getFailure = const NotFoundFailure('no');
      final notifier = _notifier(repo);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.preferences, GroupNotificationPreferences.allOn);
      expect(notifier.state.lastFailure, isNull);
    });

    test('a flip made while loading is not overwritten by the fetch', () async {
      final repo = _FakeRepository()..getHold = Completer<void>();
      final notifier = _notifier(repo);

      final flip = notifier.setChat(false);
      repo.release(0);
      expect(await flip, isTrue);
      expect(notifier.state.preferences.chat, isFalse);

      repo.getHold!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.preferences.chat, isFalse);
    });

    test('flips optimistically and sends only the changed flag', () async {
      final repo = _FakeRepository();
      final notifier = _notifier(repo);

      final flip = notifier.setContent(false);
      expect(notifier.state.preferences.content, isFalse);
      expect(repo.updates, [(chat: null, content: false)]);

      repo.release(0);
      expect(await flip, isTrue);
      expect(
        notifier.state.preferences,
        const GroupNotificationPreferences(chat: true, content: false),
      );
    });

    test('flipping to the current value is a no-op', () async {
      final repo = _FakeRepository();
      final notifier = _notifier(repo);
      expect(await notifier.setChat(true), isTrue);
      expect(repo.updates, isEmpty);
    });

    test('reverts only the failed flag and reports the failure', () async {
      final repo = _FakeRepository()..updateFailure = const NetworkFailure('x');
      final notifier = _notifier(repo);

      final flip = notifier.setChat(false);
      repo.release(0);
      expect(await flip, isFalse);
      expect(notifier.state.preferences, GroupNotificationPreferences.allOn);
      expect(notifier.state.lastFailure, isA<NetworkFailure>());
    });

    test(
      'a failed chat flip does not undo an in-flight content flip',
      () async {
        final repo = _FakeRepository();
        final notifier = _notifier(repo);

        final chatFlip = notifier.setChat(false);
        final contentFlip = notifier.setContent(false);
        expect(
          notifier.state.preferences,
          const GroupNotificationPreferences(chat: false, content: false),
        );

        repo.updateFailure = const ServerFailure('chat failed');
        repo.release(0);
        expect(await chatFlip, isFalse);
        // Chat is back on, content keeps its optimistic value.
        expect(
          notifier.state.preferences,
          const GroupNotificationPreferences(chat: true, content: false),
        );

        repo.updateFailure = null;
        repo.release(1);
        expect(await contentFlip, isTrue);
        expect(
          notifier.state.preferences,
          const GroupNotificationPreferences(chat: true, content: false),
        );
      },
    );

    test('an overtaken response never snaps the toggle back', () async {
      final repo = _FakeRepository();
      final notifier = _notifier(repo);

      final first = notifier.setChat(false);
      final second = notifier.setChat(true);
      expect(notifier.state.preferences.chat, isTrue);

      // The first request (chat=false) lands after the second started.
      repo.release(0);
      await first;
      expect(notifier.state.preferences.chat, isTrue);

      repo.release(1);
      expect(await second, isTrue);
      expect(notifier.state.preferences.chat, isTrue);
    });

    test('clears the last failure on the next flip', () async {
      final repo = _FakeRepository()..updateFailure = const ServerFailure('x');
      final notifier = _notifier(repo);

      final failed = notifier.setChat(false);
      repo.release(0);
      await failed;
      expect(notifier.state.lastFailure, isNotNull);

      repo.updateFailure = null;
      final ok = notifier.setChat(false);
      expect(notifier.state.lastFailure, isNull);
      repo.release(1);
      await ok;
    });
  });
}
