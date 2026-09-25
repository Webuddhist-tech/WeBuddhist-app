import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_notification_bell.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_notification_preferences.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_notification_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';

GroupNotificationPreferencesState _prefs({
  bool chat = true,
  bool isLoading = false,
  Failure? loadFailure,
}) {
  return GroupNotificationPreferencesState(
    preferences: GroupNotificationPreferences.allOn.copyWith(chat: chat),
    isLoading: isLoading,
    loadFailure: loadFailure,
  );
}

void main() {
  group('chatBellStateFor', () {
    test('chat on', () {
      expect(chatBellStateFor(_prefs(), masterOn: true), ChatBellState.on);
    });

    test('chat muted', () {
      expect(
        chatBellStateFor(_prefs(chat: false), masterOn: true),
        ChatBellState.off,
      );
    });

    test('still loading', () {
      expect(
        chatBellStateFor(_prefs(isLoading: true), masterOn: true),
        ChatBellState.loading,
      );
    });

    test('load failed', () {
      expect(
        chatBellStateFor(
          _prefs(loadFailure: const NetworkFailure('offline')),
          masterOn: true,
        ),
        ChatBellState.unavailable,
      );
    });

    test('master off wins over every group state', () {
      for (final prefs in [
        _prefs(),
        _prefs(chat: false),
        _prefs(isLoading: true),
        _prefs(loadFailure: const NetworkFailure('offline')),
      ]) {
        expect(chatBellStateFor(prefs, masterOn: false), ChatBellState.appOff);
      }
    });
  });
}
