import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_video_model.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// One recording of an event day: a plan-day video with its session number.
///
/// The backend copies an event's YouTube links onto the linked plan's day
/// (issue #869), so a day's `videos` are the sessions streamed that day.
class EventReplay {
  final PlanVideoModel video;
  final int dayNumber;

  /// 1-based position among the day's recordings, in display order.
  final int session;
  final String videoId;

  const EventReplay({
    required this.video,
    required this.dayNumber,
    required this.session,
    required this.videoId,
  });

  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  @override
  bool operator ==(Object other) =>
      other is EventReplay &&
      other.videoId == videoId &&
      other.dayNumber == dayNumber &&
      other.session == session;

  @override
  int get hashCode => Object.hash(videoId, dayNumber, session);
}

abstract final class EventReplays {
  /// YouTube id of a day video: the stored id, else parsed from its URL.
  static String? videoIdOf(PlanVideoModel video) {
    final stored = video.videoId.trim();
    if (stored.isNotEmpty) return stored;
    return YoutubePlayer.convertUrlToId(video.url.trim());
  }

  /// The day's recordings in display order, numbered from 1. Videos with
  /// no playable id are dropped, as are [excludeVideoIds] (the streams that
  /// are live right now: the sync puts today's on today's day too, and it
  /// would otherwise list itself as a replay).
  static List<EventReplay> of(
    List<PlanVideoModel> videos, {
    required int dayNumber,
    Iterable<String> excludeVideoIds = const [],
  }) {
    final sorted = List<PlanVideoModel>.from(videos)..sort((a, b) {
      final byOrder = a.displayOrder.compareTo(b.displayOrder);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
    final replays = <EventReplay>[];
    for (final video in sorted) {
      final id = videoIdOf(video);
      if (id == null || excludeVideoIds.contains(id)) continue;
      replays.add(
        EventReplay(
          video: video,
          dayNumber: dayNumber,
          session: replays.length + 1,
          videoId: id,
        ),
      );
    }
    return replays;
  }

  /// Row label: the CMS title when there is one, else "Day 1 · Session 2".
  static String label(
    AppLocalizations l10n,
    String languageCode,
    EventReplay replay,
  ) {
    final title = replay.video.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    return l10n.event_replay_session(
      _number(languageCode, replay.dayNumber),
      _number(languageCode, replay.session),
    );
  }

  static String _number(String languageCode, int value) =>
      AppFontConfig.isTibetanLanguage(languageCode)
          ? toTibetanDigits(value)
          : '$value';
}
