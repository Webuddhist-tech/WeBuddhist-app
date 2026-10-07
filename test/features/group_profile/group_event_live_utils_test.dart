import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_live_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupEventLiveUtils.initialLanguage', () {
    test('keeps a supported content language', () {
      expect(GroupEventLiveUtils.initialLanguage('bo'), 'bo');
      expect(GroupEventLiveUtils.initialLanguage('zh'), 'zh');
      expect(GroupEventLiveUtils.initialLanguage(' EN '), 'en');
    });

    test('falls back to English for unsupported languages', () {
      expect(GroupEventLiveUtils.initialLanguage('hi'), 'en');
      expect(GroupEventLiveUtils.initialLanguage(''), 'en');
    });
  });

  group('GroupEventLiveUtils.isLiveLabel', () {
    test('detects live in the label', () {
      expect(GroupEventLiveUtils.isLiveLabel('live'), isTrue);
      expect(GroupEventLiveUtils.isLiveLabel('Tibetan LIVE'), isTrue);
    });

    test('is false for other labels', () {
      expect(GroupEventLiveUtils.isLiveLabel('recording'), isFalse);
      expect(GroupEventLiveUtils.isLiveLabel(null), isFalse);
    });
  });

  group('GroupEventLiveUtils.videoIdOf', () {
    test('resolves the stream id from the event youtube link', () {
      const event = GroupEvent(
        id: 'e1',
        groupId: 'g1',
        youtube: [
          GroupEventLink(
            id: 'l1',
            type: 'youtube',
            url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          ),
        ],
      );
      expect(GroupEventLiveUtils.videoIdOf(event), 'dQw4w9WgXcQ');
    });

    test('is null without a usable link', () {
      const none = GroupEvent(id: 'e1', groupId: 'g1');
      const broken = GroupEvent(
        id: 'e1',
        groupId: 'g1',
        youtube: [GroupEventLink(id: 'l1', type: 'youtube', url: 'nope')],
      );
      expect(GroupEventLiveUtils.videoIdOf(none), isNull);
      expect(GroupEventLiveUtils.videoIdOf(broken), isNull);
    });
  });

  group('GroupEventLiveUtils.hasEnded', () {
    final start = DateTime.utc(2026, 10, 5, 9);
    final end = DateTime.utc(2026, 10, 7, 18);

    test('ends at the end date, with the link still attached', () {
      final event = GroupEvent(
        id: 'e1',
        groupId: 'g1',
        startDate: start,
        endDate: end,
      );
      expect(
        GroupEventLiveUtils.hasEnded(
          event,
          end.subtract(const Duration(minutes: 1)),
        ),
        isFalse,
      );
      expect(GroupEventLiveUtils.hasEnded(event, end), isTrue);
    });

    test('with no usable end, ends the grace period after the start', () {
      final noEnd = GroupEvent(id: 'e1', groupId: 'g1', startDate: start);
      final sameEnd = GroupEvent(
        id: 'e1',
        groupId: 'g1',
        startDate: start,
        endDate: start,
      );
      final graceEnd = start.add(GroupEventLiveUtils.liveGrace);
      for (final event in [noEnd, sameEnd]) {
        expect(
          GroupEventLiveUtils.hasEnded(
            event,
            graceEnd.subtract(const Duration(minutes: 1)),
          ),
          isFalse,
        );
        expect(GroupEventLiveUtils.hasEnded(event, graceEnd), isTrue);
      }
    });

    test('a recurring event or one with no start never ends', () {
      final recurring = GroupEvent(
        id: 'e1',
        groupId: 'g1',
        startDate: start,
        endDate: end,
        isRecurring: true,
      );
      const undated = GroupEvent(id: 'e1', groupId: 'g1');
      final later = end.add(const Duration(days: 30));
      expect(GroupEventLiveUtils.hasEnded(recurring, later), isFalse);
      expect(GroupEventLiveUtils.hasEnded(undated, later), isFalse);
    });
  });
}
