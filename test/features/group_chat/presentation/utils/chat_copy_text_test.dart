import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_copy_text.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessageDTO _message(String id, String body, String createdAt) {
  return ChatMessageDTO(
    id: id,
    roomId: 'room-1',
    senderId: 'u-$id',
    senderEmail: '$id@example.com',
    body: body,
    createdAt: createdAt,
  );
}

String _time(ChatMessageDTO message) => 't-${message.id}';
String _name(ChatMessageDTO message) => 'n-${message.id}';

void main() {
  group('chatCopyText', () {
    test('one message copies the bare body', () {
      final text = chatCopyText(
        [_message('a', 'hello', '2026-09-10T12:00:00Z')],
        timeOf: _time,
        nameOf: _name,
      );

      expect(text, 'hello');
    });

    test('several copy a transcript, oldest first', () {
      final text = chatCopyText(
        [
          _message('newer', 'thanks', '2026-09-10T12:05:00Z'),
          _message('older', 'hello', '2026-09-10T12:00:00Z'),
        ],
        timeOf: _time,
        nameOf: _name,
      );

      expect(text, '[t-older] n-older: hello\n[t-newer] n-newer: thanks');
    });

    test('nothing selected copies nothing', () {
      expect(chatCopyText(const [], timeOf: _time, nameOf: _name), '');
    });
  });
}
