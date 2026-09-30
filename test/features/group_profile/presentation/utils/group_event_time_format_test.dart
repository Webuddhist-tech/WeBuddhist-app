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
}
