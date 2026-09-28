import 'dart:convert';

import 'package:equatable/equatable.dart';

/// What a reader changed in one layout context (event, chant or plan), and
/// nothing else: every field is null until the person touches it, so the
/// initial-layout resolver keeps deciding the rest.
///
/// [scripts] is keyed by source language; a key whose value is null is a
/// deliberate "as written", which is different from no pick at all.
///
/// [translationVersions] holds the translation edition picked for each text
/// (keyed by the edition the reader was opened with), oldest first, capped at
/// [maxTranslationVersions].
class ReaderContextLayoutPrefs extends Equatable {
  const ReaderContextLayoutPrefs({
    this.originalVisible,
    this.translationOn,
    this.translationLanguage,
    this.scripts = const {},
    this.translationVersions = const {},
  });

  static const ReaderContextLayoutPrefs empty = ReaderContextLayoutPrefs();

  /// How many texts keep their picked translation edition; the text whose
  /// pick changed longest ago is forgotten first.
  static const int maxTranslationVersions = 50;

  final bool? originalVisible;
  final bool? translationOn;
  final String? translationLanguage;
  final Map<String, String?> scripts;
  final Map<String, String> translationVersions;

  bool hasScriptFor(String language) => scripts.containsKey(language);

  String? scriptFor(String language) => scripts[language];

  String? translationVersionFor(String textId) => translationVersions[textId];

  /// Records [scriptId] (null = as written) for [language].
  ReaderContextLayoutPrefs withScript(String language, String? scriptId) =>
      copyWith(scripts: {...scripts, language: scriptId});

  /// Records [versionId] as the translation edition picked for [textId],
  /// as the newest entry, dropping the oldest past the cap.
  ReaderContextLayoutPrefs withTranslationVersion(
    String textId,
    String versionId,
  ) {
    final versions = {
      for (final entry in translationVersions.entries)
        if (entry.key != textId) entry.key: entry.value,
      textId: versionId,
    };
    final overflow = versions.length - maxTranslationVersions;
    if (overflow > 0) {
      versions.keys.take(overflow).toList().forEach(versions.remove);
    }
    return copyWith(translationVersions: versions);
  }

  ReaderContextLayoutPrefs copyWith({
    bool? originalVisible,
    bool? translationOn,
    String? translationLanguage,
    Map<String, String?>? scripts,
    Map<String, String>? translationVersions,
  }) {
    return ReaderContextLayoutPrefs(
      originalVisible: originalVisible ?? this.originalVisible,
      translationOn: translationOn ?? this.translationOn,
      translationLanguage: translationLanguage ?? this.translationLanguage,
      scripts: scripts ?? this.scripts,
      translationVersions: translationVersions ?? this.translationVersions,
    );
  }

  Map<String, dynamic> toJson() => {
    'originalVisible': originalVisible,
    'translationOn': translationOn,
    'translationLanguage': translationLanguage,
    'scripts': scripts,
    'translationVersions': translationVersions,
  };

  factory ReaderContextLayoutPrefs.fromJson(Map<String, dynamic> json) {
    final rawScripts = json['scripts'];
    final rawVersions = json['translationVersions'];
    return ReaderContextLayoutPrefs(
      originalVisible: _boolOrNull(json['originalVisible']),
      translationOn: _boolOrNull(json['translationOn']),
      translationLanguage: _stringOrNull(json['translationLanguage']),
      scripts: {
        if (rawScripts is Map)
          for (final entry in rawScripts.entries)
            if (entry.key is String && (entry.value == null || entry.value is String))
              entry.key as String: entry.value as String?,
      },
      translationVersions: {
        if (rawVersions is Map)
          for (final entry in rawVersions.entries)
            if (entry.key is String && entry.value is String)
              entry.key as String: entry.value as String,
      },
    );
  }

  String encode() => jsonEncode(toJson());

  /// Never throws: a corrupt value reads as no picks.
  factory ReaderContextLayoutPrefs.decode(String source) {
    try {
      return ReaderContextLayoutPrefs.fromJson(
        jsonDecode(source) as Map<String, dynamic>,
      );
    } catch (_) {
      return empty;
    }
  }

  @override
  List<Object?> get props => [
    originalVisible,
    translationOn,
    translationLanguage,
    scripts,
    translationVersions,
  ];
}

/// A stored value of the wrong type reads as "no pick" rather than throwing.
bool? _boolOrNull(Object? value) => value is bool ? value : null;

String? _stringOrNull(Object? value) => value is String ? value : null;
