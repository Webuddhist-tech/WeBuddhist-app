import 'package:flutter_pecha/features/plans/data/models/plan_subtasks_model.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/plans/data/models/task_settings.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_test/flutter_test.dart';

UserSubtasksDto _source({
  required String id,
  required int order,
  required String textId,
  List<String>? segmentIds,
  bool isCompleted = false,
  String? audioUrl,
  int? startMs,
  int? endMs,
}) => UserSubtasksDto(
  id: id,
  isCompleted: isCompleted,
  contentType: PlanContentTypes.sourceReference,
  content: '',
  displayOrder: order,
  sourceTextId: textId,
  segmentIds: segmentIds,
  audioUrl: audioUrl,
  startMs: startMs,
  endMs: endMs,
);

UserTasksDto _task(
  List<UserSubtasksDto> subtasks, {
  TaskSettings? settings,
}) => UserTasksDto(
  id: 'task-1',
  title: 'Refuge and aspiration',
  estimatedTime: null,
  displayOrder: 0,
  isCompleted: false,
  subTasks: subtasks,
  settings: settings,
);

void main() {
  group('a task with several SOURCE_REFERENCE subtasks', () {
    test('is one item whose sources are every source subtask in order', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([
          _source(id: 's2', order: 2, textId: 'aspiration', segmentIds: ['a1']),
          _source(id: 's1', order: 1, textId: 'refuge', segmentIds: ['r1', 'r2']),
          UserSubtasksDto(
            id: 's3',
            isCompleted: false,
            contentType: PlanContentTypes.text,
            content: 'note',
            displayOrder: 3,
          ),
        ]),
      ]);

      expect(items, hasLength(1));
      final item = items.single;
      expect(item.isSourceReference, isTrue);
      expect(item.sources.map((s) => s.textId), ['refuge', 'aspiration']);
      expect(item.sources.map((s) => s.subtaskId), ['s1', 's2']);
      // The first source is what the route opens.
      expect(item.textId, 'refuge');
      expect(item.segmentIds, ['r1', 'r2']);
      expect(item.subtaskId, 's1');
      expect(item.subtaskIds, ['s1', 's2']);
      // Inline subtasks of a source task are not shown.
      expect(item.blocks, isEmpty);
    });

    test('a source without a text id is left out', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([
          _source(id: 's1', order: 1, textId: 'refuge'),
          UserSubtasksDto(
            id: 's2',
            isCompleted: false,
            contentType: PlanContentTypes.sourceReference,
            content: '',
            displayOrder: 2,
          ),
        ]),
      ]);

      expect(items.single.sources.map((s) => s.textId), ['refuge']);
    });

    test('is complete only once every source is', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([
          _source(id: 's1', order: 1, textId: 'refuge', isCompleted: true),
          _source(id: 's2', order: 2, textId: 'aspiration'),
        ]),
      ]);

      final item = items.single;
      expect(item.isCompleted, isFalse);
      expect(item.completedSubtaskIds, {'s1'});
    });

    test('the first source with its own audio feeds the one audio control', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([
          _source(id: 's1', order: 1, textId: 'refuge', startMs: 0, endMs: 5),
          _source(
            id: 's2',
            order: 2,
            textId: 'aspiration',
            audioUrl: 'https://cdn/aspiration.mp3',
            startMs: 10,
          ),
        ]),
      ]);

      final item = items.single;
      expect(item.audioUrl, 'https://cdn/aspiration.mp3');
      expect(item.startMs, 10);
      expect(item.endMs, isNull);
    });

    test('without any own audio the first source gives the day-audio window', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([
          _source(id: 's1', order: 1, textId: 'refuge', startMs: 0, endMs: 5),
          _source(id: 's2', order: 2, textId: 'aspiration', startMs: 5, endMs: 9),
        ]),
      ]);

      final item = items.single;
      expect(item.audioUrl, isNull);
      expect(item.startMs, 0);
      expect(item.endMs, 5);
    });

    test('task settings apply to the whole item', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task(
          [
            _source(id: 's1', order: 1, textId: 'refuge'),
            _source(id: 's2', order: 2, textId: 'aspiration'),
          ],
          settings: const TaskSettings(
            isCommentaryOpen: true,
            commentaryTextId: 'commentary',
            isLive: true,
          ),
        ),
      ]);

      final item = items.single;
      expect(item.autoOpenCommentary, isTrue);
      expect(item.commentaryTextId, 'commentary');
      expect(item.isLive, isTrue);
    });

    test('a read-only page carries no subtask ids for any source', () {
      final items = PlanSubtaskNavigation.fromUserTasks(
        [
          _task([
            _source(id: 's1', order: 1, textId: 'refuge', isCompleted: true),
            _source(id: 's2', order: 2, textId: 'aspiration', isCompleted: true),
          ]),
        ],
        withCompletion: false,
      );

      final item = items.single;
      expect(item.subtaskIds, isEmpty);
      expect(item.isCompleted, isFalse);
      expect(item.sources.map((s) => s.textId), ['refuge', 'aspiration']);
    });

    test('the preview flow builds the same sources without subtask ids', () {
      final items = PlanSubtaskNavigation.fromPlanTasks([
        PlanTasksModel(
          id: 'task-1',
          title: 'Refuge and aspiration',
          displayOrder: 0,
          subtasks: const [
            PlanSubtasksModel(
              id: 's1',
              contentType: PlanContentTypes.sourceReference,
              sourceTextId: 'refuge',
              segmentIds: ['r1'],
              displayOrder: 1,
            ),
            PlanSubtasksModel(
              id: 's2',
              contentType: PlanContentTypes.sourceReference,
              sourceTextId: 'aspiration',
              segmentIds: ['a1'],
              displayOrder: 2,
            ),
          ],
        ),
      ]);

      final item = items.single;
      expect(item.sources.map((s) => s.textId), ['refuge', 'aspiration']);
      expect(item.sources.map((s) => s.segmentIds), [
        ['r1'],
        ['a1'],
      ]);
      expect(item.subtaskIds, isEmpty);
    });
  });

  group('PlanTextItem.hasSourceText', () {
    test('names any source of the item, and nothing of an inline item', () {
      final item = PlanTextItem.sources(
        sources: const [
          PlanSourceRef(textId: 'refuge'),
          PlanSourceRef(textId: 'aspiration'),
        ],
        title: 'Both',
      );
      expect(item.hasSourceText('aspiration'), isTrue);
      expect(item.hasSourceText('other'), isFalse);

      final inline = PlanTextItem.inlineText(content: 'note', title: 'Note');
      expect(inline.sources, isEmpty);
      expect(inline.hasSourceText('refuge'), isFalse);
    });

    test('a single-source item keeps its fields as its one source', () {
      final item = PlanTextItem.sourceReference(
        textId: 'refuge',
        title: 'Refuge',
        segmentIds: const ['r1'],
        subtaskId: 's1',
        isCompleted: true,
      );
      expect(item.sources, [
        const PlanSourceRef(
          textId: 'refuge',
          segmentIds: ['r1'],
          subtaskId: 's1',
          isCompleted: true,
        ),
      ]);
      expect(item.completedSubtaskIds, {'s1'});
    });
  });
}
