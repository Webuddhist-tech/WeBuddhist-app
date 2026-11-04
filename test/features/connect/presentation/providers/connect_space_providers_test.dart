import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_space_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _a = GroupProfile(id: 'a', title: 'A');
const _b = GroupProfile(id: 'b', title: 'B');

ChatRoomDTO _room(String id, {String? groupId, int unreadCount = 0}) {
  return ChatRoomDTO(
    id: id,
    createdBy: 'u9',
    groupId: groupId,
    kind: groupId == null ? 'direct' : 'group',
    name: id,
    updatedAt: '2026-09-01T10:00:00Z',
    unreadCount: unreadCount,
  );
}

void main() {
  group('resolveConnectSpace', () {
    test('no joined spaces means the landing page', () {
      expect(resolveConnectSpace(joined: const [], rememberedId: 'a'), isNull);
    });

    test('opens the remembered space while it is still joined', () {
      expect(
        resolveConnectSpace(joined: const [_a, _b], rememberedId: 'b'),
        same(_b),
      );
    });

    test('falls back to the first space once the remembered one is left', () {
      expect(
        resolveConnectSpace(joined: const [_a, _b], rememberedId: 'gone'),
        same(_a),
      );
      expect(
        resolveConnectSpace(joined: const [_a, _b], rememberedId: null),
        same(_a),
      );
    });
  });

  test('only unread space rooms put a dot on their space', () {
    expect(
      unreadSpaceIds([
        _room('r1', groupId: 'a', unreadCount: 2),
        _room('r2', groupId: 'b'),
        _room('r3', unreadCount: 5),
      ]),
      {'a'},
    );
  });

  group('connectLastSpaceProvider', () {
    test('reads the stored space and remembers a new one', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.connectLastSpaceId: 'a',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(connectLastSpaceProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(connectLastSpaceProvider).spaceId, 'a');
      expect(container.read(connectLastSpaceProvider).loaded, isTrue);

      await container.read(connectLastSpaceProvider.notifier).select('b');
      expect(container.read(connectLastSpaceProvider).spaceId, 'b');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.connectLastSpaceId), 'b');
    });
  });
}
