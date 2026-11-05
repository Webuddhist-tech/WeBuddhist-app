import 'dart:convert';

import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/features/reader/application/reader_settings_sync.dart';
import 'package:flutter_pecha/features/reader/data/datasource/user_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/reader/domain/sync/reader_settings_sync_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';

/// Follows the API's merge rules: a top-level key sent replaces the stored
/// value whole, a top-level key sent as null is deleted, the rest are kept.
class _FakeServer implements UserSettingsRemoteDatasource {
  Map<String, dynamic> preferences = {};
  String contentLanguage = 'EN';
  final List<Map<String, dynamic>> patches = [];
  bool offline = false;
  int fetches = 0;

  /// A JSON round trip, as a real response would be.
  UserSettingsResponse get _response => UserSettingsResponse.fromJson(
    jsonDecode(
          jsonEncode({
            'content_language': contentLanguage,
            'preferences': preferences,
          }),
        )
        as Map<String, dynamic>,
  );

  @override
  Future<UserSettingsResponse> fetch() async {
    fetches++;
    if (offline) throw Exception('offline');
    return _response;
  }

  @override
  Future<UserSettingsResponse> patchPreferences(
    Map<String, dynamic> changes,
  ) async {
    if (offline) throw Exception('offline');
    patches.add(changes);
    for (final entry in changes.entries) {
      if (entry.value == null) {
        preferences.remove(entry.key);
      } else {
        preferences[entry.key] = entry.value;
      }
    }
    return _response;
  }
}

class _FakeLocal implements ReaderSyncLocalStore {
  ReaderSyncBlocks blocks = const ReaderSyncBlocks();
  String language = 'en';

  @override
  Future<ReaderSyncBlocks> read() async => blocks;

  @override
  Future<String> contentLanguage() async => language;

  @override
  Future<void> applyAppearance(Map<String, dynamic> appearance) async {
    blocks = ReaderSyncBlocks(
      appearance: appearance,
      chant: blocks.chant,
      listLanguage: blocks.listLanguage,
    );
  }

  @override
  Future<void> applyChant(Map<String, dynamic> chant) async {
    blocks = ReaderSyncBlocks(
      appearance: blocks.appearance,
      chant: chant,
      listLanguage: blocks.listLanguage,
    );
  }

  @override
  Future<void> applyListLanguage(String? language) async {
    blocks = ReaderSyncBlocks(
      appearance: blocks.appearance,
      chant: blocks.chant,
      listLanguage: language,
    );
  }
}

void main() {
  late FakeLocalStorage storage;
  late _FakeServer server;
  late _FakeLocal local;
  late ReaderSettingsSync sync;

  void build() {
    sync = ReaderSettingsSync(
      storage: storage,
      remote: server,
      local: local,
      debounce: Duration.zero,
    );
    addTearDown(sync.dispose);
  }

  setUp(() {
    storage = FakeLocalStorage();
    storage.values[StorageKeys.currentUserId] = 'user-a';
    server = _FakeServer();
    local = _FakeLocal();
    build();
  });

  Future<void> signIn([String? userId]) async {
    if (userId != null) storage.values[StorageKeys.currentUserId] = userId;
    sync.setAuthenticated(true);
    await sync.idle;
  }

  Future<void> edit(ReaderSyncBlocks blocks) async {
    local.blocks = blocks;
    sync.onLocalChanged();
    await Future<void>.delayed(Duration.zero);
    await sync.idle;
  }

  /// A later launch: same device storage, a new sync object.
  void relaunch() {
    sync.dispose();
    build();
  }

  const sky = {'background': 'sky'};
  const gold = {'background': 'gold'};
  const zhPick = {'translation_language': 'zh'};

  group('first sign-in', () {
    test('a new device restores what the account saved', () async {
      server.preferences = {
        'schema_version': 1,
        'reader_appearance': sky,
        'reader': {'chant': zhPick},
        'chant_list_language': 'hi',
      };

      await signIn();

      expect(local.blocks.appearance, sky);
      expect(local.blocks.chant, zhPick);
      expect(local.blocks.listLanguage, 'hi');
      expect(server.patches, isEmpty, reason: 'nothing to save back');
    });

    test('an account with saved settings wins over the device', () async {
      server.preferences = {'reader_appearance': sky};
      local.blocks = const ReaderSyncBlocks(
        appearance: gold,
        chant: zhPick,
        listLanguage: 'hi',
      );

      await signIn();

      expect(local.blocks.appearance, sky);
      expect(local.blocks.chant, isEmpty);
      expect(local.blocks.listLanguage, isNull);
      expect(server.patches, isEmpty);
    });

    test('an account with nothing saved receives the device settings', () async {
      local.blocks = const ReaderSyncBlocks(
        appearance: gold,
        chant: zhPick,
        listLanguage: 'hi',
      );

      await signIn();

      expect(server.patches, hasLength(1));
      expect(server.preferences, {
        'schema_version': ReaderSyncBlocks.schemaVersion,
        'reader_appearance': gold,
        'chant_list_language': 'hi',
        'reader': {'chant': zhPick},
      });
      expect(local.blocks.appearance, gold, reason: 'the device is unchanged');
    });

    test('a device left on the defaults uploads nothing', () async {
      await signIn();

      expect(server.patches, isEmpty);
    });

    test('settings from a newer app are left alone', () async {
      server.preferences = {'schema_version': 99, 'reader_appearance': sky};
      local.blocks = const ReaderSyncBlocks(appearance: gold);

      await signIn();
      await edit(const ReaderSyncBlocks(appearance: {'spacing': 'relaxed'}));

      expect(local.blocks.appearance, {'spacing': 'relaxed'});
      expect(server.patches, isEmpty);
      expect(server.preferences['reader_appearance'], sky);
    });
  });

  group('saving a change', () {
    setUp(() async {
      server.preferences = {
        'schema_version': 1,
        'reader_appearance': sky,
        'reader': {
          'library': {'translation_on': true},
          'chant': zhPick,
        },
      };
      await signIn();
    });

    test('sends only the block that changed, and all of it', () async {
      await edit(
        const ReaderSyncBlocks(
          appearance: {'background': 'sky', 'spacing': 'relaxed'},
          chant: zhPick,
        ),
      );

      expect(server.patches.single, {
        'reader_appearance': {'background': 'sky', 'spacing': 'relaxed'},
      });
    });

    test('keeps the other reader contexts when chant changes', () async {
      const hiPick = {'translation_language': 'hi'};

      await edit(const ReaderSyncBlocks(appearance: sky, chant: hiPick));

      expect(server.preferences['reader'], {
        'library': {'translation_on': true},
        'chant': hiPick,
      });
    });

    test('keeps a deliberate "as written" script pick', () async {
      const asWritten = {
        'scripts': {'bo': null},
      };

      await edit(const ReaderSyncBlocks(appearance: sky, chant: asWritten));

      expect(
        (server.preferences['reader'] as Map)['chant'],
        asWritten,
      );
      expect(
        (server.preferences['reader'] as Map)['chant'] as Map,
        containsPair('scripts', containsPair('bo', isNull)),
      );
    });

    test('dropped chant picks are removed, keeping other contexts', () async {
      // What an app language change does to the local store.
      await edit(const ReaderSyncBlocks(appearance: sky));

      expect(server.preferences['reader'], {
        'library': {'translation_on': true},
      });
    });

    test('a block back at its defaults is deleted', () async {
      await edit(const ReaderSyncBlocks(chant: zhPick));

      expect(server.preferences.containsKey('reader_appearance'), isFalse);
    });

    test('no change sends nothing', () async {
      sync.onLocalChanged();
      await Future<void>.delayed(Duration.zero);
      await sync.idle;

      expect(server.patches, isEmpty);
    });

    test('guests never reach the server', () async {
      sync.setAuthenticated(false);

      await edit(const ReaderSyncBlocks(appearance: gold));

      expect(server.patches, isEmpty);
    });
  });

  group('edits not saved yet', () {
    setUp(() async {
      server.preferences = {
        'schema_version': 1,
        'reader_appearance': sky,
        'chant_list_language': 'hi',
      };
      await signIn();
    });

    test('a failed save is retried on reconnect', () async {
      server.offline = true;
      await edit(
        const ReaderSyncBlocks(appearance: gold, listLanguage: 'hi'),
      );
      expect(server.preferences['reader_appearance'], sky);

      server.offline = false;
      sync.onReconnected();
      await sync.idle;

      expect(server.preferences['reader_appearance'], gold);
    });

    test('an edit lost to a killed app goes up at the next launch', () async {
      // Changed locally, then the app died before the debounced save ran.
      local.blocks = const ReaderSyncBlocks(
        appearance: gold,
        listLanguage: 'hi',
      );
      relaunch();

      await signIn();

      expect(server.preferences['reader_appearance'], gold);
      expect(local.blocks.appearance, gold, reason: 'the edit is kept');
    });

    test('another device\'s change to another block still comes down', () async {
      local.blocks = const ReaderSyncBlocks(
        appearance: gold,
        listLanguage: 'hi',
      );
      server.preferences['chant_list_language'] = 'zh';
      relaunch();

      await signIn();

      expect(local.blocks.listLanguage, 'zh');
      expect(server.preferences['reader_appearance'], gold);
      expect(server.preferences['chant_list_language'], 'zh');
    });

    test('another device\'s change comes down when nothing is pending', () async {
      server.preferences['reader_appearance'] = gold;
      relaunch();

      await signIn();

      expect(local.blocks.appearance, gold);
      expect(server.patches, isEmpty);
    });

    test('a save still pending at sign-out goes out first', () async {
      local.blocks = const ReaderSyncBlocks(
        appearance: gold,
        listLanguage: 'hi',
      );

      // In the order logout does it: started, then the session ends.
      final flush = sync.flushBeforeSignOut();
      sync.setAuthenticated(false);
      await flush;

      expect(server.preferences['reader_appearance'], gold);
    });
  });

  group('offline at sign-in', () {
    test('starts once the connection is back', () async {
      server
        ..preferences = {'reader_appearance': sky}
        ..offline = true;

      await signIn();
      expect(local.blocks.appearance, isEmpty);

      server.offline = false;
      sync.onReconnected();
      await sync.idle;

      expect(local.blocks.appearance, sky);
    });

    test('does not save or claim the device before it knows the server', () async {
      server.offline = true;
      await signIn();
      await edit(const ReaderSyncBlocks(appearance: gold));

      expect(server.patches, isEmpty);
      expect(storage.values[StorageKeys.readerSettingsOwner], isNull);
    });
  });

  group('another account on this device', () {
    final userBServer = {'reader_appearance': sky};

    setUp(() async {
      local.blocks = const ReaderSyncBlocks(appearance: gold, chant: zhPick);
      await signIn('user-a');
      expect(server.preferences['reader_appearance'], gold);
      sync.setAuthenticated(false);
      server.patches.clear();
    });

    test('settings stay on the device after sign-out', () {
      expect(local.blocks.appearance, gold);
    });

    test('takes that account\'s settings, uploading nothing', () async {
      server.preferences = Map.of(userBServer);

      await signIn('user-b');

      expect(local.blocks.appearance, sky);
      expect(local.blocks.chant, isEmpty);
      expect(server.patches, isEmpty);
    });

    test('an account with nothing saved does not receive them', () async {
      server.preferences = {};

      await signIn('user-b');
      expect(server.patches, isEmpty);
      expect(local.blocks.appearance, isEmpty, reason: 'back to the defaults');
      expect(local.blocks.chant, isEmpty);

      // Their first edit carries only their own settings.
      await edit(const ReaderSyncBlocks(appearance: sky));
      expect(server.preferences, {
        'schema_version': ReaderSyncBlocks.schemaVersion,
        'reader_appearance': sky,
      });
    });

    test('clears chant picks even in another content language', () async {
      server
        ..preferences = {}
        ..contentLanguage = 'BO';

      await signIn('user-b');

      expect(local.blocks.chant, isEmpty);
    });

    test('the first account gets its own settings back', () async {
      final saved = Map<String, dynamic>.of(server.preferences);
      server.preferences = {'reader_appearance': sky};
      await signIn('user-b');
      sync.setAuthenticated(false);

      server.preferences = saved;
      await signIn('user-a');

      expect(local.blocks.appearance, gold);
      expect(local.blocks.chant, zhPick);
      expect(server.patches, isEmpty);
    });
  });

  group('device in another content language', () {
    test('restores the appearance but not the chant picks', () async {
      server
        ..preferences = {
          'reader_appearance': sky,
          'reader': {'chant': zhPick},
        }
        ..contentLanguage = 'BO';
      local.language = 'en';

      await signIn();

      expect(local.blocks.appearance, sky);
      expect(local.blocks.chant, isEmpty);
      expect(server.patches, isEmpty);
    });

    test('does not upload its own chant picks over them', () async {
      const hiPick = {'translation_language': 'hi'};
      server
        ..preferences = {
          'reader': {'chant': zhPick},
        }
        ..contentLanguage = 'BO';
      local
        ..language = 'en'
        ..blocks = const ReaderSyncBlocks(chant: hiPick);

      await signIn();

      expect(local.blocks.chant, hiPick);
      expect(server.patches, isEmpty);
      expect((server.preferences['reader'] as Map)['chant'], zhPick);
    });

    test('language codes match whatever the case', () async {
      server
        ..preferences = {
          'reader': {'chant': zhPick},
        }
        ..contentLanguage = 'ZH-HANS';
      local.language = 'zh-Hans';

      await signIn();

      expect(local.blocks.chant, zhPick);
    });
  });
}
