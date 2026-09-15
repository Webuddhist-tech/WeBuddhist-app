import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';

/// Mantra display + chevron switcher as an **infinite, looping carousel**.
///
/// Mantras are shown one full page at a time between the previous/next
/// chevrons. Both horizontal swipes and the chevrons advance the carousel, and
/// it wraps endlessly (last → first, first → last): the [PageView] is seeded at
/// a large page index and each page maps back to a mantra with `page % length`,
/// so there's no real edge to hit.
///
/// The current logical index is owned by the parent ([index]); page settles are
/// reported via [onIndexChanged]. With a single mantra the carousel locks (no
/// swipe, chevrons disabled).
class MantraSwitcher extends StatefulWidget {
  const MantraSwitcher({
    super.key,
    required this.mantras,
    required this.language,
    required this.index,
    required this.onIndexChanged,
    this.tibetanFontFamily,
  });

  final List<Mantra> mantras;

  /// Locale language code, used to resolve each mantra's transliteration/name.
  final String language;

  /// Current logical mantra index (`0..mantras.length - 1`).
  final int index;

  /// Fired with the new logical index when the carousel settles on a page.
  final ValueChanged<int> onIndexChanged;

  final String? tibetanFontFamily;

  @override
  State<MantraSwitcher> createState() => _MantraSwitcherState();
}

class _MantraSwitcherState extends State<MantraSwitcher> {
  /// Pages are unbounded forward; we seed far from 0 so the user can also swipe
  /// backward effectively "forever". `initialPage % length == index`.
  static const int _loopBase = 1000;

  late final PageController _controller;

  bool get _canLoop => widget.mantras.length > 1;

  @override
  void initState() {
    super.initState();
    final length = widget.mantras.length;
    final initialPage =
        _canLoop ? _loopBase * length + widget.index : widget.index;
    _controller = PageController(initialPage: initialPage);
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

  /// Animate the carousel by [delta] pages (loops via the page → mantra map).
  void _animateBy(int delta) {
    if (!_canLoop) return;
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Chevron(
          icon: AppAssets.caretLeft2,
          onTap: _canLoop ? () => _animateBy(-1) : null,
        ),
        Expanded(
          child: PageView.builder(
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
                tibetan: mantra.tibetan,
                tibetanFontFamily: widget.tibetanFontFamily,
                transliteration:
                    mantra.transliteration(widget.language) ??
                    mantra.localizedName(widget.language),
                theme: theme,
              );
            },
          ),
        ),
        _Chevron(
          icon: AppAssets.caretRight2,
          onTap: _canLoop ? () => _animateBy(1) : null,
        ),
      ],
    );
  }
}

/// One carousel page: smaller script line (when present) above the larger
/// localized transliteration, both centered. Long content stays scrollable
/// without a visible scrollbar so it does not clash with the chevrons.
///
/// Each page owns a [ScrollController] and sets `primary: false`. A
/// controller-less vertical [SingleChildScrollView] would otherwise inherit
/// the Scaffold's [PrimaryScrollController] on mobile, so scrolling one
/// mantra would move the next page after a horizontal swipe.
class _MantraPage extends StatefulWidget {
  const _MantraPage({
    super.key,
    required this.tibetan,
    required this.tibetanFontFamily,
    required this.transliteration,
    required this.theme,
  });

  final String? tibetan;
  final String? tibetanFontFamily;
  final String transliteration;
  final ThemeData theme;

  @override
  State<_MantraPage> createState() => _MantraPageState();
}

class _MantraPageState extends State<_MantraPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            controller: _scrollController,
            primary: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.tibetan != null) ...[
                        Semantics(
                          label: context.l10n.mala_mantra_label,
                          child: Text(
                            widget.tibetan!,
                            textAlign: TextAlign.center,
                            style: widget.theme.textTheme.titleMedium?.copyWith(
                              fontFamily: widget.tibetanFontFamily,
                              height: 1.4,
                              color: widget.theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        widget.transliteration,
                        textAlign: TextAlign.center,
                        style: widget.theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
