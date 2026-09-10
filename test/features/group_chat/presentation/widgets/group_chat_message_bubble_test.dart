import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_parent_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_message_bubble.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_quoted_message.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_reaction_badges.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessageDTO _message({
  String senderId = 'other',
  String body = 'Thank you',
  List<ChatMessageReactionDTO> reactions = const [],
  ChatMessageParentDTO? parent,
  String? deletedAt,
}) {
  return ChatMessageDTO(
    id: 'm1',
    roomId: 'room-1',
    senderId: senderId,
    senderEmail: '$senderId@example.com',
    senderName: 'Pema',
    body: body,
    createdAt: '2026-09-10T12:00:00Z',
    deletedAt: deletedAt,
    parent: parent,
    reactions: reactions,
  );
}

Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('GroupChatMessageBubble', () {
    testWidgets('the reaction chip hangs under the inner corner', (
      tester,
    ) async {
      final message = _message(
        reactions: const [ChatMessageReactionDTO(emoji: '\u{1F44D}', count: 2)],
      );

      Future<Rect> chipFor({required bool isSelf}) async {
        await tester.pumpWidget(
          _host(
            GroupChatMessageBubble(
              message: message,
              isSelf: isSelf,
              isRunStart: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getRect(find.byType(GroupChatReactionBadges));
      }

      final incoming = await chipFor(isSelf: false);
      // Whatever the machine's zone renders it as, this is the label painted.
      final label = GroupChatMessageBubble.timeLabel(
        tester.element(find.byType(GroupChatMessageBubble)),
        message,
      );
      final time = tester.getRect(find.text(label));

      // A separate element riding up over the bubble's bottom edge, inside
      // its 10dp bottom padding, so it overlaps the bubble but never the time
      // label. Under an incoming bubble it hangs at the right corner: the
      // time is right-aligned 14dp in, the chip 8dp in, so the chip reaches
      // 6dp past the time.
      expect(incoming.top, greaterThanOrEqualTo(time.bottom));
      expect(incoming.top, lessThan(time.bottom + 10));
      expect(incoming.right, moreOrLessEquals(time.right + 6, epsilon: 1));
      expect(find.text('2'), findsOneWidget);

      // And at the left corner under one of the viewer's own.
      final own = await chipFor(isSelf: true);
      final ownTime = tester.getRect(find.text(label));
      expect(own.left, lessThan(ownTime.left));
      expect(own.right, lessThan(ownTime.right));
    });

    testWidgets('a quote of a deleted original is a tombstone with no name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          GroupChatMessageBubble(
            message: _message(
              body: 'ok',
              parent: const ChatMessageParentDTO(
                id: 'p1',
                senderId: 'other',
                senderEmail: 'other@example.com',
                senderName: 'Pema',
                body: 'hello everyone',
                createdAt: '2026-09-10T11:59:00Z',
              ),
            ),
            isSelf: true,
            isRunStart: true,
            isParentDeleted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GroupChatQuotedMessage), findsOneWidget);
      expect(find.text('This message was deleted'), findsOneWidget);
      expect(find.text('hello everyone'), findsNothing);
      expect(find.text('Pema'), findsNothing);
    });

    testWidgets('a quote of the viewer\'s own original reads "You"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          GroupChatMessageBubble(
            message: _message(
              body: 'ok',
              parent: const ChatMessageParentDTO(
                id: 'p1',
                senderId: 'me',
                senderEmail: 'me@example.com',
                senderName: 'Me Myself',
                body: 'hello everyone',
                createdAt: '2026-09-10T11:59:00Z',
              ),
            ),
            isSelf: false,
            isRunStart: true,
            isParentOwn: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('You'), findsOneWidget);
      expect(find.text('Me Myself'), findsNothing);
      expect(find.text('hello everyone'), findsOneWidget);

      // A reply takes the full bubble width and the quote spans it, however
      // short the answer underneath: "ok" alone would have made a tiny
      // bubble with a content-sized panel.
      final screenWidth = tester.view.physicalSize.width /
          tester.view.devicePixelRatio;
      final quote = tester.getRect(find.byType(GroupChatQuotedMessage));
      expect(quote.width, greaterThan(screenWidth * 0.68 - 40));
    });

    testWidgets('a deleted message is one line, time after the label', (
      tester,
    ) async {
      final message = _message(
        senderId: 'me',
        deletedAt: '2026-09-10T12:01:00Z',
      );
      await tester.pumpWidget(
        _host(
          GroupChatMessageBubble(
            message: message,
            isSelf: true,
            isRunStart: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This message was deleted'), findsOneWidget);
      expect(find.text('You deleted this message'), findsNothing);
      expect(find.text('Thank you'), findsNothing);

      final timeLabel = GroupChatMessageBubble.timeLabel(
        tester.element(find.byType(GroupChatMessageBubble)),
        message,
      );
      final label = tester.getRect(find.text('This message was deleted'));
      final time = tester.getRect(find.text(timeLabel));

      // Beside the label, not under it, and sitting a touch lower.
      expect(time.left, greaterThan(label.right));
      expect(time.top, lessThan(label.bottom));
      expect(time.bottom, greaterThanOrEqualTo(label.bottom - 1));
    });
  });
}
