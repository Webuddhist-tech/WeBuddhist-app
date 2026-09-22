import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/youtube_video_player.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/reader/data/models/secondary_reader_state.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_secondary_content_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_transliteration.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/interlinear_segment_item.dart'
    show interlinearTranslationFor;
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/data/models/segment_info.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/segment_provider.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Converts HTML to plain text, removing specified elements using regex
String _htmlToPlainText(String htmlString) {
  String cleanedHtml = _removeHtmlElementsWithContent(htmlString, ['sup', 'i']);
  return cleanedHtml.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}

String _removeHtmlElementsWithContent(String html, List<String> tagsToRemove) {
  String result = html;
  for (String tag in tagsToRemove) {
    RegExp regex = RegExp(
      '<$tag(?:\\s[^>]*)?>.*?<\\/$tag>',
      caseSensitive: false,
      dotAll: true,
    );
    result = result.replaceAll(regex, '');
  }
  return result;
}

/// "Resources" bottom panel: Copy/Share icon buttons + Commentaries/Versions
/// list tiles. Appears when a segment is selected and no split panel is open.
class SegmentActionBar extends ConsumerStatefulWidget {
  final Segment segment;
  final ReaderParams params;
  final VoidCallback onClose;
  final VoidCallback? onOpenCommentary;
  final VoidCallback? onOpenTranslation;

  const SegmentActionBar({
    super.key,
    required this.segment,
    required this.params,
    required this.onClose,
    this.onOpenCommentary,
    this.onOpenTranslation,
  });

  @override
  ConsumerState<SegmentActionBar> createState() => _SegmentActionBarState();
}

class _SegmentActionBarState extends ConsumerState<SegmentActionBar> {
  bool _isBookmarking = false;

  Future<void> _handleBookmark() async {
    if (_isBookmarking) return;
    HapticFeedback.lightImpact();
    setState(() => _isBookmarking = true);
    try {
      await BookmarkController(
        ref: ref,
        context: context,
      ).toggleVerse(widget.segment.segmentId);
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  /// The translation line when "translation only" draws it in place of this
  /// verse's original, else null — the verse then shows its original.
  String? _translationShownAlone() {
    final dual = ref.read(readerDualSettingsProvider(widget.params.textId));
    final versionId = dual.secondary.versionId;
    if (dual.originalVisible || !dual.secondaryEnabled || versionId == null) {
      return null;
    }
    // The key ReaderContentPart watches (the initial segment is not part of
    // its identity), so this reads the lines already on screen.
    final secondary = ref.read(
      secondaryReaderProvider(
        SecondaryReaderKey(
          textId: dual.primary.versionId ?? widget.params.textId,
          versionId: versionId,
          initialSize: widget.params.navigationContext?.initialPageSize,
        ),
      ),
    );
    // A verse with no translation yet keeps its original (interlinearLayers).
    return interlinearTranslationFor(
      secondary.contentBySegmentNumber,
      widget.segment.segmentNumber,
    );
  }

  /// Copies the verse as shown, with line breaks kept: its translation when
  /// that stands in for a hidden original, otherwise the original,
  /// transliterated when a script is picked for [language].
  void _handleCopy(BuildContext context, String content, String language) {
    final localizations = context.l10n;
    final translation = _translationShownAlone();
    final html =
        translation != null
            ? normalizeSegmentHtml(translation)
            : transliterateSegmentHtml(
              ref.read(transliterationServiceProvider),
              html: normalizeSegmentHtml(content),
              language: language,
              scriptId: ref.read(readerScriptForLanguageProvider(language)),
            );
    final textWithLineBreaks = html.replaceAll('<br>', '\n');
    final plainText = _htmlToPlainText(textWithLineBreaks);
    Clipboard.setData(ClipboardData(text: plainText));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(localizations.copied)));
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final state = ref.watch(readerNotifierProvider(widget.params));
    final notifier = ref.read(readerNotifierProvider(widget.params).notifier);

    final content = widget.segment.content;
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    final isBookmarked = ref.watch(
      isBookmarkedProvider(
        BookmarkTarget(
          type: BookmarkType.verse,
          sourceId: widget.segment.segmentId,
        ),
      ),
    );
    final segmentInfo = ref.watch(
      segmentInfoFutureProvider(widget.segment.segmentId),
    );
    final videos = segmentInfo.valueOrNull?.videos ?? const <SegmentVideo>[];

    return _ResourcesPanel(
      onDismiss: widget.onClose,
      copyButton: _IconActionButton(
        icon: AppAssets.readerCopy,
        label: localizations.copy,
        onTap: () {
          HapticFeedback.lightImpact();
          _handleCopy(context, content, state.textDetail?.language ?? 'en');
        },
      ),
      shareButton: _ShareButton(
        textId: widget.params.textId,
        segmentId: widget.segment.segmentId,
        language: state.textDetail?.language ?? 'en',
        onClose: widget.onClose,
      ),
      bookmarkButton: _IconActionButton(
        icon:
            isBookmarked
                ? AppAssets.bookmarkSimpleFill
                : AppAssets.bookmarkSimple,
        label: localizations.bookmark,
        isLoading: _isBookmarking,
        onTap: _handleBookmark,
      ),
      tiles: [
        _ResourceTile(
          icon: AppAssets.readerCommentary,
          label: localizations.text_commentary,
          onTap: () {
            HapticFeedback.lightImpact();
            notifier.toggleCommentary(widget.segment.segmentId);
            if (!state.isCommentaryOpen) {
              widget.onOpenCommentary?.call();
            }
          },
        ),
        _ResourceTile(
          icon: AppAssets.readerVersion,
          label: localizations.version,
          onTap: () {
            HapticFeedback.lightImpact();
            notifier.toggleTranslation(widget.segment.segmentId);
            if (!state.isTranslationOpen) {
              widget.onOpenTranslation?.call();
            }
          },
        ),
      ],
      videos: videos,
    );
  }
}

/// Bottom-sheet-style panel. Dismissible by swiping downward.
/// Layout: drag handle → [Copy | Share | Bookmark] → Resources → tiles.
class _ResourcesPanel extends StatefulWidget {
  final VoidCallback onDismiss;
  final Widget copyButton;
  final Widget shareButton;
  final Widget bookmarkButton;
  final List<Widget> tiles;
  final List<SegmentVideo> videos;

  const _ResourcesPanel({
    required this.onDismiss,
    required this.copyButton,
    required this.shareButton,
    required this.bookmarkButton,
    required this.tiles,
    required this.videos,
  });

  @override
  State<_ResourcesPanel> createState() => _ResourcesPanelState();
}

class _ResourcesPanelState extends State<_ResourcesPanel> {
  static const double _headerHeight = 70;
  static const double _collapsedContentHeight = 328;
  static const double _videosSectionHeight = 280;

  late final DraggableScrollableController _sheetController;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _sheetController.addListener(_onSheetSizeChanged);
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetSizeChanged);
    _sheetController.dispose();
    super.dispose();
  }

  void _onSheetSizeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sheetController.isAttached) return;

    final min = _collapsedSize(context);
    final max = _expandedSize(context);
    final size = _sheetController.size;
    if (size > max + 0.01) {
      _sheetController.jumpTo(max);
    } else if (size < min - 0.01) {
      _sheetController.jumpTo(min);
    }
  }

  Future<void> _openSegmentVideo(SegmentVideo video) async {
    if (video.url.isEmpty || !_sheetController.isAttached) return;

    if (_isExpanded(context)) {
      await _sheetController.animateTo(
        _collapsedSize(context),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
    if (!mounted) return;

    HapticFeedback.lightImpact();
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder:
            (_) => YoutubeVideoPlayer(videoUrl: video.url, title: video.title),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _ResourcesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sheetController.isAttached) return;
    if (widget.videos.isEmpty &&
        _sheetController.size > _collapsedSize(context) + 0.02) {
      _sheetController.animateTo(
        _collapsedSize(context),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  double _collapsedSize(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return ((_collapsedContentHeight + safeBottom) / screenHeight).clamp(
      0.28,
      0.45,
    );
  }

  double _expandedSize(BuildContext context) {
    if (widget.videos.isEmpty) return _collapsedSize(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final expandedHeight =
        _collapsedContentHeight + _videosSectionHeight + safeBottom;
    return (expandedHeight / screenHeight).clamp(
      _collapsedSize(context) + 0.08,
      0.85,
    );
  }

  bool _isExpanded(BuildContext context) {
    if (!_sheetController.isAttached) return false;
    return _sheetController.size > _collapsedSize(context) + 0.02;
  }

  void _expand() {
    if (widget.videos.isEmpty || !_sheetController.isAttached) return;
    HapticFeedback.lightImpact();
    _sheetController.animateTo(
      _expandedSize(context),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _collapse(BuildContext context) {
    if (!_sheetController.isAttached) return;
    HapticFeedback.lightImpact();
    _sheetController.animateTo(
      _collapsedSize(context),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _handleDragHandleDragEnd(BuildContext context, DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (!_sheetController.isAttached) return;

    final collapsed = _collapsedSize(context);
    final expanded = _expandedSize(context);
    final hasVideos = widget.videos.isNotEmpty;

    if (velocity < -200 && hasVideos) {
      _expand();
      return;
    }
    if (velocity > 200) {
      if (_isExpanded(context)) {
        _collapse(context);
      } else if (_sheetController.size <= collapsed + 0.02) {
        HapticFeedback.lightImpact();
        widget.onDismiss();
      }
      return;
    }

    final midPoint = (collapsed + expanded) / 2;
    if (hasVideos && _sheetController.size > midPoint) {
      _expand();
    } else if (_isExpanded(context)) {
      _collapse(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBackgroundColor = theme.colorScheme.onSurface.withValues(
      alpha: 0.05,
    );
    const radius = Radius.circular(20);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final collapsedSize = _collapsedSize(context);
    final expandedSize = _expandedSize(context);
    final hasVideos = widget.videos.isNotEmpty;
    final showMorePrompt = hasVideos && !_isExpanded(context);
    final currentSize =
        _sheetController.isAttached ? _sheetController.size : collapsedSize;
    final visibleHeight = currentSize * screenHeight;

    return SizedBox(
      height: visibleHeight,
      width: double.infinity,
      child: OverflowBox(
        maxHeight: screenHeight,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: screenHeight,
          width: double.infinity,
          child: DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: collapsedSize,
            minChildSize: collapsedSize,
            maxChildSize: hasVideos ? expandedSize : collapsedSize,
            snap: hasVideos,
            snapSizes: hasVideos ? [collapsedSize, expandedSize] : null,
            builder: (context, scrollController) {
              return Material(
                color: theme.colorScheme.surface,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: radius,
                  topRight: radius,
                ),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragEnd:
                            (details) =>
                                _handleDragHandleDragEnd(context, details),
                        child: ColoredBox(
                          color: cardBackgroundColor,
                          child: SizedBox(
                            height: _headerHeight,
                            width: double.infinity,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                margin: const EdgeInsets.only(top: 10),
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: ReaderPanelConstants.dragHandleColor(
                                    context,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          child: _buildPanelBody(
                            context,
                            showMorePrompt: showMorePrompt,
                            showVideos: _isExpanded(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPanelBody(
    BuildContext context, {
    required bool showMorePrompt,
    required bool showVideos,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(
            children: [
              widget.copyButton,
              const SizedBox(width: 8),
              widget.bookmarkButton,
              const SizedBox(width: 8),
              widget.shareButton,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
          child: Text(
            context.l10n.resources,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
        for (final tile in widget.tiles) tile,
        if (showMorePrompt) _SwipeForMorePrompt(onTap: _expand),
        if (showVideos && widget.videos.isNotEmpty)
          _VideosSection(videos: widget.videos, onVideoTap: _openSegmentVideo),
        SizedBox(height: 12 + MediaQuery.paddingOf(context).bottom),
      ],
    );
  }
}

class _SwipeForMorePrompt extends StatelessWidget {
  const _SwipeForMorePrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -100) onTap();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_arrow_up_rounded, color: color, size: 24),
              const SizedBox(width: 6),
              Text(
                context.l10n.reader_swipe_up_for_more,
                style: theme.textTheme.bodyMedium?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideosSection extends StatelessWidget {
  const _VideosSection({required this.videos, required this.onVideoTap});

  final List<SegmentVideo> videos;
  final Future<void> Function(SegmentVideo video) onVideoTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            context.l10n.reader_videos,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: theme.dividerColor),
        const SizedBox(height: 12),
        SizedBox(
          height: 176,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth =
                  (MediaQuery.sizeOf(context).width * 0.46)
                      .clamp(160.0, 232.0)
                      .toDouble();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: videos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: cardWidth,
                    child: _SegmentVideoCard(
                      video: videos[index],
                      onTap: () => onVideoTap(videos[index]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SegmentVideoCard extends StatelessWidget {
  const _SegmentVideoCard({required this.video, required this.onTap});

  final SegmentVideo video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: video.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => ColoredBox(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                    ),
                errorWidget:
                    (context, url, error) => ColoredBox(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                      child: Icon(
                        Icons.videocam_off_outlined,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              height: 1.15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact horizontal pill used in the Copy/Share/Bookmark row.
class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _IconActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;
    final backgroundColor = theme.colorScheme.onSurface.withValues(alpha: 0.05);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else
                Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width list tile for Commentaries / Versions with a trailing chevron.
class _ResourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ResourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: Icon(
        AppAssets.readerChevronRight,
        size: 24,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      onTap: onTap,
    );
  }
}

/// Share button — handles URL generation and loading state.
class _ShareButton extends ConsumerStatefulWidget {
  final String textId;
  final String segmentId;
  final String language;
  final VoidCallback onClose;

  const _ShareButton({
    required this.textId,
    required this.segmentId,
    required this.language,
    required this.onClose,
  });

  @override
  ConsumerState<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends ConsumerState<_ShareButton> {
  bool _isLoading = false;

  Future<void> _handleShare() async {
    HapticFeedback.lightImpact();
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final longUrl =
          DeepLinkUrlBuilder.readerSegmentLink(
            textId: widget.textId,
            segmentId: widget.segmentId,
            language: widget.language,
          ).toString();
      final shareUrl = await resolveShareUrlRef(ref, longUrl);

      if (!mounted) return;

      final sharePositionOrigin = getSharePositionOrigin(context: context);
      final shareMessage = context.l10n.share_passage_message;
      await SharePlus.instance.share(
        ShareParams(
          text: '$shareMessage\n\n$shareUrl',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      widget.onClose();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.shareError(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _IconActionButton(
      icon: AppAssets.readerShare,
      label: context.l10n.share,
      onTap: _handleShare,
      isLoading: _isLoading,
    );
  }
}
