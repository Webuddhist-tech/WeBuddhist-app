import 'dart:convert';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/storage/storage_service.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/chat_rooms_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/my_prayer_requests_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/prayer_requests_providers.dart';
import 'package:flutter_pecha/features/push_notifications/domain/entities/push_message.dart';
import 'package:flutter_pecha/features/push_notifications/domain/repositories/push_messaging_repository.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/providers/push_notification_providers.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_first_pages.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_requests_filter.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_room_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FakeRepository extends Fake implements GroupChatRepository {
  List<ChatRoomDTO> rooms = const [];
  List<ChatMessageDTO> requests = const [];
  List<ChatPrayerIntentionDTO> intentions = const [];
  Failure? failure;
  int calls = 0;

  @override
  Future<Either<Failure, ChatRoomsPage>> listRooms({
    int skip = 0,
    int limit = 20,
  }) async {
    calls++;
    final f = failure;
    if (f != null) return Left(f);
    return Right(
      ChatRoomsPage(rooms: rooms, skip: skip, limit: limit, total: rooms.length),
    );
  }

  @override
  Future<Either<Failure, ChatMessagesPage>> listMyPrayerRequests({
    int skip = 0,
    int limit = 20,
    String? eventId,
    String? groupId,
    bool? isCompleted,
  }) async {
    calls++;
    final f = failure;
    if (f != null) return Left(f);
    return Right(
      ChatMessagesPage(
        messages: requests,
        skip: skip,
        limit: limit,
        total: requests.length,
      ),
    );
  }

  @override
  Future<Either<Failure, ChatRoomDTO>> getEventRoom(
    String eventId, {
    String? language,
  }) async {
    calls++;
    final f = failure;
    if (f != null) return Left(f);
    return Right(_room('room-1'));
  }

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
    calls++;
    final f = failure;
    if (f != null) return Left(f);
    return Right(
      ChatMessagesPage(
        messages: requests,
        skip: skip,
        limit: limit,
        total: requests.length,
      ),
    );
  }

  @override
  Future<Either<Failure, List<ChatPrayerIntentionDTO>>> listIntentions() async {
    calls++;
    final f = failure;
    if (f != null) return Left(f);
    return Right(intentions);
  }
}

class _MemoryStorage extends Fake implements StorageService {
  final Map<String, Object> values = {StorageKeys.currentUserId: 'user-1'};

  @override
  Future<T?> get<T>(String key) async => values[key] as T?;

  @override
  Future<bool> set<T>(String key, T value) async {
    values[key] = value as Object;
    return true;
  }
}

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SilentPushes extends Fake implements PushMessagingRepository {
  @override
  Stream<PushMessage> get onForegroundMessage => const Stream.empty();
}

ChatRoomDTO _room(String id, {int unread = 0}) => ChatRoomDTO.fromJson({
  'id': id,
  'group_id': 'group-$id',
  'kind': 'GROUP',
  'name': 'Room $id',
  'updated_at': '2026-10-01T00:00:00Z',
  'unread_count': unread,
});

ChatMessageDTO _request(String id) => ChatMessageDTO.fromJson({
  'id': id,
  'room_id': 'room-1',
  'sender_id': 'user-1',
  'body': 'Please pray',
  'created_at': '2026-10-01T00:00:00Z',
  'message_type': 'PRAYER',
});

Future<void> _settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeScreenCacheStore store;
  late _FakeRepository repository;
  late ProviderContainer container;

  setUp(() {
    store = FakeScreenCacheStore();
    repository = _FakeRepository();
    container = ProviderContainer(
      overrides: [
        groupChatRepositoryProvider.overrideWithValue(repository),
        screenCacheStoreProvider.overrideWithValue(store),
        storageServiceProvider.overrideWithValue(_MemoryStorage()),
        pushMessagingRepositoryProvider.overrideWithValue(_SilentPushes()),
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
      ],
    );
    addTearDown(container.dispose);
  });

  test('a seeded prayer sheet builds, refreshes and publishes its count',
      () async {
    const scope = PrayerRoomScope.event('e1');
    final key = container
        .read(groupChatFirstPagesProvider)
        .prayerRoom(
          scope,
          filter: PrayerRequestsFilter.initial,
          translationLanguage: container.read(prayerTranslationLanguageProvider),
          limit: 30,
        )
        .key;
    store.entries[key] = jsonEncode(
      PrayerRoomSnapshot(
        roomId: 'room-1',
        page: ChatMessagesPage(
          messages: [_request('a')],
          skip: 0,
          limit: 30,
          total: 1,
        ),
      ).toJson(),
    );
    repository.requests = [_request('a'), _request('b')];

    container.listen(prayerRequestsProvider(scope), (_, __) {});
    container.listen(prayerRequestCountProvider(scope), (_, __) {});
    final first = container.read(prayerRequestsProvider(scope));
    expect(first.requests.map((r) => r.id), ['a']);
    expect(first.isLoading, isFalse);
    await _settle();

    expect(container.read(prayerRequestCountProvider(scope)), isNotNull);
    expect(
      container.read(prayerRequestsProvider(scope)).requests.map((r) => r.id),
      ['a', 'b'],
    );
  });

  test('chat rooms show the stored walk first, then the fresh one', () async {
    final key = ScreenCacheKey.user(
      'chat_rooms',
      userId: 'user-1',
      language: 'all',
    );
    store.entries[key] = jsonEncode({
      'rooms': [_room('old').toJson()],
      'skip': 1,
      'total': 1,
      'has_more': false,
    });
    repository.rooms = [_room('old'), _room('new', unread: 2)];

    final seen = <List<String>>[];
    container.listen(chatRoomsProvider, (_, next) {
      if (next.hasLoaded && !next.isLoading) {
        seen.add(next.rooms.map((r) => r.id).toList());
      }
    }, fireImmediately: true);
    // The stored walk is the very first state: no loading flag, no spinner.
    final first = container.read(chatRoomsProvider);
    expect(first.rooms.map((r) => r.id), ['old']);
    expect(first.isLoading, isFalse);
    expect(first.hasLoaded, isTrue);
    await _settle();

    expect(seen.first, ['old']);
    expect(seen.last, unorderedEquals(['old', 'new']));
    expect(container.read(chatRoomsProvider).hasUnread, isTrue);
    expect(jsonDecode(store.entries[key]!)['rooms'], hasLength(2));
  });

  test('my prayer requests seed from the store and keep it on failure',
      () async {
    final key = ScreenCacheKey.user(
      'my_prayer_requests',
      userId: 'user-1',
      language: 'all',
      params: ['-', '-'],
    );
    store.entries[key] = jsonEncode(
      ChatMessagesPage(
        messages: [_request('a')],
        skip: 0,
        limit: 20,
        total: 1,
      ).toJson(),
    );
    repository.failure = const ServerFailure('down');

    container.listen(myPrayerRequestsProvider, (_, __) {});
    final first = container.read(myPrayerRequestsProvider);
    expect(first.requests.map((r) => r.id), ['a']);
    expect(first.isLoading, isFalse);
    await _settle();

    final state = container.read(myPrayerRequestsProvider);
    expect(state.requests.map((r) => r.id), ['a']);
    expect(state.error, isNull);
    expect(state.hasLoaded, isTrue);
  });

  test('intentions come from the store before the server', () async {
    final key = ScreenCacheKey.public('prayer_intentions', language: 'all');
    store.entries[key] = jsonEncode([
      const ChatPrayerIntentionDTO(
        slug: 'peace',
        label: 'Peace',
        color: '#fff',
      ).toJson(),
    ]);
    repository.intentions = const [
      ChatPrayerIntentionDTO(slug: 'peace', label: 'Peace', color: '#fff'),
      ChatPrayerIntentionDTO(slug: 'health', label: 'Health', color: '#000'),
    ];

    final seen = <List<String>>[];
    // The stored list is the very first state, so listen from the start.
    container.listen(prayerIntentionsProvider, (_, next) {
      final value = next.valueOrNull;
      if (value != null) seen.add(value.map((i) => i.slug).toList());
    }, fireImmediately: true);
    expect(container.read(prayerIntentionsProvider).isLoading, isFalse);
    await _settle();

    expect(seen, [
      ['peace'],
      ['peace', 'health'],
    ]);
  });
}
