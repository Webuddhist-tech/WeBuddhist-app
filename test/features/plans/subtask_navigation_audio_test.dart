import 'package:flutter_pecha/features/plans/data/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_tasks_dto.dart';
import 'package:flutter_pecha/features/plans/domain/subtask_navigation.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_test/flutter_test.dart';

UserSubtasksDto _sub({
  required String id,
  required int order,
  String contentType = PlanContentTypes.text,
  String content = 'body',
  String? audioUrl,
  int? startMs,
  int? endMs,
  String? sourceTextId,
}) => UserSubtasksDto(
  id: id,
  isCompleted: false,
  contentType: contentType,
  content: content,
  displayOrder: order,
  audioUrl: audioUrl,
  startMs: startMs,
  endMs: endMs,
  sourceTextId: sourceTextId,
);

UserTasksDto _task(List<UserSubtasksDto> subtasks) => UserTasksDto(
  id: 'task-1',
  title: 'Task',
  estimatedTime: null,
  displayOrder: 0,
  isCompleted: false,
  subTasks: subtasks,
);

void main() {
  group('inline audio selection', () {
    test('a blank audioUrl does not become the item audio source', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([
          _sub(id: 's1', order: 0, startMs: 100, endMs: 900),
          _sub(id: 's2', order: 1, audioUrl: ''),
        ]),
      ]);

      expect(items, hasLength(1));
      expect(items.single.audioUrl, isNull);
      expect(items.single.startMs, 100);
      expect(items.single.endMs, 900);
    });

    test('a whitespace-only audioUrl is treated as absent', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([
          _sub(id: 's1', order: 0),
          _sub(id: 's2', order: 1, audioUrl: '   '),
        ]),
      ]);

      expect(items.single.audioUrl, isNull);
    });

    test('a real audioUrl still wins over an earlier blank one', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([
          _sub(id: 's1', order: 0, audioUrl: ''),
          _sub(id: 's2', order: 1, audioUrl: 'https://cdn/a.mp3', startMs: 5),
        ]),
      ]);

      expect(items.single.audioUrl, 'https://cdn/a.mp3');
      expect(items.single.startMs, 5);
    });

    test('a source reference drops its blank audioUrl', () {
      final items = PlanSubtaskNavigation.fromUserTasks([
        _task([
          _sub(
            id: 's1',
            order: 0,
            contentType: PlanContentTypes.sourceReference,
            sourceTextId: 'text-1',
            audioUrl: '',
          ),
        ]),
      ]);

      expect(items.single.audioUrl, isNull);
    });
  });

  group('effectiveAudioUrlFor', () {
    const dayAudio = 'https://cdn/day.mp3';

    NavigationContext contextWith(PlanTextItem item) => NavigationContext(
      source: NavigationSource.plan,
      planTextItems: [item],
      currentTextIndex: 0,
      dayAudioUrl: dayAudio,
    );

    test('falls back to the day track when the item URL is blank', () {
      final item = PlanTextItem.inlineText(
        content: 'body',
        title: 'Task',
        audioUrl: '',
      );

      expect(contextWith(item).effectiveAudioUrlFor(item), dayAudio);
      expect(contextWith(item).hasAudioFor(item), isTrue);
    });

    test('reports no audio when both the item and day URLs are blank', () {
      final item = PlanTextItem.inlineText(
        content: 'body',
        title: 'Task',
        audioUrl: '',
      );
      const context = NavigationContext(
        source: NavigationSource.plan,
        dayAudioUrl: '  ',
      );

      expect(context.effectiveAudioUrlFor(item), isNull);
      expect(context.hasAudioFor(item), isFalse);
    });

    test('a real item URL still wins over the day track', () {
      final item = PlanTextItem.inlineText(
        content: 'body',
        title: 'Task',
        audioUrl: 'https://cdn/sub.mp3',
      );

      expect(
        contextWith(item).effectiveAudioUrlFor(item),
        'https://cdn/sub.mp3',
      );
    });
  });

  group('hasOwnAudio', () {
    test('is false for a blank audioUrl', () {
      expect(_sub(id: 's1', order: 0, audioUrl: '').hasOwnAudio, isFalse);
      expect(_sub(id: 's2', order: 1, audioUrl: ' ').hasOwnAudio, isFalse);
      expect(_sub(id: 's3', order: 2).hasOwnAudio, isFalse);
    });

    test('is true for a real audioUrl', () {
      expect(
        _sub(id: 's1', order: 0, audioUrl: 'https://cdn/a.mp3').hasOwnAudio,
        isTrue,
      );
    });
  });
}
