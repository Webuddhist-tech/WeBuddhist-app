import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/practice/data/models/session_selection.dart';
import 'package:flutter_pecha/features/practice/domain/entities/practice_items_tab.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_items_paginated_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_recitations_paginated_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_session_screen.dart';
import 'package:flutter_pecha/features/recitation/data/models/my_recitation_list_collection_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _IdlePracticeItems extends StateNotifier<PracticeItemsState>
    implements PracticeItemsNotifier {
  _IdlePracticeItems() : super(const PracticeItemsState(hasMore: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedRecitations extends StateNotifier<PracticeRecitationsState>
    implements PracticeRecitationsNotifier {
  _FixedRecitations(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _collection = MyRecitationListCollectionModel(
  type: 'RECITATION_COLLECTION',
  name: 'Morning prayers',
  collectionId: 'collection-1',
  itemCount: 3,
);

PracticeRecitationsState _collectionAndChant() => PracticeRecitationsState(
  collections: const [_collection],
  recitations: [RecitationModel(textId: 'text-1', title: 'Heart Sutra')],
  hasMore: false,
);

/// Opens the picker on the Chants tab and returns what it pops with.
Future<Future<SessionSelection?>> _openChantsTab(
  WidgetTester tester,
  PracticeRecitationsState state,
) async {
  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        practiceItemsPaginatedProvider(
          PracticeItemsTab.all,
        ).overrideWith((ref) => _IdlePracticeItems()),
        practiceRecitationsPaginatedProvider(
          'en',
        ).overrideWith((ref) => _FixedRecitations(state)),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(),
      ),
    ),
  );

  final selection = navigatorKey.currentState!.push<SessionSelection>(
    MaterialPageRoute(builder: (_) => const SelectSessionScreen()),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Chants'));
  await tester.pumpAndSettle();
  return selection;
}

void main() {
  testWidgets('lists the user\'s collections above the chants', (tester) async {
    await _openChantsTab(
      tester,
      _collectionAndChant(),
    );

    final collectionTop = tester.getTopLeft(find.text('Morning prayers')).dy;
    final chantTop = tester.getTopLeft(find.text('Heart Sutra')).dy;
    expect(collectionTop, lessThan(chantTop));
  });

  testWidgets('tapping a collection pops it as the selection', (tester) async {
    final selection = await _openChantsTab(
      tester,
      _collectionAndChant(),
    );

    await tester.tap(find.text('Morning prayers'));
    await tester.pumpAndSettle();

    final result = await selection;
    expect(result, isA<MyRecitationCollectionSessionSelection>());
    expect(
      (result! as MyRecitationCollectionSessionSelection)
          .collection
          .collectionId,
      'collection-1',
    );
  });

  testWidgets('tapping a chant after the collections pops that chant', (
    tester,
  ) async {
    final selection = await _openChantsTab(
      tester,
      _collectionAndChant(),
    );

    await tester.tap(find.text('Heart Sutra'));
    await tester.pumpAndSettle();

    final result = await selection;
    expect(result, isA<RecitationSessionSelection>());
    expect(
      (result! as RecitationSessionSelection).recitation.textId,
      'text-1',
    );
  });

  testWidgets('collections show even when there are no chants', (tester) async {
    await _openChantsTab(
      tester,
      const PracticeRecitationsState(
        collections: [_collection],
        hasMore: false,
      ),
    );

    expect(find.text('Morning prayers'), findsOneWidget);
    expect(find.text('No chants found'), findsNothing);
  });

  testWidgets('shows the empty message with no collections or chants', (
    tester,
  ) async {
    await _openChantsTab(
      tester,
      const PracticeRecitationsState(hasMore: false),
    );

    expect(find.text('No chants found'), findsOneWidget);
  });
}
