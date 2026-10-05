import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/group_accumulation_counts_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_accumulation_selection_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/group_accumulations_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fixed bottom bar for a group accumulation chant session in the reader.
///
/// Shows the session count pill (left) and the chant title in its script
/// (centre). The pill carries the avatar of the target chants are being added
/// to and opens [GroupAccumulationsSheet] to switch it.
class GroupAccumulatorChantBar extends ConsumerWidget {
  const GroupAccumulatorChantBar({
    super.key,
    required this.mantra,
    required this.sessionCount,
    required this.chantTitle,
    this.chantTitleFontFamily,
  });

  /// The chant's preset, as the key the personal counter is held under.
  final Mantra mantra;

  /// Chants made in this reader visit, whichever target they went to.
  final int sessionCount;
  final String chantTitle;
  final String? chantTitleFontFamily;

  static const barHeight = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark ? const Color(0xCC454545) : AppColors.grey100;
    final primaryTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final titleFontSize =
        Theme.of(context).textTheme.titleMedium?.fontSize ?? 16;

    final presetId = mantra.presetId;
    ref.watch(groupAccumulationCountsProvider(presetId));
    final groupsAsync = ref.watch(joinedAccumulatorGroupsProvider(presetId));
    final groups = groupsAsync.valueOrNull ?? const <AccumulatorGroup>[];
    final selection = ref.watch(malaAccumulationSelectionProvider(presetId));
    AccumulatorGroup? activeGroup;
    for (final group in groups) {
      if (group.groupAccumulatorId == selection.groupAccumulatorId) {
        activeGroup = group;
        break;
      }
    }

    void openGroupSheet() {
      if (groups.isEmpty) return;
      GroupAccumulationsSheet.show(
        context,
        mantra: mantra,
        presetTitle: chantTitle,
        groups: groups,
      );
    }

    return Container(
      height: barHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
          ),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: pillColor,
            borderRadius: BorderRadius.circular(999),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: groups.isNotEmpty ? openGroupSheet : null,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+$sessionCount',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GroupSessionAvatar(
                      group: activeGroup,
                      isPersonal: selection.isPersonal,
                    ),
                    Icon(
                      AppAssets.caretRight2,
                      size: 20,
                      color: secondaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              chantTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              strutStyle: context.tibetanStrutStyle(titleFontSize),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: chantTitleFontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Opacity(
            opacity: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+$sessionCount',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _GroupSessionAvatar(group: null),
                  Icon(
                    AppAssets.caretRight2,
                    size: 20,
                    color: secondaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupSessionAvatar extends StatelessWidget {
  const _GroupSessionAvatar({required this.group, this.isPersonal = false});

  final AccumulatorGroup? group;

  /// Chants are going to personal practice, which has no image of its own.
  final bool isPersonal;
  static const _size = 24.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fallbackColor,
        border: Border.all(color: AppColors.surfaceWhite, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          group?.image != null && !group!.image!.isEmpty
              ? ResponsiveCoverImage(
                image: group!.image,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
              )
              : Icon(
                isPersonal ? AppAssets.profile : AppAssets.bookOpenText,
                size: _size * 0.55,
                color: isDark ? AppColors.grey500 : AppColors.grey600,
              ),
    );
  }
}
