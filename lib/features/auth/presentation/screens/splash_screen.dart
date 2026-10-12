import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/screens/splash_taglines.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.tagline});

  /// Overrides the random tagline; used by tests.
  final String? tagline;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _introDuration = Duration(milliseconds: 900);
  static const _pulseDuration = Duration(milliseconds: 1600);
  // Keep in sync with the native launch screens (96dp / 96pt logo).
  static const double _logoSize = 96;
  static const double _taglineGap = 24;
  static const double _horizontalPadding = 32;
  static const double _verticalPadding = 24;

  late final int _taglineIndex = randomSplashTaglineIndex();

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: _introDuration,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _pulseDuration,
  );

  late final Animation<double> _taglineOpacity = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
  );
  late final Animation<double> _pulseScale = Tween<double>(
    begin: 1.0,
    end: 1.05,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _intro.forward().whenComplete(() {
      if (mounted) _pulse.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  double _taglineLineHeight(BuildContext context, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'A',
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final height = painter.preferredLineHeight;
    painter.dispose();
    return height;
  }

  @override
  Widget build(BuildContext context) {
    // Follows the phone, not the saved theme, so the native launch screen
    // hands off without a background change; the saved theme applies on the
    // screen that replaces the splash.
    final isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final taglineStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    );

    final logo = ScaleTransition(
      scale: _pulseScale,
      child: Image.asset(AppAssets.weBuddhistLogo, height: _logoSize),
    );
    final tagline = FadeTransition(
      opacity: _taglineOpacity,
      child: Text(
        widget.tagline ?? splashTaglines[_taglineIndex](context.l10n),
        textAlign: TextAlign.center,
        style: taglineStyle,
      ),
    );

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
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
                    tagline,
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
                  child: tagline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
