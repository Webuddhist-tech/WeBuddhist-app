import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_post_in_app_content.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _accumulator = GroupAccumulator(
  id: 'acc1',
  presetAccumulatorId: 'preset',
  groupId: 'g-acc',
  title: 'Mani',
);

const _collection = GroupRecitationCollection(
  id: 'col1',
  groupId: 'g-col',
  name: 'Daily chants',
);

void main() {
  group('GroupPostInAppContent', () {
    test('event links to the event deep link', () {
      final content = GroupPostInAppContent.event(
        const GroupEvent(id: 'ev1', groupId: 'g1', title: 'Puja'),
      );

      expect(content.id, 'event:ev1');
      expect(content.title, 'Puja');
      expect(content.link.toString(), 'https://webuddhist.com/open/events/ev1');
    });

    test('series practice links to the series', () {
      final content = GroupPostInAppContent.practice(
        const GroupPractice(
          type: GroupPracticeType.series,
          series: GroupProfileSeries(id: 's1', title: 'Ngondro'),
        ),
      );

      expect(content?.title, 'Ngondro');
      expect(content?.link.toString(), 'https://webuddhist.com/open/series/s1');
    });

    test('accumulator practice prefers the practice group id', () {
      final content = GroupPostInAppContent.practice(
        const GroupPractice(
          type: GroupPracticeType.accumulator,
          groupId: 'g-practice',
          accumulator: _accumulator,
        ),
      );

      expect(
        content?.link.toString(),
        'https://webuddhist.com/open/group-accumulator/acc1?group=g-practice',
      );
    });

    test('accumulator practice falls back to the accumulator group id', () {
      final content = GroupPostInAppContent.practice(
        const GroupPractice(
          type: GroupPracticeType.accumulator,
          accumulator: _accumulator,
        ),
      );

      expect(
        content?.link.toString(),
        'https://webuddhist.com/open/group-accumulator/acc1?group=g-acc',
      );
    });

    test('collection practice ignores a blank practice group id', () {
      final content = GroupPostInAppContent.practice(
        const GroupPractice(
          type: GroupPracticeType.collection,
          groupId: '  ',
          collection: _collection,
        ),
      );

      expect(content?.title, 'Daily chants');
      expect(
        content?.link.toString(),
        'https://webuddhist.com/open/group/g-col/recitation-collections/col1',
      );
    });

    test('plan practice links to the plan', () {
      final content = GroupPostInAppContent.practice(
        const GroupPractice(
          type: GroupPracticeType.plan,
          plan: GroupPracticePlan(
            id: 'p1',
            title: 'Lojong',
            description: '',
            language: 'en',
          ),
        ),
      );

      expect(content?.link.toString(), 'https://webuddhist.com/open/plan/p1');
    });

    test('practice without its typed body is skipped', () {
      expect(
        GroupPostInAppContent.practice(
          const GroupPractice(type: GroupPracticeType.series),
        ),
        isNull,
      );
    });

    test('chant links to the reader', () {
      final content = GroupPostInAppContent.chant(
        RecitationModel(textId: 't1', title: 'Tara'),
      );

      expect(content.id, 'chant:t1');
      expect(content.link.toString(), 'https://webuddhist.com/open/reader/t1');
    });
  });
}
