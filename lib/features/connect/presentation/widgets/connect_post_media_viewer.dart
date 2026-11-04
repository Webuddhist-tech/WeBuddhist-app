import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_post_like_actions.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_like_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_post_share.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen photo viewer for a post: swipe between photos, pinch or
/// double-tap to zoom.
class ConnectPostMediaViewer extends StatefulWidget {
  const ConnectPostMediaViewer({
    super.key,
    required this.media,
    this.initialIndex = 0,
    this.title,
    this.actions,
  });

  final List<ConnectPostMedia> media;
  final int initialIndex;

  /// Shown above the zoom hint, usually the group name.
  final String? title;

  final Widget? actions;

  static Future<void> show(
    BuildContext context, {
    required List<ConnectPostMedia> media,
    int initialIndex = 0,
    String? title,
    Widget? actions,
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
              actions: actions,
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
    final actions = widget.actions;

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
                      media: widget.media[index],
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
                  if (actions != null) ...[const SizedBox(height: 8), actions],
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
  const _ZoomableImage({required this.media, required this.onZoomChanged});

  final ConnectPostMedia media;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  static const _doubleTapScale = 2.5;
  static const _maxScale = 4.0;

  /// Longest decoded side; keeps a huge photo from taking hundreds of MB.
  static const _maxDecodeSide = 4096.0;

  final TransformationController _transformation = TransformationController();
  Offset _doubleTapPosition = Offset.zero;

  bool get _isZoomed => _transformation.value.getMaxScaleOnAxis() > 1.01;

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  int _decodeBound(double viewportPx) {
    return (viewportPx * _maxScale).clamp(1.0, _maxDecodeSide).round();
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
        maxScale: _maxScale,
        onInteractionEnd: (_) => widget.onZoomChanged(_isZoomed),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewport =
                constraints.biggest * MediaQuery.devicePixelRatioOf(context);
            return SizedBox.expand(
              // Sharp at full zoom. The fit policy reads the real photo size,
              // so both sides stay bounded without stretching or upscaling.
              child: Image(
                image: ResizeImage(
                  widget.media.url.trim().cachedNetworkImageProvider,
                  width: _decodeBound(viewport.width),
                  height: _decodeBound(viewport.height),
                  policy: ResizeImagePolicy.fit,
                ),
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) => const Center(
                      child: Icon(
                        AppAssets.photoLibrary,
                        color: AppColors.grey500,
                      ),
                    ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Like and share buttons for the viewer's dark footer.
///
/// Holds its own copy of the post and like state: the screen that opened the
/// viewer can be reused for another post or disposed while the viewer is open.
class ConnectPostMediaViewerActions extends ConsumerStatefulWidget {
  const ConnectPostMediaViewerActions({
    super.key,
    required this.post,
    this.includeUnfollowed = false,
    this.groupId,
    this.onLikeChanged,
  });

  /// The post as the opening screen currently shows it.
  final ConnectPost post;
  final bool includeUnfollowed;
  final String? groupId;

  /// Called after a like succeeds, even if the viewer has closed by then.
  final ValueChanged<ConnectPost>? onLikeChanged;

  @override
  ConsumerState<ConnectPostMediaViewerActions> createState() =>
      _ConnectPostMediaViewerActionsState();
}

class _ConnectPostMediaViewerActionsState
    extends ConsumerState<ConnectPostMediaViewerActions> {
  final ConnectOptimisticLikeState _likeState = ConnectOptimisticLikeState();
  late ConnectPost _post = widget.post;

  bool get _isLiked => _likeState.isLiked(_post.likedByMe);

  int get _likeCount => _likeState.likeCount(
    serverLikeCount: _post.likeCount,
    serverLikedByMe: _post.likedByMe,
  );

  @override
  void initState() {
    super.initState();
    final pending = ref
        .read(connectPostLikeActionsProvider)
        .pendingLike(widget.post.id);
    if (pending != null) _followPendingLike(pending);
  }

  /// Shows a request another surface started, and stays locked until it ends,
  /// so a new toggle cannot race it. That surface reports any failure.
  void _followPendingLike(ConnectPendingPostLike pending) {
    _post = _post.copyWith(
      likedByMe: !pending.wasLiked,
      likeCount: pending.optimisticLikeCount,
    );
    _likeState.isSubmitting = true;

    void settle({required bool succeeded}) {
      if (!mounted) return;
      setState(() {
        _likeState.isSubmitting = false;
        if (succeeded) return;
        _post = _post.copyWith(
          likedByMe: pending.wasLiked,
          likeCount: nextLikeCountAfterToggle(
            currentCount: pending.optimisticLikeCount,
            wasLiked: !pending.wasLiked,
          ),
        );
      });
    }

    pending.result.then(
      (result) => settle(succeeded: result.isSuccess),
      onError: (Object _) => settle(succeeded: false),
    );
  }

  Future<void> _toggleLike() async {
    if (_likeState.isSubmitting ||
        ref.read(connectPostLikeActionsProvider).pendingLike(_post.id) !=
            null) {
      return;
    }

    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref, useRootNavigator: true);
      return;
    }

    final wasLiked = _isLiked;
    final onLikeChanged = widget.onLikeChanged;
    setState(() => _likeState.beginToggle(wasLiked));

    final result = await ref
        .read(connectPostLikeActionsProvider)
        .toggleLike(
          post: _post,
          wasLiked: wasLiked,
          optimisticLikeCount: _likeCount,
          includeUnfollowed: widget.includeUnfollowed,
          groupId: widget.groupId,
        );

    if (result.isSuccess) onLikeChanged?.call(result.updatedPost!);
    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() => _likeState.revert(wasLiked));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasLiked
                ? context.l10n.connect_failed_unlike_post_error
                : context.l10n.connect_failed_like_post_error,
          ),
        ),
      );
      return;
    }

    setState(() {
      _likeState.commitSuccess(
        serverLikeCount: _post.likeCount,
        serverLikedByMe: _post.likedByMe,
      );
      _post = result.updatedPost!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = _isLiked;
    final likeCount = _likeCount;

    return Row(
      children: [
        InkWell(
          onTap: _likeState.isSubmitting ? null : _toggleLike,
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
          onPressed: () => shareConnectPost(context, ref, _post),
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
