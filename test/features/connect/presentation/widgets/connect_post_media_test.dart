import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_expandable_caption.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_media_grid.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_media_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

List<ConnectPostMedia> _media(int count) => [
  for (var i = 0; i < count; i++)
    ConnectPostMedia(
      id: 'm$i',
      mediaType: 'IMAGE',
      url: 'https://example.com/$i.jpg',
      width: 800,
      height: 600,
    ),
];

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(width: 320, child: child)),
    ),
  );
}

Finder _tile(int index) =>
    find.byKey(ValueKey('connect_post_media_tile_$index'));

void main() {
  group('ConnectPostMediaGrid', () {
    for (final (count, visible) in [(1, 1), (2, 2), (3, 3), (4, 4), (6, 4)]) {
      testWidgets('shows $visible tiles for $count photos', (tester) async {
        await _pump(
          tester,
          ConnectPostMediaGrid(
            media: _media(count),
            isDark: false,
            onTapImage: (_) {},
          ),
        );

        for (var i = 0; i < visible; i++) {
          expect(_tile(i), findsOneWidget);
        }
        expect(_tile(visible), findsNothing);
      });
    }

    testWidgets('marks hidden photos on the fourth tile', (tester) async {
      await _pump(
        tester,
        ConnectPostMediaGrid(
          media: _media(6),
          isDark: false,
          onTapImage: (_) {},
        ),
      );

      expect(
        find.descendant(of: _tile(3), matching: find.text('+2')),
        findsOneWidget,
      );
    });

    testWidgets('no hidden-count badge for exactly four photos', (
      tester,
    ) async {
      await _pump(
        tester,
        ConnectPostMediaGrid(
          media: _media(4),
          isDark: false,
          onTapImage: (_) {},
        ),
      );

      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('reports the tapped photo index', (tester) async {
      int? tapped;
      await _pump(
        tester,
        ConnectPostMediaGrid(
          media: _media(3),
          isDark: false,
          onTapImage: (index) => tapped = index,
        ),
      );

      await tester.tap(_tile(2));
      await tester.pumpAndSettle();
      expect(tapped, 2);
    });
  });

  group('ConnectExpandableCaption', () {
    const style = TextStyle(fontSize: 15, height: 1.45);
    final longText = List.filled(40, 'compassion').join(' ');

    testWidgets('short caption has no more link', (tester) async {
      await _pump(
        tester,
        ConnectExpandableCaption(
          text: 'Short caption',
          expanded: false,
          onToggle: () {},
          style: style,
        ),
      );

      expect(find.text('Short caption'), findsOneWidget);
      expect(find.textContaining('more'), findsNothing);
    });

    testWidgets('long caption collapses with more and toggles', (tester) async {
      var toggles = 0;
      await _pump(
        tester,
        ConnectExpandableCaption(
          text: longText,
          expanded: false,
          onToggle: () => toggles++,
          style: style,
        ),
      );

      final rich = tester.widget<RichText>(
        find.descendant(
          of: find.byType(ConnectExpandableCaption),
          matching: find.byType(RichText),
        ),
      );
      final shown = rich.text.toPlainText();
      expect(shown, endsWith('… more'));
      expect(shown.length, lessThan(longText.length));

      await tester.tap(find.byType(ConnectExpandableCaption));
      expect(toggles, 1);
    });

    testWidgets('expanded long caption shows full text and less', (
      tester,
    ) async {
      await _pump(
        tester,
        ConnectExpandableCaption(
          text: longText,
          expanded: true,
          onToggle: () {},
          style: style,
        ),
      );

      final rich = tester.widget<RichText>(
        find.descendant(
          of: find.byType(ConnectExpandableCaption),
          matching: find.byType(RichText),
        ),
      );
      expect(rich.text.toPlainText(), '$longText less');
    });
  });

  group('ConnectPostMediaViewer', () {
    testWidgets('opens at the tapped photo, counts pages and closes', (
      tester,
    ) async {
      await _pump(
        tester,
        Builder(
          builder:
              (context) => TextButton(
                onPressed:
                    () => ConnectPostMediaViewer.show(
                      context,
                      media: _media(3),
                      initialIndex: 1,
                      title: 'Sangha',
                    ),
                child: const Text('open'),
              ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('Sangha'), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(ConnectPostMediaViewer), findsNothing);
    });

    testWidgets('single photo hides the counter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ConnectPostMediaViewer(media: _media(1)),
        ),
      );

      expect(find.text('1 / 1'), findsNothing);
    });
  });
}
