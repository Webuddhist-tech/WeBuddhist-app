import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/splash_exit_transition.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/screens/splash_taglines.dart';
import 'package:google_fonts/google_fonts.dart';

/// Launch screen, playing the Figma loading animation (WeBuddhist-App ›
/// Onboarding › "updated loading animation"):
///
/// ```
///    0 ms  small logo, exactly as the native launch screen drew it
///  300 ms  logo grows to 144 and turns upright, "WeBuddhist" fades in  300 ms ease-in
///  600 ms  hold                                                        800 ms
/// 1400 ms  "We" and "Buddhist" settle into the tagline, "s" fades in   600 ms ease-in-out
/// 2000 ms  hold                                                         50 ms
/// 2050 ms  the rest of the tagline slides in from the right            500 ms ease-out
/// 2550 ms  hold, then [onIntroComplete]                                800 ms
/// 3350 ms  the next screen fades in over the still splash              600 ms ease-in
/// ```
///
/// The last step is the router's: see [SplashExitTransition].
///
/// Both taglines ("We Buddhists practice together" / "… practice daily") grow
/// out of the same "WeBuddhist" wordmark. The words are measured at runtime,
/// so each tagline settles into its own centred spacing. A tagline that does
/// not start with "We Buddhists", or does not fit on one line, cross-fades
/// from the wordmark instead.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.tagline,
    this.playIntro = true,
    this.onIntroComplete,
  });

  /// Overrides the random tagline; used by tests.
  final String? tagline;

  /// Play the launch intro. False shows the finished state at once, for the
  /// splashes shown after launch (e.g. while a login runs).
  final bool playIntro;

  /// Called once the intro has fully played, or at once when it is skipped
  /// ([playIntro] false, or animations disabled). Also fires if the screen
  /// goes away before then, so a hold on it never sticks.
  final VoidCallback? onIntroComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _introDuration = Duration(milliseconds: 3350);
  static const _logoIn = Interval(300 / 3350, 600 / 3350, curve: Curves.easeIn);
  static const _settle = Interval(
    1400 / 3350,
    2000 / 3350,
    curve: Curves.easeInOut,
  );
  static const _restIn = Interval(
    2050 / 3350,
    2550 / 3350,
    curve: Curves.easeOut,
  );
  static const _pulseDuration = Duration(milliseconds: 1600);

  /// The logo stays still while the next screen fades in over the splash.
  static const _pulseDelay = SplashExitTransition.duration;

  // Keep in sync with the native launch screens (60dp / 60pt logo, turned
  // 90° clockwise), so the first Flutter frame matches what they drew.
  static const double _launchLogoSize = 60;
  static const double _launchLogoTurn = math.pi / 2;
  static const double _logoSize = 144;
  static const double _taglineGap = 24;

  /// How far the rest of the tagline slides in from.
  static const double _restSlide = 40;
  static const double _horizontalPadding = 32;
  static const double _verticalPadding = 24;

  /// The brand wordmark the tagline grows out of.
  static const _wordmarkFirst = 'We';
  static const _wordmarkSecond = 'Buddhist';
  static const _wordmark = '$_wordmarkFirst$_wordmarkSecond';
  static const _suffix = 's';
  static const _taglinePrefix = '$_wordmarkFirst $_wordmarkSecond$_suffix ';

  late final int _taglineIndex = randomSplashTaglineIndex();

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: _introDuration,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _pulseDuration,
  );

  late final Animation<double> _logoInT = CurvedAnimation(
    parent: _intro,
    curve: _logoIn,
  );
  late final Animation<double> _settleT = CurvedAnimation(
    parent: _intro,
    curve: _settle,
  );
  late final Animation<double> _restInT = CurvedAnimation(
    parent: _intro,
    curve: _restIn,
  );
  late final Animation<double> _pulseScale = Tween<double>(
    begin: 1.0,
    end: 1.05,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  Timer? _pulseStart;
  bool _started = false;
  bool _completed = false;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _intro.addStatusListener(_onIntroStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.playIntro && !MediaQuery.disableAnimationsOf(context)) {
      _intro.forward();
    } else {
      // Jump to the finished state; this reports completed to the listener.
      _intro.value = 1;
    }
  }

  @override
  void dispose() {
    _notifyIntroComplete();
    _pulseStart?.cancel();
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onIntroStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _complete();
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    // Gentle pulse while a long auth restore keeps the splash up.
    _pulseStart = Timer(_pulseDelay, () => _pulse.repeat(reverse: true));
    _notifyIntroComplete();
  }

  void _notifyIntroComplete() {
    if (_notified) return;
    _notified = true;
    final onIntroComplete = widget.onIntroComplete;
    if (onIntroComplete == null) return;
    // May run inside a build (when the intro is skipped) and the callback
    // changes router state, so run it after the current frame.
    scheduleMicrotask(onIntroComplete);
  }

  TextStyle _mergedStyle(BuildContext context, TextStyle style) =>
      DefaultTextStyle.of(context).style.merge(style);

  TextPainter _painter(BuildContext context, String text, TextStyle style) =>
      TextPainter(
        text: TextSpan(text: text, style: _mergedStyle(context, style)),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();

  double _taglineLineHeight(BuildContext context, TextStyle style) {
    final painter = _painter(context, 'A', style);
    final height = painter.preferredLineHeight;
    painter.dispose();
    return height;
  }

  /// Where each word of [tagline] starts and ends up, or null when the
  /// tagline does not grow out of the wordmark or does not fit on one line.
  _TaglineWords? _measureWords(
    BuildContext context,
    String tagline,
    TextStyle style,
    double maxWidth,
  ) {
    if (!tagline.startsWith(_taglinePrefix)) return null;
    final rest = tagline.substring(_taglinePrefix.length).trim();
    if (rest.isEmpty) return null;

    final full = _painter(context, tagline, style);
    final wordmark = _painter(context, _wordmark, style);
    try {
      if (full.width > maxWidth) return null;
      double x(TextPainter painter, int offset) =>
          painter.getOffsetForCaret(TextPosition(offset: offset), Rect.zero).dx;
      // The wordmark is centred in the same box as the finished tagline.
      final wordmarkLeft = (full.width - wordmark.width) / 2;
      return _TaglineWords(
        rest: rest,
        width: full.width,
        height: full.height,
        firstFrom: wordmarkLeft,
        firstTo: 0,
        secondFrom: wordmarkLeft + x(wordmark, _wordmarkFirst.length),
        secondTo: x(full, '$_wordmarkFirst '.length),
        suffixFrom: wordmarkLeft + wordmark.width,
        suffixTo: x(full, '$_wordmarkFirst $_wordmarkSecond'.length),
        restTo: x(full, _taglinePrefix.length),
      );
    } finally {
      full.dispose();
      wordmark.dispose();
    }
  }

  Widget _wordsTagline(_TaglineWords words, String tagline, TextStyle style) {
    Widget word(double left, String text, [double opacity = 1]) => Positioned(
      left: left,
      top: 0,
      child: Opacity(
        opacity: opacity,
        child: Text(text, style: style, maxLines: 1, softWrap: false),
      ),
    );
    return Semantics(
      label: tagline,
      excludeSemantics: true,
      child: Center(
        child: SizedBox(
          width: words.width,
          height: words.height,
          child: AnimatedBuilder(
            animation: _intro,
            builder: (context, _) {
              final settle = _settleT.value;
              final restIn = _restInT.value;
              return Opacity(
                opacity: _logoInT.value,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    word(
                      lerpDouble(words.firstFrom, words.firstTo, settle)!,
                      _wordmarkFirst,
                    ),
                    word(
                      lerpDouble(words.secondFrom, words.secondTo, settle)!,
                      _wordmarkSecond,
                    ),
                    word(
                      lerpDouble(words.suffixFrom, words.suffixTo, settle)!,
                      _suffix,
                      settle,
                    ),
                    word(
                      words.restTo + _restSlide * (1 - restIn),
                      words.rest,
                      restIn,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _crossfadeTagline(String tagline, TextStyle style) {
    return AnimatedBuilder(
      animation: _intro,
      builder: (context, _) {
        final settle = _settleT.value;
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Opacity(
              opacity: _logoInT.value * (1 - settle),
              child: ExcludeSemantics(
                child: Text(
                  _wordmark,
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
            ),
            Opacity(
              opacity: settle,
              child: Text(tagline, textAlign: TextAlign.center, style: style),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Follows the phone, not the saved theme, so the native launch screen
    // hands off without a background change; the saved theme applies on the
    // screen that replaces the splash.
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Figma "Tittle/Large": Inter Bold 20/24. The tagline is English in every
    // locale, so it does not follow the locale's UI font.
    final taglineStyle = GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 24 / 20,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    );
    final tagline =
        widget.tagline ?? splashTaglines[_taglineIndex](context.l10n);

    final logo = AnimatedBuilder(
      animation: Listenable.merge([_logoInT, _pulseScale]),
      builder: (context, child) {
        final t = _logoInT.value;
        return Transform.scale(
          scale:
              lerpDouble(_launchLogoSize / _logoSize, 1, t)! *
              _pulseScale.value,
          child: Transform.rotate(
            angle: (1 - t) * _launchLogoTurn,
            child: child,
          ),
        );
      },
      child: Image.asset(
        AppAssets.weBuddhistLogo,
        width: _logoSize,
        height: _logoSize,
      ),
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final words = _measureWords(
            context,
            tagline,
            taglineStyle,
            constraints.maxWidth - 2 * _horizontalPadding,
          );
          final taglineWidget =
              words == null
                  ? _crossfadeTagline(tagline, taglineStyle)
                  : _wordsTagline(words, tagline, taglineStyle);

          // Logo stays at the window centre where the native launch screen
          // drew it, so only the tagline animates in below.
          final taglineTop =
              constraints.maxHeight / 2 + _logoSize / 2 + _taglineGap;
          final taglineRoom =
              constraints.maxHeight -
              taglineTop -
              bottomInset -
              _verticalPadding;
          if (taglineRoom < _taglineLineHeight(context, taglineStyle)) {
            // Too short for a full line under the centred logo; scroll it all.
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  _horizontalPadding,
                  _verticalPadding,
                  _horizontalPadding,
                  bottomInset + _verticalPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    logo,
                    const SizedBox(height: _taglineGap),
                    taglineWidget,
                  ],
                ),
              ),
            );
          }
          return Stack(
            children: [
              Center(child: logo),
              Positioned(
                top: taglineTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    _horizontalPadding,
                    0,
                    _horizontalPadding,
                    bottomInset + _verticalPadding,
                  ),
                  child: taglineWidget,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Horizontal offsets of the tagline words inside a box of [width], from the
/// wordmark ("WeBuddhist", `*From`) to the finished tagline (`*To`).
class _TaglineWords {
  const _TaglineWords({
    required this.rest,
    required this.width,
    required this.height,
    required this.firstFrom,
    required this.firstTo,
    required this.secondFrom,
    required this.secondTo,
    required this.suffixFrom,
    required this.suffixTo,
    required this.restTo,
  });

  /// The words after "We Buddhists".
  final String rest;
  final double width;
  final double height;
  final double firstFrom;
  final double firstTo;
  final double secondFrom;
  final double secondTo;
  final double suffixFrom;
  final double suffixTo;
  final double restTo;
}
