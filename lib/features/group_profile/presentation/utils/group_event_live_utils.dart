import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

abstract final class GroupEventLiveUtils {
  /// Languages the live stream can be requested in, in toggle order.
  static const List<String> languages = [
    AppConfig.englishLanguageCode,
    AppConfig.tibetanLanguageCode,
    AppConfig.chineseLanguageCode,
  ];

  static const Map<String, String> languageLabels = {
    AppConfig.englishLanguageCode: 'En',
    AppConfig.tibetanLanguageCode: 'བོད',
    AppConfig.chineseLanguageCode: '中文',
  };

  /// The toggle starts on the content language when the stream supports it.
  static String initialLanguage(String contentLanguage) {
    final code = contentLanguage.trim().toLowerCase();
    return languages.contains(code) ? code : AppConfig.englishLanguageCode;
  }

  static final _liveWord = RegExp(r'\blive\b', caseSensitive: false);

  /// Whole-word match, so labels like "Delivered" do not count as live.
  static bool isLiveLabel(String? label) =>
      label != null && _liveWord.hasMatch(label);

  /// How long past its start an event is still treated as on when it has no
  /// end of its own. One occurrence of a recurring event is bounded the same
  /// way.
  static const liveGrace = Duration(hours: 6);

  /// When the event ends, or null to fall back to [liveGrace]. A recurring
  /// event's end date closes the whole series, not the occurrence on screen.
  static DateTime? liveEndOf(GroupEvent event) {
    if (event.isRecurring) return null;
    final start = event.startDate;
    final end = event.endDate;
    if (end == null || (start != null && !end.isAfter(start))) return null;
    return end;
  }

  /// Whether the event is over at [now]. The stream link stays on the event
  /// afterwards, so this, not a missing link, says the stream has ended. A
  /// recurring event never counts as over: its dates span the series.
  static bool hasEnded(GroupEvent event, DateTime now) {
    if (event.isRecurring) return false;
    final start = event.startDate;
    if (start == null) return false;
    return !now.isBefore(liveEndOf(event) ?? start.add(liveGrace));
  }

  /// YouTube id of the event's stream, or null when it has none.
  static String? videoIdOf(GroupEvent event) {
    final link = event.liveYoutubeLink;
    if (link == null) return null;
    return YoutubePlayer.convertUrlToId(link.url.trim());
  }
}
