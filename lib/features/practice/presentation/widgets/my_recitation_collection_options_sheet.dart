import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';
import 'package:flutter_pecha/features/practice/data/repositories/my_recitation_collections_repository.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/my_recitation_collections_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_recitations_paginated_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/create_edit_collection_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MyRecitationCollectionOptionsSheet extends ConsumerWidget {
  const MyRecitationCollectionOptionsSheet({
    super.key,
    required this.collection,
  });

  final MyRecitationCollectionDetailModel collection;

  static Future<void> show(
    BuildContext context, {
    required MyRecitationCollectionDetailModel collection,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder:
          (_) => MyRecitationCollectionOptionsSheet(collection: collection),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const destructiveColor = Color(0xFFB03027);
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final backgroundColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _OptionsTile(
              icon: PhosphorIconsRegular.pencilSimple,
              label: context.l10n.my_recitation_collection_edit,
              onTap: () => _onEdit(context),
            ),
            Divider(height: 1, color: dividerColor),
            _OptionsTile(
              icon: AppAssets.trash,
              label: context.l10n.my_recitation_collection_delete,
              labelColor: destructiveColor,
              iconColor: destructiveColor,
              onTap: () => _onDelete(context, ref),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _onEdit(BuildContext context) async {
    Navigator.of(context).pop();
    await openEditCollectionScreen(context, collection: collection);
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(myRecitationCollectionsRepositoryProvider);
    final languageCode = ref.read(practiceRecitationsLanguageProvider);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final collectionId = collection.id;

    final confirmed = await showDestructiveConfirmationDialog(
      context,
      title: context.l10n.my_recitation_collection_delete_title,
      message: context.l10n.my_recitation_collection_delete_message,
      barrierDismissible: false,
      onConfirmed:
          () => _deleteCollection(
            repository: repository,
            collectionId: collectionId,
          ),
    );

    if (!context.mounted) return;

    if (confirmed == true) {
      // Kick off list reload (do not await) so AllRecitationsScreen can show
      // its existing skeleton, then immediately return to that screen.
      _startChantsListReload(ref, languageCode);
      Navigator.of(context).pop();
      router.pop();
    } else if (confirmed == false) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.something_went_wrong)),
      );
    }
  }

  /// Calls `DELETE /users/me/recitation-collections/{collection_id}`.
  static Future<bool> _deleteCollection({
    required MyRecitationCollectionsRepository repository,
    required String collectionId,
  }) async {
    final result = await repository.deleteCollection(collectionId);
    return result.fold((_) => false, (_) => true);
  }

  /// Starts a chants-list refetch without waiting for it to finish.
  static void _startChantsListReload(WidgetRef ref, String languageCode) {
    final provider = practiceRecitationsPaginatedProvider(languageCode);
    if (ref.exists(provider)) {
      ref.read(provider.notifier).refresh();
    } else {
      ref.invalidate(provider);
    }
  }
}

class _OptionsTile extends StatelessWidget {
  const _OptionsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = labelColor ?? theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 24, color: iconColor ?? foreground),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: foreground,
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
