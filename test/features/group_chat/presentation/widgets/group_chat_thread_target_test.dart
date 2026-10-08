import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/update_user_info_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/update_username_usecase.dart';
import 'package:flutter_pecha/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_thread.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// A room deep enough that the opening jump has to page back for its target.
/// Newest first, matching the API.
class _PagedRepository implements GroupChatRepository {
  _PagedRepository({this.total = 90});

  final int total;

  final List<int> requestedSkips = [];

  /// When set, every page after the first fails. The opening jump then has
  /// history left to load and an error, which is the case that must not be
  /// reported as a deleted message.
  bool failLaterPages = false;

  /// When set, pages after the first wait on it, so a test can hold one in
  /// flight.
  Completer<void>? laterPagesGate;

  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
    String? messageType,
    String? sort,
    String? intention,
  }) async {
    requestedSkips.add(skip);
    if (skip > 0) await laterPagesGate?.future;
    if (skip > 0 && failLaterPages) {
      return const Left(NetworkFailure('offline'));
    }
    final page = [
      for (var index = skip; index < skip + limit && index < total; index++)
        ChatMessageDTO(
          id: 'm-$index',
          roomId: 'room-1',
          senderId: 'them',
          senderEmail: 'them@example.com',
          body: 'message $index',
          createdAt: '2026-08-28T12:00:00Z',
        ),
    ];
    return Right(
      ChatMessagesPage(messages: page, skip: skip, limit: limit, total: total),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedGetUser implements GetCurrentUserUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedUpdateInfo implements UpdateUserInfoUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedUpdateUsername implements UpdateUsernameUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedUploadAvatar implements UploadAvatarUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedStorage implements LocalStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A viewer who sent none of the messages in the room, so nothing in the
/// thread follows the newest row on its own account.
class _ViewerNotifier extends UserNotifier {
  _ViewerNotifier()
    : super(
        getCurrentUserUseCase: _UnusedGetUser(),
        updateUserInfoUseCase: _UnusedUpdateInfo(),
        updateUsernameUseCase: _UnusedUpdateUsername(),
        uploadAvatarUseCase: _UnusedUploadAvatar(),
        localStorageService: _UnusedStorage(),
      ) {
    state = UserState.loaded(const User(id: 'me', email: 'me@example.com'));
  }
}

List<Override> _overrides(_PagedRepository repository) => [
  groupChatRepositoryProvider.overrideWithValue(repository),
  userProvider.overrideWith((ref) => _ViewerNotifier()),
];

/// Pumps the thread. With [container], the test can drive the room's
/// provider before the thread exists.
Future<void> _pumpThread(
  WidgetTester tester,
  _PagedRepository repository, {
  required String? targetMessageId,
  ProviderContainer? container,
}) async {
  final app = MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: GroupChatThread(
        roomId: 'room-1',
        groupId: 'group-1',
        targetMessageId: targetMessageId,
        onReply: (_) {},
        onSelectionChanged: (_) {},
      ),
    ),
  );
  await tester.pumpWidget(
    container == null
        ? ProviderScope(overrides: _overrides(repository), child: app)
        : UncontrolledProviderScope(container: container, child: app),
  );
  await tester.pumpAndSettle();
}

void _expectOnScreen(WidgetTester tester, Finder target) {
  expect(target, findsOneWidget);
  final viewport = tester.getRect(find.byType(Scaffold));
  final row = tester.getRect(target);
  expect(row.top, greaterThanOrEqualTo(viewport.top));
  expect(row.bottom, lessThanOrEqualTo(viewport.bottom));
}

void main() {
  testWidgets('opens on a reported message that is pages back', (tester) async {
    final repository = _PagedRepository();
    await _pumpThread(tester, repository, targetMessageId: 'm-70');

    // Well outside the first page, so reaching it proves the jump paged back.
    expect(repository.requestedSkips, contains(60));

    final target = find.text('message 70');
    expect(target, findsOneWidget);

    // On screen, not merely built: the row has to be where the admin is
    // looking.
    final viewport = tester.getRect(find.byType(Scaffold));
    final row = tester.getRect(target);
    expect(row.top, greaterThanOrEqualTo(viewport.top));
    expect(row.bottom, lessThanOrEqualTo(viewport.bottom));
  });

  testWidgets('opens on a reported message hundreds of messages back', (
    tester,
  ) async {
    // Short viewport, so twenty strides of it cannot cover a few hundred
    // short rows. The target is still inside the paging budget.
    tester.view.physicalSize = const Size(400, 320);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repository = _PagedRepository(total: 330);
    await _pumpThread(tester, repository, targetMessageId: 'm-300');

    expect(repository.requestedSkips, contains(300));

    final target = find.text('message 300');
    expect(target, findsOneWidget);

    final viewport = tester.getRect(find.byType(Scaffold));
    final row = tester.getRect(target);
    expect(row.top, greaterThanOrEqualTo(viewport.top));
    expect(row.bottom, lessThanOrEqualTo(viewport.bottom));
  });

  testWidgets('says so when the reported message cannot be reached', (
    tester,
  ) async {
    final repository = _PagedRepository();
    await _pumpThread(tester, repository, targetMessageId: 'm-gone');

    expect(find.text('This message is no longer in the chat'), findsOneWidget);
    // The thread is left on the newest message rather than mid-history.
    expect(find.text('message 0'), findsOneWidget);
  });

  testWidgets('a failed history load can be retried', (tester) async {
    final repository = _PagedRepository()..failLaterPages = true;
    await _pumpThread(tester, repository, targetMessageId: 'm-40');

    expect(find.text('Messages couldn\'t be loaded'), findsOneWidget);
    expect(find.text('This message is no longer in the chat'), findsNothing);
    expect(find.text('message 0'), findsOneWidget);
    // One attempt at the next page. Repeating it through the paging budget
    // is what used to end in the missing-message notice.
    expect(repository.requestedSkips.where((skip) => skip > 0), [30]);

    repository.failLaterPages = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    final target = find.text('message 40');
    expect(target, findsOneWidget);
    final viewport = tester.getRect(find.byType(Scaffold));
    final row = tester.getRect(target);
    expect(row.top, greaterThanOrEqualTo(viewport.top));
    expect(row.bottom, lessThanOrEqualTo(viewport.bottom));
    expect(find.text('This message is no longer in the chat'), findsNothing);
  });

  testWidgets('a message past the paging budget can be searched for further', (
    tester,
  ) async {
    // The first page and twelve more reach m-389; the target is older.
    final repository = _PagedRepository(total: 600);
    await _pumpThread(tester, repository, targetMessageId: 'm-500');

    expect(
      find.text('This message is further back in the chat'),
      findsOneWidget,
    );
    // Running out of budget is not proof the message is gone.
    expect(find.text('This message is no longer in the chat'), findsNothing);
    expect(find.text('message 0'), findsOneWidget);

    await tester.tap(find.text('Keep looking'));
    await tester.pumpAndSettle();

    // Carried on from the history already loaded rather than starting over.
    expect(repository.requestedSkips.where((skip) => skip == 30), [30]);
    _expectOnScreen(tester, find.text('message 500'));
    expect(find.text('This message is no longer in the chat'), findsNothing);
  });

  testWidgets('a page already loading counts towards the search', (
    tester,
  ) async {
    final repository = _PagedRepository();
    final container = ProviderContainer(overrides: _overrides(repository));
    addTearDown(container.dispose);
    final provider = groupChatThreadProvider('room-1');
    final keepAlive = container.listen(provider, (_, _) {});
    addTearDown(keepAlive.close);
    await tester.pump();

    // A page someone else asked for, still in flight when the jump starts.
    // `loadMore` returns at once for the jump's own request then.
    repository.laterPagesGate = Completer<void>();
    unawaited(container.read(provider.notifier).loadMore());

    await _pumpThread(
      tester,
      repository,
      targetMessageId: 'm-70',
      container: container,
    );

    // Still waiting on that page, not out of budget and calling it missing.
    expect(find.text('This message is no longer in the chat'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(repository.requestedSkips, [0, 30]);

    repository.laterPagesGate!.complete();
    await tester.pumpAndSettle();

    _expectOnScreen(tester, find.text('message 70'));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('stays on the newest message without a target', (tester) async {
    final repository = _PagedRepository();
    await _pumpThread(tester, repository, targetMessageId: null);

    expect(repository.requestedSkips, equals([0]));
    expect(find.text('message 0'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}
