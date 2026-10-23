import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class MyPrayerRequestsState extends Equatable {
  /// Newest first, across every space and event.
  final List<ChatMessageDTO> requests;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasLoaded;
  final bool hasMore;
  final int skip;
  final String? error;

  const MyPrayerRequestsState({
    this.requests = const [],
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasLoaded = false,
    this.hasMore = true,
    this.skip = 0,
    this.error,
  });

  List<ChatMessageDTO> get active =>
      requests.where((request) => !request.isCompleted).toList();

  List<ChatMessageDTO> get accomplished =>
      requests.where((request) => request.isCompleted).toList();

  MyPrayerRequestsState copyWith({
    List<ChatMessageDTO>? requests,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasLoaded,
    bool? hasMore,
    int? skip,
    String? error,
    bool clearError = false,
  }) {
    return MyPrayerRequestsState(
      requests: requests ?? this.requests,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    requests,
    total,
    isLoading,
    isLoadingMore,
    hasLoaded,
    hasMore,
    skip,
    error,
  ];
}

/// Every prayer request the viewer has posted, from the my-requests
/// endpoint. Each row carries its room, which is all an edit, a completion
/// or a delete needs.
class MyPrayerRequestsNotifier extends StateNotifier<MyPrayerRequestsState> {
  MyPrayerRequestsNotifier({required this.ref})
    : super(const MyPrayerRequestsState()) {
    load();
  }

  final Ref ref;
  static const int _limit = 20;

  GroupChatRepository get _repository => ref.read(groupChatRepositoryProvider);

  /// Bumped on every first-page load, so a stale page is dropped.
  int _generation = 0;

  /// Reads the first page again. A page still in flight is dropped when it
  /// lands, so its loading flag is cleared here, not there.
  Future<void> load() async {
    if (state.isLoading) return;
    final generation = ++_generation;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );
    final result = await _repository.listMyPrayerRequests(
      skip: 0,
      limit: _limit,
    );
    if (!mounted || generation != _generation) return;
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          hasLoaded: true,
          error: failure.message,
        );
      },
      (page) {
        state = state.copyWith(
          requests: page.messages,
          total: page.total,
          isLoading: false,
          hasLoaded: true,
          hasMore: page.messages.length < page.total,
          skip: page.messages.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final generation = _generation;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final result = await _repository.listMyPrayerRequests(
      skip: state.skip,
      limit: _limit,
    );
    if (!mounted || generation != _generation) return;
    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        final known = state.requests.map((request) => request.id).toSet();
        final fresh = page.messages.where(
          (message) => !known.contains(message.id),
        );
        final requests = [...state.requests, ...fresh];
        final skip = state.skip + page.messages.length;
        state = state.copyWith(
          requests: requests,
          total: page.total,
          isLoadingMore: false,
          hasMore: page.messages.isNotEmpty && skip < page.total,
          skip: skip,
          clearError: true,
        );
      },
    );
  }

  /// Marks one request accomplished, or active again, in place.
  Future<Either<Failure, Unit>> setCompleted(
    String messageId, {
    required bool isCompleted,
  }) async {
    final request = _find(messageId);
    if (request == null) {
      return const Left(NotFoundFailure('Prayer request not found'));
    }
    final result = await _repository.setMessageCompleted(
      request.roomId,
      messageId: messageId,
      isCompleted: isCompleted,
    );
    return result.map((updated) {
      if (!mounted) return unit;
      final completed = updated?.isCompleted ?? isCompleted;
      _update(
        messageId,
        (row) => row.copyWith(
          isCompleted: completed,
          completedAt: completed ? updated?.completedAt : null,
          clearCompletedAt: !completed,
        ),
      );
      return unit;
    });
  }

  /// Edits one request's body and intention in place.
  Future<Either<Failure, ChatMessageDTO>> edit(
    String messageId, {
    required String body,
    required ChatPrayerIntentionDTO intention,
  }) async {
    final request = _find(messageId);
    if (request == null) {
      return const Left(NotFoundFailure('Prayer request not found'));
    }
    final result = await _repository.updateMessage(
      request.roomId,
      messageId: messageId,
      body: body,
      intention: intention.slug,
    );
    return result.map((updated) {
      var message = request.copyWith(
        body: updated?.body ?? body,
        intention: updated?.intention ?? intention,
      );
      if (mounted) {
        _update(messageId, (row) {
          message = row.copyWith(
            body: updated?.body ?? body,
            intention: updated?.intention ?? intention,
          );
          return message;
        });
      }
      return message;
    });
  }

  /// Deletes one request for everyone, then drops it here.
  Future<Either<Failure, Unit>> delete(String messageId) async {
    final request = _find(messageId);
    if (request == null) {
      return const Left(NotFoundFailure('Prayer request not found'));
    }
    final result = await _repository.deleteMessage(
      request.roomId,
      messageId: messageId,
    );
    if (!mounted) return result;
    result.fold((_) {}, (_) {
      state = state.copyWith(
        requests: state.requests.where((row) => row.id != messageId).toList(),
        total: state.total > 0 ? state.total - 1 : 0,
        skip: state.skip > 0 ? state.skip - 1 : 0,
      );
    });
    return result;
  }

  ChatMessageDTO? _find(String messageId) {
    for (final request in state.requests) {
      if (request.id == messageId) return request;
    }
    return null;
  }

  void _update(
    String messageId,
    ChatMessageDTO Function(ChatMessageDTO request) transform,
  ) {
    state = state.copyWith(
      requests: [
        for (final request in state.requests)
          if (request.id == messageId) transform(request) else request,
      ],
    );
  }
}

final myPrayerRequestsProvider = StateNotifierProvider.autoDispose<
  MyPrayerRequestsNotifier,
  MyPrayerRequestsState
>((ref) => MyPrayerRequestsNotifier(ref: ref));
