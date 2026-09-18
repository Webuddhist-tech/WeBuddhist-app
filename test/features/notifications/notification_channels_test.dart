import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationChannels', () {
    group('routineBlock constants', () {
      test('channel ID is stable — changing it silently breaks existing scheduled notifications on devices', () {
        expect(NotificationChannels.routineBlockId, 'routine_block_reminder');
      });

      test('channel name is correct', () {
        expect(NotificationChannels.routineBlockName, 'Routine Block Reminder');
      });

      test('iOS sound file is routine.caf', () {
        expect(NotificationChannels.routineIosSoundFile, 'routine.caf');
      });

      test('Android sound references res/raw/routine without extension', () {
        expect(
          NotificationChannels.routineAndroidSound,
          isA<RawResourceAndroidNotificationSound>(),
        );
        expect(NotificationChannels.routineAndroidSound.sound, 'routine');
      });
    });

    group('routineBlockChannel', () {
      test('importance is high', () {
        expect(
          NotificationChannels.routineBlockChannel.importance,
          Importance.high,
        );
      });

      test('playSound is true', () {
        expect(NotificationChannels.routineBlockChannel.playSound, isTrue);
      });

      test('vibration is enabled', () {
        expect(
          NotificationChannels.routineBlockChannel.enableVibration,
          isTrue,
        );
      });

      test('sound is set on channel (Android 8+ requires this for custom sound)', () {
        expect(
          NotificationChannels.routineBlockChannel.sound,
          isA<RawResourceAndroidNotificationSound>(),
        );
        final sound = NotificationChannels.routineBlockChannel.sound!;
        expect(sound.sound, 'routine');
      });

      test('channel ID matches routineBlockId constant', () {
        expect(
          NotificationChannels.routineBlockChannel.id,
          NotificationChannels.routineBlockId,
        );
      });
    });

    group('routineBlockDetails', () {
      test('Android details use correct channel ID', () {
        final details = NotificationChannels.routineBlockDetails();
        final android = details.android!;
        expect(android.channelId, NotificationChannels.routineBlockId);
      });

      test('Android details have custom sound', () {
        final details = NotificationChannels.routineBlockDetails();
        final android = details.android!;
        expect(android.sound, isA<RawResourceAndroidNotificationSound>());
        final sound = android.sound!;
        expect(sound.sound, 'routine');
      });

      test('Android details have playSound true', () {
        final details = NotificationChannels.routineBlockDetails();
        final android = details.android!;
        expect(android.playSound, isTrue);
      });

      test('Android details have importance high', () {
        final details = NotificationChannels.routineBlockDetails();
        final android = details.android!;
        expect(android.importance, Importance.high);
      });

      test('Android details have priority high', () {
        final details = NotificationChannels.routineBlockDetails();
        final android = details.android!;
        expect(android.priority, Priority.high);
      });

      test('iOS details have sound routine.caf', () {
        final details = NotificationChannels.routineBlockDetails();
        final ios = details.iOS!;
        expect(ios.sound, 'routine.caf');
      });

      test('iOS details have presentAlert true', () {
        final details = NotificationChannels.routineBlockDetails();
        final ios = details.iOS!;
        expect(ios.presentAlert, isTrue);
      });

      test('iOS details have presentSound true', () {
        final details = NotificationChannels.routineBlockDetails();
        final ios = details.iOS!;
        expect(ios.presentSound, isTrue);
      });

      test('custom icon is passed through to Android details', () {
        final details = NotificationChannels.routineBlockDetails(
          icon: 'custom_icon',
        );
        final android = details.android!;
        expect(android.icon, 'custom_icon');
      });
    });

    group('timerBellChannel', () {
      test('uses a new id, and retires the silent channels it replaces', () {
        expect(NotificationChannels.timerBellId, 'timer_bell');
        expect(
          NotificationChannels.legacyTimerBellIds,
          contains('timer_complete'),
        );
        expect(
          NotificationChannels.legacyTimerBellIds,
          isNot(contains(NotificationChannels.timerBellId)),
        );
      });

      test('rings at high importance with the routine sound', () {
        const channel = NotificationChannels.timerBellChannel;
        expect(channel.importance, Importance.high);
        expect(channel.playSound, isTrue);
        expect(channel.sound!.sound, 'routine');
      });

      test('details use the bell channel on both platforms', () {
        final android = NotificationChannels.timerBellDetails.android!;
        expect(android.channelId, NotificationChannels.timerBellId);
        expect(android.playSound, isTrue);

        final ios = NotificationChannels.timerBellDetails.iOS!;
        expect(ios.sound, 'routine.caf');
        expect(ios.presentSound, isTrue);
      });
    });
  });
}
