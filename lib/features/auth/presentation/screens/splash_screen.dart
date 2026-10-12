import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
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

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Logo stays at the window centre where the native launch screen
          // drew it, so only the tagline animates in below.
          final taglineTop = (constraints.maxHeight / 2 +
                  _logoSize / 2 +
                  _taglineGap)
              .clamp(0.0, constraints.maxHeight);
          return Stack(
            children: [
              Center(
                child: ScaleTransition(
                  scale: _pulseScale,
                  child: Image.asset(
                    AppAssets.weBuddhistLogo,
                    height: _logoSize,
                  ),
                ),
              ),
              Positioned(
                top: taglineTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: FadeTransition(
                  opacity: _taglineOpacity,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(32, 0, 32, bottomInset + 24),
                    child: Text(
                      widget.tagline ??
                          splashTaglines[_taglineIndex](context.l10n),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
