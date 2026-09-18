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
  int getCalls = 0;
  final List<({bool? chat, bool? content})> updates = [];
  final List<Completer<void>> holds = [];
  Completer<void>? getHold;

  @override
  Future<Either<Failure, GroupNotificationPreferences>>
  getGroupNotificationPreferences(String groupId) async {
    getCalls++;
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

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('loading', () {
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

        await _settle();
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.loadFailure, isNull);
        expect(
          notifier.state.preferences,
          const GroupNotificationPreferences(chat: true, content: false),
        );
      },
    );

    test('a failed load is reported, never shown as defaults', () async {
      final repo = _FakeRepository()..getFailure = const NetworkFailure('off');
      final notifier = _notifier(repo);
      await _settle();
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.loadFailure, isA<NetworkFailure>());
      expect(notifier.state.lastFailure, isNull);
    });

    test('retry reads again and clears the load failure', () async {
      final repo =
          _FakeRepository()
            ..getFailure = const NetworkFailure('off')
            ..server = const GroupNotificationPreferences(
              chat: false,
              content: true,
            );
      final notifier = _notifier(repo);
      await _settle();
      expect(notifier.state.loadFailure, isNotNull);

      repo.getFailure = null;
      final retry = notifier.retry();
      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.loadFailure, isNull);
      await retry;

      expect(repo.getCalls, 2);
      expect(notifier.state.isLoading, isFalse);
      expect(
        notifier.state.preferences,
        const GroupNotificationPreferences(chat: false, content: true),
      );
    });

    test(
      'a flip made while loading wins, the other toggle still loads',
      () async {
        final repo =
            _FakeRepository()
              ..getHold = Completer<void>()
              ..server = const GroupNotificationPreferences(
                chat: true,
                content: false,
              );
        final notifier = _notifier(repo);

        final flip = notifier.setChat(false);
        repo.release(0);
        expect(await flip, isTrue);
        expect(notifier.state.preferences.chat, isFalse);

        repo.getHold!.complete();
        await _settle();
        expect(notifier.state.isLoading, isFalse);
        expect(
          notifier.state.preferences,
          const GroupNotificationPreferences(chat: false, content: false),
        );
      },
    );
  });

  group('flipping', () {
    test('flips optimistically and sends only the changed flag', () async {
      final repo = _FakeRepository();
      final notifier = _notifier(repo);
      await _settle();

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
      await _settle();
      expect(await notifier.setChat(true), isTrue);
      expect(repo.updates, isEmpty);
    });

    test('reverts only the failed flag to the last confirmed value', () async {
      final repo = _FakeRepository()..updateFailure = const NetworkFailure('x');
      final notifier = _notifier(repo);
      await _settle();

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
        await _settle();

        final chatFlip = notifier.setChat(false);
        final contentFlip = notifier.setContent(false);
        expect(
          notifier.state.preferences,
          const GroupNotificationPreferences(chat: false, content: false),
        );

        repo.updateFailure = const ServerFailure('chat failed');
        repo.release(0);
        expect(await chatFlip, isFalse);
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

    test('clears the last failure on the next flip', () async {
      final repo = _FakeRepository()..updateFailure = const ServerFailure('x');
      final notifier = _notifier(repo);
      await _settle();

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

  group('write queue', () {
    test(
      'rapid flips of one toggle are written one at a time, in order',
      () async {
        final repo = _FakeRepository();
        final notifier = _notifier(repo);
        await _settle();

        final first = notifier.setChat(false);
        final second = notifier.setChat(true);
        final third = notifier.setChat(false);
        expect(notifier.state.preferences.chat, isFalse);
        // Only the first request has gone out; the rest wait on it.
        expect(repo.updates, [(chat: false, content: null)]);

        repo.release(0);
        await _settle();
        // Intermediate values collapse: the queue carries only the latest.
        expect(repo.updates, [
          (chat: false, content: null),
          (chat: false, content: null),
        ]);
        expect(notifier.state.preferences.chat, isFalse);

        repo.release(1);
        expect(await Future.wait([first, second, third]), [true, true, true]);
        expect(repo.server.chat, isFalse);
        expect(notifier.state.preferences.chat, isFalse);
      },
    );

    test('the backend ends on the value the switch shows', () async {
      final repo = _FakeRepository();
      final notifier = _notifier(repo);
      await _settle();

      notifier.setChat(false);
      final last = notifier.setChat(true);
      expect(notifier.state.preferences.chat, isTrue);

      repo.release(0);
      await _settle();
      expect(repo.updates.last, (chat: true, content: null));
      repo.release(1);
      expect(await last, isTrue);
      expect(repo.server.chat, isTrue);
      expect(notifier.state.preferences.chat, isTrue);
    });

    test('a superseded failure does not revert a newer queued value', () async {
      final repo = _FakeRepository();
      final notifier = _notifier(repo);
      await _settle();

      notifier.setChat(false);
      final last = notifier.setChat(true);

      repo.updateFailure = const ServerFailure('first failed');
      repo.release(0);
      await _settle();
      // The failure belongs to a write already replaced; the switch keeps
      // the user's latest choice and no error is reported yet.
      expect(notifier.state.preferences.chat, isTrue);
      expect(notifier.state.lastFailure, isNull);

      repo.updateFailure = null;
      repo.release(1);
      expect(await last, isTrue);
      expect(notifier.state.preferences.chat, isTrue);
    });

    test('the two toggles queue independently', () async {
      final repo = _FakeRepository();
      final notifier = _notifier(repo);
      await _settle();

      notifier.setChat(false);
      notifier.setContent(false);
      // Both first writes go out at once; they never block each other.
      expect(repo.updates, [
        (chat: false, content: null),
        (chat: null, content: false),
      ]);
    });
  });
}
