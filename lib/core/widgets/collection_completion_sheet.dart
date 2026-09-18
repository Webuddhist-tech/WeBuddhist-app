import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Celebration sheet shown once all chants in a recitation collection (group
/// or user-created) have been completed for the day.
class CollectionCompletionSheet extends StatelessWidget {
  const CollectionCompletionSheet({
    super.key,
    required this.collectionName,
    required this.dayCount,
  });

  final String collectionName;
  final int dayCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.goldLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.group_recitation_collection_completed_title(collectionName),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Image.asset(
                AppAssets.collectionCompletion,
                width: 64,
                height: 64,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.days_count(dayCount),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.group_recitation_collection_dedication,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: subtitleColor),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor:
                        isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                    foregroundColor:
                        isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    l10n.done,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isCollectionCompletionSheetVisible = false;

/// Shows the [CollectionCompletionSheet], guarding against being triggered
/// twice for the same completion event.
void showCollectionCompletionSheet(
  BuildContext context, {
  required String collectionName,
  required int dayCount,
}) {
  if (_isCollectionCompletionSheetVisible) return;

  _isCollectionCompletionSheetVisible = true;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder:
        (_) => CollectionCompletionSheet(
          collectionName: collectionName,
          dayCount: dayCount,
        ),
  ).whenComplete(() => _isCollectionCompletionSheetVisible = false);
}
