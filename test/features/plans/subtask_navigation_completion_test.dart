import 'package:flutter_pecha/features/plans/data/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_test/flutter_test.dart';

UserSubtasksDto _sub({
  required String id,
  required int order,
  String contentType = PlanContentTypes.text,
  String? sourceTextId,
}) => UserSubtasksDto(
  id: id,
  isCompleted: true,
  contentType: contentType,
  content: 'body',
  displayOrder: order,
  sourceTextId: sourceTextId,
);

UserTasksDto _task(String id, int order, List<UserSubtasksDto> subtasks) =>
    UserTasksDto(
      id: id,
      title: 'Task $id',
      estimatedTime: null,
      displayOrder: order,
      isCompleted: true,
      subTasks: subtasks,
    );

final _tasks = [
  _task('t1', 0, [
    _sub(id: 's1', order: 0),
    _sub(id: 's2', order: 1),
  ]),
  _task('t2', 1, [
    _sub(
      id: 's3',
      order: 0,
      contentType: PlanContentTypes.sourceReference,
      sourceTextId: 'text-1',
    ),
  ]),
];

void main() {
  group('PlanSubtaskNavigation.fromUserTasks completion fields', () {
    test('an enrolled page carries every subtask id and its completion', () {
      final items = PlanSubtaskNavigation.fromUserTasks(_tasks);

      expect(items, hasLength(2));
      expect(items[0].subtaskIds, ['s1', 's2']);
      expect(items[0].blocks.every((b) => b.isCompleted), isTrue);
      expect(items[1].subtaskIds, ['s3']);
      expect(items[1].isCompleted, isTrue);
    });

    test('a read-only page carries none, so nothing gets marked complete', () {
      final items = PlanSubtaskNavigation.fromUserTasks(
        _tasks,
        withCompletion: false,
      );

      // Same items, same order, same content: only the completion data goes.
      expect(items, hasLength(2));
      expect(items.map((i) => i.taskId), ['t1', 't2']);
      expect(items[0].blocks, hasLength(2));
      expect(items[1].textId, 'text-1');
      for (final item in items) {
        expect(item.subtaskIds, isEmpty);
        expect(item.isCompleted, isFalse);
        expect(item.blocks.any((b) => b.isCompleted), isFalse);
      }
    });
  });
}
