import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The reader background the person picked, kept in local storage. One
/// pick for every reader; Rice Paper until they choose.
class ReaderBackgroundNotifier extends StateNotifier<ReaderBackground> {
  ReaderBackgroundNotifier({required LocalStorageService localStorageService})
    : _storage = localStorageService,
      super(ReaderBackground.defaultBackground) {
    _ready = _load();
  }

  final LocalStorageService _storage;
  late final Future<void> _ready;

  /// Completes once the stored pick is in [state].
  Future<void> get ready => _ready;

  Future<void> _load() async {
    final name = await _storage.get<String>(StorageKeys.readerBackground);
    if (!mounted) return;
    state = ReaderBackground.fromName(name);
  }

  Future<void> select(ReaderBackground background) async {
    await _ready;
    state = background;
    await _storage.set<String>(StorageKeys.readerBackground, background.name);
  }
}

final readerBackgroundProvider =
    StateNotifierProvider<ReaderBackgroundNotifier, ReaderBackground>(
      (ref) => ReaderBackgroundNotifier(
        localStorageService: ref.read(localStorageServiceProvider),
      ),
    );
