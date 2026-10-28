import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_time_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  DateTime at(int hour, [int minute = 0]) =>
      DateTime(2026, 9, 29, hour, minute);

  // CLDR puts a narrow no-break space (U+202F) before the day period.
  group('12-hour clocks drop on-the-hour minutes', () {
    test('en', () {
      expect(formatGroupEventTime(at(15), 'en'), '3\u202fpm');
      expect(formatGroupEventTime(at(0), 'en'), '12\u202fam');
      expect(formatGroupEventTime(at(20, 30), 'en'), '8:30\u202fpm');
    });

    test('zh_TW keeps its leading day period', () {
      expect(formatGroupEventTime(at(15), 'zh_TW'), '下午3');
      expect(formatGroupEventTime(at(20, 30), 'zh_TW'), '下午8:30');
    });
  });

  group('24-hour clocks keep their minutes', () {
    test('zh', () {
      expect(formatGroupEventTime(at(15), 'zh'), '15:00');
      expect(formatGroupEventTime(at(0), 'zh'), '00:00');
    });

    test('mn', () {
      expect(formatGroupEventTime(at(10), 'mn'), '10:00');
    });

    test('ne keeps native digits', () {
      expect(formatGroupEventTime(at(15), 'ne'), '१५:००');
    });
  });

  group('multi-day ranges keep the year', () {
    test('same year puts the year on the end only', () {
      expect(
        formatGroupEventDayRange(
          DateTime(2026, 3, 12),
          DateTime(2026, 3, 15),
          'en',
        ),
        '12 Mar - 15 Mar 2026',
      );
    });

    test('a range that crosses a year labels both ends', () {
      expect(
        formatGroupEventDayRange(
          DateTime(2026, 12, 28),
          DateTime(2027, 1, 4),
          'en',
          separator: ' – ',
        ),
        '28 Dec 2026 – 4 Jan 2027',
      );
    });
  });
}
