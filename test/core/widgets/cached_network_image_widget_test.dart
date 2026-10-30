import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' show DefaultCacheManager;
import 'package:flutter_pecha/core/cache/app_image_cache_manager.dart';
import 'package:flutter_pecha/core/utils/network_image_utils.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_test/flutter_test.dart';

const _signed = 'https://cdn.example.com/a.png?X-Amz-Signature=1';

Widget _host(Widget child) => MaterialApp(home: Center(child: child));

void main() {
  testWidgets('uses the shared store, a stable key and no spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CachedNetworkImageWidget(imageUrl: _signed, width: 100, height: 50),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    final dpr = tester.view.devicePixelRatio;
    expect(image.cacheKey, stableNetworkImageCacheKey(_signed));
    expect(image.cacheKey, isNot(contains('Signature')));
    expect(image.cacheManager, same(appImageCacheManager));
    expect(appImageCacheManager.config.cacheKey, DefaultCacheManager.key);
    expect(appImageCacheManager.config.maxNrOfCacheObjects, 1500);
    expect(appImageCacheManager.config.stalePeriod, const Duration(days: 60));
    expect(image.useOldImageOnUrlChange, isTrue);
    expect(image.fadeOutDuration, image.fadeInDuration);
    expect(image.memCacheWidth, (100 * dpr).round());
    expect(image.memCacheHeight, isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('derives the decode bound from layout when none is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 240,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImageWidget(
              imageUrl: _signed,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, (240 * tester.view.devicePixelRatio).round());
    expect(image.memCacheHeight, isNull);
  });

  testWidgets('custom placeholder is used while loading', (tester) async {
    await tester.pumpWidget(
      _host(
        const CachedNetworkImageWidget(
          imageUrl: _signed,
          width: 40,
          height: 40,
          placeholder: ColoredBox(color: Colors.red, key: Key('ph')),
        ),
      ),
    );
    expect(find.byKey(const Key('ph')), findsOneWidget);
  });

  testWidgets('asset paths render through Image.asset', (tester) async {
    await tester.pumpWidget(
      _host(
        const CachedNetworkImageWidget(
          imageUrl: 'assets/images/tag_cover/cover_image.jpg',
          width: 40,
          height: 40,
        ),
      ),
    );
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  test('networkImageKey ignores the signature but not the path', () {
    expect(
      networkImageKey(_signed),
      networkImageKey('https://cdn.example.com/a.png?X-Amz-Signature=2'),
    );
    expect(
      networkImageKey(_signed),
      isNot(networkImageKey('https://cdn.example.com/b.png')),
    );
    expect(networkImageKey(null), const ValueKey<String?>(null));
  });
}
