import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_time_utils.dart';

RoutineData routineDataFromApiResponse(RoutineResponse? response) {
  if (response == null) return const RoutineData();
  final blocks = response.timeBlocks.map(routineBlockFromDto).toList();
  return RoutineData(blocks: blocks, apiRoutineId: response.id).sortedByTime;
}

RoutineBlock routineBlockFromDto(TimeBlockDTO tb) {
  final sessions = List<SessionDTO>.from(tb.sessions)
    ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  return RoutineBlock(
    id: tb.id,
    time: hhmmToTime(tb.timeInt),
    title: RoutineBlock.normalizeTitle(tb.title),
    notificationEnabled: tb.notificationEnabled,
    apiTimeBlockId: tb.id,
    items: sessions.map(routineItemFromSessionDto).toList(),
  );
}

RoutineItem routineItemFromSessionDto(SessionDTO s) {
  return RoutineItem(
    id: s.sourceId,
    title: s.title,
    coverImage: s.coverImage,
    type: switch (s.sessionType) {
      SessionType.plan => RoutineItemType.plan,
      SessionType.series => RoutineItemType.series,
      SessionType.recitation => RoutineItemType.recitation,
      SessionType.timer => RoutineItemType.timer,
      SessionType.accumulator => RoutineItemType.accumulator,
      SessionType.groupRecitationCollection =>
        RoutineItemType.groupRecitationCollection,
      SessionType.recitationCollection =>
        RoutineItemType.myRecitationCollection,
      SessionType.groupAccumulator => RoutineItemType.groupAccumulator,
      SessionType.unknown => RoutineItemType.unknown,
    },
    enrolledAt: s.startedAt,
    language: s.language.isEmpty ? null : s.language,
    startDate: s.startDate,
    currentPlanId: _nonEmptyId(s.currentPlanId) ??
        (s.sessionType == SessionType.plan ? s.sourceId : null),
    currentPlanTitle: s.currentPlanTitle,
    durationMs: s.durationMs,
    firstSegment: s.firstSegment,
    itemCount: s.itemCount,
    rawSessionType: s.rawSessionType,
  );
}

String? _nonEmptyId(String? value) {
  if (value == null || value.isEmpty) return null;
  return value;
}

List<SessionRequest> _sessionsForBlock(RoutineBlock block) {
  final sessions = <SessionRequest>[];
  for (var i = 0; i < block.items.length; i++) {
    final item = block.items[i];
    // Timer items without a duration can't be synced — skip them rather than
    // send an incomplete payload that the backend will reject.
    if (item.type == RoutineItemType.timer && item.durationMs == null) continue;
    sessions.add(
      SessionRequest(
        sessionType: switch (item.type) {
          RoutineItemType.plan => SessionType.plan,
          RoutineItemType.series => SessionType.series,
          RoutineItemType.recitation => SessionType.recitation,
          RoutineItemType.timer => SessionType.timer,
          RoutineItemType.accumulator => SessionType.accumulator,
          RoutineItemType.groupRecitationCollection =>
            SessionType.groupRecitationCollection,
          RoutineItemType.myRecitationCollection =>
            SessionType.recitationCollection,
          RoutineItemType.groupAccumulator => SessionType.groupAccumulator,
          RoutineItemType.unknown => SessionType.unknown,
        },
        sourceId: item.id,
        displayOrder: i,
        durationMs: item.durationMs,
        rawSessionType: item.rawSessionType,
      ),
    );
  }
  return sessions;
}

/// Converts a [RoutineBlock] to a [TimeBlockRequest] suitable for both
/// create and update API calls.
TimeBlockRequest routineBlockToRequest(RoutineBlock block) {
  return TimeBlockRequest(
    time: formatRoutineTime24h(block.time),
    timeInt: timeToHHMM(block.time),
    title: block.title,
    notificationEnabled: block.notificationEnabled,
    sessions: _sessionsForBlock(block),
  );
}
