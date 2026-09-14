import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_selection.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = 'me-uuid';
const _myEmail = 'me@example.com';

ChatMessageDTO _message(
  String id, {
  String senderId = 'other',
  String? deletedAt,
}) {
  return ChatMessageDTO(
    id: id,
    roomId: 'room-1',
    senderId: senderId,
    senderEmail: '$senderId@example.com',
    body: 'body $id',
    createdAt: '2026-09-10T12:00:00Z',
    deletedAt: deletedAt,
  );
}

ChatSelectionGates _gates(List<ChatMessageDTO> selected) {
  return chatSelectionGates(
    selected,
    currentUserId: _me,
    currentUserEmail: _myEmail,
  );
}

void main() {
  group('chatSelectionGates', () {
    test('one own message offers everything but report', () {
      final gates = _gates([_message('m1', senderId: _me)]);

      expect(gates.canReply, isTrue);
      expect(gates.canCopy, isTrue);
      expect(gates.showDelete, isTrue);
      expect(gates.canDelete, isTrue);
      expect(gates.canReport, isFalse);
      expect(gates.showPill, isTrue);
    });

    test("one other person's message offers report, not delete", () {
      final gates = _gates([_message('m1')]);

      expect(gates.canReply, isTrue);
      expect(gates.canReport, isTrue);
      expect(gates.showDelete, isFalse);
      expect(gates.canDelete, isFalse);
      expect(gates.showPill, isTrue);
    });

    test('two messages lose reply, report and the pill', () {
      final gates = _gates([
        _message('m1', senderId: _me),
        _message('m2', senderId: _me),
      ]);

      expect(gates.canReply, isFalse);
      expect(gates.canReport, isFalse);
      expect(gates.showPill, isFalse);
      expect(gates.canCopy, isTrue);
      expect(gates.canDelete, isTrue);
    });

    test('a mixed selection shows delete but disables it', () {
      final gates = _gates([_message('m1', senderId: _me), _message('m2')]);

      expect(gates.showDelete, isTrue);
      expect(gates.canDelete, isFalse);
    });

    test("only other people's messages hide delete altogether", () {
      final gates = _gates([_message('m1'), _message('m2')]);

      expect(gates.showDelete, isFalse);
      expect(gates.canDelete, isFalse);
    });

    test('an unknown viewer can neither delete nor report', () {
      final gates = chatSelectionGates([_message('m1', senderId: _me)]);

      expect(gates.showDelete, isFalse);
      expect(gates.canDelete, isFalse);
      expect(gates.canReport, isFalse);
      // Copy needs no identity.
      expect(gates.canCopy, isTrue);
    });

    test('a deleted row in the set blocks every action but copy', () {
      final gates = _gates([
        _message('m1', senderId: _me, deletedAt: '2026-09-10T12:01:00Z'),
      ]);

      expect(gates.canReply, isFalse);
      expect(gates.showDelete, isFalse);
      expect(gates.canReport, isFalse);
      expect(gates.showPill, isFalse);
    });

    test('a delete in flight greys Delete but keeps it drawn', () {
      final gates = chatSelectionGates(
        [_message('m1', senderId: _me), _message('m2', senderId: _me)],
        currentUserId: _me,
        currentUserEmail: _myEmail,
        deleteInFlight: true,
      );

      expect(gates.showDelete, isTrue);
      expect(gates.canDelete, isFalse);
      // Nothing else is held back by it.
      expect(gates.canCopy, isTrue);
    });
  });

  group('chatSelectionStaleIds', () {
    test('a row tombstoned since it was picked is stale', () {
      final stale = chatSelectionStaleIds(
        ['m1', 'm2'],
        [_message('m1', deletedAt: '2026-09-10T12:01:00Z'), _message('m2')],
      );

      expect(stale, {'m1'});
    });

    test('a row no longer in the loaded window is stale', () {
      final stale = chatSelectionStaleIds(['m1', 'gone'], [_message('m1')]);

      expect(stale, {'gone'});
    });

    test('a live selection has nothing stale', () {
      final stale = chatSelectionStaleIds(
        ['m1', 'm2'],
        [_message('m2'), _message('m1'), _message('m0')],
      );

      expect(stale, isEmpty);
    });
  });

  group('selection membership', () {
    test('a tombstone is not selectable', () {
      expect(chatMessageIsSelectable(_message('m1')), isTrue);
      expect(
        chatMessageIsSelectable(_message('m1', deletedAt: '2026-09-10')),
        isFalse,
      );
    });

    test('the cap refuses the next row once it is reached', () {
      expect(kChatMaxSelection, 10);
      expect(chatSelectionHasRoom(kChatMaxSelection - 1), isTrue);
      expect(chatSelectionHasRoom(kChatMaxSelection), isFalse);
    });
  });
}
