import 'dart:async';
import 'dart:io';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/repositories/mala_repository.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulation_chant_counter.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/group_accumulation_counts_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_accumulation_selection_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mala_fakes.dart';

const _userId = 'user-1';
const _presetId = 'tara-praises';
const _eventAccumulation = 'ga-event';
const _mantra = Mantra(presetId: _presetId);

class _FakeRepository extends Fake implements MalaRepository {
  /// When set, the personal detail request stays open until completed.
  Completer<Either<Failure, MalaCount>>? detailGate;

  @override
  Future<Either<Failure, MalaCount>> getAccumulatorDetail(String parentId) =>
      detailGate?.future ?? Future.value(const Right(MalaCount(total: 0)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MalaLocalDataSource local;
  late _FakeRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('chant_counter_test');
    Hive.init(tempDir.path);
    await MalaLocalDataSource.init();
    local = MalaLocalDataSource();
    repository = _FakeRepository();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(MalaLocalDataSource.boxName);
    await Hive.deleteBoxFromDisk(MalaLocalDataSource.groupBoxName);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// A container with the reader's chant providers held open, as the reader
  /// holds them, and the stored selection loaded.
  Future<ProviderContainer> openSession() async {
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(FakeUserStorage(_userId)),
        malaLocalDataSourceProvider.overrideWithValue(local),
        malaRepositoryProvider.overrideWithValue(repository),
        malaRemoteDataSourceProvider.overrideWithValue(FakeMalaRemote()),
        malaSyncManagerProvider.overrideWithValue(FakeMalaSync()),
        malaSoundPlayerProvider.overrideWithValue(SilentMalaSoundPlayer()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(malaAccumulationSelectionProvider(_presetId), (_, __) {});
    container.listen(groupAccumulationCountsProvider(_presetId), (_, __) {});
    container.listen(malaCounterProvider(_mantra), (_, __) {});
    await container
        .read(malaAccumulationSelectionProvider(_presetId).notifier)
        .loaded;
    await settle();
    return container;
  }

  int personalTotal(ProviderContainer container) =>
      container.read(malaCounterProvider(_mantra)).total;

  int eventTotal(ProviderContainer container) {
    final counts = container.read(groupAccumulationCountsProvider(_presetId));
    return counts[_eventAccumulation] ?? 0;
  }

  MalaAccumulationSelectionNotifier selection(ProviderContainer container) =>
      container.read(malaAccumulationSelectionProvider(_presetId).notifier);

  test('a chant goes to the selected accumulation, not to personal', () async {
    final container = await openSession();
    await selection(container).selectGroup(_eventAccumulation);

    final counted = countChantIntoSelection(container.read, _mantra);
    await settle();

    expect(counted, isTrue);
    expect(eventTotal(container), 1);
    expect(personalTotal(container), 0);
    expect(local.readGroup(_userId, _eventAccumulation).total, 1);
    expect(local.read(_userId, _presetId).total, 0);
  });

  test('a chant goes to personal practice once that is selected', () async {
    final container = await openSession();
    await selection(container).selectPersonal();

    final counted = countChantIntoSelection(container.read, _mantra);
    await settle();

    expect(counted, isTrue);
    expect(personalTotal(container), 1);
    expect(eventTotal(container), 0);
    expect(local.read(_userId, _presetId).total, 1);
    expect(local.readGroup(_userId, _eventAccumulation).total, 0);
  });

  test('switching target leaves earlier chants where they were made', () async {
    final container = await openSession();

    await selection(container).selectGroup(_eventAccumulation);
    countChantIntoSelection(container.read, _mantra);
    countChantIntoSelection(container.read, _mantra);

    await selection(container).selectPersonal();
    countChantIntoSelection(container.read, _mantra);

    await selection(container).selectGroup(_eventAccumulation);
    countChantIntoSelection(container.read, _mantra);
    await settle();

    expect(eventTotal(container), 3);
    expect(personalTotal(container), 1);
  });

  test('a chant is not counted while personal practice is seeding', () async {
    repository.detailGate = Completer();
    final container = await openSession();
    await selection(container).selectPersonal();
    expect(container.read(malaCounterProvider(_mantra)).isSeeding, isTrue);

    final counted = countChantIntoSelection(container.read, _mantra);

    expect(counted, isFalse);
    expect(personalTotal(container), 0);
    expect(eventTotal(container), 0);

    repository.detailGate!.complete(const Right(MalaCount(total: 0)));
    await settle();

    expect(countChantIntoSelection(container.read, _mantra), isTrue);
    expect(personalTotal(container), 1);
  });

  test('offline chants are added to the selected accumulation', () async {
    final container = await openSession();
    await selection(container).selectGroup(_eventAccumulation);

    final added = addOfflineChantsToSelection(container.read, _mantra, 7);
    await settle();

    expect(added, isTrue);
    expect(eventTotal(container), 7);
    expect(personalTotal(container), 0);
  });

  test('offline chants are added to personal practice when selected', () async {
    final container = await openSession();
    await selection(container).selectPersonal();

    final added = addOfflineChantsToSelection(container.read, _mantra, 5);
    await settle();

    expect(added, isTrue);
    expect(personalTotal(container), 5);
    expect(eventTotal(container), 0);
  });

  test('offline chants are refused while personal practice is seeding', () async {
    repository.detailGate = Completer();
    final container = await openSession();
    await selection(container).selectPersonal();

    final added = addOfflineChantsToSelection(container.read, _mantra, 5);

    expect(added, isFalse);
    expect(personalTotal(container), 0);

    repository.detailGate!.complete(const Right(MalaCount(total: 0)));
    await settle();
  });
}
