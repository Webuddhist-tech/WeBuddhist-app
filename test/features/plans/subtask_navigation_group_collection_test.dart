import 'package:flutter_pecha/features/plans/data/models/plan_subtasks_model.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_tasks_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_test/flutter_test.dart';

UserSubtasksDto _collection({
  String id = 'c1',
  int order = 1,
  String collectionId = 'collection-1',
  bool isCompleted = false,
}) => UserSubtasksDto(
  id: id,
  isCompleted: isCompleted,
  contentType: PlanContentTypes.groupCollection,
  content: '',
  displayOrder: order,
  referenceId: collectionId,
);

UserTasksDto _task(
  List<UserSubtasksDto> subtasks, {
  String id = 'task-1',
  int order = 0,
}) => UserTasksDto(
  id: id,
  title: 'Chants',
  estimatedTime: null,
  displayOrder: order,
  isCompleted: false,
  subTasks: subtasks,
);

const _collections = {
  'collection-1': ['refuge', 'aspiration', 'dedication'],
};

void main() {
  group('a GROUP_COLLECTION task', () {
    test('reads every chant of the collection in order on one item', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([_collection()]),
      ], collections: _collections);

      final item = items.single;
      expect(item.isSourceReference, isTrue);
      expect(item.sources.map((s) => s.textId), [
        'refuge',
        'aspiration',
        'dedication',
      ]);
      expect(item.textId, 'refuge');
      // Whole texts: no verse range.
      expect(item.sources.every((s) => s.segmentIds == null), isTrue);
    });

    test('every chant completes the one collection subtask', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([_collection()]),
      ], collections: _collections);

      expect(items.single.subtaskIds, ['c1']);
      expect(items.single.isCompleted, isFalse);
    });

    test('a completed collection subtask makes the item complete', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([_collection(isCompleted: true)]),
      ], collections: _collections);

      expect(items.single.isCompleted, isTrue);
      expect(items.single.completedSubtaskIds, {'c1'});
    });

    test('joins a SOURCE_REFERENCE of the same task in display order', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([
          _collection(order: 2),
          UserSubtasksDto(
            id: 's1',
            isCompleted: false,
            contentType: PlanContentTypes.sourceReference,
            content: '',
            displayOrder: 1,
            sourceTextId: 'opening',
          ),
        ]),
      ], collections: _collections);

      expect(items.single.sources.map((s) => s.textId), [
        'opening',
        'refuge',
        'aspiration',
        'dedication',
      ]);
      expect(items.single.subtaskIds, ['s1', 'c1']);
    });

    test('unresolved, it yields no item but is still navigable', () {
      final task = _task([_collection()]);

      expect(PlanSubtaskNavigation.fromUserTasks([task]), isEmpty);
      expect(PlanSubtaskNavigation.isUserTaskNavigable(task), isTrue);
    });

    test('keeps its place among the day\'s other tasks', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([
          UserSubtasksDto(
            id: 't1',
            isCompleted: false,
            contentType: PlanContentTypes.text,
            content: 'note',
            displayOrder: 1,
          ),
        ], id: 'task-text', order: 0),
        _task([_collection()], id: 'task-collection', order: 1),
      ], collections: _collections);

      expect(items.map((i) => i.taskId), ['task-text', 'task-collection']);
    });

    test('a read-only page carries no subtask ids', () {
      final items = PlanSubtaskNavigation.fromUserTasks(
        [
          _task([_collection(isCompleted: true)]),
        ],
        withCompletion: false,
        collections: _collections,
      );

      expect(items.single.subtaskIds, isEmpty);
      expect(items.single.isCompleted, isFalse);
    });

    test('the collection id comes from reference or reference_id', () {
      final fromReference = UserSubtasksDto.fromJson({
        'id': 'c1',
        'is_completed': false,
        'content_type': 'GROUP_COLLECTION',
        'reference': {
          'id': 'collection-1',
          'content_type': 'GROUP_COLLECTION',
          'title': 'monlam texts',
          'group_id': 'group-1',
        },
      });
      final fromReferenceId = UserSubtasksDto.fromJson({
        'id': 'c1',
        'is_completed': false,
        'content_type': 'GROUP_COLLECTION',
        'reference_id': 'collection-1',
      });

      expect(fromReference.groupCollectionId, 'collection-1');
      expect(fromReferenceId.groupCollectionId, 'collection-1');
      expect(fromReference.groupAccumulationId, isNull);
    });

    test('lists the collection ids of the day once each', () {
      final tasks = [
        _task([_collection(id: 'c1')], id: 'a'),
        _task([_collection(id: 'c2')], id: 'b'),
      ];

      expect(PlanSubtaskNavigation.groupCollectionIdsForUserTasks(tasks), {
        'collection-1',
      });
    });
  });

  group('the preview flow', () {
    test('builds the same sources without subtask ids', () {
      final task = PlanTasksModel(
        id: 'task-1',
        title: 'Chants',
        displayOrder: 0,
        subtasks: [
          PlanSubtasksModel(
            id: 'c1',
            contentType: PlanContentTypes.groupCollection,
            displayOrder: 1,
            referenceId: 'collection-1',
          ),
        ],
      );

      expect(PlanSubtaskNavigation.isPlanTaskNavigable(task), isTrue);
      expect(PlanSubtaskNavigation.groupCollectionIdsForPlanTasks([task]), {
        'collection-1',
      });
      final item =
          PlanSubtaskNavigation.fromPlanTasks([
            task,
          ], collections: _collections).single;
      expect(item.sources.map((s) => s.textId), [
        'refuge',
        'aspiration',
        'dedication',
      ]);
      expect(item.subtaskIds, isEmpty);
    });
  });
}
