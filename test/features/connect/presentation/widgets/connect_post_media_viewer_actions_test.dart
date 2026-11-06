import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/no_op_analytics_service.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/domain/repositories/connect_repository.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_analytics.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_link_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_media_viewer.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/analytics/recording_analytics_service.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConnectRepository extends Fake implements ConnectRepository {
  final List<String> calls = [];

  /// When set, requests stay in flight until this completes.
  Completer<Either<Failure, void>>? gate;

  @override
  Future<Either<Failure, void>> likePost(String postId) async {
    calls.add('like:$postId');
    return gate?.future ?? const Right(null);
  }

  @override
  Future<Either<Failure, void>> unlikePost(String postId) async {
    calls.add('unlike:$postId');
    return gate?.future ?? const Right(null);
  }
}

ConnectPost _post(String id, {bool likedByMe = false, int likeCount = 0}) {
  return ConnectPost(
    id: id,
    groupId: 'group-1',
    caption: '',
    status: 'PUBLISHED',
    creatorName: '',
    groupName: 'Group of $id',
    likedByMe: likedByMe,
    likeCount: likeCount,
    media: [
      ConnectPostMedia(
        id: 'media-$id',
        mediaType: 'IMAGE',
        url: 'https://example.com/$id.jpg',
        width: 800,
        height: 200,
      ),
    ],
  );
}

Finder get _viewerHeart => find.descendant(
  of: find.byType(ConnectPostMediaViewerActions),
  matching: find.byIcon(AppAssets.heart),
);

Finder get _viewerFilledHeart => find.descendant(
  of: find.byType(ConnectPostMediaViewerActions),
  matching: find.byIcon(AppAssets.heartFill),
);

void main() {
  late _FakeConnectRepository repository;
  late ValueNotifier<ConnectPost?> shownPost;

  setUp(() {
    repository = _FakeConnectRepository();
    shownPost = ValueNotifier(_post('a'));
    addTearDown(shownPost.dispose);
  });

  /// No key on the card, like the feed, so a new post reuses its state.
  Future<void> pumpCard(
    WidgetTester tester, {
    ConnectPostPlacement? placement,
    AnalyticsService analytics = const NoOpAnalyticsService(),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(analytics),
          // A link card would otherwise fetch its preview over the network.
          chatLinkPreviewProvider.overrideWith((ref, url) async => null),
          authProvider.overrideWith((ref) => _SignedInAuth()),
          connectRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              // A feed screen holds the tracker for as long as a visit lasts.
              if (placement != null) {
                ref.watch(connectPostViewTrackerProvider(placement.surface));
              }
              return child!;
            },
            child: Scaffold(
              body: SingleChildScrollView(
                child: ValueListenableBuilder<ConnectPost?>(
                  valueListenable: shownPost,
                  builder:
                      (context, post, _) =>
                          post == null
                              ? const SizedBox.shrink()
                              : ConnectPostCard(
                                post: post,
                                placement: placement,
                              ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Fixed pumps: a pending like's spinner never lets pumpAndSettle finish.
  Future<void> openViewer(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('connect_post_media_tile_0')));
    // The tap waits out the double-tap-to-like window.
    await tester.pump(kDoubleTapTimeout);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ConnectPostMediaViewer), findsOneWidget);
  }

  Future<void> pumpCardAndOpenViewer(WidgetTester tester) async {
    await pumpCard(tester);
    await openViewer(tester);
  }

  Finder cardIcon(IconData icon) => find.descendant(
    of: find.byType(ConnectPostCard),
    matching: find.byIcon(icon),
  );

  testWidgets('like stays on the opened post when the card is reused', (
    tester,
  ) async {
    await pumpCardAndOpenViewer(tester);

    shownPost.value = _post('b');
    await tester.pump();

    await tester.tap(_viewerHeart);
    await tester.pumpAndSettle();

    expect(repository.calls, ['like:a']);
    expect(_viewerFilledHeart, findsOneWidget);
  });

  testWidgets('buttons keep working after the card is disposed', (
    tester,
  ) async {
    await pumpCardAndOpenViewer(tester);

    shownPost.value = null;
    await tester.pump();
    expect(find.byType(ConnectPostCard), findsNothing);

    await tester.tap(_viewerHeart);
    await tester.pumpAndSettle();
    await tester.tap(_viewerFilledHeart);
    await tester.pumpAndSettle();

    expect(repository.calls, ['like:a', 'unlike:a']);
    expect(_viewerHeart, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card drops its own like state after a viewer change', (
    tester,
  ) async {
    await pumpCardAndOpenViewer(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    // Liked on the card, which keeps a local override.
    await tester.tap(
      find.descendant(
        of: find.byType(ConnectPostCard),
        matching: find.byIcon(AppAssets.heart),
      ),
    );
    await tester.pumpAndSettle();
    shownPost.value = _post('a', likedByMe: true, likeCount: 1);
    await tester.pump();

    // Unliked in the viewer, and the feed carries the result to the card.
    await tester.tap(find.byKey(const ValueKey('connect_post_media_tile_0')));
    // The tap waits out the double-tap-to-like window.
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    await tester.tap(_viewerFilledHeart);
    await tester.pumpAndSettle();
    shownPost.value = _post('a');
    await tester.pump();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(repository.calls, ['like:a', 'unlike:a']);
    expect(
      find.descendant(
        of: find.byType(ConnectPostCard),
        matching: find.byIcon(AppAssets.heartFill),
      ),
      findsNothing,
    );
  });

  testWidgets('viewer waits for a like the card still has in flight', (
    tester,
  ) async {
    final gate = repository.gate = Completer();
    await pumpCard(tester);
    await tester.tap(cardIcon(AppAssets.heart));
    await tester.pump();

    await openViewer(tester);
    expect(_viewerFilledHeart, findsOneWidget);

    await tester.tap(_viewerFilledHeart, warnIfMissed: false);
    await tester.pump();
    expect(repository.calls, ['like:a']);

    repository.gate = null;
    gate.complete(const Right(null));
    await tester.pumpAndSettle();

    await tester.tap(_viewerFilledHeart);
    await tester.pumpAndSettle();
    expect(repository.calls, ['like:a', 'unlike:a']);
    expect(_viewerHeart, findsOneWidget);
  });

  testWidgets('viewer rolls back when the card request fails', (tester) async {
    final gate = repository.gate = Completer();
    await pumpCard(tester);
    await tester.tap(cardIcon(AppAssets.heart));
    await tester.pump();

    await openViewer(tester);
    final viewerCount = find.descendant(
      of: find.byType(ConnectPostMediaViewerActions),
      matching: find.text('1'),
    );
    expect(viewerCount, findsOneWidget);

    gate.complete(const Left(ServerFailure('nope')));
    await tester.pumpAndSettle();

    expect(_viewerHeart, findsOneWidget);
    expect(_viewerFilledHeart, findsNothing);
    expect(viewerCount, findsNothing);
  });

  testWidgets('card waits for a like the closed viewer has in flight', (
    tester,
  ) async {
    final gate = repository.gate = Completer();
    await pumpCardAndOpenViewer(tester);
    await tester.tap(_viewerHeart);
    await tester.pump();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(cardIcon(AppAssets.heart));
    await tester.pump();
    expect(repository.calls, ['like:a']);

    gate.complete(const Right(null));
    await tester.pumpAndSettle();
  });

  group('post tracking', () {
    const placement = ConnectPostPlacement(
      surface: ConnectPostSurface.communityFeed,
      position: 3,
    );
    late RecordingAnalyticsService analytics;

    setUp(() {
      analytics = RecordingAnalyticsService();
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
    });

    tearDown(() {
      VisibilityDetectorController.instance.updateInterval = const Duration(
        milliseconds: 500,
      );
    });

    testWidgets('a card on screen for a second counts once per visit', (
      tester,
    ) async {
      await pumpCard(tester, placement: placement, analytics: analytics);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 900));
      expect(analytics.eventNames, isEmpty);

      await tester.pump(const Duration(milliseconds: 200));
      expect(analytics.eventNames, [AnalyticsEvents.postViewed]);
      expect(analytics.events.single.properties, {
        'post_id': 'a',
        'group_id': 'group-1',
        'has_media': true,
        'link_type': null,
        'position': 3,
        'surface': 'community_feed',
      });

      // A list recycles its cards; coming back in the same visit is no new view.
      shownPost.value = null;
      await tester.pump();
      shownPost.value = _post('a');
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(analytics.eventNames, [AnalyticsEvents.postViewed]);
    });

    testWidgets('a card gone within a second does not count', (tester) async {
      await pumpCard(tester, placement: placement, analytics: analytics);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      shownPost.value = null;
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(analytics.eventNames, isEmpty);
    });

    testWidgets('a card with no placement is not tracked', (tester) async {
      await pumpCard(tester, analytics: analytics);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(analytics.eventNames, isEmpty);
    });

    testWidgets('opening an image counts as opening the post', (tester) async {
      await pumpCard(tester, placement: placement, analytics: analytics);
      await openViewer(tester);

      expect(analytics.eventNames, contains(AnalyticsEvents.postOpened));
    });

    group('a link', () {
      const urlLauncher = MethodChannel('plugins.flutter.io/url_launcher');

      Future<void> tapLink(WidgetTester tester) async {
        shownPost.value = _post('a').copyWith(
          links: const [
            ConnectPostLink(
              id: 'l1',
              type: 'WEBSITE',
              url: 'https://example.com/private-path',
            ),
          ],
        );
        await pumpCard(tester, placement: placement, analytics: analytics);
        await tester.pump();
        await tester.ensureVisible(find.byType(ConnectPostLinkCard));
        await tester.tap(find.byType(ConnectPostLinkCard));
        await tester.pump();
      }

      void answerLaunchesWith(WidgetTester tester, bool opened) {
        final messenger = tester.binding.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(urlLauncher, (_) async => opened);
        addTearDown(
          () => messenger.setMockMethodCallHandler(urlLauncher, null),
        );
      }

      testWidgets('that opens is counted, without its URL', (tester) async {
        answerLaunchesWith(tester, true);

        await tapLink(tester);

        final opened = analytics.events.singleWhere(
          (event) => event.name == AnalyticsEvents.postLinkOpened,
        );
        expect(opened.properties['link_type'], 'website');
        expect(
          opened.properties.values,
          isNot(contains('https://example.com/private-path')),
        );
      });

      testWidgets('that fails to open is not counted', (tester) async {
        answerLaunchesWith(tester, false);

        await tapLink(tester);

        expect(
          analytics.eventNames,
          isNot(contains(AnalyticsEvents.postLinkOpened)),
        );
      });
    });
  });
}
