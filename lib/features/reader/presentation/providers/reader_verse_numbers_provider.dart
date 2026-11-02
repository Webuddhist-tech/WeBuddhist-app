import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the reader page shows verse numbers, kept in local storage. On
/// until someone turns it off; the switch is in the reader's More settings.
class ReaderVerseNumbersNotifier extends StateNotifier<bool> {
  ReaderVerseNumbersNotifier({required LocalStorageService localStorageService})
    : _storage = localStorageService,
      super(true) {
    _ready = _load();
  }

  final LocalStorageService _storage;
  late final Future<void> _ready;

  /// Completes once the stored setting is in [state].
  Future<void> get ready => _ready;

  Future<void> _load() async {
    final shown = await _storage.get<bool>(StorageKeys.readerVerseNumbers);
    if (!mounted || shown == null) return;
    state = shown;
  }

  Future<void> setShown(bool shown) async {
    await _ready;
    state = shown;
    await _storage.set<bool>(StorageKeys.readerVerseNumbers, shown);
  }
}

final readerVerseNumbersProvider =
    StateNotifierProvider<ReaderVerseNumbersNotifier, bool>(
      (ref) => ReaderVerseNumbersNotifier(
        localStorageService: ref.read(localStorageServiceProvider),
      ),
    );
