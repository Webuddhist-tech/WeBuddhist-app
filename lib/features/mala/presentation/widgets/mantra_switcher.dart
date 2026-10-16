import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mantra_marquee.dart';

/// Deity artwork carousel with the mantra band underneath.
///
/// The artwork is an **infinite, looping** [PageView] flanked by chevrons:
/// swipes and chevrons both advance it and it wraps endlessly (the page is
/// seeded far from 0 and mapped back with `page % length`). The band below
/// shows the current mantra's script and transliteration as endless marquees
/// scrolling at [speedFactor]; it follows [index], so it switches when a page
/// settles.
///
/// Tapping either line opens that text in full in place of artwork and band,
/// with the marquees stopped; the close button brings the carousel back.
/// With a single mantra the carousel locks (no swipe, chevrons disabled).
///
/// A mantra without artwork shows just the band with the chevrons beside it,
/// centred vertically in whatever height the parent gives.
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

  late PageController _controller;

  /// Controllers replaced mid-life; disposed once their PageView is gone.
  final List<PageController> _retired = [];

  /// Whether the last build mounted the artwork PageView.
  bool _pageViewMounted = false;

  /// Which line is open in full, or null while the carousel is showing.
  _MantraLine? _expanded;

  bool get _canLoop => widget.mantras.length > 1;

  @override
  void initState() {
    super.initState();
    _controller = _newController();
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final c in _retired) {
      c.dispose();
    }
    super.dispose();
  }

  PageController _newController() {
    final length = widget.mantras.length;
    return PageController(
      initialPage: _canLoop ? _loopBase * length + widget.index : widget.index,
    );
  }

  /// A PageView that re-mounts would resume from the controller's original
  /// `initialPage`, not the mantra now selected, so seed a fresh one. The old
  /// controller is disposed after the frame, once its PageView has detached.
  void _reseedController() {
    _retired.add(_controller);
    _controller = _newController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final c in _retired) {
        c.dispose();
      }
      _retired.clear();
    });
  }

  int _logical(int page) {
    final length = widget.mantras.length;
    if (length == 0) return 0;
    return page % length;
  }

  /// Animate the carousel by [delta] pages (loops via the page → mantra map).
  /// Without the artwork PageView on screen, the index switches directly.
  void _animateBy(int delta) {
    if (!_canLoop) return;
    if (!_pageViewMounted || !_controller.hasClients) {
      final length = widget.mantras.length;
      widget.onIndexChanged((widget.index + delta) % length);
      return;
    }
    final current =
        _controller.hasClients && _controller.page != null
            ? _controller.page!.round()
            : _controller.initialPage;
    _controller.animateToPage(
      current + delta,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mantra = widget.mantras[widget.index];
    final script = mantra.tibetan;
    final transliteration =
        mantra.transliteration(widget.language) ??
        mantra.localizedName(widget.language);
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

    final showImage = mantra.deityImage != null;
    if (showImage && !_pageViewMounted) _reseedController();
    _pageViewMounted = showImage;

    final expanded = _expanded;
    if (expanded != null) {
      final isScript = expanded == _MantraLine.script && script != null;
      return _FullMantraCard(
        key: const ValueKey('mantra-full'),
        text: isScript ? script : transliteration,
        style: (isScript ? scriptStyle : transliterationStyle) ?? const TextStyle(),
        onClose: () => setState(() => _expanded = null),
      );
    }

    final band = _MantraBand(
      script: script,
      scriptStyle: scriptStyle,
      transliteration: transliteration,
      transliterationStyle: transliterationStyle,
      speedFactor: widget.speedFactor,
      onScriptTap: () => setState(() => _expanded = _MantraLine.script),
      onTransliterationTap:
          () => setState(() => _expanded = _MantraLine.transliteration),
    );
    final leftChevron = _Chevron(
      icon: AppAssets.caretLeft2,
      onTap: _canLoop ? () => _animateBy(-1) : null,
    );
    final rightChevron = _Chevron(
      icon: AppAssets.caretRight2,
      onTap: _canLoop ? () => _animateBy(1) : null,
    );

    if (!showImage) {
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
                child: PageView.builder(
                  controller: _controller,
                  physics:
                      _canLoop
                          ? const PageScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                  onPageChanged:
                      (page) => widget.onIndexChanged(_logical(page)),
                  // Null itemCount = unbounded forward; bounded at 0 backward,
                  // but the large initial page keeps that out of reach.
                  itemCount: _canLoop ? null : widget.mantras.length,
                  itemBuilder: (context, page) {
                    final image = widget.mantras[_logical(page)].deityImage;
                    if (image == null) return const SizedBox.shrink();
                    return Padding(
                      key: ValueKey<int>(page),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ResponsiveCoverImage(
                        image: image,
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  },
                ),
              ),
              rightChevron,
            ],
          ),
        ),
        const SizedBox(height: 12),
        band,
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
    final fill = isDark ? AppColors.malaMantraBandDark : AppColors.malaMantraBand;
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
    final fill = isDark ? AppColors.malaMantraBandDark : AppColors.malaMantraBand;

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
