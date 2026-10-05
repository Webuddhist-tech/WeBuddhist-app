import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_member.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_members_page.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_post_permission.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_post_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_members_tab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const _members = [
  GroupMember(userId: 'u1', username: 'pema', fullname: 'Pema', role: 'OWNER'),
  GroupMember(userId: 'u2', username: 'dawa', fullname: 'Dawa', role: 'ADMIN'),
  GroupMember(userId: 'u3', username: 'karma', fullname: 'Karma'),
];

class _FakeRepository extends Fake implements GroupProfileRepositoryInterface {
  @override
  Future<Either<Failure, GroupMembersPage>> getGroupMembers(
    String groupId, {
    required int skip,
    required int limit,
  }) async {
    return Right(
      GroupMembersPage(
        members: _members,
        skip: skip,
        limit: limit,
        totalMembers: _members.length,
      ),
    );
  }
}

class _NoUser extends StateNotifier<UserState> implements UserNotifier {
  _NoUser() : super(const UserState.initial());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, {String? viewerRole}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        groupProfileRepositoryProvider.overrideWithValue(_FakeRepository()),
        userProvider.overrideWith((ref) => _NoUser()),
        groupMyPermissionProvider.overrideWith(
          (ref, groupId) async =>
              GroupPostPermission(groupId: groupId, role: viewerRole),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder:
                (context, _) => [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                    sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
                  ),
                ],
            body: const GroupProfileMembersTab(
              groupId: 'g1',
              groupType: GroupType.community,
              isDark: false,
              pageStorageKey: 'members',
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _inRow(String name, Finder matching) {
  final row = find.ancestor(of: find.text(name), matching: find.byType(Row));
  return find.descendant(of: row.first, matching: matching);
}

void main() {
  testWidgets('owner and admin rows show their own badge', (tester) async {
    await _pump(tester);

    expect(_inRow('Pema', find.text('Owner')), findsOneWidget);
    expect(_inRow('Pema', find.text('Admin')), findsNothing);
    expect(_inRow('Dawa', find.text('Admin')), findsOneWidget);
    expect(_inRow('Dawa', find.text('Owner')), findsNothing);
    expect(_inRow('Karma', find.text('Owner')), findsNothing);
    expect(_inRow('Karma', find.text('Admin')), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('an admin gets a remove button on regular members only', (
    tester,
  ) async {
    await _pump(tester, viewerRole: 'ADMIN');

    expect(find.byTooltip('Remove Karma'), findsOneWidget);
    expect(_inRow('Karma', find.byIcon(Icons.close)), findsOneWidget);
    expect(_inRow('Pema', find.byIcon(Icons.close)), findsNothing);
    expect(_inRow('Dawa', find.byIcon(Icons.close)), findsNothing);
    expect(_inRow('Pema', find.text('Owner')), findsOneWidget);
    expect(_inRow('Dawa', find.text('Admin')), findsOneWidget);
  });
}
