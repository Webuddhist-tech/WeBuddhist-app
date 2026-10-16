import 'package:flutter_pecha/features/home/data/models/today_event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses group avatar and keeps it through a cache round trip', () {
    final model = TodayEventModel.fromJson({
      'id': 'e1',
      'metadata': {'id': 'm1', 'name': 'Act of kindness', 'language': 'EN'},
      'start_date': '2026-10-13T00:30:00Z',
      'end_date': '2026-10-17T18:29:00Z',
      'timezone': 'Asia/Kolkata',
      'start_time': '06:00',
      'end_time': '23:59',
      'group_avatar_url': 'https://example.com/avatar.webp',
    });

    expect(model.groupAvatarUrl, 'https://example.com/avatar.webp');
    final cached = TodayEventModel.fromJson(model.toJson()).toEntity();
    expect(cached.groupAvatarUrl, 'https://example.com/avatar.webp');
    expect(cached.name, 'Act of kindness');
  });

  test('response keeps every event in order', () {
    final response = TodayEventsResponseModel.fromJson({
      'events': [
        {'id': 'e1', 'metadata': {'name': 'First'}},
        {'id': 'e2', 'metadata': {'name': 'Second'}},
      ],
      'total': 2,
    });

    expect(response.events.map((e) => e.id), ['e1', 'e2']);
    expect(response.events.first.groupAvatarUrl, isNull);
  });
}
