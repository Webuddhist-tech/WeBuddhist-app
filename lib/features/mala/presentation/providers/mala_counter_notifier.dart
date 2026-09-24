import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/network_image_utils.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_local_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mala_count.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/domain/usecases/mala_usecases.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_pecha/features/mala/presentation/services/mala_sound_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class MalaCounterState {
  const MalaCounterState({
    this.total = 0,
    this.totalCounted = 0,
    this.beadsPerRound = kBeadsPerRound,
    this.isSeeding = true,
    this.seedFailed = false,
    this.isResetting = false,
    this.beadImageUrl,
    this.beadImageBytes,
  });

  final int total;

  /// Lifetime `total_counted` baseline from `GET /accumulators/{parent_id}`.
  final int totalCounted;
  final int beadsPerRound;

  /// Per-user bead artwork from the accumulator detail. Null falls back to the
  /// preset/mantra image (see the screen's `?? mantra.beadImageUrl`).
  final String? beadImageUrl;
  final Uint8List? beadImageBytes;

  /// True until seed settles (detail API, failure, or seed network timeout).
  final bool isSeeding;

  /// User id could not be resolved; counting cannot be persisted safely.
  final bool seedFailed;

  /// True while a reset is in progress. Blocks [incrementBead] so taps cannot
  /// arrive between the server DELETE and the local clearSession wipe.
  final bool isResetting;

  int get beadInRound => total % beadsPerRound;

  /// Completed rounds: 0 at start, 1 only once the 108th bead lands.
  int get rounds => total ~/ beadsPerRound;

  MalaCounterState copyWith({
    int? total,
    int? totalCounted,
    int? beadsPerRound,
    bool? isSeeding,
    bool? seedFailed,
    bool? isResetting,
    String? beadImageUrl,
    Uint8List? beadImageBytes,
  }) => MalaCounterState(
    total: total ?? this.total,
    totalCounted: totalCounted ?? this.totalCounted,
    beadsPerRound: beadsPerRound ?? this.beadsPerRound,
    isSeeding: isSeeding ?? this.isSeeding,
    seedFailed: seedFailed ?? this.seedFailed,
    isResetting: isResetting ?? this.isResetting,
    beadImageUrl: beadImageUrl ?? this.beadImageUrl,
    beadImageBytes: beadImageBytes ?? this.beadImageBytes,
  );
}

/// Per-mantra monotonic counter. Seeds from the server before enabling taps,
/// then only ever increments. Persists every tap to Hive immediately and pings
/// the app-scoped [MalaSyncManager] for background sync.
class MalaCounterNotifier extends StateNotifier<MalaCounterState> {
  MalaCounterNotifier({
    required Mantra mantra,
    required MalaLocalDataSource local,
    required GetAccumulatorDetailUseCase getAccumulatorDetail,
    required DeleteUserAccumulatorUseCase deleteUserAccumulator,
    Future<List<int>> Function(String url)? downloadImageBytes,
    required MalaSyncManager sync,
    required Future<String?> Function() currentUserId,
    MalaSoundPlayer? sound,
    Duration? seedNetworkTimeout,
  }) : _mantra = mantra,
       _local = local,
       _getAccumulatorDetail = getAccumulatorDetail,
       _deleteUserAccumulator = deleteUserAccumulator,
       _downloadImageBytes = downloadImageBytes ?? _emptyImageDownload,
       _sync = sync,
       _currentUserId = currentUserId,
       _sound = sound,
       _seedNetworkTimeout =
           seedNetworkTimeout ?? _defaultSeedNetworkTimeout,
       super(MalaCounterState(beadsPerRound: mantra.beadsPerRound)) {
    seed();
  }

  static const _defaultSeedNetworkTimeout = Duration(seconds: 3);

  final Mantra _mantra;
  final MalaLocalDataSource _local;
  final GetAccumulatorDetailUseCase _getAccumulatorDetail;
  final DeleteUserAccumulatorUseCase _deleteUserAccumulator;
  final Future<List<int>> Function(String url) _downloadImageBytes;
  final MalaSyncManager _sync;
  final Future<String?> Function() _currentUserId;
  final MalaSoundPlayer? _sound;
  final Duration _seedNetworkTimeout;

  final _logger = AppLogger('MalaCounterNotifier');

  /// The user id resolved during seed. Cached so the synchronous [incrementBead]
  /// can persist taps without re-resolving.
  String? _userId;

  /// Bumped when a new seed starts or a reset succeeds so in-flight late detail
  /// applies from a timed-out seed cannot resurrect a cleared session.
  int _detailApplyGeneration = 0;

  String get _presetId => _mantra.presetId;

  /// Lifetime total for [GroupAccumulationsSheet]: API `total_counted` baseline
  /// plus any unsynced session taps.
  int get displayLifetimeCount {
    final userId = _userId;
    if (userId == null) return state.totalCounted;
    final local = _local.read(userId, _presetId);
    final dirty = local.total - local.syncedTotal;
    if (dirty <= 0) return state.totalCounted;
    return state.totalCounted + dirty;
  }

  /// Refreshes [MalaCounterState.totalCounted] after a successful personal sync.
  void handlePersonalCountSynced(String presetId) {
    if (presetId != _presetId || !mounted) return;
    final userId = _userId;
    if (userId == null) return;
    state = state.copyWith(
      totalCounted: _local.read(userId, _presetId).totalCounted,
    );
  }

  static Future<List<int>> _emptyImageDownload(String _) async => const [];

  /// Seed from local Hive, then briefly wait on the detail API before undimming.
  ///
  /// Races the network call against [_seedNetworkTimeout] so offline/slow
  /// connections fall back to local counting quickly. A late detail response
  /// still reconciles in the background without re-blocking taps.
  Future<void> seed() async {
    state = state.copyWith(isSeeding: true, seedFailed: false);

    final userId = await _currentUserId();
    if (!mounted) return; // screen left mid-seed
    if (userId == null || userId.isEmpty) {
      // Not authenticated — the route is login-gated, so treat as transient.
      state = state.copyWith(isSeeding: true, seedFailed: true);
      return;
    }
    _userId = userId;
    final applyGeneration = ++_detailApplyGeneration;

    final localState = _local.read(userId, _presetId);
    final fallbackImageUrl = localState.beadImageUrl ?? _mantra.beadImageUrl;
    // Keep isSeeding true until detail returns, fails, or the seed timeout fires
    // so the UI does not paint a stale local total before the first settle.
    state = state.copyWith(
      total: localState.total,
      totalCounted: localState.totalCounted,
      isSeeding: true,
      seedFailed: false,
      beadImageUrl: fallbackImageUrl,
      beadImageBytes: localState.beadImageBytes,
    );

    final detailFuture = _getAccumulatorDetail(_presetId);
    final raced = await Future.any<Either<Failure, MalaCount>?>([
      detailFuture.then<Either<Failure, MalaCount>?>((r) => r),
      Future<Either<Failure, MalaCount>?>.delayed(
        _seedNetworkTimeout,
        () => null,
      ),
    ]);
    if (!mounted) return; // screen left mid-seed

    String? detailBeadImageUrl;
    if (raced == null) {
      // Timeout: unblock local counting; reconcile when detail eventually lands.
      final timedOutLocal = _local.read(userId, _presetId);
      state = state.copyWith(
        total: timedOutLocal.total,
        totalCounted: timedOutLocal.totalCounted,
        isSeeding: false,
        seedFailed: false,
        beadImageUrl: fallbackImageUrl,
        beadImageBytes: timedOutLocal.beadImageBytes,
      );
      unawaited(
        detailFuture.then((lateResult) {
          if (!mounted) return;
          final lateUrl = _applyDetailResult(
            userId: userId,
            result: lateResult,
            fallbackImageUrl: fallbackImageUrl,
            applyGeneration: applyGeneration,
          );
          if (lateUrl != null) {
            unawaited(
              _refreshBeadImage(
                userId,
                urlCandidates: [
                  lateUrl,
                  if (fallbackImageUrl != null) fallbackImageUrl,
                ],
                refetchDetailOnFailure: false,
              ),
            );
          }
        }),
      );
    } else {
      detailBeadImageUrl = _applyDetailResult(
        userId: userId,
        result: raced,
        fallbackImageUrl: fallbackImageUrl,
        applyGeneration: applyGeneration,
      );
    }

    unawaited(
      _refreshBeadImage(
        userId,
        urlCandidates: [
          if (detailBeadImageUrl != null) detailBeadImageUrl!,
          if (fallbackImageUrl != null) fallbackImageUrl,
        ],
        refetchDetailOnFailure: detailBeadImageUrl == null,
      ),
    );
  }

  /// Applies a detail API result. Never sets [MalaCounterState.isSeeding] true.
  ///
  /// Returns the detail bead image URL when present (for artwork refresh), or
  /// null when [applyGeneration] is stale (e.g. after reset) or on failure.
  String? _applyDetailResult({
    required String userId,
    required Either<Failure, MalaCount> result,
    required String? fallbackImageUrl,
    required int applyGeneration,
  }) {
    if (applyGeneration != _detailApplyGeneration) return null;

    String? detailBeadImageUrl;
    result.fold(
      (failure) {
        _logger.warning('Seed failed: ${failure.message}');
        final localState = _local.read(userId, _presetId);
        // Offline / API error: fall back to local and enable counting.
        state = state.copyWith(
          total: localState.total,
          totalCounted: localState.totalCounted,
          isSeeding: false,
          seedFailed: false,
          beadImageUrl: fallbackImageUrl ?? localState.beadImageUrl,
          beadImageBytes: localState.beadImageBytes,
        );
        unawaited(_sync.flush(SyncReason.launch));
      },
      (detail) {
        detailBeadImageUrl = detail.beadImageUrl;
        // detail.accumulatorId is null when the user has no active accumulator
        // (fresh install, or after reset soft-deletes the session record).
        // detail.total maps to API `current_count` (active session), not
        // `total_counted` (lifetime across soft-deleted sessions).
        final serverTotal = detail.total;
        final serverAccId = detail.accumulatorId;

        final latestLocal = _local.read(userId, _presetId);
        // Reconcile with the server only when an active accumulator exists.
        // Without one, ignore a stale current_count so a post-reset re-entry
        // cannot resurrect the old on-screen tally.
        final total =
            serverAccId != null
                ? max(latestLocal.total, serverTotal)
                : latestLocal.total;
        final syncedTotal = serverAccId != null ? serverTotal : 0;

        final beadImageUrl = detail.beadImageUrl ?? latestLocal.beadImageUrl;
        final totalCounted = max(detail.totalCounted, latestLocal.totalCounted);
        _local.write(
          userId,
          _presetId,
          latestLocal.copyWith(
            total: total,
            syncedTotal: syncedTotal,
            totalCounted: totalCounted,
            accumulatorId: serverAccId ?? latestLocal.accumulatorId,
            beadImageUrl: beadImageUrl,
          ),
        );

        state = state.copyWith(
          total: total,
          totalCounted: totalCounted,
          isSeeding: false,
          seedFailed: false,
          beadImageUrl: beadImageUrl,
          beadImageBytes: latestLocal.beadImageBytes,
        );

        // Push any offline tail captured before this seed.
        if (total > syncedTotal) unawaited(_sync.flush(SyncReason.launch));
      },
    );
    return detailBeadImageUrl;
  }

  /// Downloads bead artwork via [MalaRemoteDataSource.fetchImageBytes]
  /// (injected as [_downloadImageBytes]) and persists bytes in Hive. Presigned
  /// S3 URLs expire, so stale cached URLs are retried against fresh catalogue /
  /// detail URLs when needed.
  Future<void> _refreshBeadImage(
    String userId, {
    List<String> urlCandidates = const [],
    bool refetchDetailOnFailure = true,
  }) async {
    final localState = _local.read(userId, _presetId);
    final cachedBytes = localState.beadImageBytes;
    if (cachedBytes != null) {
      if (!mounted) return;
      state = state.copyWith(
        beadImageUrl: localState.beadImageUrl ?? state.beadImageUrl,
        beadImageBytes: cachedBytes,
      );
      return;
    }

    final candidates = <String>[];
    void addCandidate(String? url) {
      if (url == null || url.isEmpty) return;
      final key = stableNetworkImageCacheKey(url);
      if (candidates.any((c) => stableNetworkImageCacheKey(c) == key)) return;
      candidates.add(url);
    }

    for (final url in urlCandidates) {
      addCandidate(url);
    }
    addCandidate(_mantra.beadImageUrl);
    addCandidate(localState.beadImageUrl);

    for (final url in candidates) {
      final bytes = await _tryDownloadBeadImage(url);
      if (bytes == null) continue;
      await _persistBeadImage(userId, url, bytes);
      return;
    }

    if (!refetchDetailOnFailure) return;

    final detailResult = await _getAccumulatorDetail(_presetId);
    await detailResult.fold(
      (_) async {},
      (detail) async {
        final freshUrl = detail.beadImageUrl;
        if (freshUrl == null || freshUrl.isEmpty) return;

        final bytes = await _tryDownloadBeadImage(freshUrl);
        if (bytes == null) return;
        await _persistBeadImage(userId, freshUrl, bytes);
      },
    );
  }

  /// Network fetch delegated to [MalaRemoteDataSource.fetchImageBytes].
  Future<List<int>?> _tryDownloadBeadImage(String url) async {
    try {
      final bytes = await _downloadImageBytes(url);
      if (bytes.isEmpty) return null;
      return bytes;
    } catch (e) {
      _logger.warning('Bead image download failed for $url: $e');
      return null;
    }
  }

  Future<void> _persistBeadImage(
    String userId,
    String imageUrl,
    List<int> bytes,
  ) async {
    final current = _local.read(userId, _presetId);
    await _local.write(
      userId,
      _presetId,
      current.copyWith(
        beadImageUrl: imageUrl,
        beadImageBase64: base64Encode(bytes),
      ),
    );
    if (!mounted) return;
    state = state.copyWith(
      beadImageUrl: imageUrl,
      beadImageBytes: Uint8List.fromList(bytes),
    );
  }

  /// +1 recitation. Monotonic — never decrements. Returns the new total, or
  /// null while seeding or resetting, when the tap is ignored.
  int? incrementBead({
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) {
    if (state.isSeeding || state.isResetting) return null;

    final userId = _userId;
    if (userId == null || userId.isEmpty) return null;

    final newTotal = state.total + 1;
    final roundComplete = newTotal % state.beadsPerRound == 0;

    state = state.copyWith(total: newTotal);
    _local.recordTap(userId, _presetId);

    if (soundEnabled) _sound?.play();
    if (vibrationEnabled) {
      HapticFeedback.lightImpact();
      if (roundComplete) HapticFeedback.mediumImpact();
    }
    _sync.onTap(roundComplete: roundComplete);
    return newTotal;
  }

  /// Adds completed mala rounds counted outside the app (monotonic). Returns
  /// false when the add was ignored.
  bool addRounds(int rounds) {
    if (rounds <= 0 || state.isSeeding || state.isResetting) return false;

    final userId = _userId;
    if (userId == null || userId.isEmpty) return false;

    final delta = rounds * state.beadsPerRound;
    final newTotal = state.total + delta;
    state = state.copyWith(total: newTotal);
    unawaited(_local.addToTotal(userId, _presetId, delta));
    _sync.onTap(roundComplete: true);
    return true;
  }

  /// Resets the on-screen session to zero by soft-deleting the active server
  /// accumulator (`DELETE /accumulators/user/{id}`). Unsynced taps are flushed
  /// first. Returns false on failure.
  Future<bool> resetCount() async {
    if (state.isSeeding || state.isResetting) return false;

    final userId = _userId;
    if (userId == null || userId.isEmpty) return false;

    state = state.copyWith(isResetting: true);
    // Invalidate before await: clearSession runs inside resetAccumulator, and a
    // late timed-out GET must not rewrite Hive between clear and return.
    _detailApplyGeneration++;
    try {
      await _sync.resetAccumulator(
        _presetId,
        deleteAccumulator: _deleteUserAccumulator,
      );
      if (!mounted) return false;
      final localState = _local.read(userId, _presetId);
      state = state.copyWith(
        total: 0,
        isResetting: false,
        beadImageUrl: localState.beadImageUrl ?? state.beadImageUrl,
      );
      return true;
    } catch (e, st) {
      _logger.warning('Reset failed: $e', e, st);
      if (mounted) state = state.copyWith(isResetting: false);
      return false;
    }
  }

  @override
  void dispose() {
    // Best-effort flush of this mantra's tail as the screen leaves.
    unawaited(_sync.flush(SyncReason.screenLeave));
    super.dispose();
  }
}
