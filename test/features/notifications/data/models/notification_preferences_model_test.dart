import 'package:flutter_pecha/features/notifications/data/models/notification_preferences_model.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 10, 9, 12);

Map<String, dynamic> _entry(
  String type, {
  bool enabled = true,
  String? mutedUntil,
  String source = 'GLOBAL',
}) => {
  'notification_type': type,
  'enabled': enabled,
  'muted_until': mutedUntil,
  'source': source,
};

Map<String, dynamic> _response(List<Map<String, dynamic>> preferences) => {
  'channel': 'PUSH',
  'preferences': preferences,
  'group_overrides': <Map<String, dynamic>>[],
};

NotificationPreferences _parse(List<Map<String, dynamic>> preferences) =>
    NotificationPreferencesModel.fromJson(
      _response(preferences),
      now: _now,
    ).toEntity();

const _allOn = NotificationPreferences(
  groupPosts: true,
  groupChats: true,
  prayerReceived: true,
  prayerRequest: true,
);

void main() {
  group('NotificationPreferencesModel.fromJson', () {
    test('reads each switch from its own type', () {
      expect(
        _parse([
          _entry('CHAT_MESSAGE'),
          _entry('GROUP_POST'),
          _entry('PRAYER_RECEIVED'),
          _entry('PRAYER_REQUEST'),
        ]),
        _allOn,
      );

      for (final toggle in ConnectNotificationToggle.values) {
        final prefs = _parse([
          for (final t in ConnectNotificationToggle.values)
            _entry(t.notificationType, enabled: t != toggle),
        ]);
        expect(prefs, _allOn.withValue(toggle, false), reason: '$toggle');
      }
    });

    test('a type the backend leaves out falls back to its default', () {
      expect(_parse(const []), NotificationPreferences.defaults);
      expect(
        NotificationPreferencesModel.fromJson(const {}, now: _now).toEntity(),
        NotificationPreferences.defaults,
      );
    });

    test('an entry without enabled falls back to its default', () {
      expect(
        _parse([
          {'notification_type': 'CHAT_MESSAGE'},
          {'notification_type': 'GROUP_POST'},
        ]),
        NotificationPreferences.defaults,
      );
    });

    test('an active snooze reads as off, an expired one as on', () {
      final prefs = _parse([
        _entry('GROUP_POST', mutedUntil: '2026-10-09T13:00:00Z'),
        _entry('PRAYER_RECEIVED', mutedUntil: '2026-10-09T11:00:00Z'),
      ]);
      expect(prefs.groupPosts, isFalse);
      expect(prefs.prayerReceived, isTrue);
    });

    test('types without a switch and malformed entries are ignored', () {
      expect(
        _parse([
          _entry('EVENT', enabled: false),
          _entry('SERIES', enabled: false),
          {'enabled': false},
          _entry('CHAT_MESSAGE'),
        ]),
        NotificationPreferences.defaults.copyWith(groupChats: true),
      );
    });
  });

  group('NotificationPreferencesModel.toRequestJson', () {
    test('sends only the switches passed', () {
      expect(
        NotificationPreferencesModel.toRequestJson({
          ConnectNotificationToggle.groupPosts: false,
        }),
        {
          'preferences': [
            {'notification_type': 'GROUP_POST', 'enabled': false},
          ],
        },
      );
    });

    test('turning a switch on also lifts any snooze', () {
      final body = NotificationPreferencesModel.toRequestJson({
        ConnectNotificationToggle.prayerRequest: true,
      });
      final entry =
          (body['preferences'] as List).single as Map<String, dynamic>;
      expect(entry, {
        'notification_type': 'PRAYER_REQUEST',
        'enabled': true,
        'muted_until': null,
      });
      expect(entry.containsKey('muted_until'), isTrue);
    });

    test('maps every switch to its backend type', () {
      expect(
        {
          for (final toggle in ConnectNotificationToggle.values)
            toggle: toggle.notificationType,
        },
        {
          ConnectNotificationToggle.groupPosts: 'GROUP_POST',
          ConnectNotificationToggle.groupChats: 'CHAT_MESSAGE',
          ConnectNotificationToggle.prayerReceived: 'PRAYER_RECEIVED',
          ConnectNotificationToggle.prayerRequest: 'PRAYER_REQUEST',
        },
      );
    });
  });
}
