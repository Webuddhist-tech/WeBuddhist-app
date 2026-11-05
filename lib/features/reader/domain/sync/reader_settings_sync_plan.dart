import 'dart:convert';

/// The parts of the reader's settings that sync, each saved on its own.
enum ReaderSyncBlock { appearance, chant, listLanguage }

/// The synced reader settings in their server shape. An empty map and a null
/// language both mean "nothing picked", the same as the key being absent.
class ReaderSyncBlocks {
  const ReaderSyncBlocks({
    this.appearance = const {},
    this.chant = const {},
    this.listLanguage,
  });

  static const String appearanceKey = 'reader_appearance';
  static const String readerKey = 'reader';
  static const String chantKey = 'chant';
  static const String listLanguageKey = 'chant_list_language';
  static const String schemaVersionKey = 'schema_version';

  /// The version of this structure. Bumped when its format changes.
  static const int schemaVersion = 1;

  final Map<String, dynamic> appearance;
  final Map<String, dynamic> chant;
  final String? listLanguage;

  factory ReaderSyncBlocks.fromPreferences(Map<String, dynamic> preferences) {
    final reader = _mapOf(preferences[readerKey]);
    return ReaderSyncBlocks(
      appearance: _mapOf(preferences[appearanceKey]),
      chant: _mapOf(reader[chantKey]),
      listLanguage: _languageOf(preferences[listLanguageKey]),
    );
  }

  /// Whether [preferences] holds anything this sync saved, even if empty now.
  static bool hasSettings(Map<String, dynamic> preferences) =>
      preferences.containsKey(appearanceKey) ||
      preferences.containsKey(listLanguageKey) ||
      _mapOf(preferences[readerKey]).containsKey(chantKey);

  /// Whether [preferences] was saved by a newer app in a format this one
  /// cannot read safely.
  static bool isNewerSchema(Map<String, dynamic> preferences) {
    final version = preferences[schemaVersionKey];
    return version is num && version > schemaVersion;
  }

  bool sameBlock(ReaderSyncBlock block, ReaderSyncBlocks other) =>
      switch (block) {
        ReaderSyncBlock.appearance =>
          _canonical(appearance) == _canonical(other.appearance),
        ReaderSyncBlock.chant => _canonical(chant) == _canonical(other.chant),
        ReaderSyncBlock.listLanguage => listLanguage == other.listLanguage,
      };

  /// These blocks with [blocks] taken from [other].
  ReaderSyncBlocks withBlocksFrom(
    ReaderSyncBlocks other,
    Iterable<ReaderSyncBlock> blocks,
  ) {
    final taken = blocks.toSet();
    return ReaderSyncBlocks(
      appearance:
          taken.contains(ReaderSyncBlock.appearance)
              ? other.appearance
              : appearance,
      chant: taken.contains(ReaderSyncBlock.chant) ? other.chant : chant,
      listLanguage:
          taken.contains(ReaderSyncBlock.listLanguage)
              ? other.listLanguage
              : listLanguage,
    );
  }

  String encode() => jsonEncode({
    appearanceKey: appearance,
    chantKey: chant,
    listLanguageKey: listLanguage,
  });

  /// Never throws: a corrupt value reads as null, as if nothing had synced.
  static ReaderSyncBlocks? decode(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      final json = jsonDecode(source);
      if (json is! Map) return null;
      return ReaderSyncBlocks(
        appearance: _mapOf(json[appearanceKey]),
        chant: _mapOf(json[chantKey]),
        listLanguage: _languageOf(json[listLanguageKey]),
      );
    } on FormatException {
      return null;
    }
  }

  static Map<String, dynamic> _mapOf(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static String? _languageOf(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  /// JSON with sorted keys: the server may return keys in another order.
  static String _canonical(Object? value) => jsonEncode(_sorted(value));

  static Object? _sorted(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return {for (final key in keys) key: _sorted(value[key])};
    }
    if (value is List) return value.map(_sorted).toList();
    return value;
  }
}

/// What to do with the local and server settings when a session starts.
class ReaderSyncPlan {
  const ReaderSyncPlan({
    required this.apply,
    required this.upload,
    required this.target,
  });

  /// Blocks to overwrite on the device with [target].
  final Set<ReaderSyncBlock> apply;

  /// Blocks where the device's value should go to the server.
  final Set<ReaderSyncBlock> upload;

  /// The values for [apply].
  final ReaderSyncBlocks target;
}

/// Decides each block when [userId]'s session starts.
///
/// - The device last synced with this account ([owner] is [userId]): a block
///   changed since [synced] is an edit that has not been saved yet, so it goes
///   up. Any other block takes the server's value.
/// - The device last synced with another account: everything takes the
///   server's value, so nothing crosses from one account to the other.
/// - The device has never synced: an account with saved settings wins, and an
///   account with none receives the device's settings.
///
/// Chant picks belong to one content language. When the device reads another
/// language than the server ([languageMatches] is false) they are left alone,
/// unless they belong to another account, in which case they are cleared.
ReaderSyncPlan planReaderSettingsSync({
  required String userId,
  required String? owner,
  required ReaderSyncBlocks? synced,
  required ReaderSyncBlocks local,
  required ReaderSyncBlocks server,
  required bool serverHasSettings,
  required bool languageMatches,
}) {
  final foreign = owner != null && owner != userId;
  final lastSynced = owner == userId ? synced : null;
  final apply = <ReaderSyncBlock>{};
  final upload = <ReaderSyncBlock>{};

  for (final block in ReaderSyncBlock.values) {
    if (block == ReaderSyncBlock.chant && !languageMatches) {
      if (foreign) apply.add(block);
      continue;
    }
    final bool goesUp;
    if (lastSynced != null) {
      goesUp = !local.sameBlock(block, lastSynced);
    } else {
      goesUp = !foreign && !serverHasSettings;
    }
    (goesUp ? upload : apply).add(block);
  }

  return ReaderSyncPlan(
    apply: apply,
    upload: upload,
    target: ReaderSyncBlocks(
      appearance: server.appearance,
      chant: languageMatches ? server.chant : const {},
      listLanguage: server.listLanguage,
    ),
  );
}
