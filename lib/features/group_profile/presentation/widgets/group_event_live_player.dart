import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_live_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

final _logger = AppLogger('GroupEventLivePlayer');

class GroupEventLiveStream {
  final String videoId;
  final bool isLive;
  final String subtitle;

  const GroupEventLiveStream({
    required this.videoId,
    required this.isLive,
    required this.subtitle,
  });
}

/// Event stream in the selected language; [fallback] when there is none.
class GroupEventLiveHeader extends ConsumerStatefulWidget {
  final String eventId;
  final String language;
  final bool audioOnly;
  final String fallbackTitle;
  final Widget fallback;

  const GroupEventLiveHeader({
    super.key,
    required this.eventId,
    required this.language,
    required this.audioOnly,
    required this.fallbackTitle,
    required this.fallback,
  });

  @override
  ConsumerState<GroupEventLiveHeader> createState() =>
      _GroupEventLiveHeaderState();
}

class _GroupEventLiveHeaderState extends ConsumerState<GroupEventLiveHeader> {
  GroupEventLiveStream? _stream;

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(
      groupEventInLanguageProvider((
        eventId: widget.eventId,
        language: widget.language,
      )),
    );
    // Keep the current stream playing while another language loads.
    eventAsync.valueOrNull?.fold((_) {}, (event) => _stream = _resolve(event));

    final stream = _stream;
    final fetching = eventAsync.isLoading && !eventAsync.hasValue;
    final Widget child;
    if (stream != null) {
      child = GroupEventLivePlayer(
        videoId: stream.videoId,
        isLive: stream.isLive,
        subtitle: stream.subtitle,
        audioOnly: widget.audioOnly,
        isSwitching: fetching,
      );
    } else if (fetching) {
      // Skeleton, not the cover, so the cover never flashes before the video.
      child = const AspectRatio(
        aspectRatio: 16 / 9,
        child: GroupEventLivePlaceholder(),
      );
    } else {
      child = widget.fallback;
    }
    return child;
  }

  GroupEventLiveStream? _resolve(GroupEvent event) {
    final videoId = GroupEventLiveUtils.videoIdOf(event);
    if (videoId == null) return null;
    final title = event.title.trim();
    return GroupEventLiveStream(
      videoId: videoId,
      isLive: GroupEventLiveUtils.isLiveLabel(event.liveYoutubeLink?.label),
      subtitle: title.isNotEmpty ? title : widget.fallbackTitle,
    );
  }
}

/// Inline YouTube player that stays mounted in audio mode so sound continues.
class GroupEventLivePlayer extends StatefulWidget {
  final String videoId;
  final bool audioOnly;

  /// Label-based guess; the player's own video data overrides it once known.
  final bool isLive;
  final String subtitle;

  /// True while the next language's stream is being fetched.
  final bool isSwitching;

  const GroupEventLivePlayer({
    super.key,
    required this.videoId,
    required this.audioOnly,
    required this.isLive,
    required this.subtitle,
    this.isSwitching = false,
  });

  @override
  State<GroupEventLivePlayer> createState() => _GroupEventLivePlayerState();
}

class _GroupEventLivePlayerState extends State<GroupEventLivePlayer> {
  static const _liveEdgeTolerance = Duration(seconds: 20);
  static const _switchTimeoutDuration = Duration(seconds: 10);
  static const _progressColors = ProgressBarColors(
    playedColor: AppColors.primary,
    handleColor: AppColors.primary,
  );

  // YouTube's own live timeline: seekable window and live-head flag.
  static const _progressScript = '''
JSON.stringify((function () {
  var p = (typeof player.getProgressState === 'function')
      ? player.getProgressState() : null;
  return { d: player.getDuration(), c: player.getCurrentTime(), p: p || null };
})())
''';

  late YoutubePlayerController _controller;
  int _playerGeneration = 0;
  bool _isReady = false;
  PlayerState _playerState = PlayerState.unknown;
  bool? _probedIsLive;
  String _probedVideoId = '';
  String _loggedVideoId = '';
  Timer? _livePoll;
  bool _polling = false;
  DateTime? _seekHoldUntil;
  // Loader stays up until the stream reports playing, not just ready.
  bool _switching = true;
  Timer? _switchTimeout;
  final _live = ValueNotifier<_LiveProgress>(const _LiveProgress());

  bool get _isLiveStream => _probedIsLive ?? widget.isLive;

  bool get _isPlaying => _playerState == PlayerState.playing;

  bool get _isBuffering =>
      !_isReady || _playerState == PlayerState.buffering;

  bool get _showLoader => !_isReady || _switching || widget.isSwitching;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.videoId);
    _switchTimeout = Timer(_switchTimeoutDuration, _endSwitch);
  }

  YoutubePlayerController _createController(String videoId) {
    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        controlsVisibleAtStart: false,
        disableDragSeek: true,
        useHybridComposition: true,
        enableCaption: false,
      ),
    );
    controller.addListener(_onControllerChanged);
    return controller;
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final value = _controller.value;
    final videoId = value.metaData.videoId;
    if (value.isReady && videoId.isNotEmpty && videoId != _probedVideoId) {
      _probedVideoId = videoId;
      _probeIsLive();
    }
    if (_switching &&
        value.isReady &&
        videoId == widget.videoId &&
        value.playerState == PlayerState.playing) {
      _endSwitch();
    }
    if (value.isReady == _isReady && value.playerState == _playerState) return;
    setState(() {
      _isReady = value.isReady;
      _playerState = value.playerState;
    });
    _syncLivePolling();
  }

  @override
  void didUpdateWidget(GroupEventLivePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive != oldWidget.isLive) _syncLivePolling();
    final isReady = _controller.value.isReady;
    if (widget.isSwitching && !oldWidget.isSwitching) {
      // The next stream is being fetched: pause and show the loader.
      _beginSwitch();
      if (isReady) _controller.pause();
    }
    if (widget.videoId == oldWidget.videoId) {
      if (!widget.isSwitching && oldWidget.isSwitching) {
        // Same stream after the fetch (or it failed): resume.
        _endSwitch();
        if (isReady) _controller.play();
      }
      return;
    }
    _probedIsLive = null;
    if (isReady) {
      // load() swaps the stream in place and autoplays it.
      _beginSwitch();
      _controller.load(widget.videoId);
      return;
    }
    _disposeController();
    setState(() {
      _controller = _createController(widget.videoId);
      _playerGeneration++;
      _probedVideoId = '';
      _isReady = false;
      _playerState = PlayerState.unknown;
    });
    _beginSwitch();
    _syncLivePolling();
  }

  void _beginSwitch() {
    _switchTimeout?.cancel();
    // Drop the loader anyway if the new stream never reports playing.
    _switchTimeout = Timer(_switchTimeoutDuration, _endSwitch);
    _live.value = const _LiveProgress();
    if (!_switching && mounted) setState(() => _switching = true);
  }

  void _endSwitch() {
    _switchTimeout?.cancel();
    _switchTimeout = null;
    if (_switching && mounted) setState(() => _switching = false);
  }

  @override
  void dispose() {
    _livePoll?.cancel();
    _switchTimeout?.cancel();
    _live.dispose();
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    _controller.removeListener(_onControllerChanged);
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
        _controller.pause();
        _controller.mute();
      } catch (_) {}
    }
    try {
      _controller.dispose();
    } catch (_) {}
  }

  // YouTube's video data carries an undocumented `isLive`; fall back to the
  // label when it is absent.
  Future<void> _probeIsLive() async {
    final webView = _controller.value.webViewController;
    if (webView == null) return;
    bool? isLive;
    try {
      final raw = await webView.evaluateJavascript(
        source: 'JSON.stringify(player.getVideoData())',
      );
      final data = raw is String ? jsonDecode(raw) : raw;
      if (data is Map && data['isLive'] is bool) {
        isLive = data['isLive'] as bool;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _probedIsLive = isLive);
    _syncLivePolling();
  }

  void _syncLivePolling() {
    final shouldPoll = _isReady && _isLiveStream;
    if (shouldPoll && _livePoll == null) {
      _livePoll = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => _pollLiveProgress(),
      );
    } else if (!shouldPoll) {
      _livePoll?.cancel();
      _livePoll = null;
    }
  }

  // getDuration() can run well ahead of the seekable window on a live stream,
  // so the timeline is built from getProgressState() instead.
  Future<void> _pollLiveProgress() async {
    final webView = _controller.value.webViewController;
    if (_polling || webView == null || !_controller.value.isReady) return;
    final hold = _seekHoldUntil;
    if (hold != null && DateTime.now().isBefore(hold)) return;
    _polling = true;
    try {
      final raw = await webView.evaluateJavascript(source: _progressScript);
      if (!mounted) return;
      final data = raw is String ? jsonDecode(raw) : raw;
      if (data is! Map) return;
      if (_loggedVideoId != _probedVideoId) {
        _loggedVideoId = _probedVideoId;
        _logger.info('Live progress for $_probedVideoId: $data');
      }
      final next = _parseProgress(data);
      if (next != null) _live.value = next;
    } catch (_) {
    } finally {
      _polling = false;
    }
  }

  _LiveProgress? _parseProgress(Map<dynamic, dynamic> data) {
    double? asDouble(Object? value) => value is num ? value.toDouble() : null;
    final progress = data['p'];
    double? start;
    double? end;
    double? current;
    bool? atHead;
    if (progress is Map) {
      start = asDouble(progress['seekableStart']);
      end = asDouble(progress['seekableEnd']);
      current = asDouble(progress['current']);
      final head = progress['isAtLiveHead'];
      if (head is bool) atHead = head;
    }
    current ??= asDouble(data['c']);
    if (current == null) return null;
    if (start == null || end == null || end <= start) {
      start = 0;
      end = asDouble(data['d']) ?? 0;
    }
    final span = end - start;
    final fraction =
        span <= 0 ? 1.0 : ((current - start) / span).clamp(0.0, 1.0);
    final atLiveEdge =
        atHead ??
        (span <= 0 || end - current <= _liveEdgeTolerance.inSeconds);
    return _LiveProgress(
      fraction: fraction,
      atLiveEdge: atLiveEdge,
      seekableStart: start,
      seekableEnd: end,
    );
  }

  void _runJs(String source) {
    final webView = _controller.value.webViewController;
    if (webView == null || !_controller.value.isReady) return;
    try {
      webView.evaluateJavascript(source: source);
    } catch (_) {}
  }

  // Polls pause briefly after a seek so the bar does not snap back.
  void _holdPolling() {
    _seekHoldUntil = DateTime.now().add(const Duration(milliseconds: 1500));
  }

  void _seekToFraction(double fraction) {
    final live = _live.value;
    final clamped = fraction.clamp(0.0, 1.0);
    if (!live.hasRange) {
      _controller.seekTo(_controller.metadata.duration * clamped);
      return;
    }
    final target =
        live.seekableStart + clamped * (live.seekableEnd - live.seekableStart);
    _runJs('player.seekTo($target, true); player.playVideo();');
    _live.value = live.copyWith(fraction: clamped, atLiveEdge: clamped >= 0.99);
    _holdPolling();
  }

  void _seekToLive() {
    final live = _live.value;
    final fallback =
        live.hasRange ? '${live.seekableEnd}' : 'player.getDuration()';
    _runJs('''
if (typeof player.seekToLiveHead === 'function') {
  player.seekToLiveHead();
} else {
  player.seekTo($fallback, true);
}
player.playVideo();
''');
    _live.value = live.copyWith(fraction: 1, atLiveEdge: true);
    _holdPolling();
  }

  void _onScrubStart() {
    _controller.updateValue(
      _controller.value.copyWith(isControlsVisible: true, isDragging: true),
    );
  }

  void _onScrubEnd(double fraction) {
    _controller.updateValue(
      _controller.value.copyWith(isControlsVisible: false, isDragging: false),
    );
    _seekToFraction(fraction);
  }

  void _togglePlayback() {
    if (!_isReady) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  List<Widget> _bottomActions() {
    if (_isLiveStream) {
      return [
        const SizedBox(width: 14),
        Expanded(
          child: _LiveProgressBar(
            progress: _live,
            onScrubStart: _onScrubStart,
            onScrubEnd: _onScrubEnd,
          ),
        ),
        const SizedBox(width: 10),
        ValueListenableBuilder<_LiveProgress>(
          valueListenable: _live,
          builder:
              (context, live, _) =>
                  _LiveChip(atLiveEdge: live.atLiveEdge, onTap: _seekToLive),
        ),
        const SizedBox(width: 10),
      ];
    }
    return [
      const SizedBox(width: 14),
      const CurrentPosition(),
      const SizedBox(width: 8),
      ProgressBar(isExpanded: true, colors: _progressColors),
      const SizedBox(width: 8),
      const RemainingDuration(),
      const SizedBox(width: 14),
    ];
  }

  // Shown whenever the stream is not playing, so the iframe's own paused and
  // loading overlay never shows through.
  Widget _buildCover() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImageWidget(
          imageUrl: 'https://img.youtube.com/vi/${widget.videoId}/hqdefault.jpg',
          fit: BoxFit.cover,
          placeholder: const ColoredBox(color: Colors.black),
          errorWidget: const ColoredBox(color: Colors.black),
        ),
        const ColoredBox(color: Colors.black38),
      ],
    );
  }

  Widget _buildLiveBadge() {
    return ValueListenableBuilder<_LiveProgress>(
      valueListenable: _live,
      builder:
          (context, live, _) =>
              _LiveBadge(atLiveEdge: live.atLiveEdge, onTap: _seekToLive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final playerHeight = width * 9 / 16;

        return Stack(
          children: [
            // Always mounted; audio mode clips it to a strip so sound continues.
            SizedBox(
              width: width,
              height: widget.audioOnly ? 1 : playerHeight,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minWidth: width,
                  maxWidth: width,
                  minHeight: playerHeight,
                  maxHeight: playerHeight,
                  child: YoutubePlayer(
                    key: ValueKey(_playerGeneration),
                    controller: _controller,
                    width: width,
                    thumbnail: _buildCover(),
                    progressIndicatorColor: AppColors.primary,
                    progressColors: _progressColors,
                    showVideoProgressIndicator: true,
                    bottomActions: _bottomActions(),
                  ),
                ),
              ),
            ),
            if (widget.audioOnly)
              _buildAudioRow(context, isDark)
            else ...[
              // Cover the player until YouTube is ready so nothing flickers.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _showLoader ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const GroupEventLivePlaceholder(),
                  ),
                ),
              ),
              if (_isLiveStream)
                Positioned(top: 10, left: 10, child: _buildLiveBadge()),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAudioRow(BuildContext context, bool isDark) {
    final busy = _isBuffering || _switching || widget.isSwitching;
    final primaryColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      color: isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.event_live_audio,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isLiveStream) ...[
                      const SizedBox(width: 8),
                      _buildLiveBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: TextStyle(fontSize: 13, color: secondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip:
                _isPlaying
                    ? context.l10n.player_pause
                    : context.l10n.player_play,
            iconSize: 28,
            color: primaryColor,
            onPressed: _isReady && !busy ? _togglePlayback : null,
            icon:
                busy
                    ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    )
                    : Icon(_isPlaying ? AppAssets.pause : AppAssets.play),
          ),
        ],
      ),
    );
  }
}

/// Shimmer block that fills its parent while the stream is loading.
class GroupEventLivePlaceholder extends StatelessWidget {
  const GroupEventLivePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Skeletonizer(
      enabled: true,
      child: Bone(width: double.infinity, height: double.infinity),
    );
  }
}

class _LiveProgress {
  final double fraction;
  final bool atLiveEdge;
  final double seekableStart;
  final double seekableEnd;

  const _LiveProgress({
    this.fraction = 1,
    this.atLiveEdge = true,
    this.seekableStart = 0,
    this.seekableEnd = 0,
  });

  bool get hasRange => seekableEnd > seekableStart;

  _LiveProgress copyWith({double? fraction, bool? atLiveEdge}) {
    return _LiveProgress(
      fraction: fraction ?? this.fraction,
      atLiveEdge: atLiveEdge ?? this.atLiveEdge,
      seekableStart: seekableStart,
      seekableEnd: seekableEnd,
    );
  }
}

/// Scrubbable timeline over the live seekable window.
class _LiveProgressBar extends StatefulWidget {
  final ValueListenable<_LiveProgress> progress;
  final VoidCallback onScrubStart;
  final ValueChanged<double> onScrubEnd;

  const _LiveProgressBar({
    required this.progress,
    required this.onScrubStart,
    required this.onScrubEnd,
  });

  @override
  State<_LiveProgressBar> createState() => _LiveProgressBarState();
}

class _LiveProgressBarState extends State<_LiveProgressBar> {
  double? _dragFraction;

  double _fractionAt(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(globalPosition);
    if (box.size.width <= 0) return 0;
    return (local.dx / box.size.width).clamp(0.0, 1.0);
  }

  void _start(Offset globalPosition) {
    widget.onScrubStart();
    setState(() => _dragFraction = _fractionAt(globalPosition));
  }

  void _end() {
    final fraction = _dragFraction;
    if (fraction == null) return;
    setState(() => _dragFraction = null);
    widget.onScrubEnd(fraction);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragDown: (details) => _start(details.globalPosition),
      onHorizontalDragUpdate:
          (details) => setState(
            () => _dragFraction = _fractionAt(details.globalPosition),
          ),
      onHorizontalDragEnd: (_) => _end(),
      // A plain tap arrives as down + cancel, which also seeks.
      onHorizontalDragCancel: _end,
      child: SizedBox(
        height: 28,
        child: ValueListenableBuilder<_LiveProgress>(
          valueListenable: widget.progress,
          builder:
              (context, live, _) => CustomPaint(
                painter: _LiveBarPainter(
                  fraction: _dragFraction ?? live.fraction,
                  dragging: _dragFraction != null,
                ),
              ),
        ),
      ),
    );
  }
}

class _LiveBarPainter extends CustomPainter {
  final double fraction;
  final bool dragging;

  const _LiveBarPainter({required this.fraction, required this.dragging});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final thickness = dragging ? 4.0 : 2.5;
    final playedX = size.width * fraction;
    final track =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round;
    final played =
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), track);
    canvas.drawLine(Offset(0, centerY), Offset(playedX, centerY), played);
    canvas.drawCircle(
      Offset(playedX, centerY),
      dragging ? 9 : 7,
      Paint()..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_LiveBarPainter old) =>
      old.fraction != fraction || old.dragging != dragging;
}

/// Red "LIVE" pill; grey while behind the live edge. Tap jumps to live.
class _LiveBadge extends StatelessWidget {
  final bool atLiveEdge;
  final VoidCallback onTap;

  const _LiveBadge({required this.atLiveEdge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: atLiveEdge ? AppColors.error : AppColors.grey800,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              context.l10n.event_live_badge,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                height: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// YouTube-style "● Live" chip for the control bar; red dot at the live edge.
class _LiveChip extends StatelessWidget {
  final bool atLiveEdge;
  final VoidCallback onTap;

  const _LiveChip({required this.atLiveEdge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: atLiveEdge ? AppColors.primary : AppColors.grey500,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.event_live_go_live,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
