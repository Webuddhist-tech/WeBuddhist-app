import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/home/home.dart';
import 'package:flutter_pecha/features/plans/data/models/plan_video_model.dart';
import 'package:flutter_pecha/shared/widgets/reusable_youtube_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Renders a "Shorts from the community" section as a horizontal scrolling
/// carousel of 9:16 cards. Each card autoplays muted (Instagram-style).
/// Tapping opens [YoutubeVideoPlayer] full-screen; on return ALL inline
/// previews automatically resume via a shared [ValueNotifier].
class PlanShortsSection extends StatefulWidget {
  const PlanShortsSection({super.key, required this.videos});

  final List<PlanVideoModel> videos;

  @override
  State<PlanShortsSection> createState() => _PlanShortsSectionState();
}

class _PlanShortsSectionState extends State<PlanShortsSection> {
  // Incremented each time a card returns from full-screen; every card
  // listens and calls play() when the value changes.
  final _resumeSignal = ValueNotifier<int>(0);

  @override
  void dispose() {
    _resumeSignal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) return const SizedBox.shrink();

    final sorted = List<PlanVideoModel>.from(widget.videos)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.plan_shorts_title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          // 9:16 card width * aspect = height. Card width ~160, height ~285.
          height: 285,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 160,
                child: _ShortVideoCard(
                  key: ValueKey(sorted[index].id),
                  video: sorted[index],
                  resumeSignal: _resumeSignal,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ShortVideoCard extends StatefulWidget {
  const _ShortVideoCard({
    super.key,
    required this.video,
    required this.resumeSignal,
  });

  final PlanVideoModel video;
  final ValueNotifier<int> resumeSignal;

  @override
  State<_ShortVideoCard> createState() => _ShortVideoCardState();
}

class _ShortVideoCardState extends State<_ShortVideoCard> {
  bool _playerReady = false;
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    widget.resumeSignal.addListener(_onResumeAll);
  }

  @override
  void dispose() {
    widget.resumeSignal.removeListener(_onResumeAll);
    super.dispose();
  }

  void _onResumeAll() {
    if (mounted && _controller != null && _playerReady) {
      _controller!.play();
    }
  }

  Future<void> _openFullScreen() async {
    _controller?.pause();

    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'video-player'),
        builder:
            (_) => YoutubeVideoPlayer(
              videoUrl: widget.video.url,
              title: widget.video.title ?? '',
            ),
      ),
    );

    // Signal every card in the section to resume
    if (mounted) {
      widget.resumeSignal.value++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Inline muted autoplay player ───────────────────────────
                ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: ReusableYoutubePlayer(
                      videoUrl: widget.video.url,
                      aspectRatio: 9 / 16,
                      autoPlay: true,
                      mute: true,
                      loop: true,
                      onControllerCreated: (c) => _controller = c,
                      onReady: () {
                        if (mounted) setState(() => _playerReady = true);
                      },
                    ),
                  ),
                ),

                // ── Thumbnail shown until player is ready ──────────────────
                if (!_playerReady)
                  _ThumbnailOverlay(video: widget.video, isDark: isDark),

                // ── Invisible tap layer (WebViews eat gestures) ────────────
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _openFullScreen,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.video.title != null && widget.video.title!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            widget.video.title!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _ThumbnailOverlay extends StatelessWidget {
  const _ThumbnailOverlay({required this.video, required this.isDark});

  final PlanVideoModel video;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: video.thumbnailUrl,
      fit: BoxFit.cover,
      color: isDark ? Colors.black26 : null,
      colorBlendMode: isDark ? BlendMode.darken : null,
      placeholder:
          (context, url) => Container(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
            child: Icon(
              Icons.videocam_off_outlined,
              color: isDark ? Colors.white38 : Colors.black26,
              size: 32,
            ),
          ),
    );
  }
}
