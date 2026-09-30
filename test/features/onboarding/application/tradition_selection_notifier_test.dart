import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_selection_notifier.dart';
import 'package:flutter_pecha/features/onboarding/data/datasource/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemoteDatasource extends OnboardingRemoteDatasource {
  _FakeRemoteDatasource() : super(dio: Dio());

  final saved = <String>[];
  final failing = <String>{};

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
    if (failing.contains(request.traditionCode)) throw Exception('boom');
    saved.add(request.traditionCode);
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
}
