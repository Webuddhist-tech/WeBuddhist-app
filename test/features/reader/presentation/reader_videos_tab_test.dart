import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_actions/reader_verse_sheet.dart';
import 'package:flutter_pecha/features/texts/data/models/segment_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';

SegmentVideo _video(int n) => SegmentVideo(
  id: 'v$n',
  planId: 'p',
  url: 'https://youtu.be/v$n',
  videoId: 'v$n',
  title: 'Talk $n',
  displayOrder: n,
);

void main() {
  testWidgets('two videos to a row, each with a play mark and its title', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(FakeLocalStorage()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ReaderVideosTab(
              videos: [_video(1), _video(2), _video(3)],
              onOpened: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(AppAssets.play), findsNWidgets(3));
    final first = tester.getTopLeft(find.text('Talk 1'));
    final second = tester.getTopLeft(find.text('Talk 2'));
    final third = tester.getTopLeft(find.text('Talk 3'));
    // The first two side by side, 169 wide inside 20 margins with a 12 gap
    // (WF16); the third below.
    expect(first.dx, 20);
    expect(second.dy, first.dy);
    expect(second.dx - first.dx, closeTo((390 - 40 - 12) / 2 + 12, 1));
    expect(third.dx, first.dx);
    expect(third.dy, greaterThan(first.dy));
  });
}
