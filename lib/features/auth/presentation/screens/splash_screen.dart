import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
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

  late final String _tagline = widget.tagline ?? randomSplashTagline();

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: _introDuration,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _pulseDuration,
  );

  late final Animation<double> _logoOpacity = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
  );
  late final Animation<double> _logoScale = Tween<double>(
    begin: 0.8,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ),
  );
  late final Animation<double> _taglineOpacity = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
  );
  late final Animation<Offset> _taglineOffset = Tween<Offset>(
    begin: const Offset(0, 0.4),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
    ),
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: ScaleTransition(
                      scale: _pulseScale,
                      child: Image.asset(AppAssets.weBuddhistLogo, height: 96),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: SlideTransition(
                    position: _taglineOffset,
                    child: Text(
                      _tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
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
