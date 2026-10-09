import 'package:flutter_pecha/features/plans/data/models/plan_subtasks_model.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_test/flutter_test.dart';

const _settings = {
  'is_commentary_open': true,
  'commentary_text_id': ' commentary-1 ',
  'is_translation_open': false,
  'translation_text_id': '',
  'is_live': false,
};

void main() {
  test('enrolled plan day task keeps commentary settings', () {
    final task = UserTasksDto.fromJson({
      'id': 'task-1',
      'title': 'Read',
      'estimated_time': null,
      'display_order': 0,
      'is_completed': false,
      'sub_tasks': [
        {
          'id': 'sub-1',
          'is_completed': false,
          'content_type': 'SOURCE_REFERENCE',
          'content': '',
          'source_text_id': 'text-1',
          'display_order': 0,
        },
      ],
      'settings': _settings,
    });

    expect(task.settings?.isCommentaryOpen, isTrue);
    expect(task.settings?.commentaryTextId, 'commentary-1');
    expect(task.settings?.translationTextId, isNull);

    final item = PlanSubtaskNavigation.fromUserTasks([task]).single;
    expect(item.autoOpenCommentary, isTrue);
    expect(item.commentaryTextId, 'commentary-1');
    expect(item.autoOpenTranslation, isFalse);
    expect(item.translationTextId, isNull);
  });

  test('preview plan day task keeps commentary settings', () {
    final task = PlanTasksModel.fromJson({
      'id': 'task-1',
      'title': 'Read',
      'display_order': 0,
      'subtasks': [
        {
          'id': 'sub-1',
          'content_type': 'SOURCE_REFERENCE',
          'source_text_id': 'text-1',
          'display_order': 0,
        },
      ],
      'settings': _settings,
    });

    final item = PlanSubtaskNavigation.fromPlanTasks([task]).single;
    expect(item.autoOpenCommentary, isTrue);
    expect(item.commentaryTextId, 'commentary-1');
    expect(item.autoOpenTranslation, isFalse);
    expect(item.translationTextId, isNull);
  });

  test('a translation id is shown for both plan day endpoints', () {
    const settings = {
      'is_commentary_open': false,
      'commentary_text_id': null,
      'is_translation_open': true,
      'translation_text_id': ' text-en ',
      'is_live': false,
    };

    final enrolled = PlanSubtaskNavigation.fromUserTasks([
      UserTasksDto.fromJson({
        'id': 'task-1',
        'title': 'Read',
        'estimated_time': null,
        'display_order': 0,
        'is_completed': false,
        'sub_tasks': [
          {
            'id': 'sub-1',
            'is_completed': false,
            'content_type': 'SOURCE_REFERENCE',
            'content': '',
            'source_text_id': 'text-1',
            'display_order': 0,
          },
        ],
        'settings': settings,
      }),
    ]).single;
    final preview = PlanSubtaskNavigation.fromPlanTasks([
      PlanTasksModel.fromJson({
        'id': 'task-1',
        'title': 'Read',
        'display_order': 0,
        'subtasks': [
          {
            'id': 'sub-1',
            'content_type': 'SOURCE_REFERENCE',
            'source_text_id': 'text-1',
            'display_order': 0,
          },
        ],
        'settings': settings,
      }),
    ]).single;

    expect(enrolled.autoOpenTranslation, isTrue);
    expect(enrolled.translationTextId, 'text-en');
    expect(enrolled.autoOpenCommentary, isFalse);
    expect(preview.autoOpenTranslation, isTrue);
    expect(preview.translationTextId, 'text-en');
  });

  test('a task without settings leaves the reader unchanged', () {
    final items = PlanSubtaskNavigation.fromUserTasks([
      UserTasksDto(
        id: 'task-1',
        title: 'Read',
        estimatedTime: null,
        displayOrder: 0,
        isCompleted: false,
        subTasks: [
          UserSubtasksDto(
            id: 'sub-1',
            isCompleted: false,
            contentType: PlanContentTypes.sourceReference,
            content: '',
            sourceTextId: 'text-1',
            displayOrder: 0,
          ),
        ],
      ),
    ]);

    expect(items.single.autoOpenCommentary, isFalse);
    expect(items.single.commentaryTextId, isNull);
    expect(items.single.autoOpenTranslation, isFalse);
    expect(items.single.translationTextId, isNull);
  });

  test('preview tasks without settings leave the reader unchanged', () {
    final items = PlanSubtaskNavigation.fromPlanTasks([
      PlanTasksModel(
        id: 'task-1',
        title: 'Read',
        displayOrder: 0,
        subtasks: const [
          PlanSubtasksModel(
            id: 'sub-1',
            contentType: PlanContentTypes.sourceReference,
            sourceTextId: 'text-1',
            displayOrder: 0,
          ),
        ],
      ),
    ]);

    expect(items.single.autoOpenCommentary, isFalse);
    expect(items.single.commentaryTextId, isNull);
    expect(items.single.autoOpenTranslation, isFalse);
    expect(items.single.translationTextId, isNull);
  });
}
