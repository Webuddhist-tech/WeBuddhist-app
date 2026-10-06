import 'package:flutter_pecha/features/group_profile/domain/entities/group_members_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_report.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_reports_page.dart';
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

  /// What the next page asks the server to skip. Counted from what the pages
  /// held on the wire, not from the reports kept: a dropped kind still took
  /// up a slot, and resolving reports shortens the list without moving the
  /// server's own window.
  int _serverOffset = 0;

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
        _serverOffset = page.received;
        state = state.copyWith(
          reports: page.reports,
          total: page.total,
          isLoading: false,
          hasLoaded: true,
          hasMore: _hasMore(page, _serverOffset),
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
      skip: _serverOffset,
      limit: _limit,
    );

    if (!mounted || generation != _requestGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        _serverOffset += page.received;
        state = state.copyWith(
          reports: [...state.reports, ...page.reports],
          total: page.total,
          isLoadingMore: false,
          hasMore: _hasMore(page, _serverOffset),
          clearError: true,
        );
      },
    );
  }

  /// Loads the pages still to come, so every report against an item is known
  /// before it is resolved. Gives up on a failure or on a page that does not
  /// move the offset, rather than asking again for what it already has.
  Future<void> _loadRemaining() async {
    while (mounted && state.hasMore) {
      final offsetBefore = _serverOffset;
      await loadMore();
      if (!mounted || state.error != null) return;
      if (_serverOffset == offsetBefore) return;
    }
  }

  /// Resolves every report filed against [item], then reloads the queue.
  /// Returns false when any of them could not be resolved.
  ///
  /// Reports against the same content can sit on pages not loaded yet, so the
  /// rest of the queue is pulled in first; resolving only what is on screen
  /// would bring the item straight back on the reload.
  Future<bool> resolveItem(GroupReportedItem item) async {
    await _loadRemaining();
    if (!mounted) return false;

    final reports = [
      for (final report in state.reports)
        if (report.kind == item.kind && report.targetId == item.targetId)
          report,
    ];
    // Nothing of the item is on the queue any more; the reload below says so.
    if (reports.isEmpty) {
      state = state.copyWith(isLoading: false, isLoadingMore: false);
      await loadInitial();
      return true;
    }

    final results = await Future.wait([
      for (final report in reports)
        _repository.resolveGroupReport(_groupId, reportId: report.id),
    ]);
    if (!mounted) return false;

    final resolvedIds = <String>{
      for (var i = 0; i < reports.length; i++)
        if (results[i].isRight()) reports[i].id,
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

    return resolvedIds.length == reports.length;
  }

  void retry() {
    if (state.reports.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }

  /// Measured against the offset reached, so a page whose reports were all of
  /// an unknown kind still leads to the next one, while a page the server
  /// returned empty cannot keep [loadMore] asking forever.
  static bool _hasMore(GroupReportsPage page, int offset) {
    if (page.received == 0) return false;
    return offset < page.total;
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

/// What paging the member list of one group has already established, kept
/// past the reports screen so reopening the queue does not scan the whole
/// list again for ids it has been shown not to hold.
class GroupMemberAvatarCache {
  /// Avatar urls found so far, keyed by user id.
  final Map<String, String> avatars = {};

  /// Ids a complete pass over the member list did not contain — a reporter
  /// who has since left, say. An id here is never looked for again, so one
  /// who rejoins keeps the fallback initial until the app restarts.
  final Set<String> absent = {};
}

final groupMemberAvatarCacheProvider =
    Provider.family<GroupMemberAvatarCache, String>(
      (ref, groupId) => GroupMemberAvatarCache(),
    );

/// Avatars for the people named in a group's reports, keyed by user id.
///
/// `GET /author/groups/{groupId}/members` is the existing source of
/// `avatar_url` keyed by `user_id`. Pages until every id on the queue has
/// been seen, or the member list runs out.
class GroupReportAvatarsNotifier extends StateNotifier<Map<String, String>> {
  GroupReportAvatarsNotifier({
    required GroupProfileRepositoryInterface repository,
    required String groupId,
    GroupMemberAvatarCache? cache,
  }) : _repository = repository,
       _groupId = groupId,
       _cache = cache ?? GroupMemberAvatarCache(),
       super({...?cache?.avatars});

  final GroupProfileRepositoryInterface _repository;
  final String _groupId;
  final GroupMemberAvatarCache _cache;
  final Set<String> _wanted = {};
  final Set<String> _seen = {};
  int _nextSkip = 0;
  bool _exhausted = false;
  Future<void>? _inFlight;

  static const int _pageSize = 100;

  /// Wanted ids still worth a request: neither already found on this pass nor
  /// known to be outside the member list.
  Set<String> get _missing =>
      _wanted.difference(_seen).difference(_cache.absent);

  Future<void> resolve(Set<String> userIds) {
    _wanted.addAll(userIds);
    final current = _inFlight;
    if (current != null) {
      return current.then((_) async {
        if (!mounted || _missing.isEmpty) return;
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
    while (mounted) {
      if (_missing.isEmpty) break;
      // Everything the list holds has been seen, so an id still missing is
      // either gone or newly joined. One pass from the top settles which.
      if (_exhausted) {
        _nextSkip = 0;
        _exhausted = false;
      }

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
        _cache.absent.remove(id);
        final url = member.avatarUrl?.trim() ?? '';
        if (url.isNotEmpty) found[id] = url;
      }
      if (found.isNotEmpty) {
        _cache.avatars.addAll(found);
        state = {...state, ...found};
      }

      _nextSkip += page.members.length;
      if (page.members.isEmpty || !page.hasMore) {
        _exhausted = true;
        _cache.absent.addAll(_wanted.difference(_seen));
      }
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
        cache: ref.watch(groupMemberAvatarCacheProvider(groupId)),
      );
      ref.listen(
        groupReportsProvider(groupId).select((state) => state.reports),
        (_, reports) => notifier.resolve(reportUserIds(reports)),
        fireImmediately: true,
      );
      return notifier;
    });
