import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/help_topic.dart';
import 'package:flutter_pecha/features/feedback/domain/help_context_line.dart';
import 'package:flutter_pecha/features/feedback/presentation/screens/help_contact_screen.dart';
import 'package:flutter_pecha/features/feedback/presentation/utils/help_topic_l10n.dart';
import 'package:flutter_pecha/features/feedback/presentation/widgets/message_sent_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  group('helpTopicHint', () {
    test('asks the question that fits each topic', () {
      expect(helpTopicHint(en, null), 'What would you like to tell us?');
      expect(
        helpTopicHint(en, HelpTopic.reportProblem),
        startsWith('What happened'),
      );
      expect(
        helpTopicHint(en, HelpTopic.ideaFeedback),
        contains('more helpful for your practice'),
      );
      expect(
        helpTopicHint(en, HelpTopic.suggestContent),
        contains('Links are welcome'),
      );
      expect(
        helpTopicHint(en, HelpTopic.helpCollaborate),
        startsWith('How would you like to help?'),
      );
    });

    test('every topic has its own placeholder and label', () {
      final hints = {for (final t in HelpTopic.values) helpTopicHint(en, t)};
      final labels = {for (final t in HelpTopic.values) helpTopicLabel(en, t)};
      expect(hints, hasLength(HelpTopic.values.length));
      expect(labels, hasLength(HelpTopic.values.length));
    });

    test('the English labels match what the backend writes', () {
      for (final topic in HelpTopic.values) {
        expect(helpTopicLabel(en, topic), topic.canonicalLabel);
      }
    });
  });

  group('helpContextLabel', () {
    test('joins the parts that are there', () {
      expect(
        helpContextLabel(
          en,
          const HelpContext(topic: HelpTopic.helpCollaborate, photoCount: 2),
        ),
        'Sent from Help & contact · Help or collaborate · 2 photos',
      );
      expect(
        helpContextLabel(en, const HelpContext(photoCount: 1)),
        'Sent from Help & contact · 1 photo',
      );
      expect(
        helpContextLabel(en, const HelpContext()),
        'Sent from Help & contact',
      );
    });
  });

  group('messageSentChatLocation', () {
    test('opens the Team chat when the backend named the room', () {
      expect(
        messageSentChatLocation(
          const HelpContactResult(message: 'hi', roomId: 'dm-1'),
        ),
        AppRoutes.directChatPath('dm-1'),
      );
    });

    test('falls back to the Chats list without one', () {
      expect(
        messageSentChatLocation(const HelpContactResult(message: 'hi')),
        AppRoutes.chats,
      );
      expect(
        messageSentChatLocation(
          const HelpContactResult(message: 'hi', roomId: ' '),
        ),
        AppRoutes.chats,
      );
    });
  });

  test('only a signed-in account can send', () {
    expect(
      HelpContactScreen.canSend(const AuthState(isLoggedIn: true)),
      isTrue,
    );
    expect(
      HelpContactScreen.canSend(
        const AuthState(isLoggedIn: true, isGuest: true),
      ),
      isFalse,
    );
    expect(
      HelpContactScreen.canSend(const AuthState(isLoggedIn: false)),
      isFalse,
    );
  });
}
