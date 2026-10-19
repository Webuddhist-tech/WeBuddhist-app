import 'package:flutter_pecha/features/mala/data/models/accumulator_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> preset({Object? deityImage}) => {
    'id': 'preset-1',
    'target_count': 108,
    'mala_image_url': 'https://example.com/beads.webp',
    'metadata': [
      {'language': 'EN', 'name': 'Green Tara — Protection'},
    ],
    'mantra': {
      'id': 'mantra-1',
      'mantra': 'ॐ तारे तुत्तारे तुरे स्वाहा',
      'title': 'Green Tara',
      'pronunciation': 'Om Tare Tuttare Ture Soha',
      'mala_image_url': 'https://example.com/green.webp',
      'deity_image': deityImage,
    },
  };

  test('parses the optional deity image tiers', () {
    final mantra =
        PresetAccumulatorModel.fromJson(
          preset(
            deityImage: {
              'thumbnail': 'https://example.com/t.webp',
              'medium': 'https://example.com/m.webp',
              'original': 'https://example.com/o.webp',
            },
          ),
        ).toEntity();

    expect(mantra.deityImage?.thumbnail, 'https://example.com/t.webp');
    expect(mantra.deityImage?.medium, 'https://example.com/m.webp');
    expect(mantra.deityImage?.original, 'https://example.com/o.webp');
    expect(mantra.beadImageUrl, 'https://example.com/green.webp');
  });

  test('deity image is null when absent or empty', () {
    expect(
      PresetAccumulatorModel.fromJson(preset()).toEntity().deityImage,
      isNull,
    );
    expect(
      PresetAccumulatorModel.fromJson(
        preset(deityImage: <String, dynamic>{}),
      ).toEntity().deityImage,
      isNull,
    );
  });

  test('deity image round-trips through toJson for the local cache', () {
    final model = PresetAccumulatorModel.fromJson(
      preset(deityImage: {'medium': 'https://example.com/m.webp'}),
    );
    final restored = PresetAccumulatorModel.fromJson(model.toJson()).toEntity();
    expect(restored.deityImage?.medium, 'https://example.com/m.webp');
  });
}
