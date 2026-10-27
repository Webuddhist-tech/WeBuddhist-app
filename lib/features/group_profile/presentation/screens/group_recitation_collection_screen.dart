import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_analytics.dart';
import 'package:flutter_pecha/core/widgets/collection_completion_sheet.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_recitation_collection_row.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pecha/core/widgets/screen_cache_builder.dart';

class GroupRecitationCollectionScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String collectionId;
  final String? initialTitle;

  const GroupRecitationCollectionScreen({
    super.key,
    required this.groupId,
    required this.collectionId,
    this.initialTitle,
  });

  @override
  ConsumerState<GroupRecitationCollectionScreen> createState() =>
      _GroupRecitationCollectionScreenState();
}

class _GroupRecitationCollectionScreenState
    extends ConsumerState<GroupRecitationCollectionScreen> {
  /// Guards against re-showing the sheet after the user dismisses it while
  /// staying on this screen instance (e.g. a rebuild triggered by an
  /// unrelated state change).
  bool _hasShownCompletionSheetThisVisit = false;
  bool _viewTracked = false;

  GroupRecitationCollectionKey get _key => GroupRecitationCollectionKey(
    groupId: widget.groupId,
    collectionId: widget.collectionId,
  );

  @override
  Widget build(BuildContext context) {
    final key = _key;
    final detailAsync = ref.watch(groupRecitationCollectionDetailProvider(key));
    final completionState = ref.watch(
      groupRecitationCollectionCompletionProvider(key),
    );
    final detail = detailAsync.valueOrNull?.fold((_) => null, (value) => value);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _maybeShowCompletionSheet(key, detail, completionState);
    if (detail != null && !_viewTracked) {
      _viewTracked = true;
      ref
          .read(groupAnalyticsProvider)
          .recitationCollectionOpened(
            collectionId: widget.collectionId,
            groupId: widget.groupId,
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
            _CollectionAppBar(title: detail?.name ?? widget.initialTitle),
            Expanded(
              child: ScreenCacheBuilder<GroupRecitationCollection>(
                value: detailAsync,
                skeleton: const Center(child: CircularProgressIndicator()),
                onRetry:
                    () => ref.invalidate(
                      groupRecitationCollectionDetailProvider(key),
                    ),
                data:
                    (collection) => _CollectionContent(
                      collection: collection,
                      completionState: completionState,
                      isDark: isDark,
                      onOpenItem:
                          (item) =>
                              _openReaderAndComplete(key, item, collection),
                      onPlayItem:
                          (item) =>
                              _openReaderOnFirstAudio(key, item, collection),
                      onShare: () => _onShare(collection),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the completion celebration once, when the last remaining chant
  /// of [collection] gets marked completed while this screen is alive
  /// (typically right after returning from the reader). A collection that
  /// was already fully completed before the screen opened does not
  /// re-trigger it.
  void _maybeShowCompletionSheet(
    GroupRecitationCollectionKey key,
    GroupRecitationCollection? collection,
    GroupRecitationCollectionCompletionState completionState,
  ) {
    if (_hasShownCompletionSheetThisVisit) return;
    if (collection == null || collection.items.isEmpty) return;
    // Only celebrate a completion the user performed during this visit —
    // the completion notifier is autoDispose, so this flag is false when
    // the screen opens onto a collection that was already finished today.
    if (!completionState.hasCompletedChantThisSession) return;

    final isFullyCompleted = collection.items.every(
      (item) => completionState.isCompleted(item.id),
    );
    if (!isFullyCompleted) return;

    // Claim it now so a rebuild before the post-frame callback runs can't
    // schedule a second show.
    _hasShownCompletionSheetThisVisit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showCompletionSheet(key, collection.name);
    });
  }

  /// Opens the reader and starts the first recording on this chant.
  Future<void> _openReaderOnFirstAudio(
    GroupRecitationCollectionKey key,
    GroupRecitationCollectionItem item,
    GroupRecitationCollection collection,
  ) {
    final tracks = collectionAudioTracksFor(item);
    if (tracks.isEmpty) return Future.value();
    return _openReaderAndComplete(
      key,
      item,
      collection,
      initialAudio: tracks.first,
    );
  }

  Future<void> _openReaderAndComplete(
    GroupRecitationCollectionKey key,
    GroupRecitationCollectionItem item,
    GroupRecitationCollection collection, {
    CollectionAudioTrack? initialAudio,
  }) async {
    final textId = item.textId.trim();
    final chantId = item.id.trim();
    if (textId.isEmpty || chantId.isEmpty) return;

    final navigationContext = groupRecitationCollectionNavigationContext(
      key: key,
      collection: collection,
      item: item,
      completionState: ref.read(
        groupRecitationCollectionCompletionProvider(key),
      ),
      initialAudio: initialAudio,
    );

    await context.push('/reader/$textId', extra: navigationContext);
    // No return-value handling needed — the next build after popping back
    // re-evaluates _maybeShowCompletionSheet against the live completion
    // state, so a freshly-completed collection is caught automatically.
  }

  Future<void> _showCompletionSheet(
    GroupRecitationCollectionKey key,
    String collectionName,
  ) async {
    final result = await ref.read(
      groupRecitationCollectionDaysCountProvider(key).future,
    );
    if (!mounted) return;

    final dayCount = result.fold((_) => null, (count) => count);
    if (dayCount == null) {
      // Fetch failed — un-claim so the next rebuild while still fully
      // completed retries instead of losing the celebration for good.
      _hasShownCompletionSheetThisVisit = false;
      return;
    }

    showCollectionCompletionSheet(
      context,
      collectionName: collectionName,
      dayCount: dayCount,
    );
  }

  Future<void> _onShare(GroupRecitationCollection collection) async {
    final l10n = context.l10n;
    final groupName = _resolveGroupName(ref, collection.groupId);
    final shareMessage =
        groupName == null
            ? l10n.group_recitation_collection_share_message_no_group(
              collection.name,
            )
            : l10n.group_recitation_collection_share_message(
              collection.name,
              groupName,
            );
    final longUrl =
        DeepLinkUrlBuilder.groupRecitationCollectionLink(
          groupId: collection.groupId,
          collectionId: collection.id,
        ).toString();
    final shareUrl = await resolveShareUrlRef(ref, longUrl);
    if (!mounted) return;

    final sharePositionOrigin = getSharePositionOrigin(context: context);

    final shareAnalytics = ref.read(shareAnalyticsProvider);
    final result = await SharePlus.instance.share(
      ShareParams(
        text: '$shareMessage\n\n$shareUrl',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    if (ShareAnalytics.wasUsed(result)) {
      shareAnalytics.contentShared(
        surface: ShareSurface.recitationCollection,
        targetId: collection.id,
        format: 'text',
        groupId: collection.groupId,
      );
    }
  }

  /// Resolves the group name from the cached group profile if available.
  String? _resolveGroupName(WidgetRef ref, String groupId) {
    return ref
        .read(groupProfileProvider(groupId))
        .whenOrNull(
          data:
              (either) => either.fold((_) => null, (profile) => profile.title),
        );
  }
}

class _CollectionAppBar extends StatelessWidget {
  const _CollectionAppBar({this.title});

  final String? title;

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
              } else {
                context.go(AppRoutes.home);
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
    required this.onPlayItem,
    required this.onShare,
  });

  final GroupRecitationCollection collection;
  final GroupRecitationCollectionCompletionState completionState;
  final bool isDark;
  final ValueChanged<GroupRecitationCollectionItem> onOpenItem;
  final ValueChanged<GroupRecitationCollectionItem> onPlayItem;
  final VoidCallback onShare;

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
                _CollectionHero(imageUrl: collection.imageUrl, isDark: isDark),
                const SizedBox(height: 14),
                _CollectionActionBar(
                  collection: collection,
                  isDark: isDark,
                  onShare: onShare,
                ),
                const SizedBox(height: 12),
                if (hasItems)
                  ...collection.items.map(
                    (item) => GroupRecitationCollectionRow(
                      item: item,
                      isDark: isDark,
                      isCompleted: completionState.isCompleted(item.id),
                      isSubmitting: completionState.isSubmitting(item.id),
                      onTap: () => onOpenItem(item),
                      onPlay:
                          item.audio.isEmpty ? null : () => onPlayItem(item),
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

class _CollectionHero extends StatelessWidget {
  const _CollectionHero({required this.imageUrl, required this.isDark});

  final String? imageUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fallbackColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final iconColor = isDark ? AppColors.grey500 : AppColors.grey600;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 343 / 196,
        child:
            imageUrl != null && imageUrl!.trim().isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                )
                : ColoredBox(
                  color: fallbackColor,
                  child: Icon(
                    AppAssets.bookOpenText,
                    size: 44,
                    color: iconColor,
                  ),
                ),
      ),
    );
  }
}

class _CollectionActionBar extends ConsumerWidget {
  const _CollectionActionBar({
    required this.collection,
    required this.isDark,
    required this.onShare,
  });

  final GroupRecitationCollection collection;
  final bool isDark;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkTarget = BookmarkTarget(
      type: BookmarkType.groupRecitationCollection,
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
                ).toggleGroupRecitationCollection(
                  collection.id,
                  name: collection.name,
                ),
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon: AppAssets.readerShare,
            label: context.l10n.share,
            isDark: isDark,
            onTap: onShare,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Hands the collection to the routine editor, which injects it as a
  /// GROUP_RECITATION_COLLECTION session and lets the user place its time block.
  void _addToPractices(BuildContext context, WidgetRef ref) {
    if (ref.read(authProvider).isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }
    context.pushNamed(
      'edit-routine',
      extra: {'initialGroupCollection': collection},
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
