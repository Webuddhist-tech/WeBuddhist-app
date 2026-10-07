import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_remote_datasource.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_pecha/features/mala/presentation/services/mala_sound_player.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fakes for the collaborators every mala counter provider pulls in, so a test
/// can run the real notifiers without the network, audio or sync timers.

/// Storage that only knows the signed-in user's id.
class FakeUserStorage extends Fake implements LocalStorageService {
  FakeUserStorage(this.userId);

  final String userId;

  @override
  Future<T?> get<T>(String key) async =>
      key == StorageKeys.currentUserId ? userId as T : null;
}

class FakeMalaRemote extends Fake implements MalaRemoteDataSource {
  @override
  Future<List<int>> fetchImageBytes(String url) async => const [];
}

/// Accepts taps and flushes without syncing anything.
class FakeMalaSync extends Fake implements MalaSyncManager {
  @override
  void Function(String groupAccumulatorId)? onGroupCountSynced;

  @override
  void Function(String presetId)? onPersonalCountSynced;

  @override
  void onTap({required bool roundComplete}) {}

  @override
  Future<void> flush(SyncReason reason) async {}
}

class SilentMalaSoundPlayer extends Fake implements MalaSoundPlayer {
  @override
  void play() {}
}
