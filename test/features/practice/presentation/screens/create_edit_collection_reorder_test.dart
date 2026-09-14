import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';
import 'package:flutter_pecha/features/practice/data/repositories/my_recitation_collections_repository.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/my_recitation_collections_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_recitations_paginated_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/create_edit_collection_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedLanguage extends StateNotifier<String>
    implements PracticeRecitationsLanguageNotifier {
  _FixedLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Saves the metadata, and on reload returns [reloaded] as the server's rows.
class _FakeRepository implements MyRecitationCollectionsRepository {
  _FakeRepository({required this.reloaded});

  final MyRecitationCollectionDetailModel reloaded;
  final Map<String, double> patches = {};
  int detailLoads = 0;

  @override
  Future<Either<Failure, MyRecitationCollectionModel>> updateCollection({
    required String collectionId,
    required String name,
    String? imgUrl,
  }) async => Right(MyRecitationCollectionModel(id: collectionId, name: name));

  @override
  Future<Either<Failure, MyRecitationCollectionDetailModel>>
  getCollectionDetail(String collectionId) async {
    detailLoads++;
    return Right(reloaded);
  }

  @override
  Future<Either<Failure, MyRecitationCollectionItemModel>>
  updateCollectionItemDisplayOrder({
    required String collectionId,
    required String itemId,
    required double displayOrder,
  }) async {
    patches[itemId] = displayOrder;
    final item = reloaded.items.firstWhere((item) => item.id == itemId);
    return Right(
      MyRecitationCollectionItemModel(
        id: itemId,
        textId: item.textId,
        displayOrder: displayOrder,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MyRecitationCollectionDetailModel _collection({required String chantBItemId}) {
  return MyRecitationCollectionDetailModel(
    id: 'collection-1',
    name: 'Morning chants',
    items: [
      const MyRecitationCollectionItemModel(
        id: 'item-a',
        textId: 'text-a',
        title: 'Chant A',
        displayOrder: 1,
      ),
      MyRecitationCollectionItemModel(
        id: chantBItemId,
        textId: 'text-b',
        title: 'Chant B',
        displayOrder: 2,
      ),
    ],
  );
}

/// Opens the edit screen for a collection whose chant B has no item id (as
/// when the add response omits it), drags B above A, and taps Save.
/// Returns true once the screen has popped.
Future<bool> _dragBAboveAAndSave(
  WidgetTester tester,
  _FakeRepository repository,
) async {
  await tester.binding.setSurfaceSize(const Size(800, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  var popped = false;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        practiceRecitationsLanguageProvider.overrideWith(
          (ref) => _FixedLanguage(),
        ),
        myRecitationCollectionsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder:
                            (_) => CreateEditCollectionScreen.edit(
                              collection: _collection(chantBItemId: ''),
                            ),
                      ),
                    );
                    popped = true;
                  },
                  child: const Text('open'),
                ),
              ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  tester
      .widget<ReorderableListView>(find.byType(ReorderableListView))
      .onReorder(1, 0);
  await tester.pump();

  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  return popped;
}

void main() {
  group('CreateEditCollectionScreen save with a chant missing its item id', () {
    testWidgets('reloads the collection and saves the arranged order', (
      tester,
    ) async {
      final repository = _FakeRepository(
        reloaded: _collection(chantBItemId: 'item-b'),
      );

      final popped = await _dragBAboveAAndSave(tester, repository);

      expect(repository.detailLoads, 1);
      expect(repository.patches, {'item-a': 3.0});
      expect(popped, isTrue);
    });

    testWidgets('fails the save when the reload still lacks the chant', (
      tester,
    ) async {
      final repository = _FakeRepository(
        reloaded: _collection(chantBItemId: ''),
      );

      final popped = await _dragBAboveAAndSave(tester, repository);

      expect(popped, isFalse, reason: 'must not report a successful save');
      expect(repository.patches, isEmpty);
      expect(
        find.text('Something went wrong. Please try again'),
        findsOneWidget,
      );

      // Let the snackbar's timer run out before the test ends.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}
