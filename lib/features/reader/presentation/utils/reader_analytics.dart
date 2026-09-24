import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/analytics_providers.dart';
import 'package:flutter_pecha/core/analytics/analytics_service.dart';
import 'package:flutter_pecha/core/analytics/analytics_tracking.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the reader was opened from, carried on `reader_opened` as `source`.
enum ReaderOpenSource {
  plan,
  routine,
  recitation,
  search,
  aiSearch,
  deepLink,
  collection,
  groupChant,
  library,
  bookmark;

  String get key => switch (this) {
    ReaderOpenSource.aiSearch => 'ai_search',
    ReaderOpenSource.deepLink => 'deep_link',
    ReaderOpenSource.groupChant => 'group_chant',
    _ => name,
  };
}

/// The tracking plan's source for a navigation source. Plain browsing has no
/// source of its own, so it counts as the library.
ReaderOpenSource readerOpenSourceFor(NavigationSource? source) {
  return switch (source) {
    NavigationSource.plan => ReaderOpenSource.plan,
    NavigationSource.routine => ReaderOpenSource.routine,
    NavigationSource.recitationList => ReaderOpenSource.recitation,
    NavigationSource.search => ReaderOpenSource.search,
    NavigationSource.deepLink => ReaderOpenSource.deepLink,
    NavigationSource.groupRecitationCollection ||
    NavigationSource.myRecitationCollection => ReaderOpenSource.collection,
    NavigationSource.groupAccumulatorChant => ReaderOpenSource.groupChant,
    NavigationSource.normal || null => ReaderOpenSource.library,
  };
}

/// How the text is laid out, carried on `reader_opened` as `layout`.
enum ReaderLayout { single, interlinear, split }

/// The layout the reader starts in: a translation underneath when the
/// parallel toggle is on, else one text. Split panels open later.
ReaderLayout readerLayoutFor(ReaderDualLayoutSettings settings) =>
    settings.secondaryEnabled ? ReaderLayout.interlinear : ReaderLayout.single;

/// A segment action bar button, carried on `reader_action_tapped`.
enum ReaderAction { copy, bookmark, share, commentary, version, video }

/// What one reading session added up to.
class ReaderSessionSummary {
  const ReaderSessionSummary({
    required this.duration,
    required this.pagesLoaded,
    required this.maxSegmentNumber,
  });

  final Duration duration;
  final int pagesLoaded;
  final int maxSegmentNumber;
}

/// Counts one reading session: from the reader opening until it closes or
/// stays in the background past [backgroundGrace]. Time in the background is
/// not reading, so a session that ends there ends when it left the screen.
class ReaderSessionTracker {
  ReaderSessionTracker({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const Duration backgroundGrace = Duration(seconds: 30);

  final DateTime Function() _now;
  DateTime? _startedAt;
  DateTime? _backgroundedAt;
  int _pagesLoaded = 0;
  int _maxSegmentNumber = 0;

  bool get isActive => _startedAt != null;

  /// How long the app has been in the background, zero while in front.
  Duration get backgroundedFor {
    final at = _backgroundedAt;
    return at == null ? Duration.zero : _now().difference(at);
  }

  /// Starts a session. The furthest segment carries over: a reader coming
  /// back after a long break is still that far into the text.
  void start() {
    _startedAt = _now();
    _backgroundedAt = null;
    _pagesLoaded = 0;
  }

  void pageLoaded() => _pagesLoaded++;

  void segmentReached(int segmentNumber) {
    if (segmentNumber > _maxSegmentNumber) _maxSegmentNumber = segmentNumber;
  }

  void background() => _backgroundedAt ??= _now();

  void foreground() => _backgroundedAt = null;

  /// Ends the session, or returns null when none is running.
  ReaderSessionSummary? end() {
    final startedAt = _startedAt;
    if (startedAt == null) return null;
    final endedAt = _backgroundedAt ?? _now();
    _startedAt = null;
    _backgroundedAt = null;
    return ReaderSessionSummary(
      duration: endedAt.difference(startedAt),
      pagesLoaded: _pagesLoaded,
      maxSegmentNumber: _maxSegmentNumber,
    );
  }
}

/// Product analytics for the reader: one method per tracked event, so the
/// event names and their property keys live in one place. Every call fires
/// and forgets; callers fire after the thing happened, never optimistically.
class ReaderAnalytics {
  const ReaderAnalytics(this._analytics);

  final AnalyticsService _analytics;

  /// The reader showed its first page. Fired once per screen.
  void readerOpened({
    required String textId,
    required String textTitle,
    required ReaderOpenSource source,
    required String language,
    required String versionId,
    required ReaderLayout layout,
    String? script,
    String? entrySegment,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.readerOpened, {
      AnalyticsProperties.textId: textId,
      AnalyticsProperties.textTitle: textTitle,
      AnalyticsProperties.source: source.key,
      AnalyticsProperties.language: language,
      AnalyticsProperties.versionId: versionId,
      AnalyticsProperties.script: script,
      AnalyticsProperties.layout: layout.name,
      AnalyticsProperties.entrySegment: entrySegment,
    });
  }

  /// A page fetch returned. [pageNumber] counts fetches for this text.
  void readerPageLoaded({
    required String textId,
    required int pageNumber,
    required int segmentCount,
    required int loadMs,
  }) {
    _analytics.trackInBackground(AnalyticsEvents.readerPageLoaded, {
      AnalyticsProperties.textId: textId,
      AnalyticsProperties.pageNumber: pageNumber,
      AnalyticsProperties.segmentCount: segmentCount,
      AnalyticsProperties.loadMs: loadMs,
    });
  }

  /// The reader closed or sat in the background too long. How far into the
  /// text the reader got is only sent when the text's length is known.
  void readerSessionEnded({
    required String textId,
    required ReaderSessionSummary session,
    int? segmentsTotal,
  }) {
    final hasTotal = segmentsTotal != null && segmentsTotal > 0;
    _analytics.trackInBackground(AnalyticsEvents.readerSessionEnded, {
      AnalyticsProperties.textId: textId,
      AnalyticsProperties.durationSeconds: session.duration.inSeconds,
      AnalyticsProperties.pagesLoaded: session.pagesLoaded,
      AnalyticsProperties.maxSegmentNumber: session.maxSegmentNumber,
      if (hasTotal) AnalyticsProperties.segmentsTotal: segmentsTotal,
      if (hasTotal)
        AnalyticsProperties.pctReached: (session.maxSegmentNumber *
                100 /
                segmentsTotal)
            .round()
            .clamp(0, 100),
    });
  }

  void actionTapped({required ReaderAction action, required String textId}) {
    _analytics.trackInBackground(AnalyticsEvents.readerActionTapped, {
      AnalyticsProperties.action: action.name,
      AnalyticsProperties.textId: textId,
    });
  }
}

final readerAnalyticsProvider = Provider<ReaderAnalytics>((ref) {
  return ReaderAnalytics(ref.watch(analyticsServiceProvider));
});
