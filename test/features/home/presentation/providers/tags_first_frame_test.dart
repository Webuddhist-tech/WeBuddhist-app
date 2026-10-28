import 'dart:async';

import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/home_local_datasource.dart';
import 'package:flutter_pecha/features/home/domain/repositories/home_repository.dart';
import 'package:flutter_pecha/features/home/presentation/providers/tags_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocal extends HomeLocalDatasource {
  List<String>? tags;

  @override
  List<String>? readTags(String language) => tags;
}

class _FakeTags extends Fake implements TagsRepositoryInterface {
  final updates = StreamController<Either<Failure, List<String>>>();

  @override
  Stream<Either<Failure, List<String>>> watchTags({required String language}) =>
      updates.stream;
}

void main() {
  test('stored tags are the state on the very first read', () async {
    final local = _FakeLocal()..tags = ['Tara'];
    final tags = _FakeTags();
    addTearDown(tags.updates.close);
    final container = ProviderContainer(
      overrides: [
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        homeLocalDatasourceProvider.overrideWithValue(local),
        tagsDomainRepositoryProvider.overrideWithValue(tags),
      ],
    );
    addTearDown(container.dispose);
    container.listen(tagsFutureProvider, (_, __) {});

    final first = container.read(tagsFutureProvider);
    expect(first.isLoading, isFalse);
    expect(first.requireValue.getRight().toNullable(), ['Tara']);

    tags.updates.add(const Right(['Tara', 'Medicine Buddha']));
    await pumpEventQueue();
    expect(
      container.read(tagsFutureProvider).requireValue.getRight().toNullable(),
      ['Tara', 'Medicine Buddha'],
    );
  });

  test('nothing stored loads until the repository answers', () async {
    final tags = _FakeTags();
    addTearDown(tags.updates.close);
    final container = ProviderContainer(
      overrides: [
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        homeLocalDatasourceProvider.overrideWithValue(_FakeLocal()),
        tagsDomainRepositoryProvider.overrideWithValue(tags),
      ],
    );
    addTearDown(container.dispose);
    container.listen(tagsFutureProvider, (_, __) {});
    expect(container.read(tagsFutureProvider).isLoading, isTrue);

    tags.updates.add(const Right(['Tara']));
    await pumpEventQueue();
    expect(container.read(tagsFutureProvider).hasValue, isTrue);
  });
}
