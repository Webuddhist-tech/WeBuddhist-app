import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';

/// Reader context for one chant of a collection, carrying its siblings so
/// the reader can step through and mark them complete.
NavigationContext groupRecitationCollectionNavigationContext({
  required GroupRecitationCollectionKey key,
  required GroupRecitationCollection collection,
  required GroupRecitationCollectionItem item,
  required GroupRecitationCollectionCompletionState completionState,
}) {
  final currentIndex = collection.items.indexWhere((i) => i.id == item.id);
  final planTextItems =
      collection.items.map((collectionItem) {
        return PlanTextItem.sourceReference(
          textId: collectionItem.textId,
          title: collectionItem.title,
          language: collectionItem.language,
          subtaskId: collectionItem.id,
          isCompleted: completionState.isCompleted(collectionItem.id),
        );
      }).toList();

  return NavigationContext(
    source: NavigationSource.groupRecitationCollection,
    planTextItems: planTextItems,
    currentTextIndex: currentIndex >= 0 ? currentIndex : 0,
    groupId: key.groupId,
    collectionId: key.collectionId,
    language: item.language,
  );
}

class GroupRecitationCollectionRow extends StatelessWidget {
  const GroupRecitationCollectionRow({
    super.key,
    required this.item,
    required this.isDark,
    required this.isCompleted,
    required this.isSubmitting,
    required this.onTap,
  });

  final GroupRecitationCollectionItem item;
  final bool isDark;
  final bool isCompleted;
  final bool isSubmitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey600;

    return InkWell(
      onTap: isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            _CompletionIndicator(
              isCompleted: isCompleted,
              isSubmitting: isSubmitting,
              isDark: isDark,
              borderColor: borderColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Icon(
                AppAssets.caretRight,
                size: 18,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionIndicator extends StatelessWidget {
  const _CompletionIndicator({
    required this.isCompleted,
    required this.isSubmitting,
    required this.isDark,
    required this.borderColor,
  });

  final bool isCompleted;
  final bool isSubmitting;
  final bool isDark;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    if (isSubmitting) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final fillColor = isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final checkColor = isDark ? AppColors.textPrimary : AppColors.surfaceWhite;

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? fillColor : Colors.transparent,
        border: Border.all(
          color: isCompleted ? fillColor : borderColor,
          width: 1,
        ),
      ),
      child:
          isCompleted
              ? Icon(AppAssets.check, size: 13, color: checkColor)
              : null,
    );
  }
}
