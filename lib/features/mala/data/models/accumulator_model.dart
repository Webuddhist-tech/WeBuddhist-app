import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

/// `AccumulatorMetadataDTO` — `{language, name, description}`.
class AccumulatorMetadataModel {
  const AccumulatorMetadataModel({
    required this.language,
    required this.name,
    this.description,
  });

  final String language;
  final String name;
  final String? description;

  factory AccumulatorMetadataModel.fromJson(Map<String, dynamic> json) {
    return AccumulatorMetadataModel(
      language: (json['language'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'language': language,
    'name': name,
    'description': description,
  };

  AccumulatorMetadata toEntity() => AccumulatorMetadata(
    language: language,
    name: name,
    description: description,
  );
}

List<AccumulatorMetadataModel> _parseMetadata(Object? raw) {
  final list = (raw as List<dynamic>?) ?? const [];
  return list
      .map((e) => AccumulatorMetadataModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// `PresetMantraDTO` — mantra content embedded in a preset.
class PresetMantraModel {
  const PresetMantraModel({
    required this.id,
    required this.mantra,
    this.title,
    this.pronunciation,
    this.audioUrl,
    this.beadImageUrl,
    this.deityImage,
  });

  final String id;
  final String mantra;
  final String? title;
  final String? pronunciation;
  final String? audioUrl;
  final String? beadImageUrl;

  /// Optional `deity_image` (`{thumbnail, medium, original}`).
  final ResponsiveImage? deityImage;

  factory PresetMantraModel.fromJson(Map<String, dynamic> json) {
    final deityJson = json['deity_image'];
    return PresetMantraModel(
      id: (json['id'] as String?) ?? '',
      mantra: (json['mantra'] as String?) ?? '',
      title: json['title'] as String?,
      pronunciation: json['pronunciation'] as String?,
      audioUrl: json['audio_url'] as String?,
      beadImageUrl: json['mala_image_url'] as String?,
      deityImage:
          deityJson is Map<String, dynamic>
              ? ResponsiveImage.fromJson(deityJson)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mantra': mantra,
    'title': title,
    'pronunciation': pronunciation,
    'audio_url': audioUrl,
    'mala_image_url': beadImageUrl,
    'deity_image': deityImage?.toJson(),
  };

  MantraText toEntity() => MantraText(
    id: id,
    text: mantra,
    title: title,
    pronunciation: pronunciation,
    audioUrl: audioUrl,
    beadImageUrl: beadImageUrl,
    deityImage: deityImage,
  );
}

/// `PublicAccumulatorDTO` (`GET /accumulators/presets`).
class PresetAccumulatorModel {
  const PresetAccumulatorModel({
    required this.id,
    this.targetCount,
    this.beadImageUrl,
    this.metadata = const [],
    this.mantra,
  });

  final String id;
  final int? targetCount;
  final String? beadImageUrl;
  final List<AccumulatorMetadataModel> metadata;
  final PresetMantraModel? mantra;

  factory PresetAccumulatorModel.fromJson(Map<String, dynamic> json) {
    final mantraJson = json['mantra'];
    return PresetAccumulatorModel(
      id: (json['id'] as String?) ?? '',
      targetCount: (json['target_count'] as num?)?.toInt(),
      beadImageUrl: json['mala_image_url'] as String?,
      metadata: _parseMetadata(json['metadata']),
      mantra:
          mantraJson is Map<String, dynamic>
              ? PresetMantraModel.fromJson(mantraJson)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'target_count': targetCount,
    'mala_image_url': beadImageUrl,
    'metadata': metadata.map((m) => m.toJson()).toList(),
    'mantra': mantra?.toJson(),
  };

  Mantra toEntity() => Mantra(
    presetId: id,
    targetCount: targetCount,
    // Prefer the mantra-level bead image — it mirrors the per-user detail's
    // `mala_image_url`, so the preview shown before the seed matches what
    // the accumulator detail returns (no second fetch / no bead flicker).
    // Fall back to the accumulator-level image if the mantra has none.
    beadImageUrl: mantra?.beadImageUrl ?? beadImageUrl,
    metadata: metadata.map((m) => m.toEntity()).toList(),
    mantra: mantra?.toEntity(),
  );
}

/// Wrapper for `PublicAccumulatorsResponse`.
class PresetAccumulatorsResponseModel {
  const PresetAccumulatorsResponseModel({
    required this.accumulators,
    required this.total,
  });

  final List<PresetAccumulatorModel> accumulators;
  final int total;

  factory PresetAccumulatorsResponseModel.fromJson(Map<String, dynamic> json) {
    final list = (json['accumulators'] as List<dynamic>?) ?? const [];
    return PresetAccumulatorsResponseModel(
      accumulators:
          list
              .map(
                (e) =>
                    PresetAccumulatorModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      total: (json['total'] as num?)?.toInt() ?? list.length,
    );
  }
}

/// `AccumulatorDTO` — the user's own accumulator (`POST`/`PUT` responses).
class AccumulatorModel {
  const AccumulatorModel({
    required this.id,
    this.parentId,
    this.mantraId,
    this.currentCount = 0,
    this.beadImageUrl,
    this.updatedAt,
  });

  final String id;
  final String? parentId;
  final String? mantraId;
  final int currentCount;
  final String? beadImageUrl;
  final DateTime? updatedAt;

  factory AccumulatorModel.fromJson(Map<String, dynamic> json) {
    return AccumulatorModel(
      id: (json['id'] as String?) ?? '',
      parentId: json['parent_id'] as String?,
      mantraId: json['mantra_id'] as String?,
      currentCount: (json['current_count'] as num?)?.toInt() ?? 0,
      beadImageUrl: json['mala_image_url'] as String?,
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  MalaCount toMalaCount() => MalaCount(
    accumulatorId: id,
    mantraId: mantraId,
    total: currentCount,
    updatedAt: updatedAt,
  );
}

/// `AccumulatorHistoryDTO` — the user's detail for one preset
/// (`GET /accumulators/{parent_id}`). [accumulatorId] is null when the user has
/// no accumulator for this preset yet.
class AccumulatorDetailModel {
  const AccumulatorDetailModel({
    this.accumulatorId,
    this.parentId,
    this.currentCount = 0,
    this.totalCounted = 0,
    this.beadImageUrl,
  });

  final String? accumulatorId;
  final String? parentId;
  final int currentCount;
  final int totalCounted;
  final String? beadImageUrl;

  factory AccumulatorDetailModel.fromJson(Map<String, dynamic> json) {
    return AccumulatorDetailModel(
      accumulatorId: json['accumulator_id'] as String?,
      parentId: json['parent_id'] as String?,
      currentCount: (json['current_count'] as num?)?.toInt() ?? 0,
      totalCounted: (json['total_counted'] as num?)?.toInt() ?? 0,
      beadImageUrl: json['mala_image_url'] as String?,
    );
  }

  MalaCount toMalaCount() => MalaCount(
    accumulatorId: accumulatorId,
    total: currentCount,
    totalCounted: totalCounted,
    beadImageUrl: beadImageUrl,
  );
}

DateTime? _parseDate(Object? v) {
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}
