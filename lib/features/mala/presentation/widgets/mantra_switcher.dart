import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mantra_marquee.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

/// Mantra carousel: each page is one mantra's deity artwork (when it has
/// any) above its mantra band.
///
/// The carousel is an **infinite, looping** [PageView]: swipes and the
/// chevrons both advance it and it wraps endlessly (the page is seeded far
/// from 0 and mapped back with `page % length`). Every mantra is swipeable,
/// with or without artwork. A page with artwork shows the image between the
/// chevrons and the band below it; a page without shows the band between the
/// chevrons, centred vertically in whatever height the parent gives.
///
/// The band shows the mantra's script and transliteration as marquees that
/// scroll at [speedFactor] when the text is too wide to fit.
///
/// Tapping either line opens that text in full over the carousel; the close
/// button brings it back. The carousel stays mounted (hidden, tickers muted)
/// while the full text is open, so it keeps its page.
/// With a single mantra the carousel locks (no swipe, chevrons disabled).
class MantraSwitcher extends StatefulWidget {
  const MantraSwitcher({
    super.key,
    required this.mantras,
    required this.language,
    required this.index,
    required this.onIndexChanged,
    this.tibetanFontFamily,
    this.speedFactor = 1.0,
  });

  final List<Mantra> mantras;

  /// Locale language code, used to resolve each mantra's transliteration/name.
  final String language;

  /// Current logical mantra index (`0..mantras.length - 1`).
  final int index;

  /// Fired with the new logical index when the carousel settles on a page.
  final ValueChanged<int> onIndexChanged;

  final String? tibetanFontFamily;

  /// Marquee speed multiplier from the mala settings.
  final double speedFactor;

  @override
  State<MantraSwitcher> createState() => _MantraSwitcherState();
}

enum _MantraLine { script, transliteration }

class _MantraSwitcherState extends State<MantraSwitcher> {
  /// Pages are unbounded forward; we seed far from 0 so the user can also swipe
  /// backward effectively "forever". `initialPage % length == index`.
  static const int _loopBase = 1000;

  late final PageController _controller;

  /// Which line is open in full, or null while the carousel is showing.
  _MantraLine? _expanded;

  bool get _canLoop => widget.mantras.length > 1;

  @override
  void initState() {
    super.initState();
    final length = widget.mantras.length;
    _controller = PageController(
      initialPage: _canLoop ? _loopBase * length + widget.index : widget.index,
    );
  }

  @override
  void didUpdateWidget(covariant MantraSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent can change the index (or the list) without a swipe, e.g. a
    // clamp after the catalogue reloads. Move the carousel to match.
    if (widget.index != oldWidget.index ||
        widget.mantras.length != oldWidget.mantras.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncToIndex());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _logical(int page) {
    final length = widget.mantras.length;
    if (length == 0) return 0;
    return page % length;
  }

  /// Jumps to the page nearest the current one that shows [widget.index],
  /// unless it is already showing or a swipe/animation is in flight.
  void _syncToIndex() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    if (position.isScrollingNotifier.value) return;
    final page = _controller.page?.round();
    if (page == null || _logical(page) == widget.index) return;
    final length = widget.mantras.length;
    final target =
        _canLoop
            ? page - _logical(page) + widget.index
            : widget.index.clamp(0, length - 1);
    _controller.jumpToPage(target);
  }

  /// Animate the carousel by [delta] pages (loops via the page → mantra map).
  void _animateBy(int delta) {
    if (!_canLoop || !_controller.hasClients) return;
    final current = _controller.page?.round() ?? _controller.initialPage;
    _controller.animateToPage(
      current + delta,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _transliteration(Mantra mantra) =>
      mantra.transliteration(widget.language) ??
      mantra.localizedName(widget.language);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scriptStyle = theme.textTheme.titleMedium?.copyWith(
      fontFamily: widget.tibetanFontFamily,
      height: 1.4,
      color: theme.colorScheme.onSurface,
    );
    final transliterationStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: theme.colorScheme.onSurface,
    );

    final expanded = _expanded;
    final carousel = PageView.builder(
      controller: _controller,
      physics:
          _canLoop
              ? const PageScrollPhysics()
              : const NeverScrollableScrollPhysics(),
      onPageChanged: (page) => widget.onIndexChanged(_logical(page)),
      // Null itemCount = unbounded forward; bounded at 0 backward, but the
      // large initial page keeps that out of reach.
      itemCount: _canLoop ? null : widget.mantras.length,
      itemBuilder: (context, page) {
        final mantra = widget.mantras[_logical(page)];
        return _MantraPage(
          key: ValueKey<int>(page),
          image: mantra.deityImage,
          band: _MantraBand(
            script: mantra.tibetan,
            scriptStyle: scriptStyle,
            transliteration: _transliteration(mantra),
            transliterationStyle: transliterationStyle,
            speedFactor: widget.speedFactor,
            onScriptTap: () => setState(() => _expanded = _MantraLine.script),
            onTransliterationTap:
                () => setState(() => _expanded = _MantraLine.transliteration),
          ),
          leftChevron: _Chevron(
            icon: AppAssets.caretLeft2,
            onTap: _canLoop ? () => _animateBy(-1) : null,
          ),
          rightChevron: _Chevron(
            icon: AppAssets.caretRight2,
            onTap: _canLoop ? () => _animateBy(1) : null,
          ),
        );
      },
    );

    Widget? fullCard;
    if (expanded != null) {
      final mantra = widget.mantras[widget.index];
      final script = mantra.tibetan;
      final isScript = expanded == _MantraLine.script && script != null;
      fullCard = _FullMantraCard(
        key: const ValueKey('mantra-full'),
        text: isScript ? script : _transliteration(mantra),
        // The band keeps the script small; in full it reads at display size.
        style:
            (isScript
                    ? scriptStyle?.copyWith(fontSize: 28, height: 1.6)
                    : transliterationStyle) ??
                const TextStyle(),
        onClose: () => setState(() => _expanded = null),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Kept mounted while the full text is open so the PageView keeps its
        // page; a re-mounted PageView would restart at the controller's
        // initial page and show the wrong mantra's artwork.
        Visibility(
          visible: fullCard == null,
          maintainState: true,
          child: carousel,
        ),
        if (fullCard != null) fullCard,
      ],
    );
  }
}

/// One carousel page. With artwork: image between the chevrons, band below.
/// Without: band between the chevrons, centred in the page.
class _MantraPage extends StatelessWidget {
  const _MantraPage({
    super.key,
    required this.image,
    required this.band,
    required this.leftChevron,
    required this.rightChevron,
  });

  final ResponsiveImage? image;
  final Widget band;
  final Widget leftChevron;
  final Widget rightChevron;

  @override
  Widget build(BuildContext context) {
    final art = image;
    if (art == null) {
      return Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [leftChevron, Expanded(child: band), rightChevron],
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leftChevron,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ResponsiveCoverImage(
                    image: art,
                    fit: BoxFit.contain,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              rightChevron,
            ],
          ),
        ),
        const SizedBox(height: 12),
        band,
        // Room for the band's bottom dot, which overhangs by half its size.
        const SizedBox(height: _AccentDivider.dotSize / 2),
      ],
    );
  }
}

/// Tinted band framed by an accent line + dot on its top and bottom edges,
/// holding the two scrolling mantra lines. Each line opens in full on tap.
class _MantraBand extends StatelessWidget {
  const _MantraBand({
    required this.script,
    required this.scriptStyle,
    required this.transliteration,
    required this.transliterationStyle,
    required this.speedFactor,
    required this.onScriptTap,
    required this.onTransliterationTap,
  });

  final String? script;
  final TextStyle? scriptStyle;
  final String transliteration;
  final TextStyle? transliterationStyle;
  final double speedFactor;
  final VoidCallback onScriptTap;
  final VoidCallback onTransliterationTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        isDark ? AppColors.malaMantraAccentDark : AppColors.malaMantraAccent;
    final fill =
        isDark ? AppColors.malaMantraBandDark : AppColors.malaMantraBand;
    final label = context.l10n.mala_show_full_mantra;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          color: fill,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (script != null) ...[
                _TappableLine(
                  label: label,
                  onTap: onScriptTap,
                  child: MantraMarquee(
                    text: script!,
                    style: scriptStyle ?? const TextStyle(),
                    speedFactor: speedFactor,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              _TappableLine(
                label: label,
                onTap: onTransliterationTap,
                child: MantraMarquee(
                  text: transliteration,
                  style: transliterationStyle ?? const TextStyle(),
                  speedFactor: speedFactor,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: -_AccentDivider.dotSize / 2,
          child: _AccentDivider(color: accent),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -_AccentDivider.dotSize / 2,
          child: _AccentDivider(color: accent),
        ),
      ],
    );
  }
}

class _TappableLine extends StatelessWidget {
  const _TappableLine({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      hint: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Thin accent rule with a dot at its centre, fading out towards both edges.
class _AccentDivider extends StatelessWidget {
  const _AccentDivider({required this.color});

  final Color color;

  static const double dotSize = 8;

  @override
  Widget build(BuildContext context) {
    Widget line({required bool fadeStart}) {
      final colors = [color.withValues(alpha: 0), color];
      return Expanded(
        child: Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: fadeStart ? colors : colors.reversed.toList(),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        line(fadeStart: true),
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        line(fadeStart: false),
      ],
    );
  }
}

/// The full mantra text in a bordered, tinted card with a close button.
class _FullMantraCard extends StatelessWidget {
  const _FullMantraCard({
    super.key,
    required this.text,
    required this.style,
    required this.onClose,
  });

  final String text;
  final TextStyle style;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent =
        isDark ? AppColors.malaMantraAccentDark : AppColors.malaMantraAccent;
    final fill =
        isDark ? AppColors.malaMantraBandDark : AppColors.malaMantraBand;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent, width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        children: [
          Expanded(
            // Fill the card height so short text centres; long text scrolls.
            child: LayoutBuilder(
              builder:
                  (context, constraints) => SingleChildScrollView(
                    primary: false,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: style,
                        ),
                      ),
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            shape: CircleBorder(
              side: BorderSide(color: theme.colorScheme.onSurface),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: Tooltip(
                message: context.l10n.close,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    AppAssets.x,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      color: color,
      disabledColor: color.withValues(alpha: 0.25),
      splashRadius: 24,
    );
  }
}
