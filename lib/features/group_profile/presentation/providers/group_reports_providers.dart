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

class _ItemReportScan {
  final List<GroupReport> reports;
  final bool failed;

  const _ItemReportScan({required this.reports, required this.failed});
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

  /// How far past the loaded queue one dismiss reads, looking for more
  /// reports against the same item. A few larger pages, not the rest of a
  /// long queue twenty reports at a time.
  static const int _resolveScanLimit = 100;
  static const int _resolveScanMaxPages = 4;
  int _requestGeneration = 0;
  bool _resolving = false;

  /// What the next page asks the server to skip. Counted from what the pages
  /// held on the wire, not from the reports kept: a dropped kind still took
  /// up a slot, and resolving reports shortens the list without moving the
  /// server's own window.
  int _serverOffset = 0;

  Future<void> loadInitial() async {
    if (_resolving || state.isLoading) return;

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
    if (_resolving ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.isLoading) {
      return;
    }

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

  bool _sameTarget(GroupReport report, GroupReportedItem item) {
    return report.kind == item.kind && report.targetId == item.targetId;
  }

  /// Reports against [item] from the loaded queue, plus a bounded look ahead.
  ///
  /// Later pages can hold more reports on the same post, comment, or message.
  /// Those are collected here and resolved with the ones already on screen.
  /// The look ahead stops after [_resolveScanMaxPages], at the end of the
  /// queue, or when a page does not move the offset. A failed page request
  /// still returns the matches already found.
  Future<_ItemReportScan?> _reportsForItem(
    GroupReportedItem item,
    int generation,
  ) async {
    final reports = <GroupReport>[
      for (final report in state.reports)
        if (_sameTarget(report, item)) report,
    ];
    final seen = <String>{for (final report in reports) report.id};

    var skip = _serverOffset;
    var total = state.total;
    var hasMore = state.hasMore;
    var pages = 0;

    while (hasMore && pages < _resolveScanMaxPages) {
      final result = await _repository.getGroupReports(
        _groupId,
        resolved: false,
        skip: skip,
        limit: _resolveScanLimit,
      );
      if (!mounted || generation != _requestGeneration) return null;

      final page = result.fold<GroupReportsPage?>((_) => null, (page) => page);
      if (page == null) {
        return _ItemReportScan(reports: reports, failed: true);
      }

      pages++;
      for (final report in page.reports) {
        if (_sameTarget(report, item) && seen.add(report.id)) {
          reports.add(report);
        }
      }
      if (page.received == 0) break;
      skip += page.received;
      total = page.total;
      hasMore = skip < total;
    }
    return _ItemReportScan(reports: reports, failed: false);
  }

  /// Resolves every report filed against [item] that is already loaded or
  /// found in the bounded look ahead, then reloads the queue. Returns false
  /// when any of them could not be resolved or the look ahead failed.
  Future<bool> resolveItem(GroupReportedItem item) async {
    if (_resolving) return false;
    _resolving = true;
    final generation = ++_requestGeneration;

    try {
      final scan = await _reportsForItem(item, generation);
      if (!mounted || generation != _requestGeneration || scan == null) {
        return false;
      }

      final reports = scan.reports;
      // Nothing of the item is on the queue any more; the reload below says so.
      if (reports.isEmpty) {
        state = state.copyWith(isLoading: false, isLoadingMore: false);
        _resolving = false;
        await loadInitial();
        return !scan.failed;
      }

      final results = await Future.wait([
        for (final report in reports)
          _repository.resolveGroupReport(_groupId, reportId: report.id),
      ]);
      if (!mounted || generation != _requestGeneration) return false;

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
          total: (state.total - (state.reports.length - remaining.length))
              .clamp(0, state.total),
        );
      }

      // A load already in flight predates the resolution; let the reload
      // below supersede it instead of being skipped by its guard.
      state = state.copyWith(isLoading: false, isLoadingMore: false);
      _resolving = false;
      await loadInitial();

      return !scan.failed && resolvedIds.length == reports.length;
    } finally {
      _resolving = false;
    }
  }

  /// Removes the chat message behind [item] for everyone, then resolves the
  /// reports filed against it so the card leaves the queue.
  ///
  /// Returns false when the delete itself failed; the reports are left alone
  /// then, so the item stays on the queue to be acted on again. A delete that
  /// went through reports success even if resolving the reports did not,
  /// because the message is gone either way.
  Future<bool> deleteMessageItem(GroupReportedItem item) async {
    if (item.kind != GroupReportKind.chatMessage || _resolving) return false;
    final messageId = item.latest.messageId?.trim() ?? '';
    if (messageId.isEmpty) return false;

    final result = await _repository.deleteGroupChatMessage(
      _groupId,
      messageId: messageId,
    );
    if (!mounted || result.isLeft()) return false;

    await resolveItem(item);
    return true;
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
/// list again for ids it has been shown not to hold. Absences are dropped
/// when [membershipEpoch] moves on, so a reporter who rejoins is looked up
/// again.
class GroupMemberAvatarCache {
  /// Avatar urls found so far, keyed by user id.
  final Map<String, String> avatars = {};

  /// Ids a complete pass over the member list did not contain — a reporter
  /// who has since left, say. Cleared when membership changes.
  final Set<String> absent = {};

  /// [groupMembershipEpochProvider] value [absent] was last synced to.
  int membershipEpoch = 0;

  /// Bumped when [absent] is cleared, so a member scan already in flight
  /// does not write those ids back.
  int absenceGeneration = 0;

  /// Returns true when [epoch] is newer and remembered absences were dropped.
  bool syncMembershipEpoch(int epoch) {
    if (epoch == membershipEpoch) return false;
    membershipEpoch = epoch;
    if (absent.isEmpty) return false;
    absent.clear();
    absenceGeneration++;
    return true;
  }
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

      final generation = _cache.absenceGeneration;
      final result = await _repository.getGroupMembers(
        _groupId,
        skip: _nextSkip,
        limit: _pageSize,
      );
      if (!mounted) return;
      // Membership changed while this page was in flight. Drop the pass so
      // its absences are not written back, and start the next pass at the
      // top — the person who just joined may sit on an earlier page.
      if (generation != _cache.absenceGeneration) {
        _nextSkip = 0;
        _exhausted = false;
        return;
      }

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

final groupReportAvatarsProvider = StateNotifierProvider.autoDispose.family<
  GroupReportAvatarsNotifier,
  Map<String, String>,
  String
>((ref, groupId) {
  final cache = ref.watch(groupMemberAvatarCacheProvider(groupId));
  final notifier = GroupReportAvatarsNotifier(
    repository: ref.watch(groupProfileRepositoryProvider),
    groupId: groupId,
    cache: cache,
  );
  cache.syncMembershipEpoch(ref.read(groupMembershipEpochProvider(groupId)));
  ref.listen(groupMembershipEpochProvider(groupId), (previous, next) {
    if (cache.syncMembershipEpoch(next)) {
      notifier.resolve(const {});
    }
  });
  ref.listen(
    groupReportsProvider(groupId).select((state) => state.reports),
    (_, reports) => notifier.resolve(reportUserIds(reports)),
    fireImmediately: true,
  );
  return notifier;
});
