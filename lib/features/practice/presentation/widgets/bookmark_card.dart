import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_date_format.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A single bookmark row.
///
/// Two layouts: text/verse bookmarks use a left accent bar with a title +
/// excerpt; everything else uses a leading type-icon tile (the API carries no
/// artwork, so icons stand in for covers). The trailing filled bookmark toggles
/// removal.
class BookmarkCard extends StatelessWidget {
  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.onRemove,
    this.onTap,
  });

  final BookmarkDTO bookmark;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                bookmark.isText
                    ? _buildTextRow(context, isDark)
                    : _buildIconRow(context, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildIconRow(BuildContext context, bool isDark) {
    final dateLabel = _secondaryLabel(context);
    return Row(
      children: [
        _Leading(bookmark: bookmark, isDark: isDark),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _displayTitle(context),
                style: _titleStyle(isDark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (dateLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        _RemoveButton(onRemove: onRemove, isDark: isDark),
      ],
    );
  }

  /// Secondary line under the title: a chant count for collections (or a notice
  /// when the group deleted the collection), otherwise the plan/series schedule.
  String? _secondaryLabel(BuildContext context) {
    if (bookmark.type == BookmarkItemType.groupAccumulator) {
      return bookmark.isOrphaned ? 'No longer available' : null;
    }
    if (bookmark.type == BookmarkItemType.groupRecitationCollection ||
        bookmark.type == BookmarkItemType.recitationCollection) {
      if (bookmark.isOrphaned) {
        return context.l10n.my_recitation_collection_unavailable;
      }
      final count = bookmark.itemCount;
      if (count == null || count < 0) return null;
      return bookmark.type == BookmarkItemType.recitationCollection
          ? context.l10n.my_recitation_collection_chant_count_owner(count)
          : context.l10n.my_recitation_collection_chant_count(count);
    }

    return PlanDateFormat.formatRangeOrSingle(
      bookmark.startDate,
      bookmark.endDate,
    );
  }

  Widget _buildTextRow(BuildContext context, bool isDark) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey500 : AppColors.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _displayTitle(context),
                  style: _titleStyle(isDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (bookmark.excerpt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    bookmark.excerpt!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RemoveButton(onRemove: onRemove, isDark: isDark),
        ],
      ),
    );
  }

  TextStyle _titleStyle(bool isDark) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
  );

  String _displayTitle(BuildContext context) {
    final preferred = bookmark.nestedTitle ?? bookmark.name;
    if (preferred != null && preferred.trim().isNotEmpty) {
      return preferred.trim();
    }
    return switch (bookmark.type) {
      BookmarkItemType.groupRecitationCollection ||
      BookmarkItemType.recitationCollection =>
        context.l10n.my_recitation_collection_fallback_title,
      _ => bookmark.displayTitle,
    };
  }
}

/// Leading visual: real artwork when the bookmark carries it (plan/series
/// cover, accumulator bead), otherwise a type-based icon tile.
class _Leading extends StatelessWidget {
  const _Leading({required this.bookmark, required this.isDark});

  final BookmarkDTO bookmark;
  final bool isDark;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final image = bookmark.leadingImage;
    if (image != null && !image.isEmpty) {
      final radius = BorderRadius.circular(bookmark.isRoundLeading ? _size / 2 : 10);
      return ResponsiveCoverImage(
        image: image,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        borderRadius: radius,
      );
    }
    return _IconTile(type: bookmark.type, isDark: isDark);
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.type, required this.isDark});

  final BookmarkItemType type;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final iconColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    // Mala (accumulator) reads as a round mala bead; the rest are rounded tiles.
    final isRound = type == BookmarkItemType.accumulator;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        shape: isRound ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isRound ? null : BorderRadius.circular(10),
      ),
      child: Icon(_iconFor(type), size: 26, color: iconColor),
    );
  }

  IconData _iconFor(BookmarkItemType type) => switch (type) {
    BookmarkItemType.timer => PhosphorIconsRegular.timer,
    BookmarkItemType.plan => PhosphorIconsRegular.calendarCheck,
    BookmarkItemType.series => PhosphorIconsRegular.cards,
    BookmarkItemType.accumulator ||
    BookmarkItemType.groupAccumulator =>
      PhosphorIconsRegular.circlesThree,
    BookmarkItemType.text ||
    BookmarkItemType.verse ||
    BookmarkItemType.groupRecitationCollection ||
    BookmarkItemType.recitationCollection => PhosphorIconsRegular.bookOpenText,
  };
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onRemove, required this.isDark});

  final VoidCallback onRemove;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      splashRadius: 22,
      onPressed: () {
        HapticFeedback.lightImpact();
        onRemove();
      },
      icon: Icon(
        PhosphorIconsFill.bookmarkSimple,
        size: 22,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
    );
  }
}
