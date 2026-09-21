import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_session_complete_sheet.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_sync_manager.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Opens a group accumulation practice directly (reader or mala), joining
/// first when needed. Returns true when the user recited at least once.
/// [eventId] makes the reader follow that event's live recitation.
Future<bool> openGroupAccumulatorPractice(
  BuildContext context,
  WidgetRef ref, {
  required String accumulatorId,
  String? eventId,
}) async {
  final authState = ref.read(authProvider);
  if (authState.isGuest || !authState.isLoggedIn) {
    LoginDrawer.show(context, ref);
    return false;
  }

  var detail = await _loadDetail(ref, accumulatorId);
  if (detail == null || !context.mounted) return false;

  final localJoinedIds = ref.read(
    groupAccumulatorJoinCacheProvider(detail.groupId),
  );
  if (!accumulatorHasJoined(detail, localJoinedIds: localJoinedIds)) {
    final joined = await joinGroupAccumulator(
      ref: ref,
      accumulatorId: detail.id,
      groupId: detail.groupId,
    );
    if (!context.mounted) return false;
    if (!joined) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.group_accumulator_join_error),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    detail = await _loadDetail(ref, accumulatorId) ?? detail;
    if (!context.mounted) return false;
  }

  final countBefore = detail.user?.totalCount ?? 0;

  if (!detail.hasTextContent) {
    final presetId = detail.presetAccumulatorId;
    if (presetId.isEmpty) return false;
    await context.push(
      '/mala',
      extra: {'presetId': presetId, 'groupAccumulatorId': detail.id},
    );
    if (!context.mounted) return false;
    await _refreshAfterPractice(ref, detail);
    return await _countIncreased(ref, accumulatorId, countBefore);
  }

  final textId = detail.textId;
  if (textId == null || textId.isEmpty) return false;

  final groupName = _resolveGroupName(ref, detail.groupId);
  final sessionCount = await PlanNavigator.push<int>(
    context,
    PlanTextItem.sourceReference(textId: textId, title: detail.title),
    NavigationContext(
      source: NavigationSource.groupAccumulatorChant,
      groupAccumulatorId: detail.id,
      presetAccumulatorId: detail.presetAccumulatorId,
      groupId: detail.groupId,
      groupTitle: groupName,
      groupAccumulatorSessionCount: detail.user?.totalCount ?? 0,
      eventId: eventId,
    ),
  );
  if (!context.mounted) return false;

  await _refreshAfterPractice(ref, detail);
  final practiced =
      (sessionCount ?? 0) > 0 ||
      await _countIncreased(ref, accumulatorId, countBefore);
  if (sessionCount == null || !context.mounted) return practiced;

  showGroupAccumulatorSessionCompleteSheet(
    context,
    sessionCount: sessionCount,
    accumulationTitle: detail.title,
    accumulatorId: detail.id,
    groupId: detail.groupId,
    groupName: groupName,
  );
  return practiced;
}

Future<bool> _countIncreased(
  WidgetRef ref,
  String accumulatorId,
  int countBefore,
) async {
  final detail = await _loadDetail(ref, accumulatorId);
  return (detail?.user?.totalCount ?? 0) > countBefore;
}

Future<GroupAccumulatorDetail?> _loadDetail(
  WidgetRef ref,
  String accumulatorId,
) async {
  try {
    final either = await ref.read(
      groupAccumulatorDetailProvider(accumulatorId).future,
    );
    return either.fold((_) => null, (detail) => detail);
  } catch (_) {
    return null;
  }
}

Future<void> _refreshAfterPractice(
  WidgetRef ref,
  GroupAccumulatorDetail detail,
) async {
  // Wait for the in-flight sweep too: the practice screen already kicked off
  // a flush on leave, and a plain flush() returns at once while one runs.
  try {
    await ref
        .read(malaSyncManagerProvider)
        .flushAndSettle(SyncReason.screenLeave);
  } catch (_) {}
  refreshGroupAccumulatorData(
    ref,
    accumulatorId: detail.id,
    groupId: detail.groupId,
  );
}

String? _resolveGroupName(WidgetRef ref, String groupId) {
  final title = ref
      .read(groupProfileProvider(groupId))
      .whenOrNull(
        data: (either) => either.fold((_) => null, (profile) => profile.title),
      );
  final trimmed = title?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
