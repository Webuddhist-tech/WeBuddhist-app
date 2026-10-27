import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
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
  int getCalls = 0;

  /// When set, the read waits on it so a test can look at the loading state.
  Completer<void>? holdGet;
  Failure? getFailure;

  @override
  Future<Either<Failure, GroupNotificationPreferences>>
  getGroupNotificationPreferences(String groupId) async {
    getCalls++;
    final hold = holdGet;
    if (hold != null) await hold.future;
    final failure = getFailure;
    if (failure != null) return Left(failure);
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

/// Pins the master switch and the OS permission without touching
/// SharedPreferences or the OS.
class _FakeNotificationNotifier extends NotificationNotifier {
  _FakeNotificationNotifier(
    Ref ref, {
    required bool masterOn,
    required bool permission,
  }) : super(NotificationService(), ref) {
    state = NotificationState(
      appMasterEnabled: masterOn,
      hasSystemPermission: permission,
    );
  }

  @override
  Future<void> refreshStatus({bool initial = false}) async {}
}

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The bundled English strings the sheet renders in these tests, so copy
/// changes don't break the assertions.
final _en = lookupAppLocalizations(const Locale('en'));

const _profile = GroupProfile(
  id: 'grp-1',
  title: 'Lodhen Sangha',
  isPublic: true,
);

const _page = GroupProfile(
  id: 'page-1',
  title: 'Lodhen Page',
  isPublic: true,
  groupType: GroupType.page,
);

const _followKey = GroupFollowKey(
  groupId: 'grp-1',
  groupType: GroupType.community,
);

List<Override> _overrides(
  _FakeRepository repository, {
  bool masterOn = true,
  bool permission = true,
}) {
  return [
    groupProfileRepositoryProvider.overrideWithValue(repository),
    groupProfileProvider.overrideWith(
      (ref, groupId) => Stream.value(const Right(_profile)),
    ),
    notificationProvider.overrideWith(
      (ref) => _FakeNotificationNotifier(
        ref,
        masterOn: masterOn,
        permission: permission,
      ),
    ),
    authProvider.overrideWith((ref) => _SignedInAuth()),
  ];
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeRepository repository,
  bool masterOn = true,
  bool permission = true,
  bool showNotificationSettings = true,
  // A held read keeps the spinners animating, so those tests pump one frame.
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(
        repository,
        masterOn: masterOn,
        permission: permission,
      ),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GroupNotificationSettingsDrawer(
            profile: _profile,
            followKey: _followKey,
            showNotificationSettings: showNotificationSettings,
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

/// Pumps an empty page and hands back its context, for tests that open the
/// sheet the way the space page does.
Future<BuildContext> _pumpPage(
  WidgetTester tester, {
  required _FakeRepository repository,
  bool masterOn = true,
}) async {
  late BuildContext pageContext;
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(repository, masterOn: masterOn),
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
  return pageContext;
}

Switch _switchAfter(WidgetTester tester, String label) {
  final row = find.ancestor(of: find.text(label), matching: find.byType(Row));
  return tester.widget<Switch>(
    find.descendant(of: row.first, matching: find.byType(Switch)),
  );
}

void main() {
  final chat = _en.group_notifications_chat;
  final content = _en.group_notifications_content;
  final leave = _en.group_leave_space;

  testWidgets('holds the switches back until the stored values arrive', (
    tester,
  ) async {
    final repository = _FakeRepository()..holdGet = Completer<void>();
    await _pump(tester, repository: repository, settle: false);

    expect(find.byType(Switch), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

    await tester.tap(find.text(chat));
    await tester.pump();
    expect(repository.updates, isEmpty);

    repository.holdGet!.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(_switchAfter(tester, chat).value, isFalse);
    expect(_switchAfter(tester, content).value, isTrue);
  });

  testWidgets('a failed load shows an error with retry, not defaults', (
    tester,
  ) async {
    final repository =
        _FakeRepository()..getFailure = const NetworkFailure('offline');
    await _pump(tester, repository: repository);

    expect(find.byType(Switch), findsNothing);
    expect(find.text(_en.group_notifications_load_failed), findsOneWidget);
    expect(find.text(leave), findsOneWidget);

    repository.getFailure = null;
    await tester.tap(find.text(_en.retry));
    await tester.pumpAndSettle();

    expect(find.text(_en.group_notifications_load_failed), findsNothing);
    expect(_switchAfter(tester, chat).value, isFalse);
    expect(_switchAfter(tester, content).value, isTrue);
  });

  testWidgets('shows both toggles from the stored values', (tester) async {
    await _pump(tester, repository: _FakeRepository());

    expect(find.text(_en.group_notifications_title), findsOneWidget);
    expect(_switchAfter(tester, chat).value, isFalse);
    expect(_switchAfter(tester, content).value, isTrue);
    expect(find.text(leave), findsOneWidget);
  });

  testWidgets('tapping a row flips it and saves only that flag', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository: repository);

    await tester.tap(find.text(chat));
    await tester.pumpAndSettle();

    expect(_switchAfter(tester, chat).value, isTrue);
    expect(_switchAfter(tester, content).value, isTrue);
    expect(repository.updates, [(chat: true, content: null)]);
  });

  testWidgets('a failed save reverts the toggle and explains', (tester) async {
    final repository =
        _FakeRepository()..updateFailure = const NetworkFailure('offline');
    await _pump(tester, repository: repository);

    await tester.tap(find.text(content));
    await tester.pumpAndSettle();

    expect(_switchAfter(tester, content).value, isTrue);
    expect(find.text(_en.group_notifications_update_failed), findsOneWidget);
  });

  testWidgets('master off greys out both toggles and offers the way to '
      'settings', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository: repository, masterOn: false);

    expect(_switchAfter(tester, chat).onChanged, isNull);
    expect(_switchAfter(tester, content).onChanged, isNull);
    expect(_switchAfter(tester, content).value, isFalse);
    expect(find.text(_en.group_notifications_master_off), findsOneWidget);
    expect(find.text(_en.group_notifications_open_settings), findsOneWidget);

    await tester.tap(find.text(content));
    await tester.pumpAndSettle();
    expect(repository.updates, isEmpty);
  });

  testWidgets('missing OS permission greys them out too, like the '
      'notification settings screen', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository: repository, permission: false);

    expect(_switchAfter(tester, chat).onChanged, isNull);
    expect(_switchAfter(tester, content).value, isFalse);
    expect(find.text(_en.group_notifications_master_off), findsOneWidget);

    await tester.tap(find.text(chat));
    await tester.pumpAndSettle();
    expect(repository.updates, isEmpty);
  });

  testWidgets('"Turn on" closes the sheet and hands navigation back', (
    tester,
  ) async {
    GroupNotificationSheetResult? result;
    final pageContext = await _pumpPage(
      tester,
      repository: _FakeRepository(),
      masterOn: false,
    );

    final opened = GroupNotificationSettingsDrawer.show(
      pageContext,
      _profile,
      followKey: _followKey,
    ).then((value) => result = value);
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.group_notifications_open_settings));
    await tester.pumpAndSettle();
    await opened;

    expect(result, GroupNotificationSheetResult.openNotificationSettings);
    expect(find.byType(GroupNotificationSettingsDrawer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving asks first and cancel keeps the membership', (
    tester,
  ) async {
    await _pump(tester, repository: _FakeRepository());

    await tester.tap(find.text(leave));
    await tester.pumpAndSettle();

    expect(find.text(_en.group_leave_space_confirm_title), findsOneWidget);
    expect(find.text(_en.group_leave_confirm_message), findsOneWidget);

    await tester.tap(find.text(_en.cancel));
    await tester.pumpAndSettle();

    expect(find.text(_en.group_leave_space_confirm_title), findsNothing);
    expect(find.byType(GroupNotificationSettingsDrawer), findsOneWidget);
  });

  group('without notification settings (a Page)', () {
    testWidgets('shows only the leave row and never reads preferences', (
      tester,
    ) async {
      final repository = _FakeRepository();
      await _pump(
        tester,
        repository: repository,
        showNotificationSettings: false,
      );

      expect(find.text(leave), findsOneWidget);
      expect(find.text(_en.group_notifications_title), findsNothing);
      expect(find.text(chat), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(repository.getCalls, 0);
    });

    testWidgets('leaving still asks first', (tester) async {
      await _pump(
        tester,
        repository: _FakeRepository(),
        showNotificationSettings: false,
      );

      await tester.tap(find.text(leave));
      await tester.pumpAndSettle();
      expect(find.text(_en.group_leave_space_confirm_title), findsOneWidget);
    });

    testWidgets('openGroupMemberMenu opens a Page without switches', (
      tester,
    ) async {
      final repository = _FakeRepository();
      final pageContext = await _pumpPage(tester, repository: repository);

      unawaited(
        openGroupMemberMenu(
          pageContext,
          _page,
          followKey: const GroupFollowKey(
            groupId: 'page-1',
            groupType: GroupType.page,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(leave), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(repository.getCalls, 0);
    });

    testWidgets('openGroupMemberMenu opens a community with switches', (
      tester,
    ) async {
      final repository = _FakeRepository();
      final pageContext = await _pumpPage(tester, repository: repository);

      unawaited(
        openGroupMemberMenu(pageContext, _profile, followKey: _followKey),
      );
      await tester.pumpAndSettle();

      expect(find.text(chat), findsOneWidget);
      expect(find.text(leave), findsOneWidget);
      expect(repository.getCalls, 1);
    });
  });
}
