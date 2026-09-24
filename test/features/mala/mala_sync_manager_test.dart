import 'dart:io';

import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/usecases/mala_usecases.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_pecha/features/mala/presentation/utils/mala_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../core/analytics/recording_analytics_service.dart';
import 'mala_sync_manager_test.mocks.dart';

@GenerateMocks([
  CreateUserAccumulatorUseCase,
  UpdateUserAccumulatorUseCase,
  DeleteUserAccumulatorUseCase,
  SubmitGroupAccumulatorCountUseCase,
  DeleteGroupAccumulatorUseCase,
])
void main() {
  provideDummy<Either<Failure, MalaCount>>(
    const Left(UnknownFailure('dummy')),
  );
  provideDummy<Either<Failure, Unit>>(const Left(UnknownFailure('dummy')));

  late Directory tempDir;
  late MalaLocalDataSource local;
  late MockCreateUserAccumulatorUseCase create;
  late MockUpdateUserAccumulatorUseCase update;
  late MockDeleteUserAccumulatorUseCase delete;
  late MockSubmitGroupAccumulatorCountUseCase submitGroup;
  late MockDeleteGroupAccumulatorUseCase deleteGroup;

  const userA = 'user-a';
  const userB = 'user-b';
  const presetId = 'chenrezig';
  const groupAccId = 'group-acc-1';

  MalaSyncManager buildManager({
    bool loggedIn = true,
    String? userId = userA,
    MalaAnalytics? analytics,
  }) {
    return MalaSyncManager(
      local: local,
      createAccumulator: create,
      updateAccumulator: update,
      submitGroupCount: submitGroup,
      isLoggedIn: () => loggedIn,
      currentUserId: () async => userId,
      analytics: analytics,
    );
  }

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('mala_sync_test');
    Hive.init(tempDir.path);
    await MalaLocalDataSource.init();
    local = MalaLocalDataSource();
    create = MockCreateUserAccumulatorUseCase();
    update = MockUpdateUserAccumulatorUseCase();
    delete = MockDeleteUserAccumulatorUseCase();
    submitGroup = MockSubmitGroupAccumulatorCountUseCase();
    deleteGroup = MockDeleteGroupAccumulatorUseCase();
    when(submitGroup(any)).thenAnswer((_) async => const Right(unit));
    when(deleteGroup(any)).thenAnswer((_) async => const Right(unit));
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(MalaLocalDataSource.boxName);
    await Hive.deleteBoxFromDisk(MalaLocalDataSource.groupBoxName);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('existing accumulator updates with the absolute total (no create)',
      () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 50, syncedTotal: 40, accumulatorId: 'acc-1'),
    );
    when(update(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 50)),
    );

    await buildManager().flush(SyncReason.debounce);

    final captured =
        verify(update(captureAny)).captured.single as UpdateUserAccumulatorParams;
    expect(captured.accumulatorId, 'acc-1');
    expect(captured.currentCount, 50); // absolute total, not a delta
    verifyNever(create(any)); // never creates when an id already exists

    final after = local.read(userA, presetId);
    expect(after.syncedTotal, 50);
    expect(after.isDirty, isFalse);
  });

  test('first sync creates once (parent_id) then updates the absolute total',
      () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 12, syncedTotal: 0), // no accumulatorId yet
    );
    when(create(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'new-acc', total: 0)),
    );
    when(update(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'new-acc', total: 12)),
    );

    await buildManager().flush(SyncReason.launch);

    // Created exactly once, with the preset id as parent_id.
    expect(verify(create(captureAny)).captured.single, presetId);
    // Then pushed the absolute total to the new id.
    final put =
        verify(update(captureAny)).captured.single as UpdateUserAccumulatorParams;
    expect(put.accumulatorId, 'new-acc');
    expect(put.currentCount, 12);

    final after = local.read(userA, presetId);
    expect(after.accumulatorId, 'new-acc'); // id stored for future PUTs
    expect(after.syncedTotal, 12);
  });

  test('does not create again once an id is stored', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 5, syncedTotal: 0, accumulatorId: 'acc-1'),
    );
    when(update(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 5)),
    );

    await buildManager().flush(SyncReason.launch);

    verifyNever(create(any));
    verify(update(any)).called(1);
  });

  test('server ahead is adopted via max() into total and syncedTotal', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 30, syncedTotal: 20, accumulatorId: 'acc-1'),
    );
    // Another device pushed the server to 100.
    when(update(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-1', total: 100)),
    );

    await buildManager().flush(SyncReason.reconnect);

    final after = local.read(userA, presetId);
    expect(after.total, 100); // bumped up to reflect cross-device progress
    expect(after.syncedTotal, 100);
  });

  test('failed flush keeps the entry dirty for retry', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 5, syncedTotal: 0, accumulatorId: 'acc-1'),
    );
    when(update(any)).thenAnswer(
      (_) async => const Left(NetworkFailure('offline')),
    );

    await buildManager().flush(SyncReason.debounce);

    final after = local.read(userA, presetId);
    expect(after.syncedTotal, 0);
    expect(after.isDirty, isTrue);
  });

  test('a failed flush reports mala_sync_failed once with the pending delta',
      () async {
    final recording = RecordingAnalyticsService();
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 15, syncedTotal: 10, accumulatorId: 'acc-1'),
    );
    await local.writeGroup(
      userA,
      groupAccId,
      const LocalGroupMalaState(total: 7, syncedTotal: 0),
    );
    when(update(any)).thenAnswer(
      (_) async => const Left(NetworkFailure('offline')),
    );

    final manager = buildManager(analytics: MalaAnalytics(recording));
    await manager.flush(SyncReason.debounce);
    await manager.flush(SyncReason.tap); // still failing: no second event
    manager.dispose();

    expect(recording.eventNames, [AnalyticsEvents.malaSyncFailed]);
    expect(recording.events.single.properties, {
      'reason': 'debounce',
      'pending_delta': 12,
    });
  });

  test('does nothing when not logged in', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 5, syncedTotal: 0, accumulatorId: 'acc-1'),
    );

    await buildManager(loggedIn: false).flush(SyncReason.launch);

    verifyNever(update(any));
    verifyNever(create(any));
  });

  test('only flushes the current user\'s entries (namespacing)', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 5, syncedTotal: 0, accumulatorId: 'acc-a'),
    );
    await local.write(
      userB,
      presetId,
      const LocalMalaState(total: 9, syncedTotal: 0, accumulatorId: 'acc-b'),
    );
    when(update(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-a', total: 5)),
    );

    await buildManager(userId: userA).flush(SyncReason.launch);

    final captured =
        verify(update(captureAny)).captured.single as UpdateUserAccumulatorParams;
    expect(captured.accumulatorId, 'acc-a'); // never touches user B
    expect(local.read(userB, presetId).isDirty, isTrue);
  });

  test('reset flushes dirty tail then soft-deletes the active accumulator',
      () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 50, syncedTotal: 40, accumulatorId: 'acc-old'),
    );
    when(update(any)).thenAnswer(
      (_) async => const Right(MalaCount(accumulatorId: 'acc-old', total: 50)),
    );
    when(delete(any)).thenAnswer((_) async => const Right(unit));

    await buildManager().resetAccumulator(
      presetId,
      deleteAccumulator: delete,
    );

    final put =
        verify(update(captureAny)).captured.single as UpdateUserAccumulatorParams;
    expect(put.accumulatorId, 'acc-old');
    expect(put.currentCount, 50);
    expect(verify(delete('acc-old')).callCount, 1);
    verifyNever(create(any));

    final after = local.read(userA, presetId);
    expect(after.accumulatorId, isNull);
    expect(after.total, 0);
    expect(after.syncedTotal, 0);
    expect(after.isDirty, isFalse);
  });

  test('reset skips PUT when fully synced then soft-deletes accumulator',
      () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 50, syncedTotal: 50, accumulatorId: 'acc-old'),
    );
    when(delete(any)).thenAnswer((_) async => const Right(unit));

    await buildManager().resetAccumulator(
      presetId,
      deleteAccumulator: delete,
    );

    verifyNever(update(any));
    verify(delete('acc-old')).called(1);
    verifyNever(create(any));

    final after = local.read(userA, presetId);
    expect(after.accumulatorId, isNull);
    expect(after.total, 0);
    expect(after.syncedTotal, 0);
  });

  test('reset with no server accumulator only clears local session', () async {
    await local.write(
      userA,
      presetId,
      const LocalMalaState(total: 0, syncedTotal: 0),
    );

    await buildManager().resetAccumulator(
      presetId,
      deleteAccumulator: delete,
    );

    verifyNever(update(any));
    verifyNever(delete(any));
    verifyNever(create(any));

    final after = local.read(userA, presetId);
    expect(after.accumulatorId, isNull);
    expect(after.total, 0);
  });

  test('flushes dirty group counts via POST absolute total', () async {
    await local.writeGroup(
      userA,
      groupAccId,
      const LocalGroupMalaState(total: 42, syncedTotal: 30),
    );

    await buildManager().flush(SyncReason.debounce);

    final captured = verify(submitGroup(captureAny)).captured.single
        as SubmitGroupAccumulatorCountParams;
    expect(captured.groupAccumulatorId, groupAccId);
    expect(captured.currentCount, 42);

    final after = local.readGroup(userA, groupAccId);
    expect(after.syncedTotal, 42);
    expect(after.isDirty, isFalse);
  });

  test('failed group flush keeps entry dirty for retry', () async {
    await local.writeGroup(
      userA,
      groupAccId,
      const LocalGroupMalaState(total: 10, syncedTotal: 0),
    );
    when(submitGroup(any)).thenAnswer(
      (_) async => const Left(NetworkFailure('offline')),
    );

    await buildManager().flush(SyncReason.launch);

    final after = local.readGroup(userA, groupAccId);
    expect(after.syncedTotal, 0);
    expect(after.isDirty, isTrue);
  });

  test('group flush only touches current user entries', () async {
    await local.writeGroup(
      userA,
      groupAccId,
      const LocalGroupMalaState(total: 5, syncedTotal: 0),
    );
    await local.writeGroup(
      userB,
      'group-acc-b',
      const LocalGroupMalaState(total: 9, syncedTotal: 0),
    );

    await buildManager(userId: userA).flush(SyncReason.launch);

    final captured = verify(submitGroup(captureAny)).captured.single
        as SubmitGroupAccumulatorCountParams;
    expect(captured.groupAccumulatorId, groupAccId);
    expect(local.readGroup(userB, 'group-acc-b').isDirty, isTrue);
  });

  test('group reset flushes dirty tail then soft-deletes group count', () async {
    await local.writeGroup(
      userA,
      groupAccId,
      const LocalGroupMalaState(total: 50, syncedTotal: 40),
    );
    when(submitGroup(any)).thenAnswer((_) async => const Right(unit));
    when(deleteGroup(any)).thenAnswer((_) async => const Right(unit));

    await buildManager().resetGroupAccumulator(
      groupAccId,
      deleteGroupAccumulator: deleteGroup,
    );

    final captured = verify(submitGroup(captureAny)).captured.single
        as SubmitGroupAccumulatorCountParams;
    expect(captured.groupAccumulatorId, groupAccId);
    expect(captured.currentCount, 50);
    verify(deleteGroup(groupAccId)).called(1);

    final after = local.readGroup(userA, groupAccId);
    expect(after.total, 0);
    expect(after.syncedTotal, 0);
    expect(after.isDirty, isFalse);
  });

  test('group reset skips POST when fully synced then soft-deletes', () async {
    await local.writeGroup(
      userA,
      groupAccId,
      const LocalGroupMalaState(total: 50, syncedTotal: 50),
    );
    when(deleteGroup(any)).thenAnswer((_) async => const Right(unit));

    await buildManager().resetGroupAccumulator(
      groupAccId,
      deleteGroupAccumulator: deleteGroup,
    );

    verifyNever(submitGroup(any));
    verify(deleteGroup(groupAccId)).called(1);

    final after = local.readGroup(userA, groupAccId);
    expect(after.total, 0);
    expect(after.syncedTotal, 0);
  });
}
