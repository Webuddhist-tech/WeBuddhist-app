import 'dart:convert';
import 'dart:io';

import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_remote_datasource.dart';
import 'package:flutter_pecha/features/mala/data/models/accumulator_model.dart';
import 'package:flutter_pecha/features/mala/data/repositories/mala_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Remote that is either offline or returns a fixed catalogue.
class _FakeRemote implements MalaRemoteDataSource {
  _FakeRemote({this.presets});

  final List<PresetAccumulatorModel>? presets;

  @override
  Future<List<PresetAccumulatorModel>> fetchPresets({
    String? language,
    String? search,
  }) async {
    final result = presets;
    if (result == null) throw const NetworkException('offline');
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _preset(String id, {Map<String, dynamic>? deityImage}) => {
  'id': id,
  'target_count': 108,
  'metadata': [
    {'language': 'EN', 'name': 'Preset $id'},
  ],
  'mantra': {
    'id': 'mantra-$id',
    'mantra': 'om',
    'pronunciation': 'Om',
    if (deityImage != null) 'deity_image': deityImage,
  },
};

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('mala_catalogue_cache');
    Hive.init(tempDir.path);
    await MalaLocalDataSource.init();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(MalaLocalDataSource.boxName);
    await Hive.deleteBoxFromDisk(MalaLocalDataSource.groupBoxName);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  Box<String> box() => Hive.box<String>(MalaLocalDataSource.boxName);

  test(
    'offline with only a pre-v2 cache serves it instead of failing',
    () async {
      await box().put('catalogue:en', jsonEncode([_preset('old')]));
      final repo = MalaRepositoryImpl(
        remote: _FakeRemote(),
        local: MalaLocalDataSource(),
      );

      final result = await repo.getCatalogue(language: 'en');

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => []).single.presetId, 'old');
    },
  );

  test('offline with no cache at all still fails', () async {
    final repo = MalaRepositoryImpl(
      remote: _FakeRemote(),
      local: MalaLocalDataSource(),
    );

    final result = await repo.getCatalogue(language: 'en');

    expect(result.isLeft(), isTrue);
  });

  test('an online load writes v2 and deletes the pre-v2 cache', () async {
    await box().put('catalogue:en', jsonEncode([_preset('old')]));
    final fresh = PresetAccumulatorModel.fromJson(
      _preset('new', deityImage: {'medium': 'https://example.com/m.webp'}),
    );
    final repo = MalaRepositoryImpl(
      remote: _FakeRemote(presets: [fresh]),
      local: MalaLocalDataSource(),
    );

    // The pre-v2 cache is not served while online, so this hits the remote.
    final result = await repo.getCatalogue(language: 'en');

    final mantras = result.getOrElse((_) => []);
    expect(mantras.single.presetId, 'new');
    expect(mantras.single.deityImage?.medium, 'https://example.com/m.webp');
    expect(box().get('catalogue:en'), isNull);
    expect(box().get('catalogue:v2:en'), isNotNull);
  });
}
