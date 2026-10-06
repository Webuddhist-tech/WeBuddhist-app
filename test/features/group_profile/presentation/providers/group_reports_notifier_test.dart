import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_member.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_members_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_report.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_reports_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_reports_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Serves [pages] in order, recording the skip each request asked for.
class _PagingRepository extends Fake
    implements GroupProfileRepositoryInterface {
  _PagingRepository(this.pages);

  final List<GroupReportsPage> pages;
  final List<int> reportSkips = [];
  final List<String> resolvedReportIds = [];
  int _nextPage = 0;

  @override
  Future<Either<Failure, GroupReportsPage>> getGroupReports(
    String groupId, {
    GroupReportKind? kind,
    bool? resolved,
    required int skip,
    required int limit,
  }) async {
    reportSkips.add(skip);
    if (skip == 0) _nextPage = 0;
    if (_nextPage >= pages.length) {
      return const Right(
        GroupReportsPage(reports: [], skip: 0, limit: 20, total: 0),
      );
    }
    return Right(pages[_nextPage++]);
  }

  @override
  Future<Either<Failure, void>> resolveGroupReport(
    String groupId, {
    required String reportId,
  }) async {
    resolvedReportIds.add(reportId);
    return const Right(null);
  }
}

class _MembersRepository extends Fake
    implements GroupProfileRepositoryInterface {
  _MembersRepository(this.members);

  final List<GroupMember> members;
  final List<int> memberSkips = [];

  @override
  Future<Either<Failure, GroupMembersPage>> getGroupMembers(
    String groupId, {
    required int skip,
    required int limit,
  }) async {
    memberSkips.add(skip);
    return Right(
      GroupMembersPage(
        members: members.skip(skip).take(limit).toList(),
        skip: skip,
        limit: limit,
        totalMembers: members.length,
      ),
    );
  }
}

GroupReport _report(String id, {String commentId = 'c1'}) {
  return GroupReport(
    id: id,
    kind: GroupReportKind.comment,
    commentId: commentId,
    contentText: 'A comment',
  );
}

void main() {
  test('the next page skips the reports of an unknown kind too', () async {
    // A first page the server filled, of which this client kept only one.
    final repository = _PagingRepository([
      GroupReportsPage(
        reports: [_report('r1')],
        received: 20,
        skip: 0,
        limit: 20,
        total: 25,
      ),
      GroupReportsPage(
        reports: [_report('r2', commentId: 'c2')],
        received: 5,
        skip: 20,
        limit: 20,
        total: 25,
      ),
    ]);
    final notifier = GroupReportsNotifier(
      repository: repository,
      groupId: 'g1',
    );

    await notifier.loadInitial();
    expect(notifier.state.hasMore, isTrue);
    await notifier.loadMore();

    expect(repository.reportSkips, [0, 20]);
    expect(notifier.state.reports.map((report) => report.id), ['r1', 'r2']);
    expect(notifier.state.hasMore, isFalse);
  });

  test('a page of only unknown kinds still leads to the next one', () async {
    final repository = _PagingRepository([
      const GroupReportsPage(
        reports: [],
        received: 20,
        skip: 0,
        limit: 20,
        total: 21,
      ),
      GroupReportsPage(
        reports: [_report('r1')],
        received: 1,
        skip: 20,
        limit: 20,
        total: 21,
      ),
    ]);
    final notifier = GroupReportsNotifier(
      repository: repository,
      groupId: 'g1',
    );

    await notifier.loadInitial();
    expect(notifier.state.hasMore, isTrue);
    await notifier.loadMore();

    expect(repository.reportSkips, [0, 20]);
    expect(notifier.state.reports.map((report) => report.id), ['r1']);
  });

  test('resolving an item also clears its reports on later pages', () async {
    final repository = _PagingRepository([
      GroupReportsPage(reports: [_report('r1')], skip: 0, limit: 1, total: 3),
      GroupReportsPage(reports: [_report('r2')], skip: 1, limit: 1, total: 3),
      GroupReportsPage(
        reports: [_report('r3', commentId: 'c2')],
        skip: 2,
        limit: 1,
        total: 3,
      ),
    ]);
    final notifier = GroupReportsNotifier(
      repository: repository,
      groupId: 'g1',
    );

    await notifier.loadInitial();
    final item = notifier.state.items.single;
    expect(item.reports, hasLength(1));

    expect(await notifier.resolveItem(item), isTrue);
    expect(repository.resolvedReportIds, unorderedEquals(['r1', 'r2']));
  });

  test('an id the member list does not hold is looked for once', () async {
    final repository = _MembersRepository(const [
      GroupMember(userId: 'm1', username: 'mei', fullname: 'Mei Lin'),
    ]);
    final cache = GroupMemberAvatarCache();

    final first = GroupReportAvatarsNotifier(
      repository: repository,
      groupId: 'g1',
      cache: cache,
    );
    await first.resolve({'gone'});
    expect(repository.memberSkips, [0]);

    // Reopening the queue builds a new notifier against the same cache.
    final second = GroupReportAvatarsNotifier(
      repository: repository,
      groupId: 'g1',
      cache: cache,
    );
    await second.resolve({'gone'});

    expect(repository.memberSkips, [0]);
  });
}
