import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  ConfigService._internal();
  static final ConfigService _instance = ConfigService._internal();
  static ConfigService get instance => _instance;

  String? auth0Domain;
  String? auth0ClientId;
  String? auth0Audience;
  String? auth0Scheme;

  bool _isLoaded = false;

  // Cache keys for the last-known-good Auth0 config fetched from /props. These
  // let the app initialise Auth0 (and therefore validate a stored session)
  // offline — without them a launch with no network falls through to guest mode
  // even for a fully logged-in user.
  static const String _cacheDomainKey = 'auth0_cfg_domain';
  static const String _cacheClientIdKey = 'auth0_cfg_client_id';
  static const String _cacheAudienceKey = 'auth0_cfg_audience';

  Future<void> loadConfig() async {
    if (_isLoaded) return;
    final baseUrl = dotenv.env['BASE_API_URL'];
    if (baseUrl == null) {
      throw Exception('BASE_API_URL not set in .env');
    }
    auth0Scheme = dotenv.env['AUTH0_SCHEME'];

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/props'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch auth0 config (HTTP ${response.statusCode})',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      auth0Domain = data['domain'] as String?;
      auth0ClientId = data['client_id'] as String?;
      // Accept both the new 'audience' key and the legacy 'auth0Audience' key
      // so the app keeps working while the backend migrates. Fall back to the
      // .env value so local dev / older server builds still issue JWTs.
      final serverAudience =
          (data['audience'] as String?)?.isNotEmpty == true
              ? data['audience'] as String
              : (data['auth0Audience'] as String?)?.isNotEmpty == true
              ? data['auth0Audience'] as String
              : null;
      auth0Audience = serverAudience ?? dotenv.env['AUTH0_AUDIENCE'];
      await _cacheConfig();
      _isLoaded = true;
    } catch (_) {
      // Offline or the props endpoint is unreachable. Fall back to the
      // last-known-good config so Auth0 can still be constructed and a stored
      // session validated locally. Only a first-ever launch with no cache yet
      // genuinely cannot proceed — rethrow there.
      if (await _loadCachedConfig()) {
        _isLoaded = true;
        return;
      }
      rethrow;
    }
  }

  Future<void> _cacheConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (auth0Domain != null) {
        await prefs.setString(_cacheDomainKey, auth0Domain!);
      }
      if (auth0ClientId != null) {
        await prefs.setString(_cacheClientIdKey, auth0ClientId!);
      }
      if (auth0Audience != null) {
        await prefs.setString(_cacheAudienceKey, auth0Audience!);
      }
    } catch (_) {
      // Caching is best-effort; a failure here only costs offline resilience.
    }
  }

  /// Restores [auth0Domain]/[auth0ClientId]/[auth0Audience] from the cache.
  /// Returns true only when both required values (domain + client id) are
  /// present, i.e. a usable Auth0 client can be built.
  Future<bool> _loadCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final domain = prefs.getString(_cacheDomainKey);
      final clientId = prefs.getString(_cacheClientIdKey);
      if (domain == null || clientId == null) return false;
      auth0Domain = domain;
      auth0ClientId = clientId;
      auth0Audience = prefs.getString(_cacheAudienceKey);
      return true;
    } catch (_) {
      return false;
    }
  }
}