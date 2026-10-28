import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_requests_filter.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_room_scope.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:fpdart/fpdart.dart';

/// A prayer room's id and first page, stored together so the sheet opens
/// without waiting for the room to resolve.
class PrayerRoomSnapshot {
  const PrayerRoomSnapshot({required this.roomId, required this.page});

  final String roomId;
  final ChatMessagesPage page;

  factory PrayerRoomSnapshot.fromJson(Map<String, dynamic> json) {
    return PrayerRoomSnapshot(
      roomId: json['room_id'] as String? ?? '',
      page: ChatMessagesPage.fromJson(json['page'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {'room_id': roomId, 'page': page.toJson()};
}

/// Stored first pages for the chat lists; see ScreenCacheSource.
///
/// Built on the repository rather than the datasource so the many test
/// fakes of [GroupChatRepository] keep working unchanged.
class GroupChatFirstPages {
  const GroupChatFirstPages({required this.repository, required this.store});

  final GroupChatRepository repository;
  final ScreenCacheStore store;

  ScreenCacheSource<ChatRoomsPage> rooms({required int limit}) {
    return ScreenCacheSource(
      store: store,
      key: _userKey('chat_rooms'),
      fetchJson:
          () async =>
              (await _unwrap(
                repository.listRooms(skip: 0, limit: limit),
              )).toJson(),
      fromJson: (json) => ChatRoomsPage.fromJson(json as Map<String, dynamic>),
      failureMessage: 'listRooms',
    );
  }

  ScreenCacheSource<List<ChatPrayerIntentionDTO>> intentions() {
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.public('prayer_intentions', language: 'all'),
      fetchJson:
          () async =>
              (await _unwrap(
                repository.listIntentions(),
              )).map((intention) => intention.toJson()).toList(),
      fromJson:
          (json) =>
              (json as List<dynamic>)
                  .whereType<Map<String, dynamic>>()
                  .map(ChatPrayerIntentionDTO.fromJson)
                  .toList(),
      failureMessage: 'listIntentions',
    );
  }

  ScreenCacheSource<ChatMessagesPage> myPrayerRequests({
    required int limit,
    String? eventId,
    String? groupId,
  }) {
    return ScreenCacheSource(
      store: store,
      key: _userKey(
        'my_prayer_requests',
        params: [eventId ?? '-', groupId ?? '-'],
      ),
      fetchJson:
          () async =>
              (await _unwrap(
                repository.listMyPrayerRequests(
                  skip: 0,
                  limit: limit,
                  eventId: eventId,
                  groupId: groupId,
                ),
              )).toJson(),
      fromJson:
          (json) => ChatMessagesPage.fromJson(json as Map<String, dynamic>),
      failureMessage: 'listMyPrayerRequests',
    );
  }

  /// The room and its first page under [filter]; the notifier reads and
  /// saves this itself because room resolution has its own failure states.
  ScreenCacheSource<PrayerRoomSnapshot> prayerRoom(
    PrayerRoomScope scope, {
    required PrayerRequestsFilter filter,
    required String translationLanguage,
    required int limit,
  }) {
    return ScreenCacheSource(
      store: store,
      key: _userKey(
        'prayer_room',
        language: translationLanguage,
        params: [
          scope.isEvent ? 'event' : 'group',
          scope.id,
          filter.mine ? 'mine' : (filter.sortParam ?? 'default'),
          filter.intentionParam ?? 'all',
        ],
      ),
      fetchJson: () async {
        final room = await _unwrap(
          scope.isEvent
              ? repository.getEventRoom(scope.id)
              : repository.getGroupRoom(scope.id),
        );
        final page = await _unwrap(
          filter.mine
              ? repository.listMyPrayerRequests(
                skip: 0,
                limit: limit,
                eventId: scope.eventId,
                groupId: scope.groupId,
              )
              : repository.listMessages(
                room.id,
                skip: 0,
                limit: limit,
                messageType: ChatMessageDTO.typePrayer,
                sort: filter.sortParam,
                intention: filter.intentionParam,
                translationLanguage: translationLanguage,
              ),
        );
        return PrayerRoomSnapshot(roomId: room.id, page: page).toJson();
      },
      fromJson:
          (json) => PrayerRoomSnapshot.fromJson(json as Map<String, dynamic>),
      failureMessage: 'listMessages',
    );
  }

  ScreenCacheSource<ChatPrayersPage> prayers(
    String messageId, {
    required int limit,
  }) {
    return ScreenCacheSource(
      store: store,
      key: _userKey('prayer_supporters', params: [messageId]),
      fetchJson:
          () async =>
              (await _unwrap(
                repository.listPrayers(messageId, skip: 0, limit: limit),
              )).toJson(),
      fromJson:
          (json) => ChatPrayersPage.fromJson(json as Map<String, dynamic>),
      failureMessage: 'listPrayers',
    );
  }

  // Read without an await so a screen can seed its first frame.
  String _userKey(
    String screen, {
    String language = 'all',
    List<String> params = const [],
  }) {
    String? userId;
    try {
      userId = store.currentUserIdSync;
    } catch (_) {
      userId = null;
    }
    return ScreenCacheKey.user(
      screen,
      userId: userId,
      language: language,
      params: params,
    );
  }
}

Future<T> _unwrap<T>(Future<Either<Failure, T>> result) async {
  return (await result).fold((failure) => throw failureToException(failure), (value) => value);
}

/// Turns a repository failure back into the exception ExceptionMapper maps.
Exception failureToException(Failure failure) {
  return switch (failure) {
    NetworkFailure() => NetworkException(failure.message),
    AuthenticationFailure() => AuthenticationException(failure.message),
    AuthorizationFailure() => AuthorizationException(failure.message),
    NotFoundFailure() => NotFoundException(failure.message),
    RateLimitFailure() => RateLimitException(failure.message),
    _ => ServerException(failure.message),
  };
}
