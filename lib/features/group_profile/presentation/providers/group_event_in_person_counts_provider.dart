import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_in_person_count.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_event_composer_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_event_composer_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which accumulation of an event the in-person counts belong to.
typedef GroupEventInPersonCountsKey =
    ({String eventId, String eventAccumulationId});

class GroupEventInPersonCountsState {
  final List<GroupEventInPersonCount> items;

  /// Totals and the linked accumulation; null until the first page loads.
  final GroupEventInPersonCountList? summary;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSaving;
  final Failure? error;

  const GroupEventInPersonCountsState({
    this.items = const [],
    this.summary,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSaving = false,
    this.error,
  });

  bool get hasMore {
    final total = summary?.total;
    return total != null && items.length < total;
  }

  GroupEventInPersonCountsState copyWith({
    List<GroupEventInPersonCount>? items,
    GroupEventInPersonCountList? summary,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSaving,
    Failure? error,
    bool clearError = false,
  }) {
    return GroupEventInPersonCountsState(
      items: items ?? this.items,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// The day-by-day in-person counts of one event accumulation. Every write
/// reloads the first page so the totals the API computes stay right.
class GroupEventInPersonCountsNotifier
    extends StateNotifier<GroupEventInPersonCountsState> {
  GroupEventInPersonCountsNotifier({
    required GroupEventComposerRepositoryInterface repository,
    required GroupEventInPersonCountsKey key,
  }) : _repository = repository,
       _key = key,
       super(const GroupEventInPersonCountsState());

  final GroupEventComposerRepositoryInterface _repository;
  final GroupEventInPersonCountsKey _key;
  static const int pageSize = 20;
  int _generation = 0;

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    final generation = ++_generation;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getInPersonCounts(
      _key.eventId,
      eventAccumulationId: _key.eventAccumulationId,
      skip: 0,
      limit: pageSize,
    );
    if (!mounted || generation != _generation) return;
    state = result.fold(
      (failure) => state.copyWith(isLoading: false, error: failure),
      (list) => state.copyWith(
        isLoading: false,
        items: list.items,
        summary: list,
        clearError: true,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final generation = _generation;
    state = state.copyWith(isLoadingMore: true);
    final result = await _repository.getInPersonCounts(
      _key.eventId,
      eventAccumulationId: _key.eventAccumulationId,
      skip: state.items.length,
      limit: pageSize,
    );
    if (!mounted || generation != _generation) return;
    state = result.fold(
      (failure) => state.copyWith(isLoadingMore: false, error: failure),
      (list) => state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...list.items],
        summary: list,
      ),
    );
  }

  /// Null on success, else the failure to show.
  Future<Failure?> save({
    String? countId,
    required String day,
    required int count,
  }) async {
    if (state.isSaving) return null;
    state = state.copyWith(isSaving: true);
    final result =
        countId == null
            ? await _repository.addInPersonCount(
              _key.eventId,
              eventAccumulationId: _key.eventAccumulationId,
              day: day,
              count: count,
            )
            : await _repository.updateInPersonCount(
              _key.eventId,
              countId,
              eventAccumulationId: _key.eventAccumulationId,
              day: day,
              count: count,
            );
    if (!mounted) return null;
    state = state.copyWith(isSaving: false);
    return result.fold((failure) => failure, (_) {
      loadInitial();
      return null;
    });
  }

  /// Null on success, else the failure to show.
  Future<Failure?> remove(String countId) async {
    if (state.isSaving) return null;
    state = state.copyWith(isSaving: true);
    final result = await _repository.deleteInPersonCount(
      _key.eventId,
      countId,
      eventAccumulationId: _key.eventAccumulationId,
    );
    if (!mounted) return null;
    state = state.copyWith(isSaving: false);
    return result.fold((failure) => failure, (_) {
      loadInitial();
      return null;
    });
  }
}

final groupEventInPersonCountsProvider = StateNotifierProvider.autoDispose
    .family<
      GroupEventInPersonCountsNotifier,
      GroupEventInPersonCountsState,
      GroupEventInPersonCountsKey
    >((ref, key) {
      final notifier = GroupEventInPersonCountsNotifier(
        repository: ref.watch(groupEventComposerRepositoryProvider),
        key: key,
      );
      notifier.loadInitial();
      return notifier;
    });
