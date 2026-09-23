import 'dart:convert';

class ReaderSlotConfig {
  final String languageCode;
  final String languageLabel;
  final String? versionId;
  final String? versionLabel;
  final String? scriptId;
  final String? scriptLabel;

  /// True when a language is selected but no usable version could be
  /// auto-selected for it (e.g. the same language as the main version with no
  /// alternate version, or a language with zero versions). Distinguishes
  /// "resolved: nothing available" from "not yet resolved" (both have a null
  /// [versionId]) so the UI can show a "Not available" message.
  final bool versionUnavailable;

  const ReaderSlotConfig({
    required this.languageCode,
    required this.languageLabel,
    this.versionId,
    this.versionLabel,
    this.scriptId,
    this.scriptLabel,
    this.versionUnavailable = false,
  });

  /// An unselected slot — no language and no version. Used as the secondary
  /// slot's initial state so it shows placeholders instead of a default.
  const ReaderSlotConfig.empty()
      : languageCode = '',
        languageLabel = '',
        versionId = null,
        versionLabel = null,
        scriptId = null,
        scriptLabel = null,
        versionUnavailable = false;

  /// Whether no language has been picked yet.
  bool get isUnset => languageCode.isEmpty;

  ReaderSlotConfig copyWith({
    String? languageCode,
    String? languageLabel,
    String? versionId,
    String? versionLabel,
    String? scriptId,
    String? scriptLabel,
    bool? versionUnavailable,
  }) {
    return ReaderSlotConfig(
      languageCode: languageCode ?? this.languageCode,
      languageLabel: languageLabel ?? this.languageLabel,
      versionId: versionId ?? this.versionId,
      versionLabel: versionLabel ?? this.versionLabel,
      scriptId: scriptId ?? this.scriptId,
      scriptLabel: scriptLabel ?? this.scriptLabel,
      versionUnavailable: versionUnavailable ?? this.versionUnavailable,
    );
  }

  Map<String, dynamic> toJson() => {
        'languageCode': languageCode,
        'languageLabel': languageLabel,
        'versionId': versionId,
        'versionLabel': versionLabel,
        'scriptId': scriptId,
        'scriptLabel': scriptLabel,
        'versionUnavailable': versionUnavailable,
      };

  factory ReaderSlotConfig.fromJson(Map<String, dynamic> json) {
    return ReaderSlotConfig(
      languageCode: json['languageCode'] as String? ?? 'en',
      languageLabel: json['languageLabel'] as String? ?? 'English',
      versionId: json['versionId'] as String?,
      versionLabel: json['versionLabel'] as String?,
      scriptId: json['scriptId'] as String?,
      scriptLabel: json['scriptLabel'] as String?,
      versionUnavailable: json['versionUnavailable'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderSlotConfig &&
        other.languageCode == languageCode &&
        other.versionId == versionId &&
        other.scriptId == scriptId &&
        other.versionUnavailable == versionUnavailable;
  }

  @override
  int get hashCode =>
      Object.hash(languageCode, versionId, scriptId, versionUnavailable);
}

class ReaderDualLayoutSettings {
  final bool secondaryEnabled;

  /// Whether the original text shows while a translation is on. Only
  /// meaningful together with an active secondary; readers never hide both.
  final bool originalVisible;
  final ReaderSlotConfig primary;
  final ReaderSlotConfig secondary;

  const ReaderDualLayoutSettings({
    required this.secondaryEnabled,
    this.originalVisible = true,
    required this.primary,
    required this.secondary,
  });

  factory ReaderDualLayoutSettings.initial() {
    return const ReaderDualLayoutSettings(
      secondaryEnabled: false,
      primary: ReaderSlotConfig(
        languageCode: 'en',
        languageLabel: 'English',
      ),
      secondary: ReaderSlotConfig.empty(),
    );
  }

  ReaderDualLayoutSettings copyWith({
    bool? secondaryEnabled,
    bool? originalVisible,
    ReaderSlotConfig? primary,
    ReaderSlotConfig? secondary,
  }) {
    return ReaderDualLayoutSettings(
      secondaryEnabled: secondaryEnabled ?? this.secondaryEnabled,
      originalVisible: originalVisible ?? this.originalVisible,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
    );
  }

  Map<String, dynamic> toJson() => {
        'secondaryEnabled': secondaryEnabled,
        'originalVisible': originalVisible,
        'primary': primary.toJson(),
        'secondary': secondary.toJson(),
      };

  factory ReaderDualLayoutSettings.fromJson(Map<String, dynamic> json) {
    return ReaderDualLayoutSettings(
      secondaryEnabled: json['secondaryEnabled'] as bool? ?? false,
      originalVisible: json['originalVisible'] as bool? ?? true,
      primary: ReaderSlotConfig.fromJson(
        (json['primary'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      secondary: ReaderSlotConfig.fromJson(
        (json['secondary'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  String encode() => jsonEncode(toJson());

  factory ReaderDualLayoutSettings.decode(String source) {
    try {
      final map = jsonDecode(source) as Map<String, dynamic>;
      return ReaderDualLayoutSettings.fromJson(map);
    } catch (_) {
      return ReaderDualLayoutSettings.initial();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderDualLayoutSettings &&
        other.secondaryEnabled == secondaryEnabled &&
        other.originalVisible == originalVisible &&
        other.primary == primary &&
        other.secondary == secondary;
  }

  @override
  int get hashCode =>
      Object.hash(secondaryEnabled, originalVisible, primary, secondary);
}
