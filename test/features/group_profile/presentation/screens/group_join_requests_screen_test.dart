import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_join_request.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_join_requests_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_join_requests_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Answers each page request with the next queued result.
class _FakeRepository extends Fake implements GroupProfileRepositoryInterface {
  _FakeRepository(this.pages);

  final List<Either<Failure, GroupJoinRequestsPage>> pages;
  final List<int> skips = [];

  @override
  Future<Either<Failure, GroupJoinRequestsPage>> getGroupJoinRequests(
    String groupId, {
    GroupJoinRequestStatus status = GroupJoinRequestStatus.pending,
    required int skip,
    required int limit,
  }) async {
    skips.add(skip);
    return pages.removeAt(0);
  }
}

GroupJoinRequestsPage _page(int start, int count, {required int total}) {
  return GroupJoinRequestsPage(
    requests: [
      for (var i = start; i < start + count; i++)
        GroupJoinRequest(
          id: 'r$i',
          userId: 'u$i',
          userName: 'User $i',
          status: GroupJoinRequestStatus.pending,
        ),
    ],
    skip: start,
    limit: 20,
    total: total,
  );
}

Future<void> _pump(WidgetTester tester, _FakeRepository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [groupProfileRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GroupJoinRequestsScreen(groupId: 'g1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a failed later page shows a retry under the loaded rows', (
    tester,
  ) async {
    final repository = _FakeRepository([
      Right(_page(0, 2, total: 3)),
      const Left(NetworkFailure('offline')),
      Right(_page(2, 1, total: 3)),
    ]);
    await _pump(tester, repository);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GroupJoinRequestsScreen)),
    );

    // Two rows do not fill the screen, so no scroll ever asks for more.
    await container.read(groupJoinRequestsProvider('g1').notifier).loadMore();
    await tester.pumpAndSettle();

    expect(find.text('User 0'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.skips, [0, 2, 2]);
    expect(find.text('User 2'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });
}
