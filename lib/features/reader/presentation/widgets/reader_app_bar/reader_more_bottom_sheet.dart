import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_sheet.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// The reader's More sheet (⋮), as WF23: Add to my practices, Bookmark and
/// Share, plus Audio versions and Offline recitation where they apply. The
/// size buttons are in the Display sheet.
class ReaderMoreBottomSheet extends ConsumerStatefulWidget {
  const ReaderMoreBottomSheet({
    super.key,
    required this.textId,
    required this.showAddToPractices,
    this.showOfflineRecitation = false,
    this.onAddToPractices,
    this.onAddOfflineRecitation,
    this.onAudioVersions,
  });

  final String textId;
  final bool showAddToPractices;
  final bool showOfflineRecitation;
  final VoidCallback? onAddToPractices;
  final VoidCallback? onAddOfflineRecitation;

  /// Opens the recording list for a group recitation chant. Hidden when null.
  final VoidCallback? onAudioVersions;

  @override
  ConsumerState<ReaderMoreBottomSheet> createState() =>
      _ReaderMoreBottomSheetState();
}

class _ReaderMoreBottomSheetState extends ConsumerState<ReaderMoreBottomSheet> {
  bool _isBookmarking = false;
  bool _isSharing = false;

  BookmarkTarget get _bookmarkTarget =>
      BookmarkTarget(type: BookmarkType.text, sourceId: widget.textId);

  Future<void> _toggleBookmark() async {
    if (_isBookmarking) return;
    setState(() => _isBookmarking = true);
    try {
      final nav = Navigator.of(context);
      final didToggle = await BookmarkController(
        ref: ref,
        context: context,
      ).toggleText(widget.textId);
      if (mounted && didToggle) nav.pop();
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final longUrl =
          DeepLinkUrlBuilder.readerLink(textId: widget.textId).toString();
      final shareMessage = context.l10n.share_chant_message;
      final shareUrl = await resolveShareUrlRef(ref, longUrl);
      if (!mounted) return;

      final sharePositionOrigin = getSharePositionOrigin(context: context);
      final result = await SharePlus.instance.share(
        ShareParams(
          text: '$shareMessage\n\n$shareUrl',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      if (!mounted) return;
      if (ShareAnalytics.wasUsed(result)) {
        ref
            .read(shareAnalyticsProvider)
            .contentShared(
              surface: ShareSurface.text,
              targetId: widget.textId,
              format: 'text',
            );
      }
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    final isBookmarked = ref.watch(isBookmarkedProvider(_bookmarkTarget));

    Widget busy() => SizedBox(
      width: 22,
      height: 22,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: CircularProgressIndicator(strokeWidth: 2, color: palette.ink),
      ),
    );

    final rows = <Widget>[
      if (widget.onAudioVersions != null)
        ReaderSheetRow(
          label: l10n.collection_audio_versions,
          leading: const Icon(AppAssets.speakerSimpleHigh),
          trailing: const Icon(AppAssets.caretRight),
          onTap: () {
            Navigator.of(context).pop();
            widget.onAudioVersions?.call();
          },
        ),
      if (widget.showAddToPractices)
        ReaderSheetRow(
          label: l10n.mala_add_to_practice,
          leading: const Icon(AppAssets.plus),
          onTap: () {
            Navigator.of(context).pop();
            widget.onAddToPractices?.call();
          },
        ),
      if (widget.showOfflineRecitation)
        ReaderSheetRow(
          label: l10n.group_accumulator_offline_recitation,
          leading: const Icon(AppAssets.plusCircle),
          onTap: () {
            Navigator.of(context).pop();
            widget.onAddOfflineRecitation?.call();
          },
        ),
      ReaderSheetRow(
        label: l10n.bookmark,
        leading:
            _isBookmarking
                ? busy()
                : Icon(
                  isBookmarked
                      ? AppAssets.bookmarkSimpleFill
                      : AppAssets.bookmarkSimple,
                ),
        onTap: _toggleBookmark,
      ),
      ReaderSheetRow(
        label: l10n.share,
        leading: _isSharing ? busy() : const Icon(AppAssets.readerShare),
        onTap: _share,
      ),
    ];

    // As WF23: the title centred with ✕, then the actions with rules
    // between them.
    return ReaderSheet(
      title: l10n.more,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const ReaderSheetDivider(),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Shows the reader "more" bottom sheet.
void showReaderMoreBottomSheet(
  BuildContext context, {
  required String textId,
  required bool showAddToPractices,
  bool showOfflineRecitation = false,
  VoidCallback? onAddToPractices,
  VoidCallback? onAddOfflineRecitation,
  VoidCallback? onAudioVersions,
}) {
  showReaderSheet<void>(
    context,
    builder:
        (_) => ReaderMoreBottomSheet(
          textId: textId,
          showAddToPractices: showAddToPractices,
          showOfflineRecitation: showOfflineRecitation,
          onAddToPractices: onAddToPractices,
          onAddOfflineRecitation: onAddOfflineRecitation,
          onAudioVersions: onAudioVersions,
        ),
  );
}
