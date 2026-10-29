import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_palette.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG contrast ratio of two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

void main() {
  group('backgrounds', () {
    test('seven, each with the design\'s light and dark value', () {
      expect(
        {for (final b in ReaderBackground.values) b.name: (_hex(b.light), _hex(b.dark))},
        {
          'ricePaper': ('#FFF4E3', '#222222'),
          'gold': ('#FFF1DA', '#402F12'),
          'sky': ('#EBF2FA', '#272F3A'),
          'white': ('#FFFFFF', '#141414'),
          'plum': ('#EDE8EB', '#4D183B'),
          'templeRed': ('#FDECEC', '#3A1011'),
          'robeSaffron': ('#FFDED4', '#662510'),
        },
      );
    });

    test('Rice Paper is the default, also for an unknown name', () {
      expect(ReaderBackground.defaultBackground, ReaderBackground.ricePaper);
      expect(ReaderBackground.fromName('lavender'), ReaderBackground.ricePaper);
      expect(ReaderBackground.fromName(null), ReaderBackground.ricePaper);
      expect(ReaderBackground.fromName('plum'), ReaderBackground.plum);
    });

    test('the phone\'s brightness picks the light or dark value', () {
      final light = ReaderPalette.of(ReaderBackground.sky, Brightness.light);
      final dark = ReaderPalette.of(ReaderBackground.sky, Brightness.dark);
      expect(light.background, ReaderBackground.sky.light);
      expect(dark.background, ReaderBackground.sky.dark);
      expect(light.ink, const Color(0xFF222222));
      expect(dark.ink, const Color(0xFFFFFFFF));
    });
  });

  group('derived colours', () {
    test('are the ink at a set strength, blended to a solid colour', () {
      final page = ReaderBackground.ricePaper.light;
      final palette = ReaderPalette.of(
        ReaderBackground.ricePaper,
        Brightness.light,
      );
      Color ink(double alpha) => Color.alphaBlend(
        const Color(0xFF222222).withValues(alpha: alpha),
        page,
      );
      expect(palette.translation, ink(0.72));
      expect(palette.pastVerse, ink(0.70));
      expect(palette.verseNumber, ink(0.70));
      expect(palette.liveHighlight, ink(0.08));
      expect(palette.pillBackground, ink(0.06));
      expect(palette.divider, ink(0.10));
      for (final colour in [
        palette.translation,
        palette.pastVerse,
        palette.liveHighlight,
        palette.pillBackground,
      ]) {
        expect(colour.a, 1.0, reason: 'solid, not transparent');
      }
    });

    test('dark drawers are the page with 32% black over it', () {
      final dark = ReaderPalette.of(ReaderBackground.gold, Brightness.dark);
      expect(
        dark.drawerBackground,
        Color.alphaBlend(
          Colors.black.withValues(alpha: 0.32),
          ReaderBackground.gold.dark,
        ),
      );
      final light = ReaderPalette.of(ReaderBackground.gold, Brightness.light);
      expect(light.drawerBackground, ReaderBackground.gold.light);
    });

    test('fixed colours', () {
      final light = ReaderPalette.of(ReaderBackground.white, Brightness.light);
      final dark = ReaderPalette.of(ReaderBackground.white, Brightness.dark);
      expect(_hex(light.selectedChip), '#4D1B3B');
      expect(_hex(dark.selectedChip), '#DA9F3E');
      expect(_hex(light.livePill), '#D63A3D');
      expect(_hex(light.yigchung), '#1F4E9C');
      expect(_hex(dark.yigchung), '#9CBFF9');
      expect(light.pausedPill, light.pastVerse);
      expect(light.pausedPillText, Colors.white);
      expect(dark.pausedPillText, const Color(0xFF222222));
    });
  });

  group('contrast on all 14 background values', () {
    final cases = [
      for (final background in ReaderBackground.values)
        for (final brightness in Brightness.values)
          (
            '${background.name} ${brightness.name}',
            ReaderPalette.of(background, brightness),
          ),
    ];

    for (final (name, p) in cases) {
      test('$name: text at least 4.5:1', () {
        final pairs = {
          'text': (p.text, p.background),
          'translation': (p.translation, p.background),
          'past verse / verse number': (p.pastVerse, p.background),
          'yigchung': (p.yigchung, p.background),
          'live original on the live card': (p.liveOriginal, p.liveHighlight),
          'translation on the live card': (p.translation, p.liveHighlight),
          'pill title': (p.pillText, p.pillBackground),
          'pill count': (p.pillMuted, p.pillBackground),
          'sheet text': (p.ink, p.drawerBackground),
          'sheet muted text': (p.sheetMuted, p.drawerBackground),
          'selected chip label': (p.selectedChipText, p.selectedChip),
          'live pill label': (p.livePillText, p.livePill),
          'paused pill label': (p.pausedPillText, p.pausedPill),
        };
        final failing = {
          for (final MapEntry(:key, value: (fg, bg)) in pairs.entries)
            if (_contrast(fg, bg) < 4.5)
              key: '${_contrast(fg, bg).toStringAsFixed(2)}:1',
        };
        expect(failing, isEmpty);
      });

      // The Live pill's red is fixed by the design and is told apart by its
      // white label (checked above); against some dark pages its edge is
      // under 3:1, so it is not checked here.
      test('$name: controls at least 3:1', () {
        final pairs = {
          'selected chip': (p.selectedChip, p.drawerBackground),
          'paused pill': (p.pausedPill, p.background),
        };
        final failing = {
          for (final MapEntry(:key, value: (fg, bg)) in pairs.entries)
            if (_contrast(fg, bg) < 3)
              key: '${_contrast(fg, bg).toStringAsFixed(2)}:1',
        };
        expect(failing, isEmpty);
      });
    }
  });
}
