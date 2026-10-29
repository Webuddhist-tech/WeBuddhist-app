import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/youtube_video_player.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/data/models/secondary_reader_state.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_secondary_content_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_analytics.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_numerals.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_transliteration.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/commentary_skeleton.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/reader_commentary_panel.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/interlinear_segment_item.dart'
    show interlinearTranslationFor;
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_translation/reader_translation_panel.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/segment_info.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/segment_provider.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// The text with the selected verse's sheet below it (WF13–WF16): the split
/// view. The sheet takes the part of the height the split ratio leaves it,
/// and is dragged by its top to resize or close. While it is open the text
/// is dimmed by [dim] black, taps still reaching it, and the sheet casts a
/// soft shadow up onto it.
class ReaderVerseSplitView extends ConsumerWidget {
  const ReaderVerseSplitView({
    super.key,
    required this.params,
    required this.mainContent,
  });

  final ReaderParams params;
  final Widget mainContent;

  /// As measured on WF13: the text, the verse's card included, at 90%.
  static const double dim = 0.10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerNotifierProvider(params));
    final segment = state.selectedSegment;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final sheetHeight =
            segment == null ? 0.0 : availableHeight * (1 - state.splitRatio);
        return Column(
          children: [
            SizedBox(
              height: availableHeight - sheetHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  mainContent,
                  IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      color: Colors.black.withValues(
                        alpha: segment == null ? 0 : dim,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (segment != null)
              // The dimmed page shows past the sheet's rounded corners.
              ColoredBox(
                color: Color.alphaBlend(
                  Colors.black.withValues(alpha: dim),
                  ReaderPalette.resolve(Theme.of(context), ref).background,
                ),
                // The shadow fades up over the text's last 30 points (WF16).
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: sheetHeight,
                    child: ReaderVerseSheet(
                      segment: segment,
                      params: params,
                      availableHeight: availableHeight,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A verse's sheet: "Verse 1.113" with Copy · Bookmark · Share · ✕, then
/// its tabs (Commentary / Versions / Videos, and Root text when the verse
/// has one), a tab hidden when the verse has nothing for it.
class ReaderVerseSheet extends ConsumerStatefulWidget {
  const ReaderVerseSheet({
    super.key,
    required this.segment,
    required this.params,
    required this.availableHeight,
  });

  final Segment segment;
  final ReaderParams params;

  /// The split view's height, which a drag of the top resizes against.
  final double availableHeight;

  @override
  ConsumerState<ReaderVerseSheet> createState() => _ReaderVerseSheetState();
}

class _ReaderVerseSheetState extends ConsumerState<ReaderVerseSheet> {
  bool _closedDuringDrag = false;

  ReaderNotifier get _notifier =>
      ref.read(readerNotifierProvider(widget.params).notifier);

  void _track(ReaderAction action) => ref
      .read(readerAnalyticsProvider)
      .actionTapped(action: action, textId: widget.params.textId);

  void _close() {
    HapticFeedback.lightImpact();
    _notifier.closeVerseSheet();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_closedDuringDrag) return;
    final state = ref.read(readerNotifierProvider(widget.params));
    final mainHeight = widget.availableHeight * state.splitRatio;
    _closedDuringDrag = _notifier.updateSplitRatioOrDismiss(
      ratio: (mainHeight + details.delta.dy) / widget.availableHeight,
      availableHeight: widget.availableHeight,
      onDismiss: _close,
    );
  }

  void _onTab(ReaderResourceTab tab) {
    _track(switch (tab) {
      ReaderResourceTab.commentary => ReaderAction.commentary,
      ReaderResourceTab.videos => ReaderAction.video,
      ReaderResourceTab.versions ||
      ReaderResourceTab.rootText => ReaderAction.version,
    });
    _notifier.openResourceTab(widget.segment.segmentId, tab);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    final l10n = context.l10n;
    final state = ref.watch(readerNotifierProvider(widget.params));
    final segmentId = widget.segment.segmentId;
    final info = ref.watch(segmentInfoFutureProvider(segmentId));
    final tabs = readerResourceTabs(info.valueOrNull, failed: info.hasError);
    final open = state.resourceTab;
    final language = state.textDetail?.language ?? 'en';

    return Material(
      color: palette.drawerBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The top drags the sheet: up to grow it, down to shrink or close.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: (_) => _closedDuringDrag = false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: readerSheetHandleTop),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.drawerHandle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _VerseHeader(
                  segment: widget.segment,
                  params: widget.params,
                  language: language,
                  onClose: _close,
                  onTrack: _track,
                ),
              ],
            ),
          ),
          if (tabs.isNotEmpty)
            Padding(
              // The track lands 72 below the top, as WF13; its tap target
              // reaches 2 past it either way.
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: ReaderSheetSegments<ReaderResourceTab>(
                values: tabs,
                selected: tabs.contains(open) ? open! : tabs.first,
                labelOf:
                    (tab) => switch (tab) {
                      ReaderResourceTab.commentary => l10n.reader_tab_commentary,
                      ReaderResourceTab.versions => l10n.reader_tab_versions,
                      ReaderResourceTab.videos => l10n.reader_videos,
                      ReaderResourceTab.rootText => l10n.root_text,
                    },
                onSelected: _onTab,
              ),
            ),
          Expanded(
            child: switch (open) {
              // Keyed by verse: a new verse's list starts on its first
              // language with nothing opened.
              ReaderResourceTab.commentary => ReaderCommentaryPanel(
                key: ValueKey('commentary-$segmentId'),
                segmentId: segmentId,
                textLanguage: language,
                params: widget.params,
              ),
              ReaderResourceTab.versions => ReaderTranslationPanel(
                key: ValueKey('versions-$segmentId'),
                segmentId: segmentId,
                textLanguage: language,
                params: widget.params,
              ),
              ReaderResourceTab.rootText => ReaderTranslationPanel(
                key: ValueKey('root-$segmentId'),
                segmentId: segmentId,
                textLanguage: language,
                params: widget.params,
                rootText: true,
              ),
              ReaderResourceTab.videos => ReaderVideosTab(
                videos: info.valueOrNull?.videos ?? const [],
                onOpened: () => _track(ReaderAction.video),
              ),
              // The verse's counts are loading; the first tab with
              // something opens once they arrive.
              null =>
                info.isLoading ? const CommentarySkeleton() : const SizedBox(),
            },
          ),
        ],
      ),
    );
  }
}

/// The tabs a verse has something for, in the sheet's order. Before its
/// counts arrive it has none; a failed count is not a zero, so Commentary
/// and Versions stay and report their own errors.
List<ReaderResourceTab> readerResourceTabs(
  SegmentInfo? info, {
  bool failed = false,
}) {
  if (info == null) {
    return failed
        ? const [ReaderResourceTab.commentary, ReaderResourceTab.versions]
        : const [];
  }
  return [
    if (info.relatedText.commentaries > 0) ReaderResourceTab.commentary,
    if (info.translations > 0) ReaderResourceTab.versions,
    if (info.videos.isNotEmpty) ReaderResourceTab.videos,
    if (info.relatedText.hasRootText) ReaderResourceTab.rootText,
  ];
}

/// "Verse 1.113" and the verse's actions.
class _VerseHeader extends ConsumerStatefulWidget {
  const _VerseHeader({
    required this.segment,
    required this.params,
    required this.language,
    required this.onClose,
    required this.onTrack,
  });

  final Segment segment;
  final ReaderParams params;
  final String language;
  final VoidCallback onClose;
  final void Function(ReaderAction action) onTrack;

  @override
  ConsumerState<_VerseHeader> createState() => _VerseHeaderState();
}

class _VerseHeaderState extends ConsumerState<_VerseHeader> {
  bool _isBookmarking = false;
  bool _isSharing = false;

  Segment get _segment => widget.segment;

  Future<void> _bookmark() async {
    if (_isBookmarking) return;
    widget.onTrack(ReaderAction.bookmark);
    HapticFeedback.lightImpact();
    setState(() => _isBookmarking = true);
    try {
      await BookmarkController(
        ref: ref,
        context: context,
      ).toggleVerse(_segment.segmentId);
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  /// The translation line when "translation only" draws it in place of this
  /// verse's original, else null — the verse then shows its original.
  String? _translationShownAlone() {
    final dual = ref.read(
      readerDualSettingsProvider(widget.params.settingsScope),
    );
    final versionId = dual.secondary.versionId;
    if (dual.originalVisible || !dual.secondaryEnabled || versionId == null) {
      return null;
    }
    final secondary = ref.read(
      secondaryReaderProvider(
        SecondaryReaderKey(
          textId: dual.primary.versionId ?? widget.params.textId,
          versionId: versionId,
        ),
      ),
    );
    return interlinearTranslationFor(
      secondary.contentBySegmentNumber,
      _segment.segmentNumber,
    );
  }

  /// Copies the verse as shown, with line breaks kept: its translation when
  /// that stands in for a hidden original, otherwise the original,
  /// transliterated when a script is picked for its language.
  void _copy() {
    final content = _segment.content;
    if (content == null || content.isEmpty) return;
    HapticFeedback.lightImpact();
    final translation = _translationShownAlone();
    final html =
        translation != null
            ? normalizeSegmentHtml(translation)
            : transliterateSegmentHtml(
              ref.read(transliterationServiceProvider),
              html: normalizeSegmentHtml(content),
              language: widget.language,
              scriptId: ref.read(
                readerOriginalScriptProvider(
                  ReaderScriptScope(
                    scope: widget.params.settingsScope,
                    language: widget.language,
                  ),
                ),
              ),
            );
    Clipboard.setData(
      ClipboardData(text: readerPlainText(html.replaceAll('<br>', '\n'))),
    );
    widget.onTrack(ReaderAction.copy);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }

  Future<void> _share() async {
    if (_isSharing) return;
    HapticFeedback.lightImpact();
    widget.onTrack(ReaderAction.share);
    setState(() => _isSharing = true);
    try {
      final longUrl =
          DeepLinkUrlBuilder.readerSegmentLink(
            textId: widget.params.textId,
            segmentId: _segment.segmentId,
            language: widget.language,
          ).toString();
      final shareUrl = await resolveShareUrlRef(ref, longUrl);
      if (!mounted) return;
      final result = await SharePlus.instance.share(
        ShareParams(
          text: '${context.l10n.share_passage_message}\n\n$shareUrl',
          sharePositionOrigin: getSharePositionOrigin(context: context),
        ),
      );
      if (mounted && ShareAnalytics.wasUsed(result)) {
        ref
            .read(shareAnalyticsProvider)
            .contentShared(
              surface: ShareSurface.segment,
              targetId: _segment.segmentId,
              format: 'text',
            );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.shareError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    final l10n = context.l10n;
    final dual = ref.watch(
      readerDualSettingsProvider(widget.params.settingsScope),
    );
    final translationShown =
        dual.secondaryEnabled && dual.secondary.versionId != null;
    final numerals = readerNumeralScript(
      originalLanguage: widget.language,
      translationLanguage:
          translationShown ? dual.secondary.languageCode : null,
    );
    final isBookmarked = ref.watch(
      isBookmarkedProvider(
        BookmarkTarget(type: BookmarkType.verse, sourceId: _segment.segmentId),
      ),
    );

    Widget action(
      IconData icon,
      String tooltip,
      VoidCallback onTap, {
      bool busy = false,
    }) => IconButton(
      tooltip: tooltip,
      onPressed: busy ? null : onTap,
      style: readerSheetIconButtonStyle,
      constraints: const BoxConstraints(
        minWidth: readerSheetTapTarget,
        minHeight: readerSheetTapTarget,
      ),
      icon:
          busy
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.ink,
                ),
              )
              : Icon(icon, size: 22, color: palette.ink),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.reader_verse_label(
                readerVerseLabel(_segment.displayNumber, numerals),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: readerSheetText(
                context,
                ReaderSheetTextRole.title,
                color: palette.ink,
              ).copyWith(fontFamilyFallback: readerNumeralFallback(numerals)),
            ),
          ),
          action(AppAssets.readerCopy, l10n.copy, _copy),
          action(
            isBookmarked
                ? AppAssets.bookmarkSimpleFill
                : AppAssets.bookmarkSimple,
            l10n.bookmark,
            _bookmark,
            busy: _isBookmarking,
          ),
          action(AppAssets.readerShare, l10n.share, _share, busy: _isSharing),
          action(AppAssets.x, l10n.close, widget.onClose),
        ],
      ),
    );
  }
}

/// [html] as plain text: tags gone, footnote markers (`sup`) and yigchung
/// (`i`) with their contents dropped.
String readerPlainText(String html) {
  var text = html;
  for (final tag in const ['sup', 'i']) {
    text = text.replaceAll(
      RegExp('<$tag(?:\\s[^>]*)?>.*?<\\/$tag>', caseSensitive: false, dotAll: true),
      '',
    );
  }
  return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}

/// The Videos tab (WF16): the videos about the verse, two to a row, each a
/// thumbnail with a play mark and its title. A tap plays one.
class ReaderVideosTab extends ConsumerWidget {
  const ReaderVideosTab({
    super.key,
    required this.videos,
    required this.onOpened,
  });

  final List<SegmentVideo> videos;
  final VoidCallback onOpened;

  Future<void> _play(BuildContext context, SegmentVideo video) async {
    if (video.url.isEmpty) return;
    HapticFeedback.lightImpact();
    onOpened();
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'video-player'),
        builder:
            (_) => YoutubeVideoPlayer(videoUrl: video.url, title: video.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ReaderStyle.of(context, ref);
    final palette = style.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Wrap(
          spacing: _gap,
          runSpacing: 20,
          children: [
            for (final video in videos)
              LayoutBuilder(
                builder: (context, _) {
                  final width =
                      (MediaQuery.sizeOf(context).width - 32 - _gap) / 2;
                  return SizedBox(
                    width: width,
                    child: _VideoCard(
                      video: video,
                      palette: palette,
                      titleFamily: style.type.family('en'),
                      onTap: () => _play(context, video),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  static const double _gap = 12;
}

/// [video] as WF16 draws it: a rounded 16:9 thumbnail with the play mark,
/// then its title on up to two lines.
class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.video,
    required this.palette,
    required this.titleFamily,
    required this.onTap,
  });

  final SegmentVideo video;
  final ReaderPalette palette;
  final String titleFamily;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(color: palette.drawerChip);
    return Semantics(
      button: true,
      label: video.title,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: video.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => placeholder,
                      errorWidget: (_, __, ___) => placeholder,
                    ),
                    Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          AppAssets.play,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: titleFamily,
                fontSize: 14,
                height: 1.3,
                color: palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
