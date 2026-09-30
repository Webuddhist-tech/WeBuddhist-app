import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_selection_notifier.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemoteDatasource extends OnboardingRemoteDatasource {
  _FakeRemoteDatasource() : super(dio: Dio());

  /// Codes currently saved on the "server", in save order.
  final saved = <String>[];
  final deleted = <String>[];
  final failing = <String>{};

  /// When set, saves wait on it, so a test can act while a save is running.
  Completer<void>? saveGate;

  @override
  Future<List<TraditionPath>> fetchTraditionOnboardingPaths({
    required String language,
  }) async => const [
    TraditionPath(code: 'pali', title: 'Pali', description: ''),
    TraditionPath(code: 'chinese', title: 'Chinese', description: ''),
    TraditionPath(code: 'tibetan', title: 'Tibetan', description: ''),
  ];

  @override
  Future<void> saveUserTradition(SaveTraditionRequest request) async {
    await saveGate?.future;
    if (failing.contains(request.traditionCode)) throw Exception('boom');
    saved.add(request.traditionCode);
  }

  @override
  Future<List<UserTradition>> fetchUserTraditions({
    required String language,
  }) async => [
    for (final code in saved)
      UserTradition(id: 'id-$code', traditionCode: code, traditionName: code),
  ];

  @override
  Future<void> deleteUserTradition(String userTraditionId) async {
    final code = userTraditionId.substring('id-'.length);
    if (failing.contains(code)) throw Exception('boom');
    saved.remove(code);
    deleted.add(code);
  }
}

void main() {
  late _FakeRemoteDatasource datasource;
  late TraditionSelectionNotifier notifier;

  setUp(() async {
    datasource = _FakeRemoteDatasource();
    notifier = TraditionSelectionNotifier(
      remoteDatasource: datasource,
      language: 'en',
    );
    await Future<void>.delayed(Duration.zero); // let loadPaths finish
  });

  tearDown(() => notifier.dispose());

  test('toggling checks and unchecks paths independently', () {
    notifier.toggleTradition('pali');
    notifier.toggleTradition('tibetan');
    expect(notifier.state.selectedCodes, {'pali', 'tibetan'});
    expect(notifier.state.isAllSelected, isFalse);

    notifier.toggleTradition('pali');
    expect(notifier.state.selectedCodes, {'tibetan'});
    expect(notifier.state.hasSelection, isTrue);
  });

  test('show all checks every path, and clears them when all are checked', () {
    notifier.toggleTradition('pali');
    notifier.toggleAll();
    expect(notifier.state.selectedCodes, {'pali', 'chinese', 'tibetan'});
    expect(notifier.state.isAllSelected, isTrue);

    notifier.toggleAll();
    expect(notifier.state.selectedCodes, isEmpty);
    expect(notifier.state.hasSelection, isFalse);
  });

  test('show all reads as checked once every path is checked by hand', () {
    notifier.toggleTradition('pali');
    notifier.toggleTradition('chinese');
    notifier.toggleTradition('tibetan');
    expect(notifier.state.isAllSelected, isTrue);

    notifier.toggleTradition('chinese');
    expect(notifier.state.isAllSelected, isFalse);
  });

  test('submit saves every checked tradition', () async {
    notifier.toggleAll();
    expect(await notifier.submitSelection(), isTrue);
    expect(datasource.saved, unorderedEquals(['pali', 'chinese', 'tibetan']));
  });

  test('submit with nothing checked saves nothing', () async {
    expect(await notifier.submitSelection(), isFalse);
    expect(datasource.saved, isEmpty);
  });

  test('a retry after a partial failure only sends what failed', () async {
    notifier.toggleTradition('pali');
    notifier.toggleTradition('tibetan');
    datasource.failing.add('tibetan');

    expect(await notifier.submitSelection(), isFalse);
    expect(notifier.state.error, isNotNull);
    expect(datasource.saved, ['pali']);

    datasource.failing.clear();
    expect(await notifier.submitSelection(), isTrue);
    expect(datasource.saved, ['pali', 'tibetan']);
    expect(notifier.state.error, isNull);
  });

  test(
    'a retry removes a saved tradition the user has since unchecked',
    () async {
      notifier.toggleTradition('pali');
      notifier.toggleTradition('tibetan');
      datasource.failing.add('tibetan');
      expect(await notifier.submitSelection(), isFalse);
      expect(datasource.saved, ['pali']);

      datasource.failing.clear();
      notifier.toggleTradition('pali');
      expect(await notifier.submitSelection(), isTrue);
      expect(datasource.deleted, ['pali']);
      expect(datasource.saved, ['tibetan']);
    },
  );

  test('a failed removal fails the submit and is retried next time', () async {
    notifier.toggleTradition('pali');
    notifier.toggleTradition('tibetan');
    datasource.failing.add('tibetan');
    await notifier.submitSelection();

    notifier.toggleTradition('pali');
    datasource.failing
      ..clear()
      ..add('pali');
    expect(await notifier.submitSelection(), isFalse);
    expect(datasource.saved, ['pali', 'tibetan']);

    datasource.failing.clear();
    expect(await notifier.submitSelection(), isTrue);
    expect(datasource.saved, ['tibetan']);
  });

  test('choices cannot change while a save is in flight', () async {
    notifier.toggleTradition('pali');
    datasource.saveGate = Completer<void>();

    final submit = notifier.submitSelection();
    expect(notifier.state.isSaving, isTrue);

    notifier.toggleTradition('chinese');
    notifier.toggleTradition('pali');
    notifier.toggleAll();
    expect(notifier.state.selectedCodes, {'pali'});

    datasource.saveGate!.complete();
    expect(await submit, isTrue);
    expect(datasource.saved, ['pali']);
  });
}
