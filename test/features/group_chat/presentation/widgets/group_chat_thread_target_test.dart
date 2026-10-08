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

  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
    String? messageType,
  }) async {
    requestedSkips.add(skip);
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

Future<void> _pumpThread(
  WidgetTester tester,
  _PagedRepository repository, {
  required String? targetMessageId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        groupChatRepositoryProvider.overrideWithValue(repository),
        userProvider.overrideWith((ref) => _ViewerNotifier()),
      ],
      child: MaterialApp(
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
      ),
    ),
  );
  await tester.pumpAndSettle();
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

  testWidgets('stays on the newest message without a target', (tester) async {
    final repository = _PagedRepository();
    await _pumpThread(tester, repository, targetMessageId: null);

    expect(repository.requestedSkips, equals([0]));
    expect(find.text('message 0'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}
