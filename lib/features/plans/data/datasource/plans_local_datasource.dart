import 'dart:convert';

import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_days_model.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/data/models/plans_model.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _logger = AppLogger('PlansLocalDatasource');

enum PendingPlanActionType {
  subscribe,
  unsubscribe,
  completeTask,
  completeSubTask,
  deleteTask,
}

class PendingPlanAction {
  const PendingPlanAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAtMs,
  });

  final String id;
  final PendingPlanActionType type;
  final Map<String, dynamic> payload;
  final int createdAtMs;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'payload': payload,
    'createdAtMs': createdAtMs,
  };

  factory PendingPlanAction.fromJson(Map<String, dynamic> json) {
    return PendingPlanAction(
      id: (json['id'] as String?) ?? '',
      type: PendingPlanActionType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => PendingPlanActionType.completeTask,
      ),
      payload: Map<String, dynamic>.from(
        (json['payload'] as Map?) ?? const {},
      ),
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Persistent local source of truth for Plans.
///
/// Public catalogue data is namespaced by language. Authenticated user data
/// is namespaced by user id. Pending writes are queued per user so offline
/// actions can flush later without leaking between accounts.
class PlansLocalDatasource {
  static const String boxName = 'plans_local_data';

  Box<String> get _box => Hive.box<String>(boxName);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<String>(boxName);
      _logger.info('PlansLocalDatasource initialized');
    }
  }

  Future<String?> currentUserId() {
    return SharedPreferencesService.instance.get<String>(
      StorageKeys.currentUserId,
    );
  }

  /// Same id without an await, so a screen can seed its first frame.
  String? get currentUserIdSync {
    return SharedPreferencesService.instance.getSync<String>(
      StorageKeys.currentUserId,
    );
  }

  Stream<void> watchKey(String key) async* {
    await for (final _ in _box.watch(key: key)) {
      yield null;
    }
  }

  String plansKey({
    required String language,
    int skip = 0,
    int limit = 20,
    String? tag,
    String? search,
  }) =>
      'plans:$language:$skip:$limit:${tag ?? ''}:${search ?? ''}';

  String planByIdKey(String planId) => 'plan:$planId';

  String userPlansKey({
    required String userId,
    required String language,
    int? skip,
    int? limit,
    String? seriesId,
  }) =>
      'user_plans:$userId:$language:${skip ?? ''}:${limit ?? ''}:${seriesId ?? ''}';

  String userPlanDayKey(String userId, String planId, int dayNumber) =>
      'user_plan_day:$userId:$planId:$dayNumber';

  String completionStatusKey(String userId, String planId) =>
      'completion_status:$userId:$planId';

  String planProgressKey(String userId, String planId) =>
      'user_plan_progress:$userId:$planId';

  String planDaysKey(String planId) => 'plan_days:$planId';

  String planDayContentKey(String planId, int dayNumber) =>
      'plan_day_content:$planId:$dayNumber';

  String pendingActionsKey(String userId) => 'pending_plan_actions:$userId';

  List<PlansModel>? readPlans({
    required String language,
    int skip = 0,
    int limit = 20,
    String? tag,
    String? search,
  }) {
    return _readModelList(
      plansKey(
        language: language,
        skip: skip,
        limit: limit,
        tag: tag,
        search: search,
      ),
      PlansModel.fromJson,
    );
  }

  Future<void> savePlans({
    required String language,
    int skip = 0,
    int limit = 20,
    String? tag,
    String? search,
    required List<PlansModel> plans,
  }) async {
    await _writeModelList(
      plansKey(
        language: language,
        skip: skip,
        limit: limit,
        tag: tag,
        search: search,
      ),
      plans.map((plan) => plan.toJson()).toList(),
    );
    for (final plan in plans) {
      await savePlanById(plan);
    }
  }

  PlansModel? readPlanById(String planId) {
    return _readObject(planByIdKey(planId), PlansModel.fromJson);
  }

  Future<void> savePlanById(PlansModel plan) {
    return _writeObject(planByIdKey(plan.id), plan.toJson());
  }

  UserPlanListResponseModel? readUserPlans({
    required String userId,
    required String language,
    int? skip,
    int? limit,
    String? seriesId,
  }) {
    final direct = _readObject(
      userPlansKey(
        userId: userId,
        language: language,
        skip: skip,
        limit: limit,
        seriesId: seriesId,
      ),
      UserPlanListResponseModel.fromJson,
    );
    if (direct != null) return direct;

    if (skip == null && limit == null && seriesId == null) {
      return _readObject(
        userPlansKey(
          userId: userId,
          language: language,
          skip: 0,
          limit: 20,
          seriesId: null,
        ),
        UserPlanListResponseModel.fromJson,
      );
    }
    return null;
  }

  Future<void> saveUserPlans({
    required String userId,
    required String language,
    int? skip,
    int? limit,
    String? seriesId,
    required UserPlanListResponseModel response,
  }) async {
    await _writeObject(
      userPlansKey(
        userId: userId,
        language: language,
        skip: skip,
        limit: limit,
        seriesId: seriesId,
      ),
      response.toJson(),
    );

    if (skip == 0 && seriesId == null) {
      await _writeObject(
        userPlansKey(
          userId: userId,
          language: language,
        ),
        response.toJson(),
      );
    }
  }

  UserPlanDayDetailResponse? readUserPlanDay(
    String userId,
    String planId,
    int dayNumber,
  ) {
    return _readObject(
      userPlanDayKey(userId, planId, dayNumber),
      UserPlanDayDetailResponse.fromJson,
    );
  }

  Future<void> saveUserPlanDay(
    String userId,
    String planId,
    int dayNumber,
    UserPlanDayDetailResponse response,
  ) {
    return _writeObject(
      userPlanDayKey(userId, planId, dayNumber),
      response.toJson(),
    );
  }

  Map<int, bool>? readCompletionStatus(String userId, String planId) {
    final raw = _box.get(completionStatusKey(userId, planId));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(int.parse(key), value as bool),
      );
    } catch (e, st) {
      _logger.error(
        'Failed to read completion status for $userId/$planId',
        e,
        st,
      );
      return null;
    }
  }

  Future<void> saveCompletionStatus(
    String userId,
    String planId,
    Map<int, bool> status,
  ) {
    final encoded = status.map((key, value) => MapEntry('$key', value));
    return _box.put(
      completionStatusKey(userId, planId),
      jsonEncode(encoded),
    );
  }

  List<PlanProgressModel>? readPlanProgress(String userId, String planId) {
    return _readModelList(
      planProgressKey(userId, planId),
      PlanProgressModel.fromJson,
    );
  }

  Future<void> savePlanProgress(
    String userId,
    String planId,
    List<PlanProgressModel> progress,
  ) {
    return _writeModelList(
      planProgressKey(userId, planId),
      progress.map((item) => item.toJson()).toList(),
    );
  }

  List<PlanDaysModel>? readPlanDays(String planId) {
    return _readModelList(planDaysKey(planId), PlanDaysModel.fromJson);
  }

  Future<void> savePlanDays(String planId, List<PlanDaysModel> days) async {
    await _writeModelList(
      planDaysKey(planId),
      days.map((day) => day.toJson()).toList(),
    );
    for (final day in days) {
      await savePlanDayContent(planId, day.dayNumber, day);
    }
  }

  PlanDaysModel? readPlanDayContent(String planId, int dayNumber) {
    return _readObject(
      planDayContentKey(planId, dayNumber),
      PlanDaysModel.fromJson,
    );
  }

  Future<void> savePlanDayContent(
    String planId,
    int dayNumber,
    PlanDaysModel day,
  ) {
    return _writeObject(
      planDayContentKey(planId, dayNumber),
      day.toJson(),
    );
  }

  List<PendingPlanAction> readPendingActions(String userId) {
    return _readModelList(
          pendingActionsKey(userId),
          PendingPlanAction.fromJson,
        ) ??
        const <PendingPlanAction>[];
  }

  Future<PendingPlanAction> enqueueAction(
    String userId, {
    required PendingPlanActionType type,
    required Map<String, dynamic> payload,
  }) async {
    final createdAtMs = DateTime.now().millisecondsSinceEpoch;
    final action = PendingPlanAction(
      id: '$createdAtMs:${type.name}:${jsonEncode(payload)}',
      type: type,
      payload: payload,
      createdAtMs: createdAtMs,
    );
    await _writeModelList(
      pendingActionsKey(userId),
      [
        ...readPendingActions(userId),
        action,
      ].map((item) => item.toJson()).toList(),
    );
    return action;
  }

  Future<void> removePendingAction(String userId, String actionId) {
    final remaining =
        readPendingActions(userId)
            .where((item) => item.id != actionId)
            .map((item) => item.toJson())
            .toList();
    return _writeModelList(pendingActionsKey(userId), remaining);
  }

  T? _readObject<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, st) {
      _logger.error('Failed to read plans object for $key', e, st);
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
      _logger.error('Failed to read plans list for $key', e, st);
      return null;
    }
  }

  Future<void> _writeObject(String key, Map<String, dynamic> data) {
    return _box.put(key, jsonEncode(data));
  }

  Future<void> _writeModelList(String key, List<Map<String, dynamic>> data) {
    return _box.put(key, jsonEncode(data));
  }
}
