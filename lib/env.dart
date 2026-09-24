import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for the app.
///
/// This class provides type-safe access to environment variables
/// loaded from .env files. Ensure dotenv.load() is called in main()
/// before accessing these values.
class Env {
  Env._();

  /// Analytics keys are optional, so they read an unloaded dotenv (unit
  /// tests, tooling) as "not configured" instead of throwing.
  static Map<String, String> get _optional =>
      dotenv.isInitialized ? dotenv.env : const {};

  /// API base URL for the backend
  static String get apiBaseUrl =>
      dotenv.env['BASE_API_URL'] ??
      (throw Exception('BASE_API_URL not found in environment'));

  /// Library (texts) API base URL. A blank value (an unset CI secret writes
  /// `LIBRARY_API_URL=`) falls back to the default instead of an empty base.
  static String get libraryApiUrl =>
      _nonEmpty('LIBRARY_API_URL') ?? 'https://library.webuddhist.com';

  /// Library tag that marks the texts listed as chants
  static String get libraryChantsTagId =>
      _nonEmpty('LIBRARY_CHANTS_TAG_ID') ??
      (throw Exception('LIBRARY_CHANTS_TAG_ID not found in environment'));

  static String? _nonEmpty(String key) {
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// Auth0 domain (fetched from backend /props endpoint)
  static String? get auth0Domain => dotenv.env['AUTH0_DOMAIN'];

  /// Auth0 client ID (fetched from backend /props endpoint)
  static String? get auth0ClientId => dotenv.env['AUTH0_CLIENT_ID'];

  /// Auth0 audience (fetched from backend /props endpoint)
  static String? get auth0Audience => dotenv.env['AUTH0_AUDIENCE'];

  /// Whether the app is running in debug mode
  static bool get isDebug => dotenv.env['ENVIRONMENT'] != 'production';

  /// Current environment (dev, staging, prod)
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  /// API timeout duration
  static Duration get apiTimeout => const Duration(seconds: 30);

  /// Cache TTL for static content
  static Duration get cacheTTL => const Duration(hours: 24);

  /// Cache TTL for user-specific content
  static Duration get userCacheTTL => const Duration(hours: 1);

  /// Maximum number of items to cache per type
  static int get maxCacheItems => 50;

  /// Enable verbose logging
  static bool get enableVerboseLogging => isDebug;

  /// PostHog project API key (optional — analytics disabled when absent)
  static String? get posthogApiKey => _optional['POSTHOG_API_KEY'];

  /// PostHog ingest host
  static String get posthogHost =>
      _optional['POSTHOG_HOST'] ?? 'https://us.i.posthog.com';

  /// Whether PostHog analytics is enabled for this build
  static bool get posthogEnabled {
    final String? enabledFlag = _optional['POSTHOG_ENABLED'];
    if (enabledFlag != null && enabledFlag.isNotEmpty) {
      return enabledFlag.toLowerCase() == 'true';
    }
    final String? apiKey = posthogApiKey;
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Microsoft Clarity project ID (optional — Clarity disabled when absent)
  static String? get clarityProjectId => _optional['CLARITY_PROJECT_ID'];

  /// Whether Clarity session recording and heatmaps are enabled for this build
  static bool get clarityEnabled {
    final String? enabledFlag = _optional['CLARITY_ENABLED'];
    if (enabledFlag != null && enabledFlag.isNotEmpty) {
      return enabledFlag.toLowerCase() == 'true';
    }
    final String? projectId = clarityProjectId;
    return projectId != null && projectId.isNotEmpty;
  }

  /// Tolgee project API key.
  ///
  /// This ships inside the bundled `.env` asset and can be extracted from a
  /// released build, so it must be a read-only scoped key.
  static String? get tolgeeApiKey => dotenv.env['TOLGEE_API_KEY'];

  /// Tolgee Content Delivery base URL. Translations are read from
  /// `$tolgeeCdnUrl/<languageTag>.json`.
  static String? get tolgeeCdnUrl => dotenv.env['TOLGEE_CDN_URL'];

  /// Whether over-the-air translations are enabled for this build.
  ///
  /// Defaults to enabled when both a key and a CDN URL are present, so a build
  /// without Tolgee credentials silently uses the bundled ARB translations.
  static bool get tolgeeEnabled {
    final String? enabledFlag = dotenv.env['TOLGEE_ENABLED'];
    if (enabledFlag != null && enabledFlag.isNotEmpty) {
      return enabledFlag.toLowerCase() == 'true';
    }
    final String? apiKey = tolgeeApiKey;
    final String? cdnUrl = tolgeeCdnUrl;
    return apiKey != null &&
        apiKey.isNotEmpty &&
        cdnUrl != null &&
        cdnUrl.isNotEmpty;
  }

  /// Normalized flavor label for analytics super properties
  static String get appFlavor {
    final String env = environment.toLowerCase();
    if (env.contains('prod')) {
      return 'prod';
    }
    if (env.contains('stag')) {
      return 'staging';
    }
    return 'dev';
  }
}
