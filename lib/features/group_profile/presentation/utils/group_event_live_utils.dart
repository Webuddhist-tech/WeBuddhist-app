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

  /// YouTube id of the event's stream, or null when it has none.
  static String? videoIdOf(GroupEvent event) {
    final link = event.liveYoutubeLink;
    if (link == null) return null;
    return YoutubePlayer.convertUrlToId(link.url.trim());
  }
}
