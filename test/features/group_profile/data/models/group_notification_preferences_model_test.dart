import 'package:flutter_pecha/features/group_profile/data/models/group_notification_preferences_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 9, 16, 12);

Map<String, dynamic> _entry(
  String type, {
  bool enabled = true,
  String? mutedUntil,
  String source = 'DEFAULT',
}) => {
  'notification_type': type,
  'enabled': enabled,
  'muted_until': mutedUntil,
  'source': source,
};

Map<String, dynamic> _response(List<Map<String, dynamic>> preferences) => {
  'group_id': 'grp-1',
  'channel': 'PUSH',
  'preferences': preferences,
};

GroupNotificationPreferences _parse(List<Map<String, dynamic>> preferences) =>
    GroupNotificationPreferencesModel.fromJson(
      _response(preferences),
      now: _now,
    ).toEntity();

void main() {
  group('GroupNotificationPreferencesModel.fromJson', () {
    test('everything on when the backend lists every type as enabled', () {
      expect(
        _parse([
          _entry('CHAT_MESSAGE'),
          _entry('GROUP_POST'),
          _entry('EVENT'),
          _entry('ACCUMULATION'),
        ]),
        GroupNotificationPreferences.allOn,
      );
    });

    test('chat follows CHAT_MESSAGE alone', () {
      expect(
        _parse([
          _entry('CHAT_MESSAGE', enabled: false, source: 'GROUP'),
          _entry('GROUP_POST'),
          _entry('EVENT'),
          _entry('ACCUMULATION'),
        ]),
        const GroupNotificationPreferences(chat: false, content: true),
      );
    });

    test('content is off as soon as one of its types is off', () {
      for (final type in GroupNotificationTypes.content) {
        final prefs = _parse([
          _entry('CHAT_MESSAGE'),
          for (final t in GroupNotificationTypes.content)
            _entry(t, enabled: t != type),
        ]);
        expect(prefs.content, isFalse, reason: '$type off should mute content');
        expect(prefs.chat, isTrue);
      }
    });

    test('a global off reads the same as a group off', () {
      expect(
        _parse([
          _entry('GROUP_POST', enabled: false, source: 'GLOBAL'),
        ]).content,
        isFalse,
      );
    });

    test('an active snooze reads as off, an expired one as on', () {
      expect(
        _parse([
          _entry('CHAT_MESSAGE', mutedUntil: '2026-09-16T20:00:00Z'),
        ]).chat,
        isFalse,
      );
      expect(
        _parse([
          _entry('CHAT_MESSAGE', mutedUntil: '2026-09-16T08:00:00Z'),
        ]).chat,
        isTrue,
      );
    });

    test('types the backend omits, and unrelated types, default to on', () {
      expect(_parse(const []), GroupNotificationPreferences.allOn);
      expect(
        _parse([
          _entry('EVENT_REMINDER', enabled: false),
          _entry('SERIES', enabled: false),
        ]),
        GroupNotificationPreferences.allOn,
      );
    });

    test('tolerates a missing preferences array', () {
      expect(
        GroupNotificationPreferencesModel.fromJson(const {}).toEntity(),
        GroupNotificationPreferences.allOn,
      );
    });
  });

  group('GroupNotificationPreferencesModel.toRequestJson', () {
    test('chat off sends only CHAT_MESSAGE', () {
      expect(GroupNotificationPreferencesModel.toRequestJson(chat: false), {
        'preferences': [
          {'notification_type': 'CHAT_MESSAGE', 'enabled': false},
        ],
      });
    });

    test('content expands to posts, events and accumulation', () {
      expect(GroupNotificationPreferencesModel.toRequestJson(content: false), {
        'preferences': [
          {'notification_type': 'GROUP_POST', 'enabled': false},
          {'notification_type': 'EVENT', 'enabled': false},
          {'notification_type': 'ACCUMULATION', 'enabled': false},
        ],
      });
    });

    test('turning a toggle on also lifts any snooze on its types', () {
      final body = GroupNotificationPreferencesModel.toRequestJson(chat: true);
      final entry = (body['preferences'] as List).single as Map;
      expect(entry['enabled'], isTrue);
      expect(entry.containsKey('muted_until'), isTrue);
      expect(entry['muted_until'], isNull);
    });

    test('never touches reminders or series', () {
      final body = GroupNotificationPreferencesModel.toRequestJson(
        chat: false,
        content: false,
      );
      final types =
          (body['preferences'] as List)
              .map((e) => (e as Map)['notification_type'])
              .toList();
      expect(types, isNot(contains('EVENT_REMINDER')));
      expect(types, isNot(contains('SERIES')));
      expect(types.length, 4);
    });
  });
}
