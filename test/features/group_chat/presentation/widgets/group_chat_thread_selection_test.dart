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
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_selection_header.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_thread.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const _viewer = User(id: 'me', email: 'me@example.com');

/// One page holding a single message sent by [_viewer].
class _OneMessageRepository implements GroupChatRepository {
  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
    String? messageType,
  }) async {
    return const Right(
      ChatMessagesPage(
        messages: [
          ChatMessageDTO(
            id: 'm1',
            roomId: 'room-1',
            senderId: 'me',
            senderEmail: 'me@example.com',
            body: 'my own message',
            createdAt: '2026-08-28T12:00:00Z',
          ),
        ],
        skip: 0,
        limit: 20,
        total: 1,
      ),
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

/// Starts with no profile, like a session whose `/users/info` has not landed.
class _LoadingUserNotifier extends UserNotifier {
  _LoadingUserNotifier()
    : super(
        getCurrentUserUseCase: _UnusedGetUser(),
        updateUserInfoUseCase: _UnusedUpdateInfo(),
        updateUsernameUseCase: _UnusedUpdateUsername(),
        uploadAvatarUseCase: _UnusedUploadAvatar(),
        localStorageService: _UnusedStorage(),
      );

  void land(User user) => state = UserState.loaded(user);
}

void main() {
  testWidgets(
    'a selection made before the profile loads gets Delete once it lands',
    (tester) async {
      final users = _LoadingUserNotifier();
      ChatSelection? selection;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupChatRepositoryProvider.overrideWithValue(
              _OneMessageRepository(),
            ),
            userProvider.overrideWith((ref) => users),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GroupChatThread(
                roomId: 'room-1',
                groupId: 'group-1',
                onReply: (_) {},
                onSelectionChanged: (next) => selection = next,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.longPress(find.text('my own message'));
      await tester.pump();

      // No viewer yet, so nothing can be recognised as this member's own.
      expect(selection, isNotNull);
      expect(selection!.gates.canDelete, isFalse);

      users.land(_viewer);
      await tester.pump();

      expect(selection!.count, 1);
      expect(selection!.gates.canDelete, isTrue);
    },
  );
}
