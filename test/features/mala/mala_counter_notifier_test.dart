import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/usecases/mala_usecases.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_counter_notifier.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'mala_counter_notifier_test.mocks.dart';

@GenerateMocks([GetAccumulatorDetailUseCase, MalaSyncManager, DeleteUserAccumulatorUseCase])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  provideDummy<Either<Failure, MalaCount>>(
    const Left(UnknownFailure('dummy')),
  );

  late Directory tempDir;
  late MalaLocalDataSource local;
  late MockGetAccumulatorDetailUseCase getDetail;
  late MockMalaSyncManager sync;
  late MockDeleteUserAccumulatorUseCase delete;

  const userId = 'user-1';
  const mantra = Mantra(
    presetId: 'chenrezig',
    metadata: [AccumulatorMetadata(language: 'en', name: 'Chenrezig')],
    mantra: MantraText(id: 'm1', text: 'ༀ་མ་ཎི་པདྨེ་ཧཱུྃ', pronunciation: 'Om Mani Padme Hum'),
  );

  MalaCounterNotifier buildNotifier({Duration? seedNetworkTimeout}) =>
      MalaCounterNotifier(
        mantra: mantra,
        local: local,
        getAccumulatorDetail: getDetail,
        deleteUserAccumulator: delete,
        sync: sync,
        currentUserId: () async => userId,
        seedNetworkTimeout: seedNetworkTimeout,
      );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('mala_counter_test');
    Hive.init(tempDir.path);
    await MalaLocalDataSource.init();
    local = MalaLocalDataSource();
    getDetail = MockGetAccumulatorDetailUseCase();
    sync = MockMalaSyncManager();
    delete = MockDeleteUserAccumulatorUseCase();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(MalaLocalDataSource.boxName);
    await Hive.deleteBoxFromDisk(MalaLocalDataSource.groupBoxName);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('seed adopts the server total when the server is ahead', () async {
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 4212)),
    );

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    expect(notifier.state.isSeeding, isFalse);
    expect(notifier.state.total, 4212);
    final s = local.read(userId, 'chenrezig');
    expect(s.syncedTotal, 4212);
    expect(s.accumulatorId, 'acc-1');
    notifier.dispose();
  });

  test('seed keeps isSeeding true until detail API completes', () async {
    await local.write(
      userId,
      'chenrezig',
      const LocalMalaState(total: 88, syncedTotal: 88, accumulatorId: 'acc-1'),
    );
    final gate = Completer<Either<Failure, MalaCount>>();
    when(getDetail(any)).thenAnswer((_) => gate.future);

    // Long timeout so the test observes API-first settle, not the race fallback.
    final notifier = buildNotifier(
      seedNetworkTimeout: const Duration(seconds: 30),
    );
    await Future.delayed(Duration.zero);

    expect(notifier.state.isSeeding, isTrue);
    expect(notifier.state.total, 88);

    gate.complete(const Right(MalaCount(accumulatorId: 'acc-1', total: 12)));
    await Future.delayed(Duration.zero);

    expect(notifier.state.isSeeding, isFalse);
    expect(notifier.state.total, 88); // max(local, server)
    notifier.dispose();
  });

  test('seed falls back to local after network timeout then late-reconciles',
      () async {
    await local.write(
      userId,
      'chenrezig',
      const LocalMalaState(total: 88, syncedTotal: 88, accumulatorId: 'acc-1'),
    );
    final gate = Completer<Either<Failure, MalaCount>>();
    when(getDetail(any)).thenAnswer((_) => gate.future);

    final notifier = buildNotifier(
      seedNetworkTimeout: const Duration(milliseconds: 40),
    );
    await Future.delayed(Duration.zero);
    expect(notifier.state.isSeeding, isTrue);

    await Future.delayed(const Duration(milliseconds: 60));
    expect(notifier.state.isSeeding, isFalse);
    expect(notifier.state.total, 88);

    // Late API is ahead of the timed-out local snapshot.
    gate.complete(const Right(MalaCount(accumulatorId: 'acc-1', total: 120)));
    await Future.delayed(Duration.zero);

    expect(notifier.state.isSeeding, isFalse);
    expect(notifier.state.total, 120);
    notifier.dispose();
  });

  test('late seed detail after reset does not resurrect cleared count', () async {
    await local.write(
      userId,
      'chenrezig',
      const LocalMalaState(total: 88, syncedTotal: 88, accumulatorId: 'acc-1'),
    );
    final detailGate = Completer<Either<Failure, MalaCount>>();
    final resetContinue = Completer<void>();
    when(getDetail(any)).thenAnswer((_) => detailGate.future);
    when(
      sync.resetAccumulator(
        any,
        deleteAccumulator: anyNamed('deleteAccumulator'),
      ),
    ).thenAnswer((_) async {
      // clearSession happens before resetAccumulator returns (real sync path).
      await local.clearSession(userId, 'chenrezig');
      // Late pre-reset GET lands in this window — must not rewrite Hive.
      detailGate.complete(
        const Right(MalaCount(accumulatorId: 'acc-1', total: 88)),
      );
      await Future.delayed(Duration.zero);
      await resetContinue.future;
    });

    final notifier = buildNotifier(
      seedNetworkTimeout: const Duration(milliseconds: 40),
    );
    await Future.delayed(Duration.zero);
    await Future.delayed(const Duration(milliseconds: 60));
    expect(notifier.state.isSeeding, isFalse);
    expect(notifier.state.total, 88);

    final resetFuture = notifier.resetCount();
    await Future.delayed(Duration.zero);
    expect(local.read(userId, 'chenrezig').total, 0);
    expect(local.read(userId, 'chenrezig').accumulatorId, isNull);

    resetContinue.complete();
    final ok = await resetFuture;
    expect(ok, isTrue);
    expect(notifier.state.total, 0);
    expect(local.read(userId, 'chenrezig').total, 0);
    expect(local.read(userId, 'chenrezig').accumulatorId, isNull);
    notifier.dispose();
  });

  test('seed falls back to local total when detail API fails', () async {
    await local.write(
      userId,
      'chenrezig',
      const LocalMalaState(total: 88, syncedTotal: 80, accumulatorId: 'acc-1'),
    );
    when(getDetail(any)).thenAnswer(
      (_) async => const Left(UnknownFailure('network')),
    );

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    expect(notifier.state.isSeeding, isFalse);
    expect(notifier.state.total, 88);
    verify(sync.flush(SyncReason.launch)).called(1);
    notifier.dispose();
  });

  test('seed preserves local offline taps and pushes them', () async {
    // Local is ahead of the server (offline taps captured earlier).
    await local.write(
      userId,
      'chenrezig',
      const LocalMalaState(total: 20, syncedTotal: 10, accumulatorId: 'acc-1'),
    );
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 10)),
    );

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    expect(notifier.state.total, 20); // local preserved
    verify(sync.flush(SyncReason.launch)).called(1); // tail pushed
    notifier.dispose();
  });

  test('incrementBead is a no-op while seeding', () {
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 0)),
    );

    final notifier = buildNotifier(); // seed still pending (async)
    expect(notifier.state.isSeeding, isTrue);

    notifier.incrementBead(soundEnabled: true, vibrationEnabled: true);

    expect(notifier.state.total, 0);
    notifier.dispose();
  });

  test('incrementBead increments monotonically and notifies sync', () async {
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 0)),
    );

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    notifier.incrementBead(soundEnabled: true, vibrationEnabled: true);
    notifier.incrementBead(soundEnabled: true, vibrationEnabled: true);
    notifier.incrementBead(soundEnabled: true, vibrationEnabled: true);

    expect(notifier.state.total, 3);
    expect(notifier.state.beadInRound, 3);
    expect(notifier.state.rounds, 0);
    expect(local.read(userId, 'chenrezig').total, 3);
    verify(sync.onTap(roundComplete: false)).called(3);
    notifier.dispose();
  });

  test('round completes at a multiple of beadsPerRound', () async {
    when(getDetail(any)).thenAnswer(
      (_) async =>
          const Right(MalaCount(accumulatorId: 'acc-1', total: kBeadsPerRound - 1)),
    );

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    expect(notifier.state.total, kBeadsPerRound - 1);
    notifier.incrementBead(soundEnabled: true, vibrationEnabled: true); // lands on 108

    expect(notifier.state.total, kBeadsPerRound);
    expect(notifier.state.beadInRound, 0);
    expect(notifier.state.rounds, 1);
    verify(sync.onTap(roundComplete: true)).called(1);
    notifier.dispose();
  });

  test('addCount adds recitations made outside the app', () async {
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 10)),
    );

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    expect(notifier.addCount(5), isTrue);
    expect(notifier.addCount(0), isFalse);
    await Future.delayed(Duration.zero);

    expect(notifier.state.total, 15);
    expect(local.read(userId, 'chenrezig').total, 15);
    verify(sync.onTap(roundComplete: true)).called(1);
    notifier.dispose();
  });

  test('addRounds adds whole rounds of beads', () async {
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 3)),
    );

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    expect(notifier.addRounds(2), isTrue);
    expect(notifier.addRounds(0), isFalse);

    expect(notifier.state.total, 3 + 2 * kBeadsPerRound);
    expect(notifier.state.rounds, 2);
    notifier.dispose();
  });

  test('seed ignores stale current_count when there is no active accumulator',
      () async {
    // Cleared session after reset — local is zero with no accumulator id.
    await local.write(userId, 'chenrezig', const LocalMalaState());
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(total: 10)),
    );

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    expect(notifier.state.total, 0);
    expect(local.read(userId, 'chenrezig').syncedTotal, 0);
    verifyNever(sync.flush(any));
    notifier.dispose();
  });

  test('resetCount clears display total on success', () async {
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 10)),
    );
    when(
      sync.resetAccumulator(
        any,
        deleteAccumulator: anyNamed('deleteAccumulator'),
      ),
    ).thenAnswer((_) async {});

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);
    expect(notifier.state.total, 10);

    final ok = await notifier.resetCount();

    expect(ok, isTrue);
    expect(notifier.state.total, 0);
    verify(
      sync.resetAccumulator(
        'chenrezig',
        deleteAccumulator: delete,
      ),
    ).called(1);
    notifier.dispose();
  });

  test('resetCount returns false when sync throws', () async {
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 10)),
    );
    when(
      sync.resetAccumulator(
        any,
        deleteAccumulator: anyNamed('deleteAccumulator'),
      ),
    ).thenThrow(Exception('network'));

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    final ok = await notifier.resetCount();

    expect(ok, isFalse);
    expect(notifier.state.total, 10);
    notifier.dispose();
  });

  test('resetCount returns false while seeding', () async {
    when(getDetail(any)).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return const Right(MalaCount(total: 0));
    });

    final notifier = buildNotifier();
    expect(notifier.state.isSeeding, isTrue);

    final ok = await notifier.resetCount();

    expect(ok, isFalse);
    verifyNever(
      sync.resetAccumulator(
        any,
        deleteAccumulator: anyNamed('deleteAccumulator'),
      ),
    );
    notifier.dispose();
  });

  test('resetCount returns false if disposed mid-reset', () async {
    final gate = Completer<void>();
    when(getDetail(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 5)),
    );
    when(
      sync.resetAccumulator(
        any,
        deleteAccumulator: anyNamed('deleteAccumulator'),
      ),
    ).thenAnswer((_) => gate.future);

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    final future = notifier.resetCount();
    notifier.dispose();
    gate.complete();

    expect(await future, isFalse);
  });

  test('fresh install with no accumulator seeds at 0', () async {
    // No user accumulator yet → detail returns count 0 with a null id.
    when(getDetail(any)).thenAnswer((_) async => const Right(MalaCount(total: 0)));

    final notifier = buildNotifier();
    await Future.delayed(Duration.zero);

    expect(notifier.state.total, 0);
    expect(notifier.state.isSeeding, isFalse);
    expect(local.read(userId, 'chenrezig').accumulatorId, isNull);
    // Nothing to push when local and server agree at 0.
    verifyNever(sync.flush(any));
    notifier.dispose();
  });

  test('stores bead bytes after retrying expired presigned URL', () async {
    const staleUrl =
        'https://cdn.example/mala/bead.webp?X-Amz-Expires=1&sig=old';
    const freshUrl =
        'https://cdn.example/mala/bead.webp?X-Amz-Expires=3600&sig=new';
    const imageBytes = [0x89, 0x50, 0x4E, 0x47];

    when(getDetail(any)).thenAnswer(
      (_) async => const Right(
        MalaCount(accumulatorId: 'acc-1', total: 0, beadImageUrl: freshUrl),
      ),
    );

    await local.write(
      userId,
      'chenrezig',
      const LocalMalaState(beadImageUrl: staleUrl),
    );

    final mantraWithImage = Mantra(
      presetId: mantra.presetId,
      beadImageUrl: staleUrl,
      metadata: mantra.metadata,
      mantra: mantra.mantra,
    );

    var downloadUrls = <String>[];
    final notifier = MalaCounterNotifier(
      mantra: mantraWithImage,
      local: local,
      getAccumulatorDetail: getDetail,
      deleteUserAccumulator: delete,
      sync: sync,
      currentUserId: () async => userId,
      downloadImageBytes: (url) async {
        downloadUrls.add(url);
        if (url.contains('sig=old')) {
          throw Exception('403');
        }
        return imageBytes;
      },
    );

    await Future.delayed(const Duration(milliseconds: 50));

    expect(downloadUrls, contains(freshUrl));
    expect(notifier.state.beadImageBytes, Uint8List.fromList(imageBytes));
    expect(local.read(userId, 'chenrezig').beadImageUrl, freshUrl);
    notifier.dispose();
  });

  test('retries stale presigned URL when detail has no bead image', () async {
    const staleUrl =
        'https://cdn.example/mala/bead.webp?X-Amz-Expires=1&sig=old';
    const freshUrl =
        'https://cdn.example/mala/bead.webp?X-Amz-Expires=3600&sig=new';
    const imageBytes = [0x89, 0x50, 0x4E, 0x47];

    var detailCalls = 0;
    when(getDetail(any)).thenAnswer((_) async {
      detailCalls++;
      if (detailCalls == 1) {
        return const Right(MalaCount(accumulatorId: 'acc-1', total: 0));
      }
      return const Right(
        MalaCount(accumulatorId: 'acc-1', total: 0, beadImageUrl: freshUrl),
      );
    });

    await local.write(
      userId,
      'chenrezig',
      const LocalMalaState(beadImageUrl: staleUrl),
    );

    var staleAttempts = 0;
    final notifier = MalaCounterNotifier(
      mantra: mantra,
      local: local,
      getAccumulatorDetail: getDetail,
      deleteUserAccumulator: delete,
      sync: sync,
      currentUserId: () async => userId,
      downloadImageBytes: (url) async {
        if (url.contains('sig=old')) {
          staleAttempts++;
          throw Exception('403');
        }
        return imageBytes;
      },
    );

    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 10));
      return notifier.state.beadImageBytes == null;
    }).timeout(const Duration(seconds: 1));

    expect(staleAttempts, greaterThan(0));
    expect(notifier.state.beadImageBytes, Uint8List.fromList(imageBytes));
    expect(local.read(userId, 'chenrezig').beadImageUrl, freshUrl);
    notifier.dispose();
  });
}
