import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_video_model.dart';
import 'package:flutter_pecha/features/plans/presentation/utils/event_replays.dart';
import 'package:flutter_test/flutter_test.dart';

PlanVideoModel _video(
  String id, {
  String videoId = '',
  String url = '',
  String? title,
  int order = 0,
}) => PlanVideoModel(
  id: id,
  url: url.isNotEmpty ? url : 'https://youtu.be/$videoId',
  videoId: videoId,
  title: title,
  displayOrder: order,
);

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final bo = lookupAppLocalizations(const Locale('bo'));

  group('EventReplays.of', () {
    test('orders by display order and numbers sessions from 1', () {
      final replays = EventReplays.of([
        _video('b', videoId: 'bbbbbbbbbbb', order: 2),
        _video('a', videoId: 'aaaaaaaaaaa', order: 1),
        _video('c', videoId: 'ccccccccccc', order: 3),
      ], dayNumber: 4);

      expect(replays.map((r) => r.videoId), [
        'aaaaaaaaaaa',
        'bbbbbbbbbbb',
        'ccccccccccc',
      ]);
      expect(replays.map((r) => r.session), [1, 2, 3]);
      expect(replays.every((r) => r.dayNumber == 4), isTrue);
    });

    test('ties on display order fall back to the id', () {
      final replays = EventReplays.of([
        _video('z', videoId: 'zzzzzzzzzzz'),
        _video('m', videoId: 'mmmmmmmmmmm'),
      ], dayNumber: 1);

      expect(replays.map((r) => r.video.id), ['m', 'z']);
    });

    test('parses the id from the url when the API left it empty', () {
      final replays = EventReplays.of([
        _video('a', url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=1'),
      ], dayNumber: 1);

      expect(replays.single.videoId, 'dQw4w9WgXcQ');
      expect(
        replays.single.thumbnailUrl,
        'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      );
    });

    test('drops videos with no playable id', () {
      final replays = EventReplays.of([
        _video('bad', url: 'https://example.com/not-youtube'),
        _video('ok', videoId: 'aaaaaaaaaaa', order: 1),
      ], dayNumber: 1);

      expect(replays.map((r) => r.video.id), ['ok']);
      expect(replays.single.session, 1);
    });

    test('leaves out the stream that is live right now', () {
      final replays = EventReplays.of(
        [
          _video('live', videoId: 'lllllllllll', order: 1),
          _video('a', videoId: 'aaaaaaaaaaa', order: 2),
        ],
        dayNumber: 1,
        excludeVideoId: 'lllllllllll',
      );

      // The remaining recording is Session 1, not Session 2.
      expect(replays.map((r) => r.videoId), ['aaaaaaaaaaa']);
      expect(replays.single.session, 1);
    });

    test('an empty day has no replays', () {
      expect(EventReplays.of(const [], dayNumber: 1), isEmpty);
    });
  });

  group('labels', () {
    final replay = EventReplays.of([
      _video('a', videoId: 'aaaaaaaaaaa', order: 1),
      _video('b', videoId: 'bbbbbbbbbbb', order: 2),
    ], dayNumber: 12).last;

    test('row label counts the day and the session', () {
      expect(EventReplays.label(en, 'en', replay), 'Day 12 · Session 2');
    });

    test('a CMS title replaces the generated row label', () {
      final titled = EventReplays.of([
        _video('a', videoId: 'aaaaaaaaaaa', title: ' Morning puja '),
      ], dayNumber: 3).single;

      expect(EventReplays.label(en, 'en', titled), 'Morning puja');
    });

    test('a blank title falls back to the generated label', () {
      final blank = EventReplays.of([
        _video('a', videoId: 'aaaaaaaaaaa', title: '   '),
      ], dayNumber: 3).single;

      expect(EventReplays.label(en, 'en', blank), 'Day 3 · Session 1');
    });

    test('Tibetan renders Tibetan digits', () {
      expect(EventReplays.label(bo, 'bo', replay), contains('༡༢'));
      expect(EventReplays.label(bo, 'bo', replay), contains('༢'));
      expect(EventReplays.label(bo, 'bo', replay), isNot(contains('12')));
    });
  });

  test('replays with the same video, day and session are equal', () {
    final a = EventReplays.of([
      _video('a', videoId: 'aaaaaaaaaaa'),
    ], dayNumber: 1).single;
    final b = EventReplays.of([
      _video('a', videoId: 'aaaaaaaaaaa'),
    ], dayNumber: 1).single;
    final other = EventReplays.of([
      _video('a', videoId: 'aaaaaaaaaaa'),
    ], dayNumber: 2).single;

    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(equals(other)));
  });
}
