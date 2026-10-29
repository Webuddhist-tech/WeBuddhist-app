import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_accumulator_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_sections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _GuestAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _GuestAuth() : super(const AuthState(isLoggedIn: false, isGuest: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccumulatorRepository extends Fake
    implements GroupAccumulatorRepositoryInterface {
  @override
  GroupAccumulatorMembersPage? readStoredGroupAccumulatorMembers(
    String accumulatorId, {
    required GroupAccumulatorMemberSort sortBy,
  }) => null;

  @override
  Future<Either<Failure, GroupAccumulatorMembersPage>>
  getGroupAccumulatorMembers(
    String accumulatorId, {
    required int skip,
    required int limit,
    required GroupAccumulatorMemberSort sortBy,
  }) async => const Right(
    GroupAccumulatorMembersPage(
      members: [],
      memberCount: 0,
      total: 0,
      skip: 0,
      limit: 20,
    ),
  );
}

const _video = GroupAccumulatorLink(
  id: 'link-1',
  url: 'https://youtu.be/abcdefghijk',
  linkType: 'YOUTUBE',
);

GroupAccumulatorDetail _detail({List<GroupAccumulatorLink> links = const []}) {
  return GroupAccumulatorDetail(
    id: 'acc-1',
    presetAccumulatorId: 'preset-1',
    groupId: 'group-1',
    title: 'Green Tara',
    memberCount: 1,
    targetCount: 100,
    links: links,
  );
}

Widget _app(GroupAccumulatorDetail detail) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _GuestAuth()),
      groupAccumulatorRepositoryProvider.overrideWithValue(
        _FakeAccumulatorRepository(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: GroupAccumulatorSections(detail: detail, isDark: false),
      ),
    ),
  );
}

void main() {
  group('GroupAccumulatorSections', () {
    testWidgets('adds the Videos tab when a refresh brings videos', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_detail()));
      expect(find.text('Videos'), findsNothing);

      await tester.pumpWidget(_app(_detail(links: const [_video])));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Videos'), findsOneWidget);
    });

    testWidgets('drops the Videos tab and keeps a valid selection', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_detail(links: const [_video])));
      await tester.tap(find.text('Videos'));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.pumpWidget(_app(_detail()));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('Videos'), findsNothing);
      expect(find.text('About'), findsOneWidget);
    });
  });

  group('groupAccumulatorVideoId', () {
    GroupAccumulatorLink link(String url, {String? videoId}) =>
        GroupAccumulatorLink(
          id: 'l',
          url: url,
          linkType: 'YOUTUBE',
          videoId: videoId,
        );

    test('prefers the stored video_id', () {
      expect(
        groupAccumulatorVideoId(
          link(
            'https://www.youtube.com/live/zzzzzzzzzzz',
            videoId: 'abcdefghijk',
          ),
        ),
        'abcdefghijk',
      );
    });

    test('parses watch, youtu.be, and live URLs', () {
      expect(
        groupAccumulatorVideoId(
          link('https://www.youtube.com/watch?v=abcdefghijk&t=3'),
        ),
        'abcdefghijk',
      );
      expect(
        groupAccumulatorVideoId(link('https://youtu.be/abcdefghijk')),
        'abcdefghijk',
      );
      expect(
        groupAccumulatorVideoId(
          link('https://www.youtube.com/live/abcdefghijk?si=x'),
        ),
        'abcdefghijk',
      );
    });

    test('returns null for a non-YouTube URL', () {
      expect(groupAccumulatorVideoId(link('https://example.com/v')), isNull);
    });
  });
}
