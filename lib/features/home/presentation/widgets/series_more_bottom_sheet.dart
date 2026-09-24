import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/home/presentation/utils/series_analytics.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet opened from the three-dot (⋮) button on the series detail
/// screen.
///
/// Contains:
///   • "+ Add to my practices" action
///   • Bookmark toggle action
///   • Share action
class SeriesMoreBottomSheet extends ConsumerStatefulWidget {
  const SeriesMoreBottomSheet({
    super.key,
    required this.seriesId,
    required this.seriesName,
    this.onAddToPractices,
    this.onShare,
  });

  final String seriesId;
  final String seriesName;
  final VoidCallback? onAddToPractices;
  final VoidCallback? onShare;

  @override
  ConsumerState<SeriesMoreBottomSheet> createState() =>
      _SeriesMoreBottomSheetState();
}

class _SeriesMoreBottomSheetState extends ConsumerState<SeriesMoreBottomSheet> {
  bool _isBookmarking = false;

  BookmarkTarget get _bookmarkTarget => BookmarkTarget(
        type: BookmarkType.series,
        sourceId: widget.seriesId,
      );

  Future<void> _toggleBookmark() async {
    if (_isBookmarking) return;
    setState(() => _isBookmarking = true);
    try {
      final nav = Navigator.of(context);
      final wasBookmarked = ref.read(isBookmarkedProvider(_bookmarkTarget));
      final didToggle = await BookmarkController(
        ref: ref,
        context: context,
      ).toggleSeries(widget.seriesId, name: widget.seriesName);
      if (!mounted || !didToggle) return;
      // A failed request puts the cached state back, so only a state that
      // actually changed is a bookmark event.
      final isBookmarked = ref.read(isBookmarkedProvider(_bookmarkTarget));
      if (isBookmarked != wasBookmarked) {
        ref
            .read(seriesAnalyticsProvider)
            .seriesBookmarked(
              seriesId: widget.seriesId,
              bookmarked: isBookmarked,
            );
      }
      nav.pop();
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isBookmarked = ref.watch(isBookmarkedProvider(_bookmarkTarget));

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Add to my practices ────────────────────────────────────────
          _SectionDivider(theme: theme),
          ListTile(
            leading: Icon(AppAssets.plus, color: theme.colorScheme.onSurface),
            title: Text(
              l10n.mala_add_to_practice,
              style: theme.textTheme.bodyLarge,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              widget.onAddToPractices?.call();
            },
          ),

          // ── Bookmark ───────────────────────────────────────────────────
          _SectionDivider(theme: theme),
          ListTile(
            leading:
                _isBookmarking
                    ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                    : Icon(
                      isBookmarked
                          ? AppAssets.bookmarkSimpleFill
                          : AppAssets.bookmarkSimple,
                      color: theme.colorScheme.onSurface,
                    ),
            title: Text(l10n.bookmark, style: theme.textTheme.bodyLarge),
            onTap: () {
              HapticFeedback.lightImpact();
              _toggleBookmark();
            },
          ),

          // ── Share ──────────────────────────────────────────────────────
          _SectionDivider(theme: theme),
          ListTile(
            leading: Icon(AppAssets.share, color: theme.colorScheme.onSurface),
            title: Text(l10n.share, style: theme.textTheme.bodyLarge),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              widget.onShare?.call();
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: theme.dividerColor);
}

/// Shows the series "more" bottom sheet.
void showSeriesMoreBottomSheet(
  BuildContext context, {
  required String seriesId,
  required String seriesName,
  VoidCallback? onAddToPractices,
  VoidCallback? onShare,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    useRootNavigator: true,
    builder:
        (_) => SeriesMoreBottomSheet(
          seriesId: seriesId,
          seriesName: seriesName,
          onAddToPractices: onAddToPractices,
          onShare: onShare,
        ),
  );
}
