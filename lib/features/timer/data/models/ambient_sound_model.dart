import 'package:flutter_pecha/features/timer/domain/entities/ambient_sound.dart';

class AmbientSoundModel {
  const AmbientSoundModel({
    required this.id,
    required this.name,
    required this.url,
    this.imageUrl,
    this.isDefault = false,
    this.displayOrder = 0,
  });

  final String id;
  final String name;
  final String url;
  final String? imageUrl;
  final bool isDefault;
  final int displayOrder;

  factory AmbientSoundModel.fromJson(Map<String, dynamic> json) {
    return AmbientSoundModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
      imageUrl: json['image_url'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  AmbientSound toEntity() {
    return AmbientSound(
      id: id,
      name: name,
      url: url,
      imageUrl: imageUrl,
      isDefault: isDefault,
      displayOrder: displayOrder,
    );
  }
}

class AmbientSoundsResponseModel {
  const AmbientSoundsResponseModel({required this.sounds});

  final List<AmbientSoundModel> sounds;

  factory AmbientSoundsResponseModel.fromJson(Map<String, dynamic> json) {
    final soundsJson = (json['sounds'] as List<dynamic>?) ?? [];
    return AmbientSoundsResponseModel(
      sounds:
          soundsJson
              .map(
                (s) => AmbientSoundModel.fromJson(s as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}
