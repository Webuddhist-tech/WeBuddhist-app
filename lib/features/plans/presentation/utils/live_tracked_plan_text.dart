import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the plan item for [liveTextId].
///
/// An exact text id wins. Otherwise the first source text whose id is in
/// [editionIds] — other editions of the same work, such as the English text
/// of a Tibetan recitation.
int planItemIndexForLiveEditions({
  required List<PlanTextItem> items,
  required String liveTextId,
  Set<String> editionIds = const {},
}) {
  if (liveTextId.isEmpty) return -1;
  final exact = items.indexWhere(
    (item) => item.isSourceReference && item.textId == liveTextId,
  );
  if (exact >= 0) return exact;
  if (editionIds.isEmpty) return -1;
  return items.indexWhere(
    (item) => item.isSourceReference && editionIds.contains(item.textId),
  );
}

/// Editions of [liveTextId] in [languages], from the library version list.
Future<Set<String>> liveTextEditionIds(
  WidgetRef ref,
  String liveTextId,
  List<String> languages,
) async {
  final ids = <String>{};
  final seen = <String>{};
  for (final language in languages) {
    final code = language.trim();
    if (code.isEmpty || !seen.add(code)) continue;
    try {
      final versions = await ref.read(
        readerVersionsProvider(
          ReaderLanguageQuery(textId: liveTextId, language: code),
        ).future,
      );
      for (final version in versions) {
        if (version.id.isNotEmpty) ids.add(version.id);
      }
    } catch (_) {}
  }
  return ids;
}

/// Opens the plan item live tracking is on, the same way a tap on that task
/// does. The live segment is used when the plan item is that same edition;
/// another language keeps the task's own first segment and live follow
/// aligns the verse.
Future<void> openLiveTrackedPlanText({
  required BuildContext context,
  required WidgetRef ref,
  required List<PlanTextItem> items,
  required String liveTextId,
  required String? liveSegmentId,
  required String planId,
  required int dayNumber,
  required String? dayAudioUrl,
  required String? eventId,
  required bool isOnlineAttendee,
  required List<String> languages,
}) async {
  if (items.isEmpty || liveTextId.isEmpty) return;
  var index = planItemIndexForLiveEditions(
    items: items,
    liveTextId: liveTextId,
  );
  if (index < 0) {
    final editions = await liveTextEditionIds(ref, liveTextId, languages);
    if (!context.mounted) return;
    index = planItemIndexForLiveEditions(
      items: items,
      liveTextId: liveTextId,
      editionIds: editions,
    );
  }
  if (index < 0) return;

  final target = items[index];
  final sameEdition = target.textId == liveTextId;
  final segment =
      sameEdition && liveSegmentId != null && liveSegmentId.isNotEmpty
          ? liveSegmentId
          : target.firstSegmentId;
  await PlanNavigator.push(
    context,
    target,
    NavigationContext(
      source: NavigationSource.plan,
      planId: planId,
      dayNumber: dayNumber,
      targetSegmentId: segment,
      planTextItems: items,
      currentTextIndex: index,
      dayAudioUrl: dayAudioUrl,
      eventId: eventId,
      isOnlineAttendee: isOnlineAttendee,
    ),
  );
}
