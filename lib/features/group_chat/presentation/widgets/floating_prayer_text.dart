import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/prayer_intention_tint.dart';

/// Mantra shown when the viewer prays, by app language. Static for now; the
/// event will supply it later.
String prayerMantraForLocale(Locale locale) {
  return switch (locale.languageCode) {
    'hi' => 'ॐ तारे तुत्तारे तुरे स्वाहा',
    'ne' => 'ॐ तारे तुत्तारे तुरे स्वाहा',
    'mn' => 'Ом тарэ туттарэ турэ сууха',
    'bo' => 'ཨོཾ་ཏཱ་རེ་ཏུཏྟཱ་རེ་ཏུ་རེ་སྭཱ་ཧཱ།',
    'zh' => '嗡 達咧 都達咧 都咧 梭哈',
    _ => 'Om Tare Tuttare Ture Soha',
  };
}

/// Floats [text] up from [origin] and fades it out, like a tapped heart.
/// Goes into the root overlay so it rises above bottom sheets too.
void showFloatingPrayerText(
  BuildContext context, {
  required Offset origin,
  required String text,
  required Color accent,
  required bool isDark,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder:
        (_) => _FloatingPrayerText(
          origin: origin,
          text: text,
          accent: accent,
          isDark: isDark,
          onDone: () {
            if (entry.mounted) entry.remove();
          },
        ),
  );
  overlay.insert(entry);
}

class _FloatingPrayerText extends StatefulWidget {
  const _FloatingPrayerText({
    required this.origin,
    required this.text,
    required this.accent,
    required this.isDark,
    required this.onDone,
  });

  final Offset origin;
  final String text;

  /// Painted like the filled "Praying" button: accent pill, contrasting text.
  final Color accent;
  final bool isDark;
  final VoidCallback onDone;

  @override
  State<_FloatingPrayerText> createState() => _FloatingPrayerTextState();
}

class _FloatingPrayerTextState extends State<_FloatingPrayerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  static const double _rise = 110;
  static const double _sway = 10;

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Alignment keeps the text on screen even when the tap is at an edge:
    // the text's own fractional point lands on the tap's fractional point.
    final alignment = FractionalOffset(
      (widget.origin.dx / size.width).clamp(0.0, 1.0),
      (widget.origin.dy / size.height).clamp(0.0, 1.0),
    );

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final rise = Curves.easeOutCubic.transform(t) * _rise;
          final sway = math.sin(t * math.pi * 2) * _sway * (1 - t);
          final scale =
              0.7 + Curves.easeOutBack.transform(math.min(1, t * 3)) * 0.4;
          final opacity =
              t < 0.55 ? 1.0 : Curves.easeIn.transform((1 - t) / 0.45);
          return Align(
            alignment: alignment,
            child: Transform.translate(
              offset: Offset(sway, -rise),
              child: Transform.scale(
                scale: scale,
                child: Opacity(opacity: opacity, child: child),
              ),
            ),
          );
        },
        child: _buildPill(context),
      ),
    );
  }

  Widget _buildPill(BuildContext context) {
    final accent = widget.accent;
    final foreground = prayerAccentOnColor(accent);
    final border =
        prayerAccentNeedsBorder(accent, widget.isDark)
            ? (widget.isDark ? AppColors.cardBorderDark : AppColors.grey300)
            : accent;
    // Material gives the text its own style scope: an overlay entry has no
    // ancestor to inherit from, which is what draws the yellow debug lines.
    return Material(
      color: accent,
      shape: StadiumBorder(side: BorderSide(color: border)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          strutStyle: context.tibetanStrutStyle(15, compact: true),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: foreground,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
