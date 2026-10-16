import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

/// Standard beads in one mala round. Not exposed by the API, so it is fixed
/// here. (`target_count` on the accumulator is a separate lifetime goal.)
const int kBeadsPerRound = 108;

/// One localized rendering of an accumulator's display text
/// (`AccumulatorMetadataDTO` — `{language, name, description}`).
class AccumulatorMetadata extends Equatable {
  final String language;
  final String name;
  final String? description;

  const AccumulatorMetadata({
    required this.language,
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [language, name, description];
}

/// The mantra content embedded in a preset (`PresetMantraDTO`). The server
/// localizes [text]/[title]/[pronunciation] by the `language` query param.
class MantraText extends Equatable {
  final String id;

  /// The mantra script itself (e.g. the stacked Tibetan glyphs).
  final String text;

  final String? title;

  /// Transliteration line (e.g. "Om Mani Padme Hum").
  final String? pronunciation;

  final String? audioUrl;
  final String? beadImageUrl;

  /// Optional deity artwork shown above the mantra text.
  final ResponsiveImage? deityImage;

  const MantraText({
    required this.id,
    required this.text,
    this.title,
    this.pronunciation,
    this.audioUrl,
    this.beadImageUrl,
    this.deityImage,
  });

  @override
  List<Object?> get props =>
      [id, text, title, pronunciation, audioUrl, beadImageUrl, deityImage];
}

/// A mantra the user can accumulate — a **preset accumulator**
/// (`GET /accumulators/presets`).
///
/// [presetId] is the preset's id, used as the local namespacing key and as the
/// `parent_id` when lazily creating the user's own accumulator. The user-owned
/// accumulator id (needed for PUT) is tracked separately in the local store.
///
/// The localized display name/description come from [metadata]; the large
/// mantra script and transliteration come from the embedded [mantra]
/// (`PresetMantraDTO`), already localized by the catalogue's `language` query.
class Mantra extends Equatable {
  final String presetId;
  final int? targetCount;

  /// Bead artwork URL (`mala_image_url`). Null-safe — UI falls back to the
  /// bundled bead asset.
  final String? beadImageUrl;

  final List<AccumulatorMetadata> metadata;

  /// Embedded mantra content (script, transliteration, audio).
  final MantraText? mantra;

  const Mantra({
    required this.presetId,
    this.targetCount,
    this.beadImageUrl,
    this.metadata = const [],
    this.mantra,
  });

  String? get mantraId => mantra?.id;

  int get beadsPerRound => kBeadsPerRound;

  /// Localized display name (falls back to English, then anything, then id).
  String localizedName(String language) =>
      (_byLanguage(language) ?? _byLanguage('en') ??
              (metadata.isNotEmpty ? metadata.first : null))
          ?.name ??
      mantra?.title ??
      presetId;

  /// Title for the header. Prefers the embedded mantra [title]
  /// (`PresetMantraModel.title`), which the backend already localizes via the
  /// catalogue's `language` query — unlike [localizedName], which matches the
  /// metadata list client-side. Falls back to [localizedName] when absent.
  String displayTitle(String language) {
    final title = mantra?.title;
    if (title != null && title.isNotEmpty) return title;
    return localizedName(language);
  }

  String? description(String language) =>
      (_byLanguage(language) ?? _byLanguage('en'))?.description;

  /// The large mantra script (e.g. stacked Tibetan glyphs).
  String? get tibetan => mantra?.text;

  /// Deity artwork, or null when the preset has none (or only empty URLs).
  ResponsiveImage? get deityImage {
    final image = mantra?.deityImage;
    if (image == null || image.isEmpty) return null;
    return image;
  }

  /// Transliteration line. Already localized server-side via the catalogue's
  /// `language` query, so [language] is accepted for API symmetry but unused.
  String? transliteration(String language) => mantra?.pronunciation;

  AccumulatorMetadata? _byLanguage(String language) {
    for (final m in metadata) {
      if (m.language.toLowerCase() == language.toLowerCase()) return m;
    }
    return null;
  }

  @override
  List<Object?> get props =>
      [presetId, targetCount, beadImageUrl, metadata, mantra];
}
