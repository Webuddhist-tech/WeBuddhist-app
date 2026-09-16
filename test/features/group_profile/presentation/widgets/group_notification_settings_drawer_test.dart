import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_notification_preferences.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/domain/repositories/group_profile_repository.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_notification_settings_drawer.dart';
import 'package:flutter_pecha/features/notifications/data/services/notification_service.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeRepository extends Fake implements GroupProfileRepositoryInterface {
  GroupNotificationPreferences server = const GroupNotificationPreferences(
    chat: false,
    content: true,
  );
  Failure? updateFailure;
  final List<({bool? chat, bool? content})> updates = [];

  /// When set, the read waits on it so a test can look at the loading state.
  Completer<void>? holdGet;

  @override
  Future<Either<Failure, GroupNotificationPreferences>>
  getGroupNotificationPreferences(String groupId) async {
    final hold = holdGet;
    if (hold != null) await hold.future;
    return Right(server);
  }

  @override
  Future<Either<Failure, GroupNotificationPreferences>>
  updateGroupNotificationPreferences(
    String groupId, {
    bool? chat,
    bool? content,
  }) async {
    updates.add((chat: chat, content: content));
    final failure = updateFailure;
    if (failure != null) return Left(failure);
    server = server.copyWith(chat: chat, content: content);
    return Right(server);
  }
}

/// Pins the master switch without touching SharedPreferences or the OS.
class _FakeNotificationNotifier extends NotificationNotifier {
  final bool masterOn;

  _FakeNotificationNotifier(Ref ref, {required this.masterOn})
    : super(NotificationService(), ref) {
    state = NotificationState(appMasterEnabled: masterOn);
  }

  @override
  Future<void> refreshStatus({bool initial = false}) async {}
}

const _profile = GroupProfile(
  id: 'grp-1',
  title: 'Lodhen Sangha',
  isPublic: true,
);

const _followKey = GroupFollowKey(
  groupId: 'grp-1',
  groupType: GroupType.community,
);

Future<void> _pump(
  WidgetTester tester, {
  required _FakeRepository repository,
  bool masterOn = true,
  // A held read keeps the spinners animating, so those tests pump one frame.
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        groupProfileRepositoryProvider.overrideWithValue(repository),
        groupProfileProvider.overrideWith(
          (ref, groupId) async => const Right(_profile),
        ),
        notificationProvider.overrideWith(
          (ref) => _FakeNotificationNotifier(ref, masterOn: masterOn),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: GroupNotificationSettingsDrawer(
            profile: _profile,
            followKey: _followKey,
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Switch _switchAfter(WidgetTester tester, String label) {
  final row = find.ancestor(of: find.text(label), matching: find.byType(Row));
  return tester.widget<Switch>(
    find.descendant(of: row.first, matching: find.byType(Switch)),
  );
}

void main() {
  testWidgets('holds the switches back until the stored values arrive', (
    tester,
  ) async {
    final repository = _FakeRepository()..holdGet = Completer<void>();
    await _pump(tester, repository: repository, settle: false);

    expect(find.byType(Switch), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

    await tester.tap(find.text('Group chat'));
    await tester.pump();
    expect(repository.updates, isEmpty);

    repository.holdGet!.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(_switchAfter(tester, 'Group chat').value, isFalse);
    expect(_switchAfter(tester, 'Group content').value, isTrue);
  });

  testWidgets('shows both toggles from the stored values', (tester) async {
    await _pump(tester, repository: _FakeRepository());

    expect(find.text('Notifications'), findsOneWidget);
    expect(_switchAfter(tester, 'Group chat').value, isFalse);
    expect(_switchAfter(tester, 'Group content').value, isTrue);
    expect(find.text('Leave group'), findsOneWidget);
  });

  testWidgets('tapping a row flips it and saves only that flag', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository: repository);

    await tester.tap(find.text('Group chat'));
    await tester.pumpAndSettle();

    expect(_switchAfter(tester, 'Group chat').value, isTrue);
    expect(_switchAfter(tester, 'Group content').value, isTrue);
    expect(repository.updates, [(chat: true, content: null)]);
  });

  testWidgets('a failed save reverts the toggle and explains', (tester) async {
    final repository =
        _FakeRepository()..updateFailure = const NetworkFailure('offline');
    await _pump(tester, repository: repository);

    await tester.tap(find.text('Group content'));
    await tester.pumpAndSettle();

    expect(_switchAfter(tester, 'Group content').value, isTrue);
    expect(
      find.text("Couldn't update notification settings. Try again."),
      findsOneWidget,
    );
  });

  testWidgets('master off greys out both toggles and offers the way to '
      'settings', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository: repository, masterOn: false);

    expect(_switchAfter(tester, 'Group chat').onChanged, isNull);
    expect(_switchAfter(tester, 'Group content').onChanged, isNull);
    expect(_switchAfter(tester, 'Group content').value, isFalse);
    expect(
      find.text('Notifications are turned off for the app.'),
      findsOneWidget,
    );
    expect(find.text('Turn on'), findsOneWidget);

    await tester.tap(find.text('Group content'));
    await tester.pumpAndSettle();
    expect(repository.updates, isEmpty);
  });

  testWidgets('"Turn on" closes the sheet and hands navigation back', (
    tester,
  ) async {
    GroupNotificationSheetResult? result;
    late BuildContext pageContext;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupProfileRepositoryProvider.overrideWithValue(_FakeRepository()),
          groupProfileProvider.overrideWith(
            (ref, groupId) async => const Right(_profile),
          ),
          notificationProvider.overrideWith(
            (ref) => _FakeNotificationNotifier(ref, masterOn: false),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                pageContext = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );

    final opened = GroupNotificationSettingsDrawer.show(
      pageContext,
      _profile,
      followKey: _followKey,
    ).then((value) => result = value);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    await opened;

    expect(result, GroupNotificationSheetResult.openNotificationSettings);
    expect(find.byType(GroupNotificationSettingsDrawer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leave group asks first and cancel keeps the membership', (
    tester,
  ) async {
    await _pump(tester, repository: _FakeRepository());

    await tester.tap(find.text('Leave group'));
    await tester.pumpAndSettle();

    expect(find.text('Leave group?'), findsOneWidget);
    expect(
      find.text("You'll stop getting messages and updates from this group."),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Leave group?'), findsNothing);
    expect(find.byType(GroupNotificationSettingsDrawer), findsOneWidget);
  });
}
