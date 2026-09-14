import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_embedded_host.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_embedded_panel.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorage implements LocalStorageService {
  final Map<String, Object?> _values = {};

  @override
  Future<void> setUserData(Map<String, dynamic> userData) async {}

  @override
  Future<Map<String, dynamic>?> getUserData() async => null;

  @override
  Future<void> clearUserData() async {}

  @override
  Future<T?> get<T>(String key) async => _values[key] as T?;

  @override
  Future<bool> set<T>(String key, T value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async => _values.remove(key) != null;

  @override
  Future<bool> clear() async {
    _values.clear();
    return true;
  }

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);
}

final _alpha = PlanTextItem.inlineText(content: 'Alpha body', title: 'Alpha');
final _beta = PlanTextItem.inlineText(content: 'Beta body', title: 'Beta');

NavigationContext _contextAt(int index) => NavigationContext(
  source: NavigationSource.plan,
  planTextItems: [_alpha, _beta],
  currentTextIndex: index,
);

Finder _richText(String text) => find.textContaining(text, findRichText: true);

void main() {
  group('PlanEmbeddedController', () {
    test('open completes with the close result; replace swaps in place', () {
      final controller = PlanEmbeddedController();
      expect(controller.isOpen, isFalse);

      final result = controller.open<int>(_alpha, _contextAt(0));
      expect(controller.isOpen, isTrue);
      expect(controller.item, _alpha);
      final generation = controller.generation;

      controller.replace(_beta, _contextAt(1));
      expect(controller.item, _beta);
      expect(controller.navigationContext?.currentTextIndex, 1);
      expect(controller.generation, generation + 1);

      controller.close(7);
      expect(controller.isOpen, isFalse);
      expect(controller.item, isNull);
      expect(result, completion(7));
    });

    test('close without a session is a no-op; dispose ends a pending one', () {
      final controller = PlanEmbeddedController();
      var notified = 0;
      controller.addListener(() => notified++);

      controller.close();
      expect(notified, 0);

      final result = controller.open<int>(_alpha, _contextAt(0));
      controller.dispose();
      expect(result, completion(isNull));
    });
  });

  testWidgets('PlanNavigator routes through an enclosing scope', (
    tester,
  ) async {
    final controller = PlanEmbeddedController();
    late BuildContext scoped;
    await tester.pumpWidget(
      MaterialApp(
        home: PlanEmbeddedScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              scoped = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final result = PlanNavigator.push<String>(scoped, _alpha, _contextAt(0));
    expect(controller.item, _alpha);

    PlanNavigator.replace(scoped, _beta, _contextAt(1));
    expect(controller.item, _beta);

    PlanNavigator.pop(scoped, 'done');
    expect(controller.isOpen, isFalse);
    expect(await result, 'done');
  });

  testWidgets('panel hosts the text screen; next swaps and X closes', (
    tester,
  ) async {
    final controller = PlanEmbeddedController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_FakeStorage()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PlanEmbeddedScope(
              controller: controller,
              child: PlanEmbeddedPanel(controller: controller),
            ),
          ),
        ),
      ),
    );

    final closed = controller.open<void>(_alpha, _contextAt(0));
    await tester.pumpAndSettle();

    expect(_richText('Alpha body'), findsOneWidget);
    expect(find.byIcon(AppAssets.x), findsOneWidget);
    expect(find.byIcon(AppAssets.readerFontSize), findsOneWidget);
    expect(find.byIcon(AppAssets.arrowLeft), findsNothing);

    await tester.tap(find.byIcon(AppAssets.caretRight).hitTestable());
    await tester.pumpAndSettle();

    expect(_richText('Beta body'), findsOneWidget);
    expect(_richText('Alpha body'), findsNothing);
    expect(controller.navigationContext?.currentTextIndex, 1);

    await tester.tap(find.byIcon(AppAssets.x));
    await tester.pumpAndSettle();

    expect(controller.isOpen, isFalse);
    expect(_richText('Beta body'), findsNothing);
    await closed;
  });
}
