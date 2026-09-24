import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/clarity_screen_observer.dart';
import 'package:flutter_pecha/core/analytics/clarity_screen_tracker.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/env.dart';
import 'package:uuid/uuid.dart';

final _logger = AppLogger('ClarityAnalytics');

/// Clarity custom events are one string of at most this many characters.
const int _customEventMaxLength = 254;

/// Property keys that never reach Clarity; mirrors the PostHog redaction.
const Set<String> _redactedKeys = {'email', 'id_token', 'access_token'};

/// Microsoft Clarity session recordings and heatmaps. [wrap] starts the SDK
/// with the first frame; the route observers keep its screen name current.
class ClarityAnalyticsService implements AnalyticsService {
  ClarityAnalyticsService._();

  static ClarityAnalyticsService? _instance;
  static ClarityAnalyticsService get instance =>
      _instance ??= ClarityAnalyticsService._();

  static bool get isEnabled {
    final String? projectId = Env.clarityProjectId;
    return Env.clarityEnabled && projectId != null && projectId.isNotEmpty;
  }

  final ClarityScreenTracker _screenTracker = ClarityScreenTracker(
    onScreenChanged: Clarity.setCurrentScreenName,
  );

  /// Sanghas seen this session, kept as one multi-value tag so recordings
  /// can be filtered by group.
  final Set<String> _sanghas = {};

  /// Wraps the app so Clarity records from the first frame. Returns [app]
  /// untouched when the project ID is missing or invalid.
  static Widget wrap(Widget app) {
    final String? projectId = Env.clarityProjectId;
    if (!Env.clarityEnabled || projectId == null || projectId.isEmpty) {
      _logger.info('Clarity disabled — CLARITY_PROJECT_ID not set');
      return app;
    }

    final ClarityConfig config = ClarityConfig(
      projectId: projectId,
      logLevel: Env.isDebug ? LogLevel.Info : LogLevel.None,
    );
    if (!config.isProjectIdValid()) {
      _logger.warning('CLARITY_PROJECT_ID is not a valid Clarity project id');
      return app;
    }

    // Buffered by the SDK and attached once the session starts.
    Clarity.setCustomTag('environment', Env.environment);
    Clarity.setCustomTag('app_flavor', Env.appFlavor);
    _logger.info('Clarity enabled for ${Env.appFlavor}');
    return ClarityWidget(app: app, clarityConfig: config);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object?>? properties,
  }) async {
    Clarity.setCustomUserId(userId);
    if (properties != null) await setSuperProperties(properties);
  }

  /// Clarity cannot unset the custom user ID and carries tags into new
  /// sessions, so logout swaps in a fresh anonymous ID, blanks the sangha tag
  /// and cuts a new session. Nothing recorded from here on is attributed to
  /// the previous user or their groups.
  @override
  Future<void> reset() async {
    if (_sanghas.isNotEmpty) {
      _sanghas.clear();
      Clarity.setCustomTag(AnalyticsGroupTypes.sangha, 'none');
    }
    Clarity.setCustomUserId('anon-${const Uuid().v4()}');
    Clarity.startNewSession((_) {});
  }

  /// The bare name keeps the dashboard's custom-event filter clean; a second
  /// event carries the non-sensitive properties into the recording timeline.
  @override
  Future<void> track(String event, {Map<String, Object?>? properties}) async {
    Clarity.sendCustomEvent(event);
    final String? details = formatEventDetails(event, properties);
    if (details != null) Clarity.sendCustomEvent(details);
    _tagSangha(properties);
  }

  void _tagSangha(Map<String, Object?>? properties) {
    final Object? groupId = properties?[AnalyticsProperties.groupId];
    if (groupId is! String || groupId.isEmpty || !_sanghas.add(groupId)) {
      return;
    }
    Clarity.setCustomTags(AnalyticsGroupTypes.sangha, _sanghas);
  }

  @override
  Future<void> setSuperProperties(Map<String, Object?> properties) async {
    for (final MapEntry<String, String> entry in tagEntries(properties)) {
      Clarity.setCustomTag(entry.key, entry.value);
    }
  }

  @override
  List<NavigatorObserver> get routeObservers => [
    ClarityScreenObserver(_screenTracker),
  ];

  /// Bottom tab shown by the home shell; tabs are not routes, so the shell's
  /// screen name comes from here.
  void setTab(String tab) => _screenTracker.setTab(tab);

  /// `event key=value key=value`, or null when no property survives
  /// redaction. Cut to Clarity's custom event limit.
  static String? formatEventDetails(
    String event,
    Map<String, Object?>? properties,
  ) {
    if (properties == null) return null;
    final List<String> parts = [
      for (final MapEntry<String, String> entry in tagEntries(properties))
        '${entry.key}=${entry.value}',
    ];
    if (parts.isEmpty) return null;
    final String details = '$event ${parts.join(' ')}';
    if (details.length <= _customEventMaxLength) return details;
    return details.substring(0, _customEventMaxLength);
  }

  /// Drops nulls, redacted keys and blank values; collapses whitespace.
  static List<MapEntry<String, String>> tagEntries(
    Map<String, Object?> properties,
  ) {
    final List<MapEntry<String, String>> entries = [];
    for (final MapEntry<String, Object?> entry in properties.entries) {
      final Object? value = entry.value;
      if (value == null || _redactedKeys.contains(entry.key)) continue;
      final String text =
          value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty) continue;
      entries.add(MapEntry(entry.key, text));
    }
    return entries;
  }
}
