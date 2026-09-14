import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// (⋮) sheet on the group accumulator screen: add to practices, bookmark, share.
class GroupAccumulatorMoreSheet extends ConsumerStatefulWidget {
  const GroupAccumulatorMoreSheet({
    super.key,
    required this.accumulatorId,
    required this.accumulatorTitle,
    this.onAddToPractices,
    this.onShare,
  });

  final String accumulatorId;
  final String accumulatorTitle;
  final VoidCallback? onAddToPractices;
  final VoidCallback? onShare;

  @override
  ConsumerState<GroupAccumulatorMoreSheet> createState() =>
      _GroupAccumulatorMoreSheetState();
}

class _GroupAccumulatorMoreSheetState
    extends ConsumerState<GroupAccumulatorMoreSheet> {
  bool _isBookmarking = false;

  BookmarkTarget get _bookmarkTarget => BookmarkTarget(
    type: BookmarkType.groupAccumulator,
    sourceId: widget.accumulatorId,
  );

  Future<void> _toggleBookmark() async {
    if (_isBookmarking) return;
    setState(() => _isBookmarking = true);
    try {
      final nav = Navigator.of(context);
      final didToggle = await BookmarkController(
        ref: ref,
        context: context,
      ).toggleGroupAccumulator(
        widget.accumulatorId,
        name: widget.accumulatorTitle,
      );
      if (mounted && didToggle) nav.pop();
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
          _SectionDivider(theme: theme),
          ListTile(
            leading: Icon(
              AppAssets.readerShare,
              color: theme.colorScheme.onSurface,
            ),
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

void showGroupAccumulatorMoreSheet(
  BuildContext context, {
  required String accumulatorId,
  required String accumulatorTitle,
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
        (_) => GroupAccumulatorMoreSheet(
          accumulatorId: accumulatorId,
          accumulatorTitle: accumulatorTitle,
          onAddToPractices: onAddToPractices,
          onShare: onShare,
        ),
  );
}
