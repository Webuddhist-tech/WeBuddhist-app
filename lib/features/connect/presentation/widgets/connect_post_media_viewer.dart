import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';

/// Full-screen photo viewer for a post: swipe between photos, pinch or
/// double-tap to zoom.
class ConnectPostMediaViewer extends StatefulWidget {
  const ConnectPostMediaViewer({
    super.key,
    required this.media,
    this.initialIndex = 0,
    this.title,
    this.listenable,
    this.actionsBuilder,
  });

  final List<ConnectPostMedia> media;
  final int initialIndex;

  /// Shown above the zoom hint, usually the group name.
  final String? title;

  /// Rebuilds [actionsBuilder] when the post's like state changes.
  final Listenable? listenable;
  final WidgetBuilder? actionsBuilder;

  static Future<void> show(
    BuildContext context, {
    required List<ConnectPostMedia> media,
    int initialIndex = 0,
    String? title,
    Listenable? listenable,
    WidgetBuilder? actionsBuilder,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder:
            (_, __, ___) => ConnectPostMediaViewer(
              media: media,
              initialIndex: initialIndex,
              title: title,
              listenable: listenable,
              actionsBuilder: actionsBuilder,
            ),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<ConnectPostMediaViewer> createState() => _ConnectPostMediaViewerState();
}

class _ConnectPostMediaViewerState extends State<ConnectPostMediaViewer> {
  late final PageController _controller;
  late int _index;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.media.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title?.trim() ?? '';
    final actionsBuilder = widget.actionsBuilder;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Stack(
                children: [
                  if (widget.media.length > 1)
                    Center(
                      child: Text(
                        '${_index + 1} / ${widget.media.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      icon: const Icon(AppAssets.x, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics:
                    _zoomed
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                itemCount: widget.media.length,
                onPageChanged:
                    (index) => setState(() {
                      _index = index;
                      _zoomed = false;
                    }),
                itemBuilder:
                    (context, index) => _ZoomableImage(
                      url: widget.media[index].url,
                      onZoomChanged: (zoomed) {
                        if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                      },
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.connect_post_media_viewer_hint,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  if (actionsBuilder != null) ...[
                    const SizedBox(height: 8),
                    widget.listenable == null
                        ? actionsBuilder(context)
                        : ListenableBuilder(
                          listenable: widget.listenable!,
                          builder: (context, _) => actionsBuilder(context),
                        ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.url, required this.onZoomChanged});

  final String url;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  static const _doubleTapScale = 2.5;

  final TransformationController _transformation = TransformationController();
  Offset _doubleTapPosition = Offset.zero;

  bool get _isZoomed => _transformation.value.getMaxScaleOnAxis() > 1.01;

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_isZoomed) {
      _transformation.value = Matrix4.identity();
    } else {
      final dx = -_doubleTapPosition.dx * (_doubleTapScale - 1);
      final dy = -_doubleTapPosition.dy * (_doubleTapScale - 1);
      _transformation.value = Matrix4.diagonal3Values(
        _doubleTapScale,
        _doubleTapScale,
        1,
      )..setTranslationRaw(dx, dy, 0);
    }
    widget.onZoomChanged(_isZoomed);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transformation,
        minScale: 1,
        maxScale: 4,
        onInteractionEnd: (_) => widget.onZoomChanged(_isZoomed),
        child: SizedBox.expand(
          child: CachedNetworkImageWidget(
            imageUrl: widget.url,
            fit: BoxFit.contain,
            errorWidget: const Center(
              child: Icon(AppAssets.photoLibrary, color: AppColors.grey500),
            ),
          ),
        ),
      ),
    );
  }
}

/// Like and share buttons for the viewer's dark footer.
class ConnectPostMediaViewerActions extends StatelessWidget {
  const ConnectPostMediaViewerActions({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.isLoading,
    required this.onLike,
    required this.onShare,
  });

  final bool isLiked;
  final int likeCount;
  final bool isLoading;
  final VoidCallback onLike;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: isLoading ? null : onLike,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? AppAssets.heartFill : AppAssets.heart,
                  size: 20,
                  color: isLiked ? AppColors.error : Colors.white,
                ),
                if (likeCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$likeCount',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onShare,
          icon: const Icon(
            AppAssets.readerShare,
            size: 20,
            color: Colors.white,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
