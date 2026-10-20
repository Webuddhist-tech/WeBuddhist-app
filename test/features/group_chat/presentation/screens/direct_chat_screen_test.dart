import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/direct_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/screens/direct_chat_screen.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_emoji_pill.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_reply_preview.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_selection_header.dart';
import 'package:flutter_pecha/features/push_notifications/application/foreground_push_filter.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/domain/repositories/push_messaging_repository.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/providers/push_notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

class _Tenzin extends StateNotifier<UserState> implements UserNotifier {
  _Tenzin()
    : super(
        const UserState(
          user: User(id: 'me', firstName: 'Tenzin', email: 'me@example.com'),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SilentPushRepository implements PushMessagingRepository {
  final _foreground = StreamController<PushMessage>.broadcast();

  @override
  Stream<PushMessage> get onForegroundMessage => _foreground.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _room = ChatRoomDTO(
  id: 'dm-1',
  createdBy: 'team',
  kind: 'PRIVATE',
  name: 'WeBuddhist Team',
  updatedAt: '2026-10-16T18:31:00Z',
  otherUserId: 'team',
  otherUserName: 'WeBuddhist Team',
  isOfficial: true,
);

const _teamReply = 'Thank you, Tenzin! Our content team would love that.';

ChatMessageDTO _message(
  String id, {
  required String senderId,
  required String body,
  required String createdAt,
}) {
  return ChatMessageDTO(
    id: id,
    roomId: 'dm-1',
    senderId: senderId,
    senderEmail: '$senderId@example.com',
    senderName: senderId == 'team' ? 'WeBuddhist Team' : 'Tenzin',
    body: body,
    createdAt: createdAt,
  );
}

class _FakeRepository implements GroupChatRepository {
  final sent = <({String body, String? parentMessageId})>[];
  final reacted = <({String messageId, String emoji})>[];
  var messages = [
    _message(
      'reply',
      senderId: 'team',
      body: _teamReply,
      createdAt: '2026-10-16T18:31:00Z',
    ),
    _message(
      'request',
      senderId: 'me',
      body:
          'Sent from Help & contact · Help or collaborate\n\n'
          'I translate dharma texts into Nepali.',
      createdAt: '2026-10-16T12:04:00Z',
    ),
  ];

  @override
  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId) async =>
      const Right(_room);

  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
    String? messageType,
    String? sort,
    String? intention,
    String? translationLanguage,
  }) async {
    return Right(
      ChatMessagesPage(
        messages: messages,
        skip: skip,
        limit: limit,
        total: messages.length,
      ),
    );
  }

  @override
  Future<Either<Failure, ChatMessageDTO>> sendDirectMessage(
    String userId, {
    required String body,
    String? parentMessageId,
  }) async {
    sent.add((body: body, parentMessageId: parentMessageId));
    return Right(
      _message(
        'sent',
        senderId: 'me',
        body: body,
        createdAt: '2026-10-16T19:00:00Z',
      ),
    );
  }

  @override
  Future<Either<Failure, List<ChatMessageReactionDTO>>> addReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async {
    reacted.add((messageId: messageId, emoji: emoji));
    return Right([
      ChatMessageReactionDTO.fromJson({
        'emoji': emoji,
        'count': 1,
        'reacted_by_me': true,
        'user_ids': ['me'],
      }),
    ]);
  }

  @override
  Future<Either<Failure, Unit>> markRoomRead(String roomId) async =>
      const Right(unit);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        groupChatRepositoryProvider.overrideWithValue(repository),
        // REST only here; the socket is covered by the notifier tests.
        directChatLiveConfigProvider.overrideWithValue(null),
        userProvider.overrideWith((ref) => _Tenzin()),
        analyticsServiceProvider.overrideWithValue(
          RecordingAnalyticsService(),
        ),
        pushMessagingRepositoryProvider.overrideWithValue(
          _SilentPushRepository(),
        ),
        foregroundPushFilterProvider.overrideWithValue(ForegroundPushFilter()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DirectChatScreen(roomId: 'dm-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the Team chat says who it is and when they reply', (
    tester,
  ) async {
    await _pumpScreen(tester, _FakeRepository());

    expect(find.text('WeBuddhist Team'), findsOneWidget);
    expect(find.text('Usually replies within 1 day'), findsOneWidget);
  });

  testWidgets('a Help & contact message shows its context line above it', (
    tester,
  ) async {
    await _pumpScreen(tester, _FakeRepository());

    expect(
      find.text('Sent from Help & contact · Help or collaborate'),
      findsOneWidget,
    );
    expect(
      find.textContaining('I translate dharma texts into Nepali.'),
      findsOneWidget,
    );
    // The raw first line is not left in the bubble.
    expect(find.textContaining('Sent from Help & contact\n'), findsNothing);
    expect(find.textContaining(_teamReply), findsOneWidget);
  });

  testWidgets('a message goes to the other person and shows in the thread', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pumpScreen(tester, repository);

    await tester.enterText(find.byType(TextField), 'Wonderful, thank you');
    await tester.pump();
    await tester.tap(find.byIcon(AppAssets.paperPlaneRight));
    await tester.pumpAndSettle();

    expect(repository.sent, [
      (body: 'Wonderful, thank you', parentMessageId: null),
    ]);
    expect(find.textContaining('Wonderful, thank you'), findsOneWidget);
    // The field clears once the message is accepted.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('long-press offers reactions and the selection bar', (
    tester,
  ) async {
    await _pumpScreen(tester, _FakeRepository());

    await tester.longPress(find.textContaining(_teamReply));
    await tester.pumpAndSettle();

    expect(find.byType(GroupChatEmojiPill), findsOneWidget);
    expect(find.byType(GroupChatSelectionHeader), findsOneWidget);
    // The selection bar takes the header's place.
    expect(find.text('Usually replies within 1 day'), findsNothing);
  });

  testWidgets('picking an emoji reacts to the message', (tester) async {
    final repository = _FakeRepository();
    await _pumpScreen(tester, repository);

    await tester.longPress(find.textContaining(_teamReply));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(GroupChatEmojiPill),
        matching: find.text('\u{1F44D}'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.reacted, [(messageId: 'reply', emoji: '\u{1F44D}')]);
  });

  testWidgets('a reply quotes the message and sends it as the parent', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pumpScreen(tester, repository);

    await tester.longPress(find.textContaining(_teamReply));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(AppAssets.arrowBendUpLeft));
    await tester.pumpAndSettle();

    expect(find.byType(GroupChatReplyPreview), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Here is a sample');
    await tester.pump();
    await tester.tap(find.byIcon(AppAssets.paperPlaneRight));
    await tester.pumpAndSettle();

    expect(repository.sent, [
      (body: 'Here is a sample', parentMessageId: 'reply'),
    ]);
    expect(find.byType(GroupChatReplyPreview), findsNothing);
  });
}
