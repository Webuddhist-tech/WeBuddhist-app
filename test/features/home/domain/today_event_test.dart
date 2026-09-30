import 'package:flutter_pecha/features/home/domain/entities/today_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);

  const event = TodayEvent(
    id: 'e1',
    name: 'Tara Puja',
    timezone: 'Asia/Kolkata',
    startTime: '08:00',
    endTime: '17:00',
  );

  test('active inside the daily window in the event timezone', () {
    // 10:00 IST == 04:30 UTC
    expect(event.isActiveAt(DateTime.utc(2026, 9, 30, 4, 30)), isTrue);
  });

  test('inactive before the window starts', () {
    // 07:59 IST == 02:29 UTC
    expect(event.isActiveAt(DateTime.utc(2026, 9, 30, 2, 29)), isFalse);
  });

  test('inactive once the window ends', () {
    // 17:00 IST == 11:30 UTC
    expect(event.isActiveAt(DateTime.utc(2026, 9, 30, 11, 30)), isFalse);
  });

  test('respects start and end dates', () {
    final dated = TodayEvent(
      id: 'e2',
      name: 'Dated',
      startDate: DateTime.utc(2026, 9, 25, 2, 30),
      endDate: DateTime.utc(2026, 10, 15, 11, 30),
      timezone: 'Asia/Kolkata',
      startTime: '08:00',
      endTime: '17:00',
    );
    expect(dated.isActiveAt(DateTime.utc(2026, 9, 24, 4, 30)), isFalse);
    expect(dated.isActiveAt(DateTime.utc(2026, 10, 16, 4, 30)), isFalse);
    expect(dated.isActiveAt(DateTime.utc(2026, 10, 1, 4, 30)), isTrue);
  });

  test('overnight window wraps past midnight', () {
    const night = TodayEvent(
      id: 'e3',
      name: 'Night',
      timezone: 'UTC',
      startTime: '22:00',
      endTime: '02:00',
    );
    expect(night.isActiveAt(DateTime.utc(2026, 9, 30, 23)), isTrue);
    expect(night.isActiveAt(DateTime.utc(2026, 9, 30, 1)), isTrue);
    expect(night.isActiveAt(DateTime.utc(2026, 9, 30, 12)), isFalse);
  });

  test('always active without a time window', () {
    const allDay = TodayEvent(id: 'e4', name: 'All day');
    expect(allDay.isActiveAt(DateTime.utc(2026, 9, 30, 12)), isTrue);
  });
}
