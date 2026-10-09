import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_translation_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_summary_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prayer request DTOs', () {
    test('a PRAYER message carries its prayer fields', () {
      final message = ChatMessageDTO.fromJson({
        'id': 'm1',
        'room_id': 'r1',
        'sender_id': 'u1',
        'sender_email': 'u1@example.com',
        'sender_name': 'Tenzin',
        'body': 'Please pray for my mother',
        'created_at': '2026-09-11T10:04:00+00:00',
        'message_type': 'PRAYER',
        'intention': {
          'slug': 'healing',
          'label': 'Healing',
          'color': '#4A78C2',
          'description': 'For illness, surgery and recovery.',
          'display_order': 0,
        },
        'prayer_count': 12,
        'prayed_by_me': true,
        'my_prayer_count': 5,
        'recent_prayers': [
          {'user_id': 'u2', 'name': 'Pema', 'avatar_url': 'https://a/p.png'},
        ],
      });

      expect(message.isPrayerRequest, isTrue);
      expect(message.intention?.slug, 'healing');
      expect(message.intention?.color, '#4A78C2');
      expect(message.prayerCount, 12);
      expect(message.prayedByMe, isTrue);
      expect(message.myPrayerCount, 5);
      expect(message.recentPrayers, [
        const ChatPrayerUserDTO(
          userId: 'u2',
          name: 'Pema',
          avatarUrl: 'https://a/p.png',
        ),
      ]);
      expect(ChatMessageDTO.fromJson(message.toJson()), message);
    });

    test('a message without message_type is TEXT with no prayer fields', () {
      final message = ChatMessageDTO.fromJson({
        'id': 'm1',
        'room_id': 'r1',
        'sender_id': 'u1',
        'sender_email': 'u1@example.com',
        'body': 'hello',
        'created_at': '2026-09-11T10:04:00+00:00',
      });

      expect(message.isPrayerRequest, isFalse);
      expect(message.messageType, ChatMessageDTO.typeText);
      final json = message.toJson();
      expect(json['message_type'], 'TEXT');
      expect(json.containsKey('prayer_count'), isFalse);
      expect(json.containsKey('prayed_by_me'), isFalse);
      expect(json.containsKey('my_prayer_count'), isFalse);
      expect(json.containsKey('recent_prayers'), isFalse);
      expect(json.containsKey('intention'), isFalse);
    });

    test('a who-prayed row keeps email, time and count', () {
      final user = ChatPrayerUserDTO.fromJson({
        'user_id': 'u2',
        'email': 'pema@example.com',
        'name': 'Pema',
        'avatar_url': 'https://a/p.png',
        'created_at': '2026-09-11T10:04:00+00:00',
        'prayer_count': 4,
        'last_prayed_at': '2026-09-29T10:04:00+00:00',
      });
      expect(user.email, 'pema@example.com');
      expect(user.createdAt, '2026-09-11T10:04:00+00:00');
      expect(user.prayerCount, 4);
      expect(user.lastPrayedAt, '2026-09-29T10:04:00+00:00');
      expect(ChatPrayerUserDTO.fromJson(user.toJson()), user);
    });

    test('an avatar-stack row without a count reads as zero', () {
      final user = ChatPrayerUserDTO.fromJson({'user_id': 'u2', 'name': 'Pema'});
      expect(user.prayerCount, 0);
      expect(user.toJson().containsKey('prayer_count'), isFalse);
      expect(ChatPrayerUserDTO.fromJson(user.toJson()), user);
    });

    test('copyWith keeps message_type and rewrites prayer state', () {
      final message = ChatMessageDTO.fromJson({
        'id': 'm1',
        'room_id': 'r1',
        'sender_id': 'u1',
        'sender_email': 'u1@example.com',
        'body': 'hello',
        'created_at': '2026-09-11T10:04:00+00:00',
        'message_type': 'PRAYER',
        'prayer_count': 1,
        'prayed_by_me': false,
      });

      final updated = message.copyWith(
        prayerCount: 2,
        prayedByMe: true,
        myPrayerCount: 3,
      );
      expect(updated.isPrayerRequest, isTrue);
      expect(updated.prayerCount, 2);
      expect(updated.prayedByMe, isTrue);
      expect(updated.myPrayerCount, 3);
      expect(updated.body, 'hello');
    });

    test('ChatPrayerSummaryDTO round-trips', () {
      final summary = ChatPrayerSummaryDTO.fromJson({
        'message_id': 'm1',
        'prayer_count': 4,
        'prayed_by_me': true,
        'my_prayer_count': 2,
        'created': false,
      });
      expect(summary.created, isFalse);
      expect(summary.myPrayerCount, 2);
      expect(ChatPrayerSummaryDTO.fromJson(summary.toJson()), summary);
    });

    test('ChatPrayerSummaryDTO without my_prayer_count keeps it null', () {
      final summary = ChatPrayerSummaryDTO.fromJson({
        'message_id': 'm1',
        'prayer_count': 4,
        'prayed_by_me': true,
      });
      expect(summary.myPrayerCount, isNull);
      expect(summary.toJson().containsKey('my_prayer_count'), isFalse);
      expect(ChatPrayerSummaryDTO.fromJson(summary.toJson()), summary);
    });

    test('an EVENT room carries event_id instead of group_id', () {
      final room = ChatRoomDTO.fromJson({
        'id': 'r1',
        'created_by': 'u1',
        'kind': 'EVENT',
        'event_id': 'e1',
        'name': 'Tara puja',
        'updated_at': '2026-09-11T10:04:00+00:00',
      });
      expect(room.eventId, 'e1');
      expect(room.groupId, isNull);
      expect(ChatRoomDTO.fromJson(room.toJson()), room);
    });

    test('a PRAYER message parses a ready translation from the API', () {
      final message = ChatMessageDTO.fromJson({
        'id': 'm1',
        'room_id': 'r1',
        'sender_id': 'u1',
        'sender_email': 'u1@example.com',
        'sender_name': 'Tenzin',
        'body': '愿上师加持我的母亲',
        'created_at': '2026-09-11T10:04:00+00:00',
        'message_type': 'PRAYER',
        'prayer_count': 1,
        'prayed_by_me': false,
        'source_language': 'ZH',
        'translation': {
          'target_language': 'EN',
          'status': 'ready',
          'body': 'May the Guru bless my mother',
        },
        'can_translate': true,
      });

      expect(message.sourceLanguage, 'ZH');
      expect(
        message.translation,
        const ChatMessageTranslationDTO(
          targetLanguage: 'EN',
          status: ChatMessageTranslationDTO.statusReady,
          body: 'May the Guru bless my mother',
        ),
      );
      expect(message.translation?.isReady, isTrue);
      expect(message.canTranslate, isTrue);
      expect(message.translatedBody, 'May the Guru bless my mother');
      final json = message.toJson();
      expect(json['source_language'], 'ZH');
      expect(json['translation'], {
        'target_language': 'EN',
        'status': 'ready',
        'body': 'May the Guru bless my mother',
      });
      expect(json['can_translate'], isTrue);
      expect(ChatMessageDTO.fromJson(json), message);
    });

    test('a pending translation parses but is not ready', () {
      final message = ChatMessageDTO.fromJson(
        prayerJson({
          'source_language': null,
          'translation': {'status': 'pending', 'body': null},
          'can_translate': true,
        }),
      );

      expect(message.sourceLanguage, isNull);
      expect(
        message.translation?.status,
        ChatMessageTranslationDTO.statusPending,
      );
      expect(message.translation?.isReady, isFalse);
      expect(message.canTranslate, isTrue);
      expect(message.translatedBody, isNull);
      expect(ChatMessageDTO.fromJson(message.toJson()), message);
    });

    test('a prayer without a translation key has none', () {
      final message = ChatMessageDTO.fromJson(
        prayerJson({'can_translate': false}),
      );

      expect(message.sourceLanguage, isNull);
      expect(message.translation, isNull);
      expect(message.canTranslate, isFalse);
      expect(message.translatedBody, isNull);
      final json = message.toJson();
      expect(json.containsKey('translation'), isFalse);
      expect(json.containsKey('source_language'), isFalse);
      expect(json['can_translate'], isFalse);
      expect(ChatMessageDTO.fromJson(json), message);
    });

    test('an English prayer keeps source_language with no translation', () {
      final message = ChatMessageDTO.fromJson(
        prayerJson({'source_language': 'EN', 'can_translate': false}),
      );

      expect(message.sourceLanguage, 'EN');
      expect(message.translation, isNull);
      expect(message.translatedBody, isNull);
      final json = message.toJson();
      expect(json['source_language'], 'EN');
      expect(json.containsKey('translation'), isFalse);
      expect(ChatMessageDTO.fromJson(json), message);
    });

    test('can_translate false gates a ready translation', () {
      final message = ChatMessageDTO.fromJson(
        prayerJson({
          'source_language': 'ZH',
          'translation': readyTranslationJson,
          'can_translate': false,
        }),
      );

      expect(message.translation?.isReady, isTrue);
      expect(message.translatedBody, isNull);
    });

    test('a ready status with an empty body is not ready', () {
      const empty = ChatMessageTranslationDTO(
        targetLanguage: 'EN',
        status: ChatMessageTranslationDTO.statusReady,
        body: '',
      );
      expect(empty.isReady, isFalse);
      expect(
        ChatMessageTranslationDTO.fromJson({
          'target_language': 'EN',
          'status': 'ready',
          'body': null,
        }).isReady,
        isFalse,
      );

      final message = ChatMessageDTO.fromJson(
        prayerJson({
          'source_language': 'ZH',
          'translation': {
            'target_language': 'EN',
            'status': 'ready',
            'body': '',
          },
          'can_translate': true,
        }),
      );
      expect(message.translatedBody, isNull);
    });

    test('copyWith(clearTranslation: true) drops the translation', () {
      final message = ChatMessageDTO.fromJson(
        prayerJson({
          'source_language': 'ZH',
          'translation': readyTranslationJson,
          'can_translate': true,
        }),
      );

      final cleared = message.copyWith(clearTranslation: true);
      expect(cleared.translation, isNull);
      expect(cleared.sourceLanguage, isNull);
      expect(cleared.translatedBody, isNull);
      expect(cleared.canTranslate, isTrue);
      expect(cleared.body, message.body);
    });

    test('copyWith(clearTranslation: true) keeps values passed with it', () {
      final message = ChatMessageDTO.fromJson(
        prayerJson({
          'source_language': 'ZH',
          'translation': readyTranslationJson,
          'can_translate': true,
        }),
      );
      const replacement = ChatMessageTranslationDTO(
        targetLanguage: 'EN',
        status: ChatMessageTranslationDTO.statusReady,
        body: 'May all beings be happy',
      );

      final replaced = message.copyWith(
        clearTranslation: true,
        translation: replacement,
        sourceLanguage: 'BO',
      );
      expect(replaced.translation, replacement);
      expect(replaced.sourceLanguage, 'BO');
      expect(replaced.translatedBody, 'May all beings be happy');
    });

    test('copyWith without clearTranslation keeps the translation', () {
      final message = ChatMessageDTO.fromJson(
        prayerJson({
          'source_language': 'ZH',
          'translation': readyTranslationJson,
          'can_translate': true,
        }),
      );

      final same = message.copyWith();
      expect(same.translation, message.translation);
      expect(same.sourceLanguage, 'ZH');
      expect(same, message);

      final prayed = message.copyWith(prayerCount: 2);
      expect(prayed.prayerCount, 2);
      expect(prayed.translation, message.translation);
      expect(prayed.sourceLanguage, 'ZH');
      expect(prayed.translatedBody, 'May the Guru bless my mother');
    });

    test('ChatMessageTranslationDTO.fromJson tolerates missing keys', () {
      final translation = ChatMessageTranslationDTO.fromJson({});
      expect(translation.targetLanguage, '');
      expect(translation.status, '');
      expect(translation.body, isNull);
      expect(translation.isReady, isFalse);
      final json = translation.toJson();
      expect(json, {'target_language': '', 'status': '', 'body': null});
      expect(ChatMessageTranslationDTO.fromJson(json), translation);
    });
  });
}

const readyTranslationJson = {
  'target_language': 'EN',
  'status': 'ready',
  'body': 'May the Guru bless my mother',
};

Map<String, dynamic> prayerJson(Map<String, dynamic> extra) {
  return {
    'id': 'm1',
    'room_id': 'r1',
    'sender_id': 'u1',
    'sender_email': 'u1@example.com',
    'sender_name': 'Tenzin',
    'body': 'Please pray for my mother',
    'created_at': '2026-09-11T10:04:00+00:00',
    'message_type': 'PRAYER',
    'prayer_count': 1,
    'prayed_by_me': false,
    ...extra,
  };
}
