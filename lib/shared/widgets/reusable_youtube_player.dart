import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

final _logger = AppLogger('ReusableYoutubePlayer');

class ReusableYoutubePlayer extends StatefulWidget {
  final String videoUrl;
  final double aspectRatio;
  final bool autoPlay;
  final bool mute;
  final bool loop;

  /// When true, the player expands to fill its parent instead of being
  /// constrained by [aspectRatio]. Use this for true full-screen layouts.
  final bool fillParent;
  final bool showControls;
  final VoidCallback? onReady;
  final ValueChanged<bool>? onStateChanged;
  final ValueChanged<YoutubePlayerController>? onControllerCreated;
  final ValueChanged<VoidCallback>? onStopPlaybackRegistered;

  const ReusableYoutubePlayer({
    super.key,
    required this.videoUrl,
    this.aspectRatio = 16 / 9,
    this.autoPlay = false,
    this.mute = false,
    this.loop = false,
    this.fillParent = false,
    this.showControls = false,
    this.onReady,
    this.onStateChanged,
    this.onControllerCreated,
    this.onStopPlaybackRegistered,
  });

  @override
  State<ReusableYoutubePlayer> createState() => _ReusableYoutubePlayerState();
}

class _ReusableYoutubePlayerState extends State<ReusableYoutubePlayer> {
  late YoutubePlayerController _controller;
  bool _hasCalledOnReady = false;
  bool? _previousIsPlaying;
  bool _isDisposed = false;
  // Prevents more than one seekTo callback from being queued at a time
  // when the video reaches the end in loop mode.
  bool _seekPending = false;
  bool _playbackStopped = false;
  // Fullscreen moves the player into its own route; the key keeps the WebView.
  final _playerKey = GlobalKey();
  final _fullscreenTick = ValueNotifier<int>(0);
  bool _fullscreen = false;
  Route<void>? _fullscreenRoute;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: YoutubePlayerFlags(
        autoPlay: widget.autoPlay,
        mute: widget.mute,
        loop: widget.loop,
        hideControls: !widget.showControls,
        controlsVisibleAtStart: widget.showControls,
        useHybridComposition: true,
        enableCaption: false,
      ),
    );

    // Notify parent widget about controller creation
    if (widget.onControllerCreated != null) {
      widget.onControllerCreated!(_controller);
    }

    // Listen to player state changes
    _controller.addListener(_onControllerUpdate);
    widget.onStopPlaybackRegistered?.call(_stopPlayback);
  }

  // The fullscreen route builds outside this subtree, so nudge it as well.
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_fullscreenRoute != null) _fullscreenTick.value++;
  }

  /// Stops decoding/audio and clears the WebView polling interval before exit.
  void _stopPlayback() {
    if (_playbackStopped) return;
    _playbackStopped = true;
    _seekPending = false;
    _controller.removeListener(_onControllerUpdate);

    final webView = _controller.value.webViewController;
    if (_controller.value.isReady && webView != null) {
      try {
        webView.evaluateJavascript(
          source: '''
            if (typeof timerId !== 'undefined') {
              clearInterval(timerId);
            }
            if (typeof player !== 'undefined' && player) {
              player.stopVideo();
            }
          ''',
        );
      } catch (_) {
        // Ignore JS errors if the WebView is already torn down.
      }
      try {
        _controller.pause();
        _controller.mute();
      } catch (_) {
        // Ignore errors if the controller is already in a bad state.
      }
    }
  }

  void _onControllerUpdate() {
    if (_isDisposed || _playbackStopped || !mounted) return;

    // Handle onReady callback
    if (_controller.value.isReady &&
        !_hasCalledOnReady &&
        widget.onReady != null) {
      _hasCalledOnReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed && !_playbackStopped) {
          widget.onReady!();
        }
      });
    }

    // Safety-net loop: restart from the beginning when the video ends.
    // The _seekPending flag ensures only one callback is ever queued per
    // ended-state notification so rapid listener firings don't stack up.
    if (widget.loop &&
        _controller.value.isReady &&
        _controller.value.playerState == PlayerState.ended &&
        !_seekPending) {
      _seekPending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _seekPending = false;
        if (mounted && !_isDisposed && !_playbackStopped) {
          _controller.seekTo(Duration.zero);
          _controller.play();
        }
      });
    }

    // Handle state change callback
    if (widget.onStateChanged != null && _controller.value.isReady) {
      final currentState = _controller.value.playerState;
      final isPlaying = currentState == PlayerState.playing;
      if (isPlaying != _previousIsPlaying) {
        _previousIsPlaying = isPlaying;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposed && !_playbackStopped) {
            widget.onStateChanged!(isPlaying);
          }
        });
      }
    }
  }

  Future<void> _setFullscreenChrome(bool on) async {
    try {
      if (on) {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
        ]);
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      }
    } catch (e) {
      _logger.warning('Fullscreen ${on ? 'enter' : 'exit'}: $e');
    }
  }

  void _toggleFullscreen() {
    if (_fullscreen) {
      _exitFullscreen();
    } else {
      _enterFullscreen();
    }
  }

  void _enterFullscreen() {
    if (_fullscreenRoute != null) return;
    final route = PageRouteBuilder<void>(
      settings: const RouteSettings(name: 'youtube-player-fullscreen'),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => _buildFullscreen(),
    );
    _fullscreenRoute = route;
    // The inline slot and the route rebuild in the same frame, so the keyed
    // player moves across without recreating the WebView.
    setState(() => _fullscreen = true);
    _controller.updateValue(_controller.value.copyWith(isFullScreen: true));
    unawaited(_setFullscreenChrome(true));
    unawaited(
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(route).then((_) => _onFullscreenClosed(route)),
    );
  }

  void _exitFullscreen() {
    final route = _fullscreenRoute;
    if (route == null) return;
    if (route.isCurrent) {
      route.navigator?.pop();
      return;
    }
    if (route.isActive) route.navigator?.removeRoute(route);
    _onFullscreenClosed(route);
  }

  void _onFullscreenClosed(Route<void> route) {
    if (_fullscreenRoute != route || !mounted) return;
    setState(() => _fullscreen = false);
    _fullscreenRoute = null;
    _controller.updateValue(_controller.value.copyWith(isFullScreen: false));
    unawaited(_setFullscreenChrome(false));
  }

  @override
  void dispose() {
    _isDisposed = true;
    final route = _fullscreenRoute;
    if (route != null) {
      // Unmounted underneath fullscreen: drop the route once this frame ends.
      _fullscreenRoute = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isActive) route.navigator?.removeRoute(route);
      });
      unawaited(_setFullscreenChrome(false));
    }
    _fullscreenTick.dispose();
    _stopPlayback();
    // Wrap dispose in try-catch to handle InAppWebView disposal race condition
    try {
      _controller.dispose();
    } catch (_) {
      // Ignore disposal errors from InAppWebView race condition
    }
    super.dispose();
  }

  List<Widget> _bottomActions() {
    return [
      const SizedBox(width: 14),
      const CurrentPosition(),
      const SizedBox(width: 8),
      const ProgressBar(isExpanded: true),
      const RemainingDuration(),
      const PlaybackSpeedButton(),
      _FullscreenButton(isFullscreen: _fullscreen, onTap: _toggleFullscreen),
    ];
  }

  Widget _buildPlayer(double aspectRatio) {
    return KeyedSubtree(
      key: _playerKey,
      child: YoutubePlayer(
        controller: _controller,
        aspectRatio: aspectRatio,
        showVideoProgressIndicator: false,
        bottomActions: widget.showControls ? _bottomActions() : null,
      ),
    );
  }

  Widget _buildFullscreen() {
    return ListenableBuilder(
      listenable: _fullscreenTick,
      builder: (context, _) {
        // Player handed back to the inline slot; the route is on its way out.
        if (!_fullscreen) return const ColoredBox(color: Colors.black);
        final size = MediaQuery.sizeOf(context);
        final ratio = widget.aspectRatio;
        final width = math.min(size.width, size.height * ratio);
        return ColoredBox(
          color: Colors.black,
          child: Center(
            child: SizedBox(
              width: width,
              height: width / ratio,
              child: _buildPlayer(ratio),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return const SizedBox.shrink();

    if (widget.fillParent) {
      // YoutubePlayer's internal AspectRatio widget will always pick the
      // largest size satisfying its ratio within the given constraints.
      // To truly fill any screen (e.g. 9:19.5), we measure the available
      // space via LayoutBuilder and feed that exact ratio back to the player,
      // so AspectRatio resolves to the full bounds.
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenRatio = constraints.maxWidth / constraints.maxHeight;
          return _buildPlayer(screenRatio);
        },
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child:
          _fullscreen
              ? const ColoredBox(color: Colors.black)
              : _buildPlayer(widget.aspectRatio),
    );
  }
}

/// Enters or leaves the landscape fullscreen player.
class _FullscreenButton extends StatelessWidget {
  final bool isFullscreen;
  final VoidCallback onTap;

  const _FullscreenButton({required this.isFullscreen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip:
          isFullscreen
              ? context.l10n.player_exit_fullscreen
              : context.l10n.player_fullscreen,
      iconSize: 24,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      color: Colors.white,
      onPressed: onTap,
      icon: Icon(
        isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
      ),
    );
  }
}
