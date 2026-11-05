import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/datasource/user_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/reader/domain/sync/reader_settings_sync_plan.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/transliteration_service.dart';

/// The device's settings stores, as the sync sees them.
abstract class ReaderSyncLocalStore {
  /// The current settings, once every store has loaded.
  Future<ReaderSyncBlocks> read();

  /// The content language the app is reading in.
  Future<String> contentLanguage();

  Future<void> applyAppearance(Map<String, dynamic> appearance);

  Future<void> applyChant(Map<String, dynamic> chant);

  Future<void> applyListLanguage(String? language);
}

/// One signed-in account's link to the server.
class _Session {
  _Session({
    required this.userId,
    required this.synced,
    required this.reader,
    required this.schemaVersion,
  });

  final String userId;

  /// What the server is known to hold. A local value that differs is unsaved.
  ReaderSyncBlocks synced;

  /// The server's whole `reader` object, sent back with each change because a
  /// `reader` sent without its other contexts deletes them.
  Map<String, dynamic> reader;

  Object? schemaVersion;
}

/// Keeps the chant reader's settings on the server, so they survive a
/// reinstall or a new device. Signed-in accounts only; guests stay on the
/// device.
///
/// There is no "dirty" flag: the last value known to be on the server is
/// stored, and anything local that differs from it is what needs saving. A
/// save lost to a killed app or a dropped connection is therefore found again
/// at the next change, reconnect or launch.
class ReaderSettingsSync {
  ReaderSettingsSync({
    required LocalStorageService storage,
    required UserSettingsRemoteDatasource remote,
    required ReaderSyncLocalStore local,
    this.debounce = const Duration(seconds: 2),
    this.signOutTimeout = const Duration(seconds: 3),
  }) : _storage = storage,
       _remote = remote,
       _local = local;

  final LocalStorageService _storage;
  final UserSettingsRemoteDatasource _remote;
  final ReaderSyncLocalStore _local;
  final _logger = AppLogger('ReaderSettingsSync');

  /// How long a change waits for the next one, so dragging through sizes makes
  /// one save rather than several.
  final Duration debounce;

  /// How long signing out waits for a last save.
  final Duration signOutTimeout;

  _Session? _session;
  bool _authenticated = false;
  bool _disposed = false;

  /// Bumped on every sign-in and sign-out, so a session still starting for the
  /// previous account does not finish under the next one.
  int _epoch = 0;
  Timer? _debounceTimer;

  /// Work runs one step at a time, so two saves cannot overwrite each other's
  /// `reader`.
  Future<void> _queue = Future.value();

  /// Completes once the work queued so far has finished.
  @visibleForTesting
  Future<void> get idle => _queue;

  void setAuthenticated(bool authenticated) {
    if (authenticated == _authenticated) return;
    _authenticated = authenticated;
    _epoch++;
    _debounceTimer?.cancel();
    _session = null;
    if (authenticated) _enqueue(_startSession);
  }

  /// A setting may have changed; saves it shortly if it did.
  void onLocalChanged() {
    if (_session == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, _enqueuePush);
  }

  /// The connection is back: finishes whatever could not happen without it.
  void onReconnected() {
    if (!_authenticated) return;
    if (_session == null) {
      _enqueue(_startSession);
    } else {
      _enqueuePush();
    }
  }

  /// Saves any pending change while the token is still valid. Called just
  /// before sign-out, and never fails or holds sign-out up for long.
  Future<void> flushBeforeSignOut() async {
    _debounceTimer?.cancel();
    final session = _session;
    if (session == null) return;
    try {
      await _enqueue(() => _push(session)).timeout(signOutTimeout);
    } on TimeoutException {
      _logger.warning('Saving reader settings before sign-out timed out');
    }
  }

  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
  }

  void _enqueuePush() {
    final session = _session;
    if (session != null) _enqueue(() => _push(session));
  }

  Future<void> _enqueue(Future<void> Function() work) {
    return _queue = _queue.then((_) async {
      if (_disposed) return;
      try {
        await work();
      } catch (e, st) {
        // Whatever failed is still different from what is stored as synced,
        // so the next change, reconnect or launch tries again.
        _logger.warning('Reader settings sync failed', e, st);
      }
    });
  }

  Future<void> _startSession() async {
    if (_session != null || !_authenticated) return;
    final epoch = _epoch;
    final userId = await _storage.get<String>(StorageKeys.currentUserId);
    if (userId == null || userId.isEmpty) return;

    final response = await _remote.fetch();
    if (epoch != _epoch) return;
    final preferences = response.preferences;
    if (ReaderSyncBlocks.isNewerSchema(preferences)) {
      _logger.warning('Reader settings use a newer format; not syncing');
      return;
    }

    final owner = await _storage.get<String>(StorageKeys.readerSettingsOwner);
    final synced = ReaderSyncBlocks.decode(
      await _storage.get<String>(StorageKeys.readerSettingsSynced),
    );
    final server = ReaderSyncBlocks.fromPreferences(preferences);
    final languageMatches = _languagesMatch(
      await _local.contentLanguage(),
      response.contentLanguage,
    );
    final plan = planReaderSettingsSync(
      userId: userId,
      owner: owner,
      synced: synced,
      local: await _local.read(),
      server: server,
      serverHasSettings: ReaderSyncBlocks.hasSettings(preferences),
      languageMatches: languageMatches,
    );

    if (plan.apply.contains(ReaderSyncBlock.appearance)) {
      await _local.applyAppearance(plan.target.appearance);
    }
    if (plan.apply.contains(ReaderSyncBlock.chant)) {
      await _local.applyChant(plan.target.chant);
    }
    if (plan.apply.contains(ReaderSyncBlock.listLanguage)) {
      await _local.applyListLanguage(plan.target.listLanguage);
    }
    if (epoch != _epoch) return;

    // Read back rather than trusting the server's values: a setting this app
    // does not recognise reads as its default, and must not count as an edit.
    // Blocks going up keep the server's value, so the push below sees them as
    // changed.
    final reader = preferences[ReaderSyncBlocks.readerKey];
    final session = _Session(
      userId: userId,
      synced: (await _local.read()).withBlocksFrom(server, plan.upload),
      reader: reader is Map ? Map<String, dynamic>.from(reader) : const {},
      schemaVersion: preferences[ReaderSyncBlocks.schemaVersionKey],
    );
    await _persist(session);
    if (epoch != _epoch) return;
    _session = session;
    await _push(session);
  }

  Future<void> _push(_Session session) async {
    final local = await _local.read();
    final changed = [
      for (final block in ReaderSyncBlock.values)
        if (!local.sameBlock(block, session.synced)) block,
    ];
    if (changed.isEmpty) return;

    final response = await _remote.patchPreferences(
      _changesFor(session, local, changed),
    );

    final reader = response.preferences[ReaderSyncBlocks.readerKey];
    session
      ..reader = reader is Map ? Map<String, dynamic>.from(reader) : const {}
      ..schemaVersion = response.preferences[ReaderSyncBlocks.schemaVersionKey]
      ..synced = session.synced.withBlocksFrom(local, changed);
    await _persist(session);
  }

  /// Only the blocks that changed, each one whole. A block with nothing left
  /// in it is deleted rather than saved empty.
  Map<String, dynamic> _changesFor(
    _Session session,
    ReaderSyncBlocks local,
    List<ReaderSyncBlock> changed,
  ) {
    return {
      if (session.schemaVersion != ReaderSyncBlocks.schemaVersion)
        ReaderSyncBlocks.schemaVersionKey: ReaderSyncBlocks.schemaVersion,
      if (changed.contains(ReaderSyncBlock.appearance))
        ReaderSyncBlocks.appearanceKey:
            local.appearance.isEmpty ? null : local.appearance,
      if (changed.contains(ReaderSyncBlock.listLanguage))
        ReaderSyncBlocks.listLanguageKey: local.listLanguage,
      if (changed.contains(ReaderSyncBlock.chant))
        ReaderSyncBlocks.readerKey: {
          for (final entry in session.reader.entries)
            if (entry.key != ReaderSyncBlocks.chantKey) entry.key: entry.value,
          if (local.chant.isNotEmpty) ReaderSyncBlocks.chantKey: local.chant,
        },
    };
  }

  Future<void> _persist(_Session session) async {
    await _storage.set<String>(
      StorageKeys.readerSettingsSynced,
      session.synced.encode(),
    );
    await _storage.set<String>(
      StorageKeys.readerSettingsOwner,
      session.userId,
    );
  }

  /// The API sends uppercase codes (`ZH-HANS`) and the app holds lowercase
  /// ones; a server with no language has nothing to disagree with.
  static bool _languagesMatch(String local, String? server) {
    if (server == null || server.trim().isEmpty) return true;
    return TransliterationService.normalizeLanguage(local) ==
        TransliterationService.normalizeLanguage(server);
  }
}
