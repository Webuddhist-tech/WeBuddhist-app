import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/prayer_room_scope.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/prayer_requests_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_request_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' show Either;

enum _Phase { finding, found, empty, failed }

/// "A prayer for you": deals through the room's cards while the server
/// picks one the viewer has not prayed for, slows the deal once it has, and
/// shows the pick with a pray button. Skip, or Next prayer once prayed,
/// picks again, passing every card shown so far so they come back last.
class RandomPrayerOverlay extends ConsumerStatefulWidget {
  const RandomPrayerOverlay({super.key, required this.scope, this.viewer});

  final PrayerRoomScope scope;

  /// The viewer as they join a card's avatar stack; null when signed out.
  final ChatPrayerUserDTO? viewer;

  static Future<void> show(
    BuildContext context, {
    required PrayerRoomScope scope,
    ChatPrayerUserDTO? viewer,
  }) {
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder:
          (_, _, _) => RandomPrayerOverlay(scope: scope, viewer: viewer),
      transitionBuilder:
          (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  ConsumerState<RandomPrayerOverlay> createState() =>
      _RandomPrayerOverlayState();
}

class _RandomPrayerOverlayState extends ConsumerState<RandomPrayerOverlay> {
  /// The deal runs at least this long before it starts to settle, so a
  /// fast answer still reads as a search; settling adds about a second.
  static const Duration _minFinding = Duration(milliseconds: 1800);

  /// The server takes this many excluded ids at most.
  static const int _maxExcludes = 50;

  _Phase _phase = _Phase.finding;
  ChatMessageDTO? _card;

  /// Every card shown, oldest first.
  final List<String> _shown = [];

  /// Cards dealt past while finding; the room's own, shuffled.
  List<ChatMessageDTO?> _deck = const [];

  /// Set once the answer is in: the deck slows to a stop, then shows it.
  bool _settling = false;
  Either<Failure, ChatMessageDTO>? _result;
  int _generation = 0;

  PrayerRequestsNotifier get _notifier =>
      ref.read(prayerRequestsProvider(widget.scope).notifier);

  @override
  void initState() {
    super.initState();
    unawaited(_pick());
  }

  List<String> _excludes() {
    if (_shown.length <= _maxExcludes) return List.of(_shown);
    return _shown.sublist(_shown.length - _maxExcludes);
  }

  /// What the deck has to deal: others' active requests already loaded,
  /// shuffled, without the card just shown. Blanks pad it to a stack of
  /// three so no card sits under itself.
  List<ChatMessageDTO?> _buildDeck() {
    final viewerId = widget.viewer?.userId ?? '';
    final current = _card?.id;
    final cards = <ChatMessageDTO?>[
      ...ref
          .read(prayerRequestsProvider(widget.scope))
          .requests
          .where(
            (request) =>
                !request.isCompleted &&
                request.id != current &&
                (viewerId.isEmpty || request.senderId != viewerId),
          ),
    ]..shuffle(math.Random());
    while (cards.length < 3) {
      cards.add(null);
    }
    return cards;
  }

  Future<void> _pick() async {
    final generation = ++_generation;
    _deck = _buildDeck();
    setState(() {
      _phase = _Phase.finding;
      _card = null;
      _settling = false;
      _result = null;
    });

    final minimum = Future<void>.delayed(_minFinding);
    final result = await _notifier.pickRandom(excludeIds: _excludes());
    await minimum;
    if (!mounted || generation != _generation) return;
    _result = result;
    setState(() => _settling = true);
  }

  /// The deck has come to rest: show what the server answered.
  void _onSettled() {
    final result = _result;
    if (result == null || !mounted) return;
    result.fold(
      (failure) => setState(() {
        _phase = failure is NotFoundFailure ? _Phase.empty : _Phase.failed;
      }),
      (picked) {
        _shown.add(picked.id);
        unawaited(HapticFeedback.mediumImpact());
        setState(() {
          _card = picked;
          _phase = _Phase.found;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(prayerRequestsProvider(widget.scope));
    // The notifier's copy carries the viewer's taps as they land.
    final spotlight = state.spotlight;
    final card =
        spotlight != null && spotlight.id == _card?.id ? spotlight : _card;

    final String title;
    switch (_phase) {
      case _Phase.finding:
        title = l10n.event_prayer_finding;
      case _Phase.found:
        title = l10n.event_prayer_found;
      case _Phase.empty:
        title = l10n.event_prayer_random_empty_title;
      case _Phase.failed:
        title = l10n.event_prayer_random_failed;
    }

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    strutStyle: context.tibetanStrutStyle(18, compact: true),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildStage(context, card),
                ),
                const Spacer(flex: 3),
                _buildAction(context, card),
                const SizedBox(height: 16),
              ],
            ),
            Positioned(
              top: 4,
              right: 12,
              child: _CloseButton(onTap: () => Navigator.of(context).pop()),
            ),
          ],
        ),
      ),
    );
  }

  /// The deck while finding, the picked card once found, a note otherwise.
  Widget _buildStage(BuildContext context, ChatMessageDTO? card) {
    final l10n = context.l10n;
    final Widget child;
    switch (_phase) {
      case _Phase.finding:
        child = _ShuffleDeck(
          key: const ValueKey('deck'),
          cards: _deck,
          settling: _settling,
          onSettled: _onSettled,
          builder:
              (card) =>
                  card == null ? const _BlankCard() : _tile(context, card),
        );
      case _Phase.found:
        child = KeyedSubtree(
          key: ValueKey('found-${card?.id}'),
          child: card == null ? const SizedBox.shrink() : _tile(context, card),
        );
      case _Phase.empty:
        child = _Note(
          key: const ValueKey('empty'),
          text: l10n.event_prayer_random_empty_body,
        );
      case _Phase.failed:
        child = const SizedBox.shrink(key: ValueKey('failed'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder:
          (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1).animate(animation),
              child: child,
            ),
          ),
      child: child,
    );
  }

  Widget _tile(BuildContext context, ChatMessageDTO request) {
    final live = _phase == _Phase.found;
    final name =
        chatSenderDisplayName(
          messageName: request.senderName,
          senderEmail: request.senderEmail,
        ) ??
        context.l10n.group_chat_unknown_sender;
    final tile = PrayerRequestTile(
      key: ValueKey(request.id),
      request: request,
      displayName: name,
      avatarUrl: request.senderAvatarUrl,
      onPray:
          live ? () => _notifier.pray(request.id, viewer: widget.viewer) : null,
    );
    return live ? tile : IgnorePointer(child: tile);
  }

  Widget _buildAction(BuildContext context, ChatMessageDTO? card) {
    final l10n = context.l10n;
    switch (_phase) {
      case _Phase.finding:
      case _Phase.empty:
        return const SizedBox(height: 52);
      case _Phase.found:
        // Skip stays quiet so the card gets the attention; once prayed,
        // moving on is the thing to do and gets the pill.
        if (card?.prayedByMe ?? false) {
          return _ActionPill(
            icon: AppAssets.shuffle,
            label: l10n.event_prayer_next,
            onTap: () => unawaited(_pick()),
          );
        }
        return _QuietAction(
          icon: AppAssets.shuffle,
          label: l10n.event_prayer_skip,
          onTap: () => unawaited(_pick()),
        );
      case _Phase.failed:
        return _ActionPill(
          icon: AppAssets.arrowsClockwise,
          label: l10n.group_chat_retry,
          onTap: () => unawaited(_pick()),
        );
    }
  }
}

/// A stack of three cards dealt from the top: the top card whips off to
/// the left while the ones beneath slide up a slot and a new one fades in
/// at the bottom. Deals run quick until [settling], then take three slower
/// ones to come to rest and call [onSettled].
class _ShuffleDeck extends StatefulWidget {
  const _ShuffleDeck({
    super.key,
    required this.cards,
    required this.settling,
    required this.onSettled,
    required this.builder,
  });

  /// Dealt in order, round and round; null is a blank card.
  final List<ChatMessageDTO?> cards;
  final bool settling;
  final VoidCallback onSettled;
  final Widget Function(ChatMessageDTO? card) builder;

  @override
  State<_ShuffleDeck> createState() => _ShuffleDeckState();
}

class _ShuffleDeckState extends State<_ShuffleDeck>
    with SingleTickerProviderStateMixin {
  static const Duration _dealPeriod = Duration(milliseconds: 230);
  static const List<Duration> _settlePeriods = [
    Duration(milliseconds: 320),
    Duration(milliseconds: 440),
    Duration(milliseconds: 620),
  ];

  /// How far down, how small and how faint each slot sits, top first.
  static const List<double> _slotDy = [0, 14, 28, 42];
  static const List<double> _slotScale = [1, 0.94, 0.88, 0.82];
  static const List<double> _slotOpacity = [1, 0.9, 0.7, 0];

  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener(_onDealDone);

  /// Index into the cards of the one flying off this deal.
  int _top = 0;
  int _settleStep = 0;

  @override
  void initState() {
    super.initState();
    _deal(_dealPeriod);
  }

  @override
  void didUpdateWidget(_ShuffleDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settling && !oldWidget.settling) _settleStep = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _deal(Duration period) {
    unawaited(HapticFeedback.selectionClick());
    _controller.duration = period;
    _controller.forward(from: 0);
  }

  void _onDealDone(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _top++);
    if (!widget.settling) {
      _deal(_dealPeriod);
    } else if (_settleStep < _settlePeriods.length) {
      _deal(_settlePeriods[_settleStep++]);
    } else {
      widget.onSettled();
    }
  }

  ChatMessageDTO? _cardAt(int offset) =>
      widget.cards[(_top + offset) % widget.cards.length];

  /// A card [t] of the way from slot [from] to the one above it.
  Widget _inSlot(
    Widget card,
    int from,
    int to,
    double t, {
    required bool clip,
  }) {
    final dy = _slotDy[from] + (_slotDy[to] - _slotDy[from]) * t;
    final scale = _slotScale[from] + (_slotScale[to] - _slotScale[from]) * t;
    final opacity =
        _slotOpacity[from] + (_slotOpacity[to] - _slotOpacity[from]) * t;
    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: clip ? _ClippedToDeck(child: card) : card,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final slide = Curves.easeOutCubic.transform(_controller.value);
        final fly = Curves.easeInCubic.transform(_controller.value);
        return AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Fades in at the bottom of the stack.
              Positioned.fill(
                child: _inSlot(
                  widget.builder(_cardAt(3)),
                  3,
                  2,
                  slide,
                  clip: true,
                ),
              ),
              Positioned.fill(
                child: _inSlot(
                  widget.builder(_cardAt(2)),
                  2,
                  1,
                  slide,
                  clip: true,
                ),
              ),
              // Becomes the top, and sizes the deck.
              _inSlot(widget.builder(_cardAt(1)), 1, 0, slide, clip: false),
              // The one dealt away, over everything until it is gone.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: (1 - fly * 1.6).clamp(0, 1),
                  child: FractionalTranslation(
                    translation: Offset(-1.25 * fly, -0.12 * fly),
                    child: Transform.rotate(
                      angle: -0.28 * fly,
                      alignment: Alignment.bottomLeft,
                      child: widget.builder(_cardAt(0)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A card beneath the top one, cut to the deck's height so a taller card
/// does not hang out below it.
class _ClippedToDeck extends StatelessWidget {
  const _ClippedToDeck({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: child,
      ),
    );
  }
}

/// Stands in for a card when nothing is loaded to deal.
class _BlankCard extends StatelessWidget {
  const _BlankCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1);
    Widget bar(double width) => Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: line,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 14, backgroundColor: line),
                const SizedBox(width: 8),
                bar(96),
              ],
            ),
            const SizedBox(height: 14),
            bar(double.infinity),
            const SizedBox(height: 8),
            bar(double.infinity),
            const SizedBox(height: 8),
            bar(160),
            const SizedBox(height: 20),
            bar(120),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        strutStyle: context.tibetanStrutStyle(14),
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Material(
          color: AppColors.surfaceWhite,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                Text(
                  label,
                  strutStyle: context.tibetanStrutStyle(15, compact: true),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Plain white text on the scrim, sized like the pill so nothing shifts
/// when one replaces the other.
class _QuietAction extends StatelessWidget {
  const _QuietAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: 0.85);
    return SizedBox(
      height: 52,
      child: Center(
        child: TextButton.icon(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: Icon(icon, size: 18, color: color),
          label: Text(
            label,
            strutStyle: context.tibetanStrutStyle(15, compact: true),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: const Icon(AppAssets.x, color: Colors.white),
        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        onPressed: onTap,
      ),
    );
  }
}
