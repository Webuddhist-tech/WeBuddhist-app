import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/domain/repositories/connect_repository.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_media_viewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConnectRepository extends Fake implements ConnectRepository {
  final List<String> calls = [];

  @override
  Future<Either<Failure, void>> likePost(String postId) async {
    calls.add('like:$postId');
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> unlikePost(String postId) async {
    calls.add('unlike:$postId');
    return const Right(null);
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
  Future<void> pumpCardAndOpenViewer(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _SignedInAuth()),
          connectRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ValueListenableBuilder<ConnectPost?>(
                valueListenable: shownPost,
                builder:
                    (context, post, _) =>
                        post == null
                            ? const SizedBox.shrink()
                            : ConnectPostCard(post: post),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('connect_post_media_tile_0')));
    // The tap waits out the double-tap-to-like window.
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(find.byType(ConnectPostMediaViewer), findsOneWidget);
  }

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
}
