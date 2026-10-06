import 'package:flutter_pecha/features/group_profile/domain/entities/group_members_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_report.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupReportsState {
  final List<GroupReport> reports;

  /// [reports] grouped by the content they target.
  final List<GroupReportedItem> items;

  /// Unresolved reports on the server, not distinct reported items.
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final bool hasLoaded;

  const GroupReportsState({
    this.reports = const [],
    this.items = const [],
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.hasLoaded = false,
  });

  List<GroupReportedItem> itemsOfKind(GroupReportKind kind) => [
    for (final item in items)
      if (item.kind == kind) item,
  ];

  GroupReportsState copyWith({
    List<GroupReport>? reports,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    bool? hasLoaded,
    bool clearError = false,
  }) {
    final nextReports = reports ?? this.reports;
    return GroupReportsState(
      reports: nextReports,
      items: reports == null ? items : groupReportsByTarget(nextReports),
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

/// The unresolved moderation queue of one group, for its admins.
class GroupReportsNotifier extends StateNotifier<GroupReportsState> {
  GroupReportsNotifier({
    required GroupProfileRepositoryInterface repository,
    required String groupId,
  }) : _repository = repository,
       _groupId = groupId,
       super(const GroupReportsState());

  final GroupProfileRepositoryInterface _repository;
  final String _groupId;
  static const int _limit = 20;
  int _requestGeneration = 0;

  Future<void> loadInitial() async {
    if (state.isLoading) return;

    final generation = ++_requestGeneration;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );

    final result = await _repository.getGroupReports(
      _groupId,
      resolved: false,
      skip: 0,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

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
          reports: page.reports,
          total: page.total,
          isLoading: false,
          hasLoaded: true,
          hasMore: _hasMore(page.reports.length, page.reports, page.total),
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    final generation = _requestGeneration;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await _repository.getGroupReports(
      _groupId,
      resolved: false,
      skip: state.reports.length,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        final merged = [...state.reports, ...page.reports];
        state = state.copyWith(
          reports: merged,
          total: page.total,
          isLoadingMore: false,
          hasMore: _hasMore(merged.length, page.reports, page.total),
          clearError: true,
        );
      },
    );
  }

  /// Resolves every report filed against [item], then reloads the queue.
  /// Returns false when any of them could not be resolved.
  Future<bool> resolveItem(GroupReportedItem item) async {
    final results = await Future.wait([
      for (final report in item.reports)
        _repository.resolveGroupReport(_groupId, reportId: report.id),
    ]);
    if (!mounted) return false;

    final resolvedIds = <String>{
      for (var i = 0; i < item.reports.length; i++)
        if (results[i].isRight()) item.reports[i].id,
    };
    if (resolvedIds.isNotEmpty) {
      final remaining = [
        for (final report in state.reports)
          if (!resolvedIds.contains(report.id)) report,
      ];
      state = state.copyWith(
        reports: remaining,
        total: (state.total - (state.reports.length - remaining.length)).clamp(
          0,
          state.total,
        ),
      );
    }

    // A load already in flight predates the resolution; let the reload
    // below supersede it instead of being skipped by its guard.
    state = state.copyWith(isLoading: false, isLoadingMore: false);
    await loadInitial();

    return resolvedIds.length == item.reports.length;
  }

  void retry() {
    if (state.reports.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }

  /// Measured against what has been accumulated, so an empty page with a
  /// stale `total` cannot keep [loadMore] asking forever.
  static bool _hasMore(int loaded, List<GroupReport> page, int total) {
    if (page.isEmpty) return false;
    return loaded < total;
  }
}

final groupReportsProvider = StateNotifierProvider.autoDispose
    .family<GroupReportsNotifier, GroupReportsState, String>((ref, groupId) {
      final notifier = GroupReportsNotifier(
        repository: ref.watch(groupProfileRepositoryProvider),
        groupId: groupId,
      );
      notifier.loadInitial();
      return notifier;
    });

/// Reporter and reported-user ids on [reports]. The reports payload names
/// people but carries no avatar, so these ids are what the members list is
/// queried with.
Set<String> reportUserIds(Iterable<GroupReport> reports) {
  final ids = <String>{};
  for (final report in reports) {
    for (final user in [report.reporter, report.reportedUser]) {
      final id = user?.id.trim() ?? '';
      if (id.isNotEmpty) ids.add(id);
    }
  }
  return ids;
}

/// Avatars for the people named in a group's reports, keyed by user id.
///
/// `GET /author/groups/{groupId}/members` is the existing source of
/// `avatar_url` keyed by `user_id`. Pages until every id on the queue has
/// been seen, or the member list runs out.
class GroupReportAvatarsNotifier extends StateNotifier<Map<String, String>> {
  GroupReportAvatarsNotifier({
    required GroupProfileRepositoryInterface repository,
    required String groupId,
  }) : _repository = repository,
       _groupId = groupId,
       super(const {});

  final GroupProfileRepositoryInterface _repository;
  final String _groupId;
  final Set<String> _wanted = {};
  final Set<String> _seen = {};
  int _nextSkip = 0;
  bool _exhausted = false;
  Future<void>? _inFlight;

  static const int _pageSize = 100;

  Future<void> resolve(Set<String> userIds) {
    _wanted.addAll(userIds);
    final current = _inFlight;
    if (current != null) {
      return current.then((_) async {
        if (!mounted || _exhausted) return;
        if (_wanted.difference(_seen).isEmpty) return;
        await resolve(const {});
      });
    }
    final run = _pump();
    _inFlight = run;
    return run.whenComplete(() {
      if (identical(_inFlight, run)) _inFlight = null;
    });
  }

  Future<void> _pump() async {
    while (mounted && !_exhausted) {
      final missing = _wanted.difference(_seen);
      if (missing.isEmpty) break;

      final result = await _repository.getGroupMembers(
        _groupId,
        skip: _nextSkip,
        limit: _pageSize,
      );
      if (!mounted) return;

      final page = result.fold<GroupMembersPage?>((_) => null, (page) => page);
      // A failed page leaves the ids unseen, so the next queue refresh
      // asks again instead of spinning on the same error.
      if (page == null) return;

      final found = <String, String>{};
      for (final member in page.members) {
        final id = member.userId.trim();
        if (id.isEmpty) continue;
        _seen.add(id);
        final url = member.avatarUrl?.trim() ?? '';
        if (url.isNotEmpty) found[id] = url;
      }
      if (found.isNotEmpty) state = {...state, ...found};

      _nextSkip += page.members.length;
      if (page.members.isEmpty || !page.hasMore) _exhausted = true;
    }
  }
}

final groupReportAvatarsProvider = StateNotifierProvider.autoDispose
    .family<GroupReportAvatarsNotifier, Map<String, String>, String>((
      ref,
      groupId,
    ) {
      final notifier = GroupReportAvatarsNotifier(
        repository: ref.watch(groupProfileRepositoryProvider),
        groupId: groupId,
      );
      ref.listen(
        groupReportsProvider(groupId).select((state) => state.reports),
        (_, reports) => notifier.resolve(reportUserIds(reports)),
        fireImmediately: true,
      );
      return notifier;
    });
