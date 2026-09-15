import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationChannels', () {
    group('routineBlock constants', () {
      test('channel ID is stable — changing it silently breaks existing scheduled notifications on devices', () {
          expect(NotificationChannels.routineBlockId, 'routine_block_reminder');
        },
      );

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
        },
      );

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

    group('timerCompleteChannel', () {
      test('channel ID is versioned so Android recreates sound settings', () {
        expect(NotificationChannels.timerCompleteId, 'timer_complete_v2');
      });

      test('sound is set on channel', () {
        expect(
          NotificationChannels.timerCompleteChannel.sound,
          isA<RawResourceAndroidNotificationSound>(),
        );
        final sound = NotificationChannels.timerCompleteChannel.sound!;
        expect(sound.sound, 'routine');
      });

      test('alerts with high importance', () {
        expect(
          NotificationChannels.timerCompleteChannel.importance,
          Importance.high,
        );
        expect(NotificationChannels.timerCompleteChannel.playSound, isTrue);
      });
    });

    group('timerCompleteDetails', () {
      test('Android details use the timer completion channel and sound', () {
        final android = NotificationChannels.timerCompleteDetails.android!;

        expect(android.channelId, NotificationChannels.timerCompleteId);
        expect(android.sound, isA<RawResourceAndroidNotificationSound>());
        final sound = android.sound!;
        expect(sound.sound, 'routine');
        expect(android.playSound, isTrue);
      });

      test('iOS details present the bundled bell sound', () {
        final ios = NotificationChannels.timerCompleteDetails.iOS!;

        expect(ios.sound, 'routine.caf');
        expect(ios.presentSound, isTrue);
      });
    });
  });
}
