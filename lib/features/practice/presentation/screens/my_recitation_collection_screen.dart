import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/collection_completion_sheet.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_analytics.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/my_recitation_collections_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/my_recitation_collection_options_sheet.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Detail screen for a user-created recitation collection
/// (`GET /users/me/recitation-collections/{id}`).
///
/// Layout matches [GroupRecitationCollectionScreen]. Tapping a chant opens the
/// shared reader using the item's `text_id` and `language`.
class MyRecitationCollectionScreen extends ConsumerStatefulWidget {
  const MyRecitationCollectionScreen({
    super.key,
    required this.collectionId,
    this.initialTitle,
  });

  final String collectionId;
  final String? initialTitle;

  @override
  ConsumerState<MyRecitationCollectionScreen> createState() =>
      _MyRecitationCollectionScreenState();
}

class _MyRecitationCollectionScreenState
    extends ConsumerState<MyRecitationCollectionScreen> {
  bool _hasShownCompletionSheetThisVisit = false;
  bool _viewTracked = false;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      myRecitationCollectionDetailProvider(widget.collectionId),
    );
    final completionState = ref.watch(
      myRecitationCollectionCompletionProvider(widget.collectionId),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final detail = detailAsync.valueOrNull?.fold((_) => null, (value) => value);

    _maybeShowCompletionSheet(detail, completionState);
    if (detail != null && !_viewTracked) {
      _viewTracked = true;
      ref
          .read(groupAnalyticsProvider)
          .recitationCollectionOpened(
            collectionId: widget.collectionId,
            groupId: null,
            itemCount: detail.items.length,
          );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _CollectionAppBar(
              title: detail?.name ?? widget.initialTitle,
              onMenuTap:
                  detail != null
                      ? () => MyRecitationCollectionOptionsSheet.show(
                        context,
                        collection: detail,
                      )
                      : null,
            ),
            Expanded(
              child: detailAsync.when(
                data:
                    (either) => either.fold(
                      (failure) => ErrorStateWidget(
                        error: failure,
                        onRetry:
                            () => ref.invalidate(
                              myRecitationCollectionDetailProvider(
                                widget.collectionId,
                              ),
                            ),
                      ),
                      (collection) => _CollectionContent(
                        collection: collection,
                        completionState: completionState,
                        isDark: isDark,
                        onOpenItem: (item) async {
                          await _openChantReader(
                            context,
                            ref,
                            widget.collectionId,
                            collection,
                            item,
                          );
                          if (!mounted) return;
                          final latestCompletion = ref.read(
                            myRecitationCollectionCompletionProvider(
                              widget.collectionId,
                            ),
                          );
                          _maybeShowCompletionSheet(
                            collection,
                            latestCompletion,
                          );
                        },
                      ),
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => ErrorStateWidget(
                      error: error,
                      onRetry:
                          () => ref.invalidate(
                            myRecitationCollectionDetailProvider(
                              widget.collectionId,
                            ),
                          ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _maybeShowCompletionSheet(
    MyRecitationCollectionDetailModel? collection,
    MyRecitationCollectionCompletionState completionState,
  ) {
    if (_hasShownCompletionSheetThisVisit) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (collection == null || collection.items.isEmpty) return;
    if (!completionState.hasCompletedChantThisSession) return;

    final isFullyCompleted = collection.items.every(
      (item) => _isItemCompleted(completionState, item),
    );
    if (!isFullyCompleted) return;

    _hasShownCompletionSheetThisVisit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showCompletionSheet(collection.name);
    });
  }

  Future<void> _showCompletionSheet(String collectionName) async {
    final result = await ref.read(
      myRecitationCollectionDaysCountProvider(widget.collectionId).future,
    );
    if (!mounted) return;

    final dayCount = result.fold((_) => null, (count) => count);
    if (dayCount == null) {
      _hasShownCompletionSheetThisVisit = false;
      return;
    }

    showCollectionCompletionSheet(
      context,
      collectionName: collectionName,
      dayCount: dayCount,
    );
  }
}

Future<void> _openChantReader(
  BuildContext context,
  WidgetRef ref,
  String collectionId,
  MyRecitationCollectionDetailModel collection,
  MyRecitationCollectionItemModel item,
) async {
  final textId = item.textId.trim();
  if (textId.isEmpty) return;

  final completionState = ref.read(
    myRecitationCollectionCompletionProvider(collectionId),
  );
  final currentIndex = collection.items.indexWhere((i) => i.id == item.id);
  final planTextItems =
      collection.items.map((collectionItem) {
        final itemTextId = collectionItem.textId.trim();
        final title =
            collectionItem.title?.trim().isNotEmpty == true
                ? collectionItem.title!
                : itemTextId;
        return PlanTextItem.sourceReference(
          textId: itemTextId,
          title: title,
          language: collectionItem.language,
          subtaskId: collectionItem.id,
          isCompleted: _isItemCompleted(completionState, collectionItem),
        );
      }).toList();

  final language = item.language?.trim();
  final navigationContext = NavigationContext(
    source: NavigationSource.myRecitationCollection,
    planTextItems: planTextItems,
    currentTextIndex: currentIndex >= 0 ? currentIndex : 0,
    collectionId: collectionId,
    language: language != null && language.isNotEmpty ? language : null,
  );

  await context.push('/reader/$textId', extra: navigationContext);
}

class _CollectionAppBar extends StatelessWidget {
  const _CollectionAppBar({this.title, this.onMenuTap});

  final String? title;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
            },
          ),
          Expanded(
            child: Text(
              resolvedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onMenuTap != null)
            IconButton(
              icon: const Icon(AppAssets.dotsThreeVertical),
              onPressed: onMenuTap,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _CollectionContent extends StatelessWidget {
  const _CollectionContent({
    required this.collection,
    required this.completionState,
    required this.isDark,
    required this.onOpenItem,
  });

  final MyRecitationCollectionDetailModel collection;
  final MyRecitationCollectionCompletionState completionState;
  final bool isDark;
  final ValueChanged<MyRecitationCollectionItemModel> onOpenItem;

  @override
  Widget build(BuildContext context) {
    final hasItems = collection.items.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CollectionHero(imageUrl: collection.imgUrl),
                const SizedBox(height: 14),
                _CollectionActionBar(collection: collection, isDark: isDark),
                const SizedBox(height: 12),
                if (hasItems)
                  ...collection.items.map(
                    (item) => _RecitationCollectionRow(
                      item: item,
                      isDark: isDark,
                      isCompleted: _isItemCompleted(completionState, item),
                      isSubmitting: _isItemSubmitting(completionState, item),
                      onTap: () => onOpenItem(item),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        context.l10n.noContentAvailable,
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            8,
            22,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  hasItems ? () => onOpenItem(collection.items.first) : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                disabledBackgroundColor:
                    isDark ? AppColors.grey800 : AppColors.grey300,
                foregroundColor:
                    isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                context.l10n.start_reading,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Completion is keyed by the chant ID we POST (`item.id`), but the
/// `complete/today` payload has been seen carrying text IDs, so both are
/// matched. [_isItemSubmitting] mirrors this so a row's spinner and its check
/// can never disagree about which key identifies the item.
bool _isItemCompleted(
  MyRecitationCollectionCompletionState completionState,
  MyRecitationCollectionItemModel item,
) {
  return _matchesItem(completionState.isCompleted, item);
}

bool _isItemSubmitting(
  MyRecitationCollectionCompletionState completionState,
  MyRecitationCollectionItemModel item,
) {
  return _matchesItem(completionState.isSubmitting, item);
}

bool _matchesItem(
  bool Function(String) predicate,
  MyRecitationCollectionItemModel item,
) {
  return predicate(item.id) || predicate(item.textId);
}

class _CollectionHero extends StatelessWidget {
  const _CollectionHero({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 343 / 196,
        // Covers are user uploads of unbounded resolution; hand the image the
        // laid-out size so the decode is bounded by the hero, not the source.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CachedNetworkImageWidget(
              imageUrl: imageUrl,
              fallbackAsset: AppAssets.myCollectionDefault,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }
}

class _CollectionActionBar extends ConsumerWidget {
  const _CollectionActionBar({required this.collection, required this.isDark});

  final MyRecitationCollectionDetailModel collection;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkTarget = BookmarkTarget(
      type: BookmarkType.recitationCollection,
      sourceId: collection.id,
    );
    final isBookmarked = ref.watch(isBookmarkedProvider(bookmarkTarget));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionChip(
            icon: AppAssets.plus,
            label: context.l10n.nav_practice,
            isDark: isDark,
            onTap: () => _addToPractices(context, ref),
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon:
                isBookmarked
                    ? AppAssets.bookmarkSimpleFill
                    : AppAssets.bookmarkSimple,
            label: context.l10n.bookmark,
            isDark: isDark,
            onTap:
                () => BookmarkController(
                  ref: ref,
                  context: context,
                ).toggleRecitationCollection(
                  collection.id,
                  name: collection.name,
                ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Hands the collection to the routine editor, which injects it as a
  /// RECITATION_COLLECTION session and lets the user place its time block.
  void _addToPractices(BuildContext context, WidgetRef ref) {
    if (ref.read(authProvider).isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }
    context.pushNamed(
      'edit-routine',
      extra: {'initialMyCollection': collection},
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecitationCollectionRow extends StatelessWidget {
  const _RecitationCollectionRow({
    required this.item,
    required this.isDark,
    required this.isCompleted,
    required this.isSubmitting,
    required this.onTap,
  });

  final MyRecitationCollectionItemModel item;
  final bool isDark;
  final bool isCompleted;
  final bool isSubmitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey600;
    final title =
        item.title?.trim().isNotEmpty == true ? item.title! : item.textId;

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
                title,
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
