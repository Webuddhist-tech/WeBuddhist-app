import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_bottom_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Bottom sheet opened from the reader's three-dot (⋮) button.
///
/// Contains:
///   • Font-size A / A buttons
///   • "+ Add to my practices" action
///   • Bookmark toggle action
class ReaderMoreBottomSheet extends ConsumerStatefulWidget {
  const ReaderMoreBottomSheet({
    super.key,
    required this.textId,
    required this.showAddToPractices,
    this.showOfflineRecitation = false,
    this.onAddToPractices,
    this.onAddOfflineRecitation,
  });

  final String textId;
  final bool showAddToPractices;
  final bool showOfflineRecitation;
  final VoidCallback? onAddToPractices;
  final VoidCallback? onAddOfflineRecitation;

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

  // ── font size helpers ──────────────────────────────────────────────────────

  int _stepIndex(double fontSize) {
    for (int i = 0; i < ReaderFontSizeBottomSheet.fontSizeSteps.length; i++) {
      if ((fontSize - ReaderFontSizeBottomSheet.fontSizeSteps[i]).abs() < 0.5) {
        return i;
      }
    }
    int closest = ReaderFontSizeBottomSheet.defaultStepIndex;
    double minDiff = double.infinity;
    for (int i = 0; i < ReaderFontSizeBottomSheet.fontSizeSteps.length; i++) {
      final d = (fontSize - ReaderFontSizeBottomSheet.fontSizeSteps[i]).abs();
      if (d < minDiff) {
        minDiff = d;
        closest = i;
      }
    }
    return closest;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isBookmarked = ref.watch(isBookmarkedProvider(_bookmarkTarget));

    final fontSize = ref.watch(fontSizeProvider);
    final stepIndex = _stepIndex(fontSize);
    final canDecrease = stepIndex > 0;
    final canIncrease =
        stepIndex < ReaderFontSizeBottomSheet.fontSizeSteps.length - 1;

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
                color: ReaderPanelConstants.dragHandleColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Font size row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _FontSizeButton(
                    label: 'A',
                    fontSize: 16,
                    isEnabled: canDecrease,
                    onTap:
                        canDecrease
                            ? () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(fontSizeProvider.notifier)
                                  .setFontSize(
                                    ReaderFontSizeBottomSheet
                                        .fontSizeSteps[stepIndex - 1],
                                  );
                            }
                            : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FontSizeButton(
                    label: 'A',
                    fontSize: 26,
                    isEnabled: canIncrease,
                    onTap:
                        canIncrease
                            ? () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(fontSizeProvider.notifier)
                                  .setFontSize(
                                    ReaderFontSizeBottomSheet
                                        .fontSizeSteps[stepIndex + 1],
                                  );
                            }
                            : null,
                  ),
                ),
              ],
            ),
          ),

          if (widget.showAddToPractices) ...[
            // ── Add to my practices ──────────────────────────────────────
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
          ],

          if (widget.showOfflineRecitation) ...[
            _SectionDivider(theme: theme),
            ListTile(
              leading: Icon(
                AppAssets.plusCircle,
                color: theme.colorScheme.onSurface,
              ),
              title: Text(
                l10n.group_accumulator_offline_recitation,
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
                widget.onAddOfflineRecitation?.call();
              },
            ),
          ],

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
            leading:
                _isSharing
                    ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                    : Icon(Icons.share, color: theme.colorScheme.onSurface),
            title: Text(l10n.share, style: theme.textTheme.bodyLarge),
            onTap: () {
              HapticFeedback.lightImpact();
              _share();
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

class _FontSizeButton extends StatelessWidget {
  const _FontSizeButton({
    required this.label,
    required this.fontSize,
    required this.isEnabled,
    this.onTap,
  });

  final String label;
  final double fontSize;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color:
                isEnabled
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color:
                  isEnabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
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
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (_) => ReaderMoreBottomSheet(
          textId: textId,
          showAddToPractices: showAddToPractices,
          showOfflineRecitation: showOfflineRecitation,
          onAddToPractices: onAddToPractices,
          onAddOfflineRecitation: onAddOfflineRecitation,
        ),
  );
}
