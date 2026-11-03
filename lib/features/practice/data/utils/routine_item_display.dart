import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';

/// Localized label for a [RoutineItem].
///
/// Timer items derive their title from [RoutineItem.durationMs] so persisted
/// data stays locale-neutral when the app language changes.
String routineItemDisplayTitle(RoutineItem item, AppLocalizations l10n) {
  if (item.type == RoutineItemType.timer) {
    final durationMs = item.durationMs;
    if (durationMs != null && durationMs > 0) {
      return l10n.timer_minute_session(durationMs ~/ 60000);
    }
  }
  return item.title;
}

/// Title shown for a [RoutineBlock]: the user-given title, or a default built
/// from its items ("Morning chants" / "Morning chants +3 more").
///
/// Returns null when the block has neither a title nor items.
String? routineBlockDisplayTitle(RoutineBlock block, AppLocalizations l10n) {
  final title = block.title;
  if (title != null && title.isNotEmpty) return title;
  if (block.items.isEmpty) return null;
  final firstItem = routineItemDisplayTitle(block.items.first, l10n);
  final remaining = block.items.length - 1;
  if (remaining == 0) return firstItem;
  return l10n.routine_block_default_title(firstItem, remaining);
}
