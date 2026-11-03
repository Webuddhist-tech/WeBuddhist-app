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
/// The default names the block after its first item with a non-blank label,
/// since API sessions may arrive without a title. Returns null when the block
/// has no title and no item has a label.
String? routineBlockDisplayTitle(RoutineBlock block, AppLocalizations l10n) {
  final title = block.title?.trim();
  if (title != null && title.isNotEmpty) return title;
  final firstItem =
      block.items
          .map((item) => routineItemDisplayTitle(item, l10n).trim())
          .where((label) => label.isNotEmpty)
          .firstOrNull;
  if (firstItem == null) return null;
  final remaining = block.items.length - 1;
  if (remaining == 0) return firstItem;
  return l10n.routine_block_default_title(firstItem, remaining);
}
