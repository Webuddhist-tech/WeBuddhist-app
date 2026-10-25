import 'dart:async';
import 'dart:convert';

import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/home/data/models/routine_info_model.dart';
import 'package:flutter_pecha/features/home/data/models/series_model.dart';
import 'package:flutter_pecha/features/home/data/models/today_event_model.dart';
import 'package:flutter_pecha/features/home/data/models/verse_of_day_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/featured_day_response.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _logger = AppLogger('HomeLocalDatasource');

/// Persistent local source of truth for Home.
///
/// This is intentionally not wired through the TTL cache service: Home must keep the
/// last known good data available offline even when a TTL would have expired.
class HomeLocalDatasource {
  static const String boxName = 'home_local_data';

  Box<String> get _box => Hive.box<String>(boxName);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<String>(boxName);
      _logger.info('HomeLocalDatasource initialized');
    }
  }

  Future<String?> currentUserId() {
    return SharedPreferencesService.instance.get<String>(
      StorageKeys.currentUserId,
    );
  }

  Stream<void> watchKey(String key) async* {
    await for (final _ in _box.watch(key: key)) {
      yield null;
    }
  }

  String featuredDayKey(String language) => 'featured_day:$language';
  String tagsKey(String language) => 'tags:$language';
  // v3: entries cached before the request sent auth lack progress/partner.
  String featuredSeriesKey(String language, int limit) =>
      'featured_series:v3:$language:$limit';
  String seriesListKey(String language) => 'series_list:$language';
  String seriesByIdKey(String language, String id) =>
      'series:v2:$language:$id';
  // v2: entries cached before group_avatar_url was read lack the avatar.
  String todayEventsKey(String language) => 'today_events:v2:$language';
  String verseOfDayKey(String language) => 'verse_of_day:$language';
  String routineInfoKey(String userId) => 'routine_info:$userId';
  String streakKey(String userId) => 'streak:$userId';
  String enrollmentsKey(String userId) => 'series_enrollments:$userId';
  String pendingEnrollmentsKey(String userId) =>
      'pending_series_enrollments:$userId';

  FeaturedDayResponse? readFeaturedDay(String language) {
    return _readObject(featuredDayKey(language), FeaturedDayResponse.fromJson);
  }

  Future<void> saveFeaturedDay(String language, FeaturedDayResponse response) {
    return _writeObject(featuredDayKey(language), response.toJson());
  }

  List<String>? readTags(String language) {
    return _readStringList(tagsKey(language));
  }

  Future<void> saveTags(String language, List<String> tags) {
    return _writeList(tagsKey(language), tags);
  }

  List<SeriesModel>? readFeaturedSeries(String language, int limit) {
    return _readModelList(
      featuredSeriesKey(language, limit),
      SeriesModel.fromJson,
    );
  }

  Future<void> saveFeaturedSeries(
    String language,
    int limit,
    List<SeriesModel> series,
  ) async {
    await _writeModelList(
      featuredSeriesKey(language, limit),
      series.map((s) => s.toJson()).toList(),
    );
  }

  List<SeriesModel>? readSeriesList(String language) {
    return _readModelList(seriesListKey(language), SeriesModel.fromJson);
  }

  Future<void> saveSeriesList(String language, List<SeriesModel> series) async {
    await _writeModelList(
      seriesListKey(language),
      series.map((s) => s.toJson()).toList(),
    );
  }

  SeriesModel? readSeriesById(String language, String id) {
    return _readObject(seriesByIdKey(language, id), SeriesModel.fromJson);
  }

  Future<void> saveSeriesById(String language, SeriesModel series) {
    return _writeObject(seriesByIdKey(language, series.id), series.toJson());
  }

  List<TodayEventModel>? readTodayEvents(String language) {
    return _readModelList(todayEventsKey(language), TodayEventModel.fromJson);
  }

  Future<void> saveTodayEvents(String language, List<TodayEventModel> events) {
    return _writeModelList(
      todayEventsKey(language),
      events.map((e) => e.toJson()).toList(),
    );
  }

  VerseOfDayModel? readVerseOfDay(String language) {
    return _readObject(verseOfDayKey(language), VerseOfDayModel.fromJson);
  }

  Future<void> saveVerseOfDay(String language, VerseOfDayModel verse) {
    return _writeObject(verseOfDayKey(language), verse.toJson());
  }

  RoutineInfoModel? readRoutineInfo(String userId) {
    return _readObject(routineInfoKey(userId), RoutineInfoModel.fromJson);
  }

  Future<void> saveRoutineInfo(String userId, RoutineInfoModel info) {
    return _writeObject(routineInfoKey(userId), info.toJson());
  }

  int? readStreak(String userId) {
    final raw = _box.get(streakKey(userId));
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<void> saveStreak(String userId, int streak) {
    return _box.put(streakKey(userId), streak.toString());
  }

  Set<String>? readEnrollments(String userId) {
    return _readStringList(enrollmentsKey(userId))?.toSet();
  }

  Future<void> saveEnrollments(String userId, Set<String> ids) {
    return _writeList(enrollmentsKey(userId), ids.toList()..sort());
  }

  Set<String> readPendingEnrollments(String userId) {
    return _readStringList(pendingEnrollmentsKey(userId))?.toSet() ??
        const <String>{};
  }

  Future<void> enqueueEnrollment(String userId, String seriesId) async {
    final pending = {...readPendingEnrollments(userId), seriesId};
    await _writeList(pendingEnrollmentsKey(userId), pending.toList()..sort());

    final enrollments = {...?readEnrollments(userId), seriesId};
    await saveEnrollments(userId, enrollments);
  }

  Future<void> removePendingEnrollment(String userId, String seriesId) {
    final pending = {...readPendingEnrollments(userId)}..remove(seriesId);
    return _writeList(pendingEnrollmentsKey(userId), pending.toList()..sort());
  }

  /// Undoes [enqueueEnrollment] when the server rejected the enrollment, so
  /// the Enroll button comes back. Leaves [seriesId] in the enrollments when
  /// [keepEnrolled] (the user was already enrolled before this attempt).
  Future<void> discardEnrollment(
    String userId,
    String seriesId, {
    bool keepEnrolled = false,
  }) async {
    await removePendingEnrollment(userId, seriesId);
    if (keepEnrolled) return;
    final enrollments = readEnrollments(userId);
    if (enrollments == null || !enrollments.contains(seriesId)) return;
    await saveEnrollments(userId, {...enrollments}..remove(seriesId));
  }

  T? _readObject<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, st) {
      _logger.error('Failed to read home object for $key', e, st);
      return null;
    }
  }

  List<T>? _readModelList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logger.error('Failed to read home list for $key', e, st);
      return null;
    }
  }

  List<String>? _readStringList(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List<dynamic>).whereType<String>().toList();
    } catch (e, st) {
      _logger.error('Failed to read string list for $key', e, st);
      return null;
    }
  }

  Future<void> _writeObject(String key, Map<String, dynamic> data) {
    return _box.put(key, jsonEncode(data));
  }

  Future<void> _writeModelList(String key, List<Map<String, dynamic>> data) {
    return _box.put(key, jsonEncode(data));
  }

  Future<void> _writeList(String key, List<String> data) {
    return _box.put(key, jsonEncode(data));
  }
}
