import 'package:flutter_pecha/features/group_profile/data/models/group_event_in_person_count_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupEventInPersonCountListModel', () {
    test('reads the page, totals and the linked accumulation', () {
      final list =
          GroupEventInPersonCountListModel.fromJson({
            'items': [
              {
                'id': 'c1',
                'day': '2026-10-16',
                'count': 1000,
                'created_at': '2026-10-16T10:00:00Z',
                'updated_at': null,
              },
            ],
            'total': 3,
            'skip': 0,
            'limit': 1,
            'total_count': 1000,
            'group_accumulator_id': 'ga1',
            'event_accumulation_id': 'ea1',
            'group_accumulator_title': 'Good deeds',
            'group_accumulator_total_count': 1010,
            'group_accumulator_target_count': 10000,
            'group_accumulator_image': {'thumbnail': 'https://x/t.webp'},
            'timezone': 'Asia/Kolkata',
          }).toEntity();

      expect(list.items.single.id, 'c1');
      expect(list.items.single.date, DateTime(2026, 10, 16));
      expect(list.hasMore, isTrue);
      expect(list.totalCount, 1000);
      expect(list.appCount, 10);
      expect(list.groupAccumulatorTitle, 'Good deeds');
      expect(list.groupAccumulatorImage?.thumbnail, 'https://x/t.webp');
      expect(list.timezone, 'Asia/Kolkata');
    });

    test('an unlinked event has no accumulation and no app count', () {
      final list =
          GroupEventInPersonCountListModel.fromJson({
            'items': [],
            'total': 0,
            'skip': 0,
            'limit': 20,
            'total_count': 0,
            'group_accumulator_id': null,
            'timezone': 'UTC',
          }).toEntity();

      expect(list.groupAccumulatorId, isNull);
      expect(list.hasMore, isFalse);
      expect(list.appCount, 0);
    });
  });

  group('GroupEventAccumulation count mode', () {
    GroupEventAccumulation parse(Map<String, dynamic> json) =>
        GroupEventAccumulationModel.fromJson({
          'id': 'ea1',
          'group_accumulator_id': 'ga1',
          ...json,
        }).toEntity();

    test('manual in-person rows are counted by the admin', () {
      final row = parse({
        'event_format': 'offline',
        'count_mode': 'manual_in_person',
      });
      expect(row.countMode, 'manual_in_person');
      expect(row.isAdminCounted, isTrue);
    });

    test('attendee-logged rows are not, whatever their format', () {
      expect(
        parse({
          'event_format': 'offline',
          'count_mode': 'offline_participants',
        }).isAdminCounted,
        isFalse,
      );
      expect(
        parse({
          'event_format': 'online',
          'count_mode': 'offline_participants',
        }).isAdminCounted,
        isFalse,
      );
    });

    test('rows without a mode fall back to the in-person format', () {
      expect(parse({'event_format': 'offline'}).isAdminCounted, isTrue);
      expect(parse({'event_format': 'online'}).isAdminCounted, isFalse);
      expect(parse({}).isAdminCounted, isFalse);
    });
  });
}
