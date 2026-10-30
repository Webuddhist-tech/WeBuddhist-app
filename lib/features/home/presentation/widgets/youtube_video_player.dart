import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_post_link_utils.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../shared/widgets/reusable_youtube_player.dart';

class YoutubeVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;

  const YoutubeVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<YoutubeVideoPlayer> createState() => _YoutubeVideoPlayerState();
}

class _YoutubeVideoPlayerState extends State<YoutubeVideoPlayer> {
  YoutubePlayerController? _controller;
  VoidCallback? _stopPlayback;
  Timer? _controlsTimer;
  bool _isPlaying = false;
  bool _isReady = false;
  bool _showPlaybackControls = true;
  late final bool _isShort;

  @override
  void initState() {
    super.initState();
    _isShort = ConnectPostLinkUtils.isYoutubeShort(widget.videoUrl);
    if (!_isShort) return;
    // Hide status bar and navigation bar for a true full-screen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _scheduleControlsHide();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _stopPlayback?.call();
    _controller = null;
    _stopPlayback = null;
    _restoreSystemUi();
    super.dispose();
  }

  void _restoreSystemUi() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _closePlayer() {
    _controlsTimer?.cancel();
    _stopPlayback?.call();
    _controller = null;
    _stopPlayback = null;
    _restoreSystemUi();
    Navigator.of(context).pop();
  }

  void _seekBy(Duration offset) {
    final controller = _controller;
    if (controller == null || !_isReady) return;

    final current = controller.value.position;
    final target = current + offset;
    controller.seekTo(target < Duration.zero ? Duration.zero : target);
    _showControlsTemporarily();
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !_isReady) return;

    HapticFeedback.selectionClick();
    if (_isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() => _isPlaying = !_isPlaying);
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    if (!_showPlaybackControls) {
      setState(() => _showPlaybackControls = true);
    }
    _scheduleControlsHide();
  }

  void _scheduleControlsHide() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _showPlaybackControls = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _controlsTimer?.cancel();
          _stopPlayback?.call();
          _controller = null;
          _stopPlayback = null;
          _restoreSystemUi();
        }
      },
      child: _isShort ? _buildShorts(context) : _buildStandard(context),
    );
  }

  /// Hour-long recordings and other non-Shorts: a 16:9 player with the
  /// normal progress bar, not the vertical full-screen loop.
  Widget _buildStandard(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: _closePlayer,
        ),
        title:
            widget.title.isEmpty
                ? null
                : Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ReusableYoutubePlayer(
          videoUrl: widget.videoUrl,
          aspectRatio: 16 / 9,
          autoPlay: true,
          mute: false,
          loop: false,
          showControls: true,
          onControllerCreated: (controller) => _controller = controller,
          onStopPlaybackRegistered: (stop) => _stopPlayback = stop,
        ),
      ),
    );
  }

  Widget _buildShorts(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Let the player go behind where the status bar was
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen player ─────────────────────────────────────────
          AbsorbPointer(
            child: ReusableYoutubePlayer(
              videoUrl: widget.videoUrl,
              aspectRatio: 9 / 16,
              autoPlay: true,
              mute: false,
              loop: true,
              fillParent: true,
              onControllerCreated: (controller) => _controller = controller,
              onStopPlaybackRegistered: (stop) => _stopPlayback = stop,
              onReady: () {
                if (mounted) setState(() => _isReady = true);
              },
              onStateChanged: (isPlaying) {
                if (mounted) setState(() => _isPlaying = isPlaying);
              },
            ),
          ),

          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _showControlsTemporarily,
            ),
          ),

          // ── Quick playback controls ────────────────────────────────────
          Center(
            child: IgnorePointer(
              ignoring: !_showPlaybackControls,
              child: AnimatedOpacity(
                opacity: _showPlaybackControls ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PlaybackControlButton(
                      icon: Icons.replay_10_rounded,
                      label: context.l10n.player_back_10,
                      onPressed:
                          _isReady
                              ? () {
                                HapticFeedback.selectionClick();
                                _seekBy(const Duration(seconds: -10));
                              }
                              : null,
                    ),
                    const SizedBox(width: 20),
                    _PlaybackControlButton(
                      icon:
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                      label:
                          _isPlaying
                              ? context.l10n.player_pause
                              : context.l10n.player_play,
                      size: 45,
                      onPressed: _isReady ? _togglePlayPause : null,
                    ),
                    const SizedBox(width: 20),
                    _PlaybackControlButton(
                      icon: Icons.forward_10_rounded,
                      label: context.l10n.player_forward_10,
                      onPressed:
                          _isReady
                              ? () {
                                HapticFeedback.selectionClick();
                                _seekBy(const Duration(seconds: 10));
                              }
                              : null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Back button overlay ────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(AppAssets.arrowLeft, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
                shape: const CircleBorder(),
              ),
              onPressed: _closePlayer,
            ),
          ),

          // ── Title overlay at bottom ────────────────────────────────────
          if (widget.title.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaybackControlButton extends StatelessWidget {
  const _PlaybackControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 34,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      iconSize: size,
      color: Colors.white,
      disabledColor: Colors.white54,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black45,
        disabledBackgroundColor: Colors.black26,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(10),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}
