import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const String tolgeeNamespace = 'webuddhist';
const String tolgeeApiBase = 'https://app.tolgee.io';

/// Kept public so a Flutter test can verify parity with [TolgeeCdn.baseUrl].
const String tolgeeCdnBase =
    'https://cdn.tolg.ee/a23495c159b886551292e856ecf7a332/webuddhist';

/// Kept public so a Flutter test can verify parity with [TolgeeLocaleMap].
const Map<String, String> tolgeeSyncLanguageTags = <String, String>{
  'en': 'en',
  'bo': 'bo-IN',
  'zh': 'zh-Hant-TW',
  'hi': 'hi',
  'mn': 'mn',
  'ne': 'ne',
};

Future<void> main(List<String> arguments) async {
  try {
    if (arguments.isEmpty || arguments.contains('--help')) {
      _printUsage();
      exitCode = arguments.isEmpty ? 64 : 0;
      return;
    }

    final String command = arguments.first;
    final Set<String> flags = arguments.skip(1).toSet();
    final Directory root = _findRepositoryRoot();

    switch (command) {
      case 'pull':
        _validateFlags(flags, const <String>{'--dry-run'});
        await _runPull(root, dryRun: flags.contains('--dry-run'));
      case 'push':
        _validateFlags(flags, const <String>{'--dry-run'});
        await _runPush(root, dryRun: flags.contains('--dry-run'));
      case 'doctor':
        _validateFlags(flags, const <String>{'--remote'});
        final bool healthy = await _runDoctor(
          root,
          remote: flags.contains('--remote'),
        );
        if (!healthy) {
          exitCode = 1;
        }
      default:
        throw UsageException('Unknown command: $command');
    }
  } on UsageException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln();
    _printUsage();
    exitCode = 64;
  } on SyncException catch (error) {
    stderr.writeln('Tolgee sync failed: ${error.message}');
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln('Invalid JSON: ${error.message}');
    exitCode = 1;
  } catch (error, stackTrace) {
    stderr.writeln('Tolgee sync failed unexpectedly: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

void _printUsage() {
  stdout.writeln('''
Usage:
  dart run tool/tolgee_sync.dart pull [--dry-run]
  dart run tool/tolgee_sync.dart push [--dry-run]
  dart run tool/tolgee_sync.dart doctor [--remote]

Environment:
  TOLGEE_SYNC_API_KEY  Required for pull, push, and doctor --remote.
''');
}

void _validateFlags(Set<String> actual, Set<String> allowed) {
  final Set<String> unknown = actual.difference(allowed);
  if (unknown.isNotEmpty) {
    throw UsageException('Unknown option(s): ${unknown.join(', ')}');
  }
}

Directory _findRepositoryRoot() {
  Directory current = Directory.current.absolute;
  while (true) {
    final bool hasPubspec =
        File(
          '${current.path}${Platform.pathSeparator}pubspec.yaml',
        ).existsSync();
    final bool hasTemplate =
        File(
          '${current.path}${Platform.pathSeparator}'
          'lib${Platform.pathSeparator}core${Platform.pathSeparator}'
          'l10n${Platform.pathSeparator}app_en.arb',
        ).existsSync();
    if (hasPubspec && hasTemplate) {
      return current;
    }
    final Directory parent = current.parent;
    if (parent.path == current.path) {
      throw const SyncException(
        'Run this command from the repository or one of its subdirectories.',
      );
    }
    current = parent;
  }
}

Future<void> _runPull(Directory root, {required bool dryRun}) async {
  final TolgeeApi api = TolgeeApi.fromEnvironment();
  try {
    final int projectId = await api.resolveProjectId();
    stdout.writeln('Tolgee project: $projectId');
    stdout.writeln('Fetching all six languages before touching ARB files...');

    final RemoteCatalog catalog = await api.fetchCatalog(projectId);
    final Map<String, ArbDocument> documents = _readAllArbs(root);
    final ArbDocument template = documents['en']!;
    final List<_PullResult> results = <_PullResult>[];

    for (final MapEntry<String, String> locale
        in tolgeeSyncLanguageTags.entries) {
      final ArbDocument document = documents[locale.key]!;
      final Map<String, String> translations =
          catalog.translations[locale.value] ?? const <String, String>{};
      results.add(
        _applyTranslations(
          locale: locale.key,
          document: document,
          template: template,
          translations: translations,
        ),
      );
    }

    for (final _PullResult result in results) {
      stdout.writeln(
        '${result.locale}: updated=${result.updated} '
        'inserted=${result.inserted} unchanged=${result.unchanged}',
      );
      for (final String key in result.samples) {
        stdout.writeln('  $key');
      }
    }

    if (dryRun) {
      stdout.writeln('Dry run: no ARB files were written.');
      return;
    }

    _writeAllArbsAtomically(documents);
    stdout.writeln('Updated all ARB files.');
    stdout.writeln(
      'Next: flutter gen-l10n && '
      'dart run tool/generate_tolgee_bridge.dart',
    );
  } finally {
    api.close();
  }
}

Future<void> _runPush(Directory root, {required bool dryRun}) async {
  final TolgeeApi api = TolgeeApi.fromEnvironment();
  try {
    final int projectId = await api.resolveProjectId();
    final ArbDocument template = ArbDocument.read(_arbFile(root, 'en'));
    final Set<String> remoteNames = await api.fetchKeyNames(projectId);
    final List<String> missing =
        template.messageKeys
            .where((String key) => !remoteNames.contains(key))
            .toList();

    stdout.writeln('Tolgee project: $projectId');
    stdout.writeln('Missing from Tolgee: ${missing.length}');
    for (final String key in missing) {
      stdout.writeln('  + $key');
    }
    if (missing.isEmpty) {
      stdout.writeln('Nothing to create.');
      return;
    }
    if (dryRun) {
      stdout.writeln('Dry run: no Tolgee keys were created.');
      return;
    }

    await api.importKeys(projectId, <String, String>{
      for (final String key in missing) key: template.message(key)!,
    });
    stdout.writeln('Created ${missing.length} key(s).');
    stdout.writeln(
      'Publish Tolgee Content Delivery when the new keys are ready.',
    );
  } finally {
    api.close();
  }
}

Future<bool> _runDoctor(Directory root, {required bool remote}) async {
  final Map<String, ArbDocument> documents = _readAllArbs(root);
  final ArbDocument template = documents['en']!;
  bool structurallyHealthy = true;

  stdout.writeln('ARB consistency');
  for (final MapEntry<String, ArbDocument> entry in documents.entries) {
    final String locale = entry.key;
    final ArbDocument document = entry.value;
    final Set<String> missing = template.messageKeys.difference(
      document.messageKeys,
    );
    final Set<String> orphans = document.messageKeys.difference(
      template.messageKeys,
    );
    final Set<String> staleMetadata = document.metadataKeys.difference(
      document.messageKeys,
    );
    final List<String> placeholderMismatches = <String>[];

    for (final String key in template.messageKeys.intersection(
      document.messageKeys,
    )) {
      final Set<String> expected = _placeholderNames(template.message(key)!);
      final Set<String> actual = _placeholderNames(document.message(key)!);
      if (!_setEquals(expected, actual)) {
        placeholderMismatches.add(
          '$key (expected ${_formatSet(expected)}, '
          'found ${_formatSet(actual)})',
        );
      }
    }

    stdout.writeln(
      '  $locale: messages=${document.messageKeys.length} '
      'missing=${missing.length} orphans=${orphans.length} '
      'staleMetadata=${staleMetadata.length} '
      'placeholderMismatches=${placeholderMismatches.length}',
    );
    _printItems('missing', missing);
    _printItems('orphan', orphans);
    _printItems('stale metadata', staleMetadata);
    _printItems('placeholder mismatch', placeholderMismatches);

    if (orphans.isNotEmpty ||
        staleMetadata.isNotEmpty ||
        placeholderMismatches.isNotEmpty) {
      structurallyHealthy = false;
    }
  }

  if (remote) {
    await _runRemoteDoctor(template);
  }

  stdout.writeln(
    structurallyHealthy
        ? 'Doctor completed: no structural ARB problems.'
        : 'Doctor found structural ARB problems.',
  );
  return structurallyHealthy;
}

Future<void> _runRemoteDoctor(ArbDocument template) async {
  final TolgeeApi api = TolgeeApi.fromEnvironment();
  try {
    final int projectId = await api.resolveProjectId();
    final Set<String> remoteNames = await api.fetchKeyNames(projectId);
    final RemoteCatalog catalog = await api.fetchCatalog(projectId);
    final Set<String> missingInTolgee = template.messageKeys.difference(
      remoteNames,
    );
    final Set<String> missingInArb = remoteNames.difference(
      template.messageKeys,
    );

    stdout.writeln('Remote consistency (project $projectId)');
    stdout.writeln('  ARB keys missing in Tolgee: ${missingInTolgee.length}');
    _printItems('missing in Tolgee', missingInTolgee);
    stdout.writeln('  Tolgee keys missing in ARB: ${missingInArb.length}');
    _printItems('missing in ARB', missingInArb);
    for (final MapEntry<String, String> locale
        in tolgeeSyncLanguageTags.entries) {
      final int translated = catalog.translations[locale.value]?.length ?? 0;
      stdout.writeln(
        '  ${locale.key} (${locale.value}): '
        '$translated/${remoteNames.length} translated',
      );
      try {
        await api.checkCdn(locale.value);
      } on SyncException catch (error) {
        stderr.writeln('    CDN warning: ${error.message}');
      }
    }
  } finally {
    api.close();
  }
}

Map<String, ArbDocument> _readAllArbs(Directory root) {
  return <String, ArbDocument>{
    for (final String locale in tolgeeSyncLanguageTags.keys)
      locale: ArbDocument.read(_arbFile(root, locale)),
  };
}

File _arbFile(Directory root, String locale) {
  return File(
    '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}'
    'core${Platform.pathSeparator}l10n${Platform.pathSeparator}'
    'app_$locale.arb',
  );
}

_PullResult _applyTranslations({
  required String locale,
  required ArbDocument document,
  required ArbDocument template,
  required Map<String, String> translations,
}) {
  int updated = 0;
  int inserted = 0;
  int unchanged = 0;
  final List<String> samples = <String>[];

  for (final String key in document.messageKeys.toList()) {
    final String? remote = translations[key];
    if (remote == null || remote.trim().isEmpty) {
      continue;
    }
    if (document.message(key) == remote) {
      unchanged++;
      continue;
    }
    document.setMessage(key, remote);
    updated++;
    if (samples.length < 8) {
      samples.add('~ $key');
    }
  }

  for (final String key in template.messageKeys) {
    if (document.messageKeys.contains(key)) {
      continue;
    }
    final String? remote = translations[key];
    if (remote == null || remote.trim().isEmpty) {
      continue;
    }
    document.addMessage(key, remote, metadata: template.metadata(key));
    inserted++;
    if (samples.length < 8) {
      samples.add('+ $key');
    }
  }

  return _PullResult(
    locale: locale,
    updated: updated,
    inserted: inserted,
    unchanged: unchanged,
    samples: samples,
  );
}

void _writeAllArbsAtomically(Map<String, ArbDocument> documents) {
  final Map<File, String> originals = <File, String>{};
  final List<File> replaced = <File>[];
  final List<File> temps = <File>[];
  try {
    for (final ArbDocument document in documents.values) {
      originals[document.file] = document.originalText;
    }
    for (final ArbDocument document in documents.values) {
      final File target = document.file;
      final File temp = File('${target.path}.tmp.$pid');
      temps.add(temp);
      temp.writeAsStringSync(document.encode(), encoding: utf8, flush: true);
      temp.renameSync(target.path);
      replaced.add(target);
    }
  } catch (error) {
    final List<String> restoreFailures = <String>[];
    for (final File file in replaced.reversed) {
      final String? original = originals[file];
      if (original == null) {
        continue;
      }
      try {
        file.writeAsStringSync(original, encoding: utf8, flush: true);
      } catch (_) {
        restoreFailures.add(file.path);
      }
    }
    final String restoreNote =
        restoreFailures.isEmpty
            ? 'changes rolled back'
            : 'rollback incomplete for: ${restoreFailures.join(', ')}';
    throw SyncException('Could not write all ARB files; $restoreNote: $error');
  } finally {
    for (final File temp in temps) {
      try {
        if (temp.existsSync()) {
          temp.deleteSync();
        }
      } catch (_) {
        // Best-effort cleanup of leftover temp files.
      }
    }
  }
}

Set<String> _placeholderNames(String message) {
  final RegExp pattern = RegExp(r'\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*[,}]');
  return pattern
      .allMatches(message)
      .map((RegExpMatch match) => match.group(1)!)
      .toSet();
}

bool _setEquals<T>(Set<T> first, Set<T> second) {
  return first.length == second.length && first.containsAll(second);
}

String _formatSet(Set<String> values) {
  if (values.isEmpty) {
    return 'none';
  }
  final List<String> sorted = values.toList()..sort();
  return sorted.join(', ');
}

void _printItems(String label, Iterable<String> items) {
  final List<String> sorted = items.toList()..sort();
  for (final String item in sorted.take(20)) {
    stdout.writeln('    $label: $item');
  }
  if (sorted.length > 20) {
    stdout.writeln('    ... and ${sorted.length - 20} more');
  }
}

class ArbDocument {
  ArbDocument._({
    required this.file,
    required this.originalText,
    required Map<String, dynamic> values,
  }) : _values = values;

  factory ArbDocument.read(File file) {
    if (!file.existsSync()) {
      throw SyncException('ARB file not found: ${file.path}');
    }
    final String text = file.readAsStringSync(encoding: utf8);
    final Object? decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw SyncException('ARB root must be a JSON object: ${file.path}');
    }
    return ArbDocument._(file: file, originalText: text, values: decoded);
  }

  final File file;
  final String originalText;
  final Map<String, dynamic> _values;

  Set<String> get messageKeys =>
      _values.entries
          .where(
            (MapEntry<String, dynamic> entry) =>
                !entry.key.startsWith('@') && entry.value is String,
          )
          .map((MapEntry<String, dynamic> entry) => entry.key)
          .toSet();

  Set<String> get metadataKeys =>
      _values.keys
          .where((String key) => key.startsWith('@') && !key.startsWith('@@'))
          .map((String key) => key.substring(1))
          .toSet();

  String? message(String key) {
    final Object? value = _values[key];
    return value is String ? value : null;
  }

  Object? metadata(String key) => _values['@$key'];

  void setMessage(String key, String value) {
    _values[key] = value;
  }

  void addMessage(String key, String value, {Object? metadata}) {
    _values[key] = value;
    if (metadata != null) {
      _values['@$key'] = metadata;
    }
  }

  String encode() => '${const JsonEncoder.withIndent('  ').convert(_values)}\n';
}

class TolgeeApi {
  TolgeeApi({required this.apiKey, HttpClient? client})
    : _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 30);
  }

  factory TolgeeApi.fromEnvironment() {
    final Map<String, String> environment = Platform.environment;
    final String? apiKey = environment['TOLGEE_SYNC_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const SyncException(
        'TOLGEE_SYNC_API_KEY is not set. Use a separate sync key; '
        'never put a write-scoped key in .env.*.',
      );
    }
    return TolgeeApi(apiKey: apiKey);
  }

  final String apiKey;
  final HttpClient _client;

  Future<int> resolveProjectId() async {
    final Object? decoded = await _requestJson(
      'GET',
      _apiUri('/v2/api-keys/current'),
    );
    if (decoded is! Map<String, dynamic>) {
      throw const SyncException('Unexpected API-key response shape.');
    }
    final Object? value = decoded['projectId'];
    final int? projectId =
        value is int ? value : int.tryParse(value?.toString() ?? '');
    if (projectId == null) {
      throw const SyncException(
        'The API key response did not contain a projectId. '
        'Use a Tolgee project API key (tgpak_...).',
      );
    }
    return projectId;
  }

  Future<Set<String>> fetchKeyNames(int projectId) async {
    final Set<String> names = <String>{};
    int page = 0;
    int totalPages = 1;
    do {
      final Object? decoded = await _requestJson(
        'GET',
        _apiUri('/v2/projects/$projectId/keys', <String, Object>{
          'page': '$page',
          'size': '1000',
        }),
      );
      final Map<String, dynamic> body = _jsonObject(decoded, 'keys');
      for (final Map<String, dynamic> item in _embeddedItems(body)) {
        if (_namespaceOf(item['namespace']) != tolgeeNamespace) {
          continue;
        }
        final String? name = item['name']?.toString();
        if (name != null && name.isNotEmpty) {
          names.add(name);
        }
      }
      totalPages = _totalPages(body);
      page++;
    } while (page < totalPages);
    return names;
  }

  Future<RemoteCatalog> fetchCatalog(int projectId) async {
    final Map<String, Map<String, String>> translations =
        <String, Map<String, String>>{
          for (final String tag in tolgeeSyncLanguageTags.values)
            tag: <String, String>{},
        };
    final Set<String> names = <String>{};
    int page = 0;
    int totalPages = 1;
    do {
      final Object? decoded = await _requestJson(
        'GET',
        _apiUri('/v2/projects/$projectId/translations', <String, Object>{
          'languages': tolgeeSyncLanguageTags.values.toList(),
          'page': '$page',
          'size': '1000',
        }),
      );
      final Map<String, dynamic> body = _jsonObject(decoded, 'translations');
      for (final Map<String, dynamic> item in _embeddedItems(body)) {
        if (_namespaceOf(item['keyNamespace']) != tolgeeNamespace) {
          continue;
        }
        final String? name = item['keyName']?.toString();
        if (name == null || name.isEmpty) {
          continue;
        }
        names.add(name);
        final Object? translationsValue = item['translations'];
        if (translationsValue is! Map<String, dynamic>) {
          continue;
        }
        for (final String tag in tolgeeSyncLanguageTags.values) {
          final Object? translationValue = translationsValue[tag];
          if (translationValue is! Map<String, dynamic>) {
            continue;
          }
          final Object? textValue = translationValue['text'];
          if (textValue is String && textValue.trim().isNotEmpty) {
            translations[tag]![name] = textValue;
          }
        }
      }
      totalPages = _totalPages(body);
      page++;
    } while (page < totalPages);
    return RemoteCatalog(names: names, translations: translations);
  }

  Future<void> importKeys(int projectId, Map<String, String> values) async {
    final List<MapEntry<String, String>> entries = values.entries.toList();
    const int chunkSize = 100;
    for (int start = 0; start < entries.length; start += chunkSize) {
      final int end = (start + chunkSize).clamp(0, entries.length);
      final List<MapEntry<String, String>> chunk = entries.sublist(start, end);
      await _requestJson(
        'POST',
        _apiUri('/v2/projects/$projectId/keys/import'),
        body: <String, Object>{
          'keys': <Map<String, Object>>[
            for (final MapEntry<String, String> entry in chunk)
              <String, Object>{
                'name': entry.key,
                'namespace': tolgeeNamespace,
                'translations': <String, String>{'en': entry.value},
              },
          ],
        },
      );
      stdout.writeln('  imported ${chunk.length} key(s)');
    }
  }

  Future<void> checkCdn(String tag) async {
    final Uri uri = Uri.parse('$tolgeeCdnBase/$tag.json');
    final _HttpResult result = await _send('GET', uri, includeApiKey: false);
    if (result.statusCode < 200 || result.statusCode >= 300) {
      throw SyncException('CDN $tag returned HTTP ${result.statusCode}.');
    }
    final Object? decoded = jsonDecode(utf8.decode(result.bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded.values.any((Object? value) => value is! String)) {
      throw SyncException('CDN $tag is not a flat JSON string map.');
    }
    stdout.writeln(
      '    CDN $tag: HTTP ${result.statusCode}, ${decoded.length} keys',
    );
  }

  Uri _apiUri(String path, [Map<String, Object>? query]) {
    return Uri.parse('$tolgeeApiBase$path').replace(
      queryParameters:
          query == null
              ? null
              : <String, dynamic>{
                for (final MapEntry<String, Object> entry in query.entries)
                  entry.key: entry.value,
              },
    );
  }

  Future<Object?> _requestJson(String method, Uri uri, {Object? body}) async {
    final _HttpResult result = await _send(method, uri, body: body);
    if (result.statusCode < 200 || result.statusCode >= 300) {
      final String response = utf8.decode(result.bytes, allowMalformed: true);
      throw SyncException(
        '$method ${uri.path} returned HTTP ${result.statusCode}'
        '${response.isEmpty ? '' : ': $response'}',
      );
    }
    if (result.bytes.isEmpty) {
      return null;
    }
    return jsonDecode(utf8.decode(result.bytes));
  }

  Future<_HttpResult> _send(
    String method,
    Uri uri, {
    Object? body,
    bool includeApiKey = true,
  }) async {
    const int maxAttempts = 5;
    const Duration attemptTimeout = Duration(seconds: 60);
    final bool idempotent = method.toUpperCase() == 'GET';
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final _HttpResult result = await () async {
          final HttpClientRequest request = await _client.openUrl(method, uri);
          if (includeApiKey) {
            request.headers.set('X-API-Key', apiKey);
          }
          if (body != null) {
            request.headers.contentType = ContentType.json;
            request.add(utf8.encode(jsonEncode(body)));
          }
          final HttpClientResponse response = await request.close();
          final List<int> bytes = await _readBytes(response);
          return _HttpResult(
            statusCode: response.statusCode,
            bytes: bytes,
            retryAfter: response.headers.value(HttpHeaders.retryAfterHeader),
          );
        }().timeout(attemptTimeout);
        if ((result.statusCode == 429 || result.statusCode == 503) &&
            attempt + 1 < maxAttempts) {
          final Duration delay = _retryDelay(result.retryAfter, attempt);
          stderr.writeln(
            'HTTP ${result.statusCode}; retrying in ${delay.inSeconds}s '
            '(${attempt + 2}/$maxAttempts)...',
          );
          await Future<void>.delayed(delay);
          continue;
        }
        return result;
      } on TimeoutException catch (error) {
        if (!idempotent || attempt + 1 == maxAttempts) {
          throw SyncException('Network request timed out: $error');
        }
        await Future<void>.delayed(_retryDelay(null, attempt));
      } on SocketException catch (error) {
        if (!idempotent || attempt + 1 == maxAttempts) {
          throw SyncException('Network request failed: $error');
        }
        await Future<void>.delayed(_retryDelay(null, attempt));
      } on HttpException catch (error) {
        if (!idempotent || attempt + 1 == maxAttempts) {
          throw SyncException('HTTP request failed: $error');
        }
        await Future<void>.delayed(_retryDelay(null, attempt));
      }
    }
    throw const SyncException('Request retry limit reached.');
  }

  void close() => _client.close(force: true);
}

Future<List<int>> _readBytes(HttpClientResponse response) async {
  final BytesBuilder builder = BytesBuilder(copy: false);
  await for (final List<int> chunk in response) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}

Duration _retryDelay(String? retryAfter, int attempt) {
  if (retryAfter != null) {
    final int? seconds = int.tryParse(retryAfter.trim());
    if (seconds != null) {
      return Duration(seconds: seconds.clamp(1, 60));
    }
    try {
      final Duration until = HttpDate.parse(
        retryAfter,
      ).difference(DateTime.now().toUtc());
      if (!until.isNegative) {
        return Duration(seconds: until.inSeconds.clamp(1, 60));
      }
    } on FormatException {
      // Fall through to exponential backoff.
    } on HttpException {
      // Fall through to exponential backoff.
    }
  }
  return Duration(seconds: (1 << attempt).clamp(1, 16));
}

Map<String, dynamic> _jsonObject(Object? value, String endpoint) {
  if (value is! Map<String, dynamic>) {
    throw SyncException('Unexpected $endpoint response shape.');
  }
  return value;
}

List<Map<String, dynamic>> _embeddedItems(Map<String, dynamic> body) {
  final Object? embedded = body['_embedded'];
  if (embedded is! Map<String, dynamic>) {
    return const <Map<String, dynamic>>[];
  }
  final Object? keys = embedded['keys'];
  if (keys is! List<dynamic>) {
    return const <Map<String, dynamic>>[];
  }
  return keys.whereType<Map<String, dynamic>>().toList();
}

int _totalPages(Map<String, dynamic> body) {
  final Object? page = body['page'];
  if (page is! Map<String, dynamic>) {
    return 1;
  }
  final Object? totalPages = page['totalPages'];
  return totalPages is int ? totalPages : int.tryParse('$totalPages') ?? 1;
}

String _namespaceOf(Object? value) {
  if (value is String) {
    return value;
  }
  if (value is Map<String, dynamic>) {
    return value['name']?.toString() ?? '';
  }
  return '';
}

class RemoteCatalog {
  const RemoteCatalog({required this.names, required this.translations});

  final Set<String> names;
  final Map<String, Map<String, String>> translations;
}

class _PullResult {
  const _PullResult({
    required this.locale,
    required this.updated,
    required this.inserted,
    required this.unchanged,
    required this.samples,
  });

  final String locale;
  final int updated;
  final int inserted;
  final int unchanged;
  final List<String> samples;
}

class _HttpResult {
  const _HttpResult({
    required this.statusCode,
    required this.bytes,
    required this.retryAfter,
  });

  final int statusCode;
  final List<int> bytes;
  final String? retryAfter;
}

class UsageException implements Exception {
  const UsageException(this.message);

  final String message;
}

class SyncException implements Exception {
  const SyncException(this.message);

  final String message;
}
