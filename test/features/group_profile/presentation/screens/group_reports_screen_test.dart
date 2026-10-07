import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_member.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_members_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_report.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_reports_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_reports_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_reports_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeRepository extends Fake implements GroupProfileRepositoryInterface {
  _FakeRepository(this.reports, {this.members = const [], this.pageSize});

  List<GroupReport> reports;
  final List<GroupMember> members;
  final List<bool?> resolvedFilters = [];
  final List<String> resolvedReportIds = [];

  /// When set, [getGroupReports] pages the queue instead of returning it all.
  final int? pageSize;
  final List<int> requestedSkips = [];

  /// When set, [resolveGroupReport] waits on it before recording the id.
  Future<void>? pendingResolve;

  @override
  Future<Either<Failure, GroupReportsPage>> getGroupReports(
    String groupId, {
    GroupReportKind? kind,
    bool? resolved,
    required int skip,
    required int limit,
  }) async {
    resolvedFilters.add(resolved);
    requestedSkips.add(skip);
    final size = pageSize;
    return Right(
      GroupReportsPage(
        reports:
            size == null ? reports : reports.skip(skip).take(size).toList(),
        skip: size == null ? 0 : skip,
        limit: size ?? 20,
        total: reports.length,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> resolveGroupReport(
    String groupId, {
    required String reportId,
  }) async {
    final pending = pendingResolve;
    if (pending != null) await pending;
    resolvedReportIds.add(reportId);
    reports = [
      for (final report in reports)
        if (report.id != reportId) report,
    ];
    return const Right(null);
  }

  @override
  Future<Either<Failure, GroupMembersPage>> getGroupMembers(
    String groupId, {
    required int skip,
    required int limit,
  }) async {
    final page = members.skip(skip).take(limit).toList();
    return Right(
      GroupMembersPage(
        members: page,
        skip: skip,
        limit: limit,
        totalMembers: members.length,
      ),
    );
  }
}

GroupReport _report(
  String id, {
  required GroupReportKind kind,
  String? postId,
  String? commentId,
  String? messageId,
  required String reporter,
  required String description,
  String reason = '',
  required String content,
}) {
  return GroupReport(
    id: id,
    kind: kind,
    postId: postId,
    commentId: commentId,
    messageId: messageId,
    reason: reason,
    description: description,
    contentText: content,
    reporter: GroupReportUser(id: 'u-$id', firstname: reporter),
    reportedUser: const GroupReportUser(id: 'author', firstname: 'Mei Lin'),
  );
}

List<GroupReport> _sampleReports() => [
  _report(
    'r1',
    kind: GroupReportKind.comment,
    commentId: 'c1',
    reporter: 'Tai Lang',
    description: 'False information',
    content: 'Thank you for moving it',
  ),
  _report(
    'r2',
    kind: GroupReportKind.chatMessage,
    messageId: 'm1',
    reporter: 'Pema',
    description: 'Off-topic or disruptive',
    content: 'You do not belong here.',
  ),
  _report(
    'r3',
    kind: GroupReportKind.comment,
    commentId: 'c1',
    reporter: 'Shifu',
    description: 'Spam',
    content: 'Thank you for moving it',
  ),
];

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [groupProfileRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GroupReportsScreen(groupId: 'g1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('groups reports per item and expands to show each reporter', (
    tester,
  ) async {
    final repository = _FakeRepository(_sampleReports());
    await _pumpScreen(tester, repository);

    expect(repository.resolvedFilters, everyElement(isFalse));
    expect(find.text('Comments'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Posts'), findsNothing);
    expect(find.text('Thank you for moving it'), findsOneWidget);
    expect(find.text('Delete comment'), findsOneWidget);
    expect(find.text('Delete message'), findsOneWidget);
    expect(find.text('2 reports'), findsOneWidget);
    expect(find.text('1 report'), findsOneWidget);
    expect(find.text('False information'), findsNothing);

    await tester.tap(find.text('2 reports'));
    await tester.pumpAndSettle();

    expect(find.text('False information'), findsOneWidget);
    expect(find.text('Spam'), findsOneWidget);
    expect(find.text('Off-topic or disruptive'), findsNothing);
  });

  testWidgets('keeps paging when a full page collapses into one short card', (
    tester,
  ) async {
    // A page's worth of reports on one post makes a single card, too short
    // to scroll; the older message report sits on the next page.
    final repository = _FakeRepository([
      for (var i = 0; i < 20; i++)
        _report(
          'p$i',
          kind: GroupReportKind.post,
          postId: 'post-1',
          reporter: 'Reporter $i',
          description: 'Spam',
          content: 'Buy now',
        ),
      _report(
        'm1',
        kind: GroupReportKind.chatMessage,
        messageId: 'msg-1',
        reporter: 'Pema',
        description: 'Off-topic or disruptive',
        content: 'You do not belong here.',
      ),
    ], pageSize: 20);
    await _pumpScreen(tester, repository);

    expect(repository.requestedSkips, containsAllInOrder([0, 20]));
    expect(find.text('20 reports'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('You do not belong here.'), findsOneWidget);
  });

  testWidgets('the cross resolves every report on the item and refreshes', (
    tester,
  ) async {
    final repository = _FakeRepository(_sampleReports());
    await _pumpScreen(tester, repository);
    final loadsBefore = repository.resolvedFilters.length;

    await tester.tap(find.byIcon(AppAssets.x).first);
    await tester.pumpAndSettle();

    expect(repository.resolvedReportIds, unorderedEquals(['r1', 'r3']));
    expect(repository.resolvedFilters.length, greaterThan(loadsBefore));
    expect(find.text('Thank you for moving it'), findsNothing);
    expect(find.text('Comments'), findsNothing);
    expect(find.text('You do not belong here.'), findsOneWidget);
  });

  testWidgets('a second dismiss is ignored while the first is resolving', (
    tester,
  ) async {
    final repository = _FakeRepository(_sampleReports());
    final gate = Completer<void>();
    repository.pendingResolve = gate.future;
    await _pumpScreen(tester, repository);

    final dismiss =
        tester
            .widgetList<IconButton>(
              find.widgetWithIcon(IconButton, AppAssets.x),
            )
            .toList();
    expect(dismiss, hasLength(2));
    for (final icon in tester.widgetList<Icon>(find.byIcon(AppAssets.x))) {
      expect(icon.color, AppColors.textPrimary);
    }

    dismiss[0].onPressed!();
    dismiss[1].onPressed!();
    await tester.pump();

    expect(find.text('Something went wrong. Please try again'), findsNothing);
    for (final button in tester.widgetList<IconButton>(
      find.widgetWithIcon(IconButton, AppAssets.x),
    )) {
      expect(button.onPressed, isNull);
    }
    for (final icon in tester.widgetList<Icon>(find.byIcon(AppAssets.x))) {
      expect(icon.color, AppColors.grey400);
    }

    gate.complete();
    await tester.pumpAndSettle();

    expect(repository.resolvedReportIds, unorderedEquals(['r1', 'r3']));
    expect(find.text('Something went wrong. Please try again'), findsNothing);
    expect(find.text('You do not belong here.'), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(AppAssets.x)).color,
      AppColors.textPrimary,
    );
  });

  testWidgets('falls back to the reason when no description was written', (
    tester,
  ) async {
    final repository = _FakeRepository([
      _report(
        'r1',
        kind: GroupReportKind.chatMessage,
        messageId: 'm1',
        reporter: 'Pema',
        reason: 'HARASSMENT',
        description: '',
        content: 'You do not belong here.',
      ),
    ]);
    await _pumpScreen(tester, repository);

    await tester.tap(find.text('1 report'));
    await tester.pumpAndSettle();

    expect(find.text('Harassment or bullying'), findsOneWidget);
  });

  testWidgets('the deferred card actions read as disabled', (tester) async {
    final repository = _FakeRepository(_sampleReports());
    await _pumpScreen(tester, repository);

    final button = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Delete comment'),
        matching: find.byType(TextButton),
      ),
    );
    final foreground = button.style!.foregroundColor!;

    expect(button.onPressed, isNull);
    expect(
      foreground.resolve({WidgetState.disabled})!.a,
      lessThan(foreground.resolve({})!.a),
    );
  });

  testWidgets('draws a divider only between different subsections', (
    tester,
  ) async {
    final repository = _FakeRepository([
      _report(
        'p1',
        kind: GroupReportKind.post,
        postId: 'post-1',
        reporter: 'Tai Lang',
        description: 'Spam',
        content: 'First post',
      ),
      _report(
        'p2',
        kind: GroupReportKind.post,
        postId: 'post-2',
        reporter: 'Pema',
        description: 'Spam',
        content: 'Second post',
      ),
      _report(
        'm1',
        kind: GroupReportKind.chatMessage,
        messageId: 'message-1',
        reporter: 'Shifu',
        description: 'Off-topic',
        content: 'A message',
      ),
    ]);
    await _pumpScreen(tester, repository);

    expect(find.text('First post'), findsOneWidget);
    expect(find.text('Second post'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('shows the member avatar for the reported user', (tester) async {
    final repository = _FakeRepository(
      [
        _report(
          'p1',
          kind: GroupReportKind.post,
          postId: 'post-1',
          reporter: 'Tai Lang',
          description: 'Spam',
          content: 'First post',
        ),
      ],
      members: const [
        GroupMember(
          userId: 'author',
          username: 'mei',
          fullname: 'Mei Lin',
          avatarUrl: 'https://example.com/mei.png',
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GroupReportsScreen(groupId: 'g1'),
        ),
      ),
    );
    for (
      var i = 0;
      i < 10 && find.byType(CachedNetworkImageWidget).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(find.byType(CachedNetworkImageWidget), findsOneWidget);
    expect(
      tester
          .widget<CachedNetworkImageWidget>(
            find.byType(CachedNetworkImageWidget),
          )
          .imageUrl,
      'https://example.com/mei.png',
    );
  });

  test('loads avatars for reporter and reported user ids', () async {
    final repository = _FakeRepository(
      const [],
      members: const [
        GroupMember(
          userId: 'author',
          username: 'mei',
          fullname: 'Mei Lin',
          avatarUrl: 'https://example.com/mei.png',
        ),
        GroupMember(
          userId: 'u-r1',
          username: 'tai',
          fullname: 'Tai Lang',
          avatarUrl: '  ',
        ),
      ],
    );
    final notifier = GroupReportAvatarsNotifier(
      repository: repository,
      groupId: 'g1',
    );
    await notifier.resolve({'author', 'u-r1', 'missing'});

    expect(notifier.state['author'], 'https://example.com/mei.png');
    expect(notifier.state.containsKey('u-r1'), isFalse);
    expect(notifier.state.containsKey('missing'), isFalse);
  });
}
