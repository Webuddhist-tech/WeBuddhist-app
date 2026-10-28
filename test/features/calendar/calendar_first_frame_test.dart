import 'dart:convert';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/features/calendar/data/datasource/calendar_remote_datasource.dart';
import 'package:flutter_pecha/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:flutter_pecha/features/calendar/presentation/providers/tibetan_calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_screen_cache_store.dart';

class _FakeRemote implements CalendarRemoteDatasource {
  int lunarDay = 2;

  @override
  Future<Map<String, dynamic>> fetchTodayJson() async => _day(lunarDay);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _day(int lunarDay) => {
  'gregorian_date': '2026-10-28',
  'lunar_day': lunarDay,
};

void main() {
  test('the stored day is the state on the very first read', () async {
    final store = FakeScreenCacheStore();
    final now = DateTime.now();
    final key = ScreenCacheKey.public(
      'calendar_today',
      language: 'all',
      params: ['${now.year}-${now.month}-${now.day}'],
    );
    store.entries[key] = jsonEncode(_day(1));
    final remote = _FakeRemote();
    final container = ProviderContainer(
      overrides: [
        screenCacheStoreProvider.overrideWithValue(store),
        calendarRepositoryProvider.overrideWithValue(
          CalendarRepositoryImpl(datasource: remote, store: store),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(todayCalendarDayProvider, (_, __) {});

    final first = container.read(todayCalendarDayProvider);
    expect(first.isLoading, isFalse);
    expect(first.requireValue.lunarDay, 1);

    await pumpEventQueue();
    expect(container.read(todayCalendarDayProvider).requireValue.lunarDay, 2);
  });
}
