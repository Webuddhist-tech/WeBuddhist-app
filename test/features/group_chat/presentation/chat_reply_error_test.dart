import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/chat_moderation.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('INVALID_PARENT_MESSAGE_ID', () {
    test('is classified from a REST validation failure', () {
      expect(
        chatSendErrorKind(
          const ValidationFailure(
            'bad parent',
            code: ChatModeration.invalidParentMessage,
          ),
        ),
        ChatSendErrorKind.invalidParent,
      );
    });

    test('is classified from a validation exception', () {
      expect(
        chatSendErrorKind(
          const ValidationException(
            'bad parent',
            code: ChatModeration.invalidParentMessage,
          ),
        ),
        ChatSendErrorKind.invalidParent,
      );
    });

    test('an unrelated failure stays generic', () {
      expect(
        chatSendErrorKind(const NetworkFailure('offline')),
        ChatSendErrorKind.generic,
      );
    });
  });
}
