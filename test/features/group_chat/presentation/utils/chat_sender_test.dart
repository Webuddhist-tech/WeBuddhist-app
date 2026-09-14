import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reconnect_backoff.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isSelfChatMessage', () {
    test('matches on the user id', () {
      expect(
        isSelfChatMessage(
          senderId: 'u1',
          senderEmail: 'rena@example.com',
          currentUserId: 'u1',
        ),
        isTrue,
      );
    });

    test('matches on email when the id spaces differ', () {
      // Stored id is the JWT sub; sender_id is a backend UUID.
      expect(
        isSelfChatMessage(
          senderId: '2f1c-uuid',
          senderEmail: 'Rena@Example.com',
          currentUserId: 'auth0|abc123',
          currentUserEmail: 'rena@example.com',
        ),
        isTrue,
      );
    });

    test('does not match another member', () {
      expect(
        isSelfChatMessage(
          senderId: 'u2',
          senderEmail: 'jack@example.com',
          currentUserId: 'u1',
          currentUserEmail: 'rena@example.com',
        ),
        isFalse,
      );
    });

    test('does not match when nothing identifies the user', () {
      expect(
        isSelfChatMessage(
          senderId: 'u2',
          senderEmail: 'jack@example.com',
          currentUserId: '',
          currentUserEmail: null,
        ),
        isFalse,
      );
    });

    test('an empty sender email cannot match an empty stored email', () {
      expect(
        isSelfChatMessage(
          senderId: 'u2',
          senderEmail: '',
          currentUserId: '',
          currentUserEmail: '',
        ),
        isFalse,
      );
    });
  });

  group('isChatViewerKnown', () {
    test('an id or an email is enough', () {
      expect(isChatViewerKnown(currentUserId: 'u1'), isTrue);
      expect(isChatViewerKnown(currentUserEmail: 'me@x.org'), isTrue);
    });

    test('nothing, empty or blank is unknown', () {
      // The state while the profile is loading or failed to load. Here
      // isSelfChatMessage says "not mine" about every message, the viewer's
      // own included, so that answer must not be taken as a verdict.
      expect(isChatViewerKnown(), isFalse);
      expect(isChatViewerKnown(currentUserId: '', currentUserEmail: ''), isFalse);
      expect(isChatViewerKnown(currentUserId: '  ', currentUserEmail: ' '), isFalse);
      expect(
        isSelfChatMessage(
          senderId: 'u1',
          senderEmail: 'me@x.org',
          currentUserId: '',
          currentUserEmail: null,
        ),
        isFalse,
      );
    });
  });

  group('chatSenderDisplayName', () {
    test('prefers the name carried by the message', () {
      expect(
        chatSenderDisplayName(
          messageName: 'Pema Yangchen',
          senderEmail: 'rena@example.com',
        ),
        'Pema Yangchen',
      );
    });

    test('treats a blank message name as absent', () {
      expect(
        chatSenderDisplayName(
          messageName: '   ',
          senderEmail: 'rena@example.com',
        ),
        'rena',
      );
    });

    test('falls back to the email local part', () {
      expect(
        chatSenderDisplayName(senderEmail: 'rena.dolma@example.com'),
        'rena.dolma',
      );
    });

    test('returns null when there is nothing to show', () {
      expect(chatSenderDisplayName(senderEmail: ''), isNull);
    });
  });

  group('chatSenderSeed', () {
    test('prefers the id, then the email, then the name', () {
      expect(
        chatSenderSeed(senderId: 'U1', senderEmail: 'a@b.com', name: 'A'),
        'u1',
      );
      expect(chatSenderSeed(senderEmail: 'A@B.com', name: 'A'), 'a@b.com');
      expect(chatSenderSeed(name: 'Rena'), 'rena');
      expect(chatSenderSeed(), '');
    });
  });

  group('chatSenderColor', () {
    test('gives one person the same colour every time', () {
      final first = chatSenderColor(seed: 'u1', onDark: false);
      final again = chatSenderColor(seed: 'u1', onDark: false);
      expect(first, again);
    });

    test('casing cannot split a person across two colours', () {
      expect(
        chatSenderColor(
          seed: chatSenderSeed(senderEmail: 'Rena@X.com'),
          onDark: false,
        ),
        chatSenderColor(
          seed: chatSenderSeed(senderEmail: 'rena@x.com'),
          onDark: false,
        ),
      );
    });

    test('the light and dark variants line up on the same index', () {
      final light = chatSenderColor(seed: 'u1', onDark: false);
      final dark = chatSenderColor(seed: 'u1', onDark: true);
      expect(
        AppColors.chatSenderColors.indexOf(light),
        AppColors.chatSenderColorsDark.indexOf(dark),
      );
    });

    test('spreads a handful of people across the palette', () {
      final seeds = List.generate(10, (i) => 'user-$i');
      final used =
          seeds
              .map((seed) => chatSenderColor(seed: seed, onDark: false))
              .toSet();
      // Collisions are expected in a fixed palette; a single bucket is not.
      expect(used.length, greaterThan(3));
    });

    test('an empty seed still yields a colour', () {
      expect(
        chatSenderColor(seed: '', onDark: false),
        AppColors.chatSenderColors.first,
      );
    });
  });

  group('chatSenderInitials', () {
    test('takes one letter from each of the first two words', () {
      expect(chatSenderInitials('Rena Dolma'), 'RD');
    });

    test('splits an email local part on its separators', () {
      expect(chatSenderInitials('rena.dolma'), 'RD');
    });

    test('uses a single letter for a one-word name', () {
      expect(chatSenderInitials('Jack'), 'J');
    });

    test('falls back to a placeholder for an empty name', () {
      expect(chatSenderInitials(''), '?');
      expect(chatSenderInitials(null), '?');
    });
  });

  group('chatReconnectDelay', () {
    test('doubles from one second', () {
      expect(chatReconnectDelay(1), const Duration(seconds: 1));
      expect(chatReconnectDelay(2), const Duration(seconds: 2));
      expect(chatReconnectDelay(3), const Duration(seconds: 4));
      expect(chatReconnectDelay(4), const Duration(seconds: 8));
      expect(chatReconnectDelay(5), const Duration(seconds: 16));
    });

    test('caps at thirty seconds', () {
      expect(chatReconnectDelay(6), const Duration(seconds: 30));
      expect(chatReconnectDelay(50), const Duration(seconds: 30));
    });

    test('treats a non-positive attempt as the first retry', () {
      expect(chatReconnectDelay(0), const Duration(seconds: 1));
    });
  });
}
